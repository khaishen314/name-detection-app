/* 
    Dummy table for testing
    Contains 150,000 random strings & 50,000 actual SEA names
*/
-- DROP TABLE IF EXISTS name_detection.watchlist_test;
-- CREATE TABLE IF NOT EXISTS name_detection.watchlist_test (
--     LIKE name_detection.watchlist INCLUDING ALL
-- );
-- INSERT INTO name_detection.watchlist_test (full_name)
-- SELECT
--     string_agg(
--         chr(97 + floor(random() * 26)::int),
--         ''
--     )
-- FROM generate_series(1, 150000) g,
--      generate_series(1, 5 + floor(random() * 10)::int) s
-- GROUP BY g;
-- CREATE TABLE IF NOT EXISTS tmp_first_names (name TEXT);
-- CREATE TABLE IF NOT EXISTS tmp_last_names (name TEXT);
-- INSERT INTO tmp_first_names VALUES
-- ('Ahmad'), ('Muhammad'), ('Mohd'), ('Nur'), ('Siti'), ('Aisyah'),
-- ('Firdaus'), ('Aiman'), ('Daniel'), ('Aina'), ('Wei'), ('Ming'),
-- ('Kumar'), ('Raj'), ('Arjun'), ('Ravi'), ('Ainul'), ('Hafiz'), ('Lina'), 
-- ('Farah'), ('Hana'), ('Yusuf'), ('Ibrahim'), ('Zain'), ('Hassan'),
-- ('Lee'), ('Chan'), ('Chee'), ('Ling'), ('Mei'), ('Xiu'),
-- ('Devi'), ('Priya'), ('Anita'), ('Lakshmi'), ('Rani'), ('Sundari'), 
-- ('Gopal'), ('Mani'), ('Rashid'), ('Farid'), ('Jamal'), ('Latif'), 
-- ('Nadia'), ('Amina'), ('Fatimah'), ('Zulaikha'), ('Huda'), 
-- ('Salmah'), ('Rashida'), ('Ho'), ('Tan'), ('Ying'), ('Yi');
-- INSERT INTO tmp_last_names VALUES
-- ('Ali'), ('Hassan'), ('Abdullah'), ('Rahman'), ('Ismail'),
-- ('Ahmad'), ('Lim'), ('Tan'), ('Wong'), ('Kaur'),
-- ('Singh'), ('Kumarasamy'), ('Subramaniam'), ('Ramasamy'),
-- ('Chong'), ('Lee'), ('Chan'), ('Cheah'), ('Goh'),
-- ('Zain'), ('Ibrahim'), ('Yusuf'), ('Hafiz'), ('Farid'),
-- ('Abu'), ('Bakar'), ('Jamaluddin'), ('Sulaiman'),
-- ('Ong'), ('Teo'), ('Chua'), ('Ng'), ('Tay'),
-- ('Rashid'), ('Rahim'), ('Aziz'), ('Mustafa'), ('Ho'),
-- ('Nair'), ('Chan'), ('Lee'), ('Wong'), ('Teoh'), ('Liew');
-- INSERT INTO name_detection.watchlist_test (full_name)
-- SELECT
--     fn1.name || ' ' ||
--     CASE
--         WHEN r < 0.70 THEN
--             CASE
--                 WHEN r2 < 0.5 THEN 'bin'
--                 ELSE 'binti'
--             END || ' '
--         WHEN r < 0.85 THEN
--             CASE
--                 WHEN r2 < 0.5 THEN 'A/L'
--                 ELSE 'A/P'
--             END || ' '
--         ELSE
--             CASE
--                 WHEN r2 < 0.1 THEN 'Xin'
--                 WHEN r2 < 0.2 THEN 'Ting'
--                 WHEN r2 < 0.3 THEN 'Yuan'
--                 WHEN r2 < 0.4 THEN 'Kai'
--                 WHEN r2 < 0.5 THEN 'Hui'
--                 WHEN r2 < 0.6 THEN 'Ling'
--                 WHEN r2 < 0.7 THEN 'Fang'
--                 WHEN r2 < 0.8 THEN 'Zhen'
--                 WHEN r2 < 0.9 THEN 'Zhi'
--                 ELSE 'Weng'
--             END || ' '
--     END ||
--     fn2.name || ' ' ||
--     ln.name
-- FROM
--     tmp_first_names fn1
-- CROSS JOIN tmp_first_names fn2
-- CROSS JOIN tmp_last_names ln
-- CROSS JOIN LATERAL (
--     SELECT random() AS r, random() AS r2
-- ) rnd
-- ORDER BY random()
-- LIMIT 50000;
-- UPDATE name_detection.watchlist_test
-- SET full_name = regexp_replace(full_name, 'Muhammad', 'Mohamad')
-- WHERE random() < 0.2;
-- UPDATE name_detection.watchlist_test
-- SET full_name = regexp_replace(full_name, 'Muhammad', 'Mohamed')
-- WHERE random() < 0.2;
-- UPDATE name_detection.watchlist_test
-- SET full_name = regexp_replace(full_name, 'Muhammad', 'Mohammad')
-- WHERE random() < 0.2;
-- UPDATE name_detection.watchlist_test
-- SET full_name = regexp_replace(full_name, 'Muhammad', 'Mohd')
-- WHERE random() < 0.2;
-- UPDATE name_detection.watchlist_test
-- SET full_name = regexp_replace(full_name, 'ai', 'ia')
-- WHERE random() < 0.05;

