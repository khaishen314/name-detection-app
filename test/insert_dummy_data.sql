/* 
    Dummy table for testing
    Contains 150,000 random strings & 50,000 actual SEA names
*/

INSERT INTO name_detection.watchlist (full_name)
SELECT
    string_agg(
        chr(97 + floor(random() * 26)::int),
        ''
    )
FROM generate_series(1, 150000) g,
     generate_series(1, 5 + floor(random() * 10)::int) s
GROUP BY g;
CREATE TABLE IF NOT EXISTS tmp_first_names (name TEXT);
CREATE TABLE IF NOT EXISTS tmp_last_names (name TEXT);
INSERT INTO tmp_first_names VALUES
('Ahmad'), ('Muhammad'), ('Mohd'), ('Nur'), ('Siti'), ('Aisyah'),
('Firdaus'), ('Aiman'), ('Daniel'), ('Aina'), ('Wei'), ('Ming'),
('Kumar'), ('Raj'), ('Arjun'), ('Ravi'), ('Ainul'), ('Hafiz'), ('Lina'), 
('Farah'), ('Hana'), ('Yusuf'), ('Ibrahim'), ('Zain'), ('Hassan'),
('Lee'), ('Chan'), ('Chee'), ('Ling'), ('Mei'), ('Xiu'),
('Devi'), ('Priya'), ('Anita'), ('Lakshmi'), ('Rani'), ('Sundari'), 
('Gopal'), ('Mani'), ('Rashid'), ('Farid'), ('Jamal'), ('Latif'), 
('Nadia'), ('Amina'), ('Fatimah'), ('Zulaikha'), ('Huda'), 
('Salmah'), ('Rashida'), ('Ho'), ('Tan'), ('Ying'), ('Yi');
INSERT INTO tmp_last_names VALUES
('Ali'), ('Hassan'), ('Abdullah'), ('Rahman'), ('Ismail'),
('Ahmad'), ('Lim'), ('Tan'), ('Wong'), ('Kaur'),
('Singh'), ('Kumarasamy'), ('Subramaniam'), ('Ramasamy'),
('Chong'), ('Lee'), ('Chan'), ('Cheah'), ('Goh'),
('Zain'), ('Ibrahim'), ('Yusuf'), ('Hafiz'), ('Farid'),
('Abu'), ('Bakar'), ('Jamaluddin'), ('Sulaiman'),
('Ong'), ('Teo'), ('Chua'), ('Ng'), ('Tay'),
('Rashid'), ('Rahim'), ('Aziz'), ('Mustafa'), ('Ho'),
('Nair'), ('Chan'), ('Lee'), ('Wong'), ('Teoh'), ('Liew');
INSERT INTO name_detection.watchlist (full_name)
SELECT
    fn1.name || ' ' ||
    CASE
        WHEN r < 0.70 THEN
            CASE
                WHEN r2 < 0.5 THEN 'bin'
                ELSE 'binti'
            END || ' '
        WHEN r < 0.85 THEN
            CASE
                WHEN r2 < 0.5 THEN 'A/L'
                ELSE 'A/P'
            END || ' '
        ELSE
            CASE
                WHEN r2 < 0.1 THEN 'Xin'
                WHEN r2 < 0.2 THEN 'Ting'
                WHEN r2 < 0.3 THEN 'Yuan'
                WHEN r2 < 0.4 THEN 'Kai'
                WHEN r2 < 0.5 THEN 'Hui'
                WHEN r2 < 0.6 THEN 'Ling'
                WHEN r2 < 0.7 THEN 'Fang'
                WHEN r2 < 0.8 THEN 'Zhen'
                WHEN r2 < 0.9 THEN 'Zhi'
                ELSE 'Weng'
            END || ' '
    END ||
    fn2.name || ' ' ||
    ln.name
FROM
    tmp_first_names fn1
CROSS JOIN tmp_first_names fn2
CROSS JOIN tmp_last_names ln
CROSS JOIN LATERAL (
    SELECT random() AS r, random() AS r2
) rnd
ORDER BY random()
LIMIT 50000;
UPDATE name_detection.watchlist
SET full_name = regexp_replace(full_name, 'Muhammad', 'Mohamad')
WHERE random() < 0.2;
UPDATE name_detection.watchlist
SET full_name = regexp_replace(full_name, 'Muhammad', 'Mohamed')
WHERE random() < 0.2;
UPDATE name_detection.watchlist
SET full_name = regexp_replace(full_name, 'Muhammad', 'Mohammad')
WHERE random() < 0.2;
UPDATE name_detection.watchlist
SET full_name = regexp_replace(full_name, 'Muhammad', 'Mohd')
WHERE random() < 0.2;
UPDATE name_detection.watchlist
SET full_name = regexp_replace(full_name, 'ai', 'ia')
WHERE random() < 0.05;

----------------------------------------------------------------------------------------------------
/*
    Preview watchlist
*/
SELECT COUNT(*) AS total_records FROM name_detection.watchlist;
SELECT *
FROM name_detection.watchlist
LIMIT 10;

----------------------------------------------------------------------------------------------------
/*
    Cleanup all dummy data
    Uncomment if needed
*/
-- TRUNCATE TABLE name_detection.watchlist CASCADE;
-- DROP TABLE IF EXISTS tmp_first_names, tmp_last_names;

----------------------------------------------------------------------------------------------------
