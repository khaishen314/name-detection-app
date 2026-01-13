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
CREATE OR REPLACE FUNCTION name_detection.processed_distance_score(
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
        sim_top_n: Number of top candidates to consider from similarity() filtering
        w_s: Weight for similarity score
        confidence_threshold: Minimum base score to consider phonetic boost
        phonetic_boost: Boost factor per phonetic match
        length_coverage_factor: Factor for length coverage adjustment
    @Returns:
        TABLE: watchlist_id, matched_watchlist_full_name, final_score
*/
CREATE OR REPLACE FUNCTION name_detection.match_watchlist(
    input_full_name TEXT,
    limit_results INT DEFAULT 500,
    sim_top_n INT DEFAULT 200000, -- top N candidates from similarity
    w_s FLOAT DEFAULT 0.4, -- similarity weight [0, 1]
    confidence_threshold FLOAT DEFAULT 0.45, -- minimum score for phonetic boost [0.4, 0.5]
    phonetic_boost FLOAT DEFAULT 0.2, -- phonetic boost factor [0.1, 0.25]
    length_coverage_factor FLOAT DEFAULT 0.95 -- length coverage factor
)
RETURNS TABLE (
    watchlist_id BIGINT,
    matched_watchlist_full_name TEXT,
    final_score FLOAT
)
LANGUAGE SQL STABLE AS $$
-- normalise input name
WITH input AS (
    SELECT
        input_full_name,
        name_detection.normalise_and_sort_name(input_full_name) AS input_norm_name
),
-- compute input helpers
input_full AS (
    SELECT
        input_norm_name,
        char_length(input_norm_name) AS input_name_len,
        soundex(input_full_name) AS input_soundex_code,
        metaphone(input_full_name, 8) AS input_metaphone_code,
        dmetaphone(input_full_name) AS input_dmeta_primary,
        dmetaphone_alt(input_full_name) AS input_dmeta_alt
    FROM input
),
-- similarity filter
candidates AS (
    SELECT 
        w.id,
        w.full_name,
        w.norm_name,
        w.name_len,
        w.soundex_code,
        w.metaphone_code,
        w.dmeta_primary,
        w.dmeta_alt
    FROM name_detection.watchlist w
    JOIN input_full i ON TRUE
    WHERE w.norm_name % i.input_norm_name
    ORDER BY similarity(w.norm_name, i.input_norm_name) DESC
    LIMIT sim_top_n
),
-- scoring
scored AS (
    SELECT
        w.id,
        w.full_name,
        w.name_len,
        i.input_name_len,
        similarity(w.norm_name, i.input_norm_name) AS sim_score,
        name_detection.processed_distance_score(
            levenshtein(w.norm_name, i.input_norm_name),
            greatest(w.name_len, i.input_name_len)
        ) AS lev_score,
        (
            (w.soundex_code = i.input_soundex_code)::int +
            (w.metaphone_code = i.input_metaphone_code)::int +
            (w.dmeta_primary = i.input_dmeta_primary)::int +
            (w.dmeta_alt = i.input_dmeta_alt)::int
        ) AS phonetic_hits
    FROM candidates w
    CROSS JOIN input_full i
),
combined AS (
    SELECT
        id,
        full_name,
        name_len,
        input_name_len,
        (w_s * sim_score + (1 - w_s) * lev_score) AS base_score,
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
            WHEN phonetic_hits > 0 AND base_score >= confidence_threshold
            THEN base_score + phonetic_boost * (1 - base_score)
            ELSE base_score
        END AS boosted_score
    FROM combined
)
SELECT
    id,
    full_name,
    round(
        least(
            1.0,
            boosted_score *
            pow(
                least(name_len, input_name_len)::float /
                greatest(name_len, input_name_len),
                length_coverage_factor
            )
        )::numeric,
        4
    ) AS final_score
FROM boosted
ORDER BY final_score DESC
LIMIT limit_results;
$$;