----------------------------------------------------------------------------------------------------
/*
    Preview watchlist_test
*/
-- SELECT COUNT(*) AS total_records FROM name_detection.watchlist_test;
-- SELECT *
-- FROM name_detection.watchlist_test
-- LIMIT 10;

----------------------------------------------------------------------------------------------------
/*
    Test 1: Single-name lookup
    Passing criterion: Matching names appear in top 20 results
*/
-- WITH input AS (
--     SELECT
--         'Muhammad Firdaus bin Ahmad' AS input_full_name,
--         name_detection.normalise_and_sort_name('Muhammad Firdaus bin Ahmad') AS norm,
--         soundex(name_detection.normalise_and_sort_name('Muhammad Firdaus bin Ahmad')) AS sx,
--         dmetaphone(name_detection.normalise_and_sort_name('Muhammad Firdaus bin Ahmad')) AS dm
-- )
-- SELECT
--     w.full_name,
--     similarity(w.norm_name, i.norm) AS sim
-- FROM name_detection.watchlist_test w
-- JOIN input i ON true
-- WHERE
--     w.norm_name % i.norm
-- ORDER BY sim DESC
-- LIMIT 20;
-- WITH input AS (
--     SELECT
--         'Tan Mei Mei' AS input_full_name,
--         name_detection.normalise_and_sort_name('Tan Mei Mei') AS norm,
--         soundex(name_detection.normalise_and_sort_name('Tan Mei Mei')) AS sx,
--         dmetaphone(name_detection.normalise_and_sort_name('Tan Mei Mei')) AS dm
-- )
-- SELECT
--     w.full_name,
--     similarity(w.norm_name, i.norm) AS sim
-- FROM name_detection.watchlist_test w
-- JOIN input i ON true
-- WHERE
--     w.norm_name % i.norm
-- ORDER BY sim DESC
-- LIMIT 20;

----------------------------------------------------------------------------------------------------
/*
    Test 2: Performance benchmark
    Passing criterion: Query executes within SLA < 20ms
    Comment out line 79 and line 96
    Add in line 80 and line 97 
    in 06_functions.sql to test
*/
-- example match
-- SELECT *
-- FROM name_detection.match_watchlist('mohamad ali bin hassan');

-- -- run EXPLAIN ANALYZE
-- EXPLAIN ANALYZE
-- SELECT *
-- FROM name_detection.match_watchlist('mohamad ali bin hassan');

----------------------------------------------------------------------------------------------------
EXPLAIN ANALYZE
WITH input AS (
    SELECT
        'mohamad ali bin hassan' AS input_full_name,
        name_detection.normalise_and_sort_name('mohamad ali bin hassan') AS input_norm_name
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
    FROM name_detection.watchlist_test w
    JOIN input_full i ON TRUE
    WHERE w.norm_name % i.input_norm_name
    ORDER BY similarity(w.norm_name, i.input_norm_name) DESC
    LIMIT 200000
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
        (0.4 * sim_score + (1 - 0.4) * lev_score) AS base_score,
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
            WHEN phonetic_hits > 0 AND base_score >= 0.45
            THEN base_score + 0.2 * (1 - base_score)
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
                0.95
            )
        )::numeric,
        4
    ) AS final_score
FROM boosted
ORDER BY final_score DESC
LIMIT 500;