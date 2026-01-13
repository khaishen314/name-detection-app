CREATE VIEW name_detection.v_watchlist AS
SELECT
    w.id,
    w.full_name,
    w.norm_name,
    w.name_len,
    w.soundex_code,
    w.metaphone_code,
    w.dmeta_primary,
    w.dmeta_alt
FROM name_detection.watchlist w;
