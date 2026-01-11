/*
    Function: processed_distance_score
    @Params:
        lev_dist: Levenshtein distance between two names
        len: Length of the longer name
        k: Scaling factor to adjust the steepness of the decay curve
        p: Damping factor to adjust the curvature of the decay
    @Returns:
        FLOAT: Processed distance score in [0,1]
*/
CREATE OR REPLACE FUNCTION processed_distance_score(
    lev_dist INT,
    len INT,
    k FLOAT DEFAULT 3.5, -- scaling factor
    p FLOAT DEFAULT 1.5 -- damping factor
)
RETURNS FLOAT
LANGUAGE SQL IMMUTABLE AS $$
SELECT
    CASE
        WHEN lev_dist = 0 THEN 1.0
        WHEN lev_dist = 1 THEN 1.0 - (1.0 / len)
        ELSE exp(-k * pow(lev_dist::float / len, p))
    END;
$$;

/*
    Function: match_watchlist
    @Params:
        input_full_name: The input full name to match against the watchlist
        limit_results: Maximum number of results to return
        w_s: Weight for similarity score
        w_d: Weight for distance score
        confidence_threshold: Minimum base score to consider phonetic boost
        phonetic_boost: Boost factor per phonetic match
        length_coverage_factor: Factor for length coverage adjustment
    @Returns:
        TABLE: watchlist_id, matched_watchlist_full_name, final_score
*/
CREATE OR REPLACE FUNCTION match_watchlist(
    input_full_name TEXT,
    limit_results INT DEFAULT 10,
    w_s FLOAT DEFAULT 0.4, -- similarity weight
    w_d FLOAT DEFAULT 0.6, -- distance weight
    confidence_threshold FLOAT DEFAULT 0.5, -- minimum score for phonetic boost
    phonetic_boost FLOAT DEFAULT 0.2, -- phonetic boost factor
    length_coverage_factor FLOAT DEFAULT 0.8 -- length coverage factor
)
RETURNS TABLE (
    watchlist_id BIGINT,
    matched_watchlist_full_name TEXT,
    final_score FLOAT
)
LANGUAGE SQL STABLE AS $$
WITH input AS (
    SELECT
        name_detection.normalise_and_sort_name(input_full_name) AS input_norm_name
),
input_full AS (
    SELECT
        *,
        char_length(input_norm_name) AS input_name_len,
        soundex(input_norm_name) AS input_soundex_code,
        metaphone(input_norm_name, 8) AS input_metaphone_code,
        dmetaphone(input_norm_name) AS input_dmeta_primary,
        dmetaphone_alt(input_norm_name) AS input_dmeta_alt
    FROM input
),
candidates AS (
    SELECT
        w.id,
        w.full_name,
        w.name_len,
        i.input_name_len,
        similarity(w.norm_name, i.input_norm_name) AS sim_score,
        levenshtein(w.norm_name, i.input_norm_name, 1, 1, 1) AS lev_dist,
        (w.soundex_code = i.input_soundex_code)::int +
        (w.metaphone_code = i.input_metaphone_code)::int +
        (w.dmeta_primary = i.input_dmeta_primary)::int +
        (w.dmeta_alt = i.input_dmeta_alt)::int AS phonetic_hits
    FROM name_detection.watchlist w
    CROSS JOIN input_full i
    WHERE
        w.norm_name % i.input_norm_name
        OR w.dmeta_primary = i.input_dmeta_primary
        OR w.dmeta_alt = i.input_dmeta_alt
    ORDER BY similarity(w.norm_name, i.input_norm_name) DESC
    LIMIT 100
),
scored AS (
    SELECT
        id,
        full_name,
        name_len,
        input_name_len,
        sim_score,
        processed_distance_score(
            lev_dist,
            greatest(name_len, input_name_len)
        ) AS lev_score,
        phonetic_hits
    FROM candidates
),
combined AS (
    SELECT
        id,
        full_name,
        name_len,
        input_name_len,
        (w_s * sim_score + w_d * lev_score) AS base_score,
        phonetic_hits
    FROM scored
),
boosted AS (
    SELECT
        id,
        full_name,
        name_len,
        input_name_len,
        CASE
            WHEN (phonetic_hits > 0 AND base_score >= confidence_threshold) THEN
                base_score + phonetic_boost * phonetic_hits
            ELSE
                base_score
        END AS boosted_score
    FROM combined
),
final AS (
    SELECT
        id,
        full_name,
        boosted_score * pow((least(name_len, input_name_len)::float) / greatest(name_len, input_name_len), length_coverage_factor) AS final_score
    FROM boosted
)
SELECT
    id,
    full_name,
    round(least(1.0, greatest(0.0, final_score))::numeric, 4)
FROM final
ORDER BY final_score DESC
LIMIT limit_results;
$$;
