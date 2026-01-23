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
        ELSE exp(-k * pow(lev_dist::float / len, p))
    END;
$$;

/*
    Function: score_candidates
    Get top N candidates from watchlist based on similarity()
    @Params:
        input_full_name: The input full name to match against the watchlist
        sim_top_n: Number of top candidates to consider from similarity() filtering
    @Returns:
        TABLE: id, full_name, name_len, input_name_len, sim_score, lev_score, phonetic_hits
*/
CREATE OR REPLACE FUNCTION name_detection.score_candidates(
    input_full_name TEXT,
    sim_top_n INT -- top N candidates from similarity
)
RETURNS TABLE (
    id BIGINT,
    full_name TEXT,
    name_len INT,
    input_name_len INT,
    sim_score FLOAT,
    lev_score FLOAT,
    phonetic_hits INT
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
        w.dmeta_alt,
        i.input_norm_name,
        i.input_name_len,
        i.input_soundex_code,
        i.input_metaphone_code,
        i.input_dmeta_primary,
        i.input_dmeta_alt
    -- FROM name_detection.watchlist w
    FROM name_detection.watchlist_test w
    CROSS JOIN input_full i
    WHERE w.norm_name % i.input_norm_name
),
-- sim scoring & top n
top_sim_candidates AS (
    SELECT
        id,
        full_name,
        norm_name,
        name_len,
        soundex_code,
        metaphone_code,
        dmeta_primary,
        dmeta_alt,
        input_norm_name,
        input_name_len,
        input_soundex_code,
        input_metaphone_code,
        input_dmeta_primary,
        input_dmeta_alt,
        similarity(norm_name, input_norm_name) AS sim_score
    FROM candidates
    ORDER BY sim_score DESC
    LIMIT sim_top_n
)
SELECT
    id,
    full_name,
    name_len,
    input_name_len,
    sim_score,
    name_detection.processed_distance_score(
        levenshtein(norm_name, input_norm_name),
        greatest(name_len, input_name_len)
    ) AS lev_score,
    (
        (soundex_code = input_soundex_code)::int +
        (metaphone_code = input_metaphone_code)::int +
        (dmeta_primary = input_dmeta_primary)::int +
        (dmeta_alt = input_dmeta_alt)::int
    ) AS phonetic_hits
FROM top_sim_candidates;
$$;
