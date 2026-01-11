CREATE OR REPLACE VIEW name_detection.v_watchlist_match_explain AS
SELECT
    w.id,
    w.norm_name,
    w.soundex_code,
    w.metaphone_code,
    w.dmeta_primary,
    w.dmeta_alt
FROM name_detection.watchlist w;
