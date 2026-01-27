-- Trigram similarity
CREATE INDEX IF NOT EXISTS idx_watchlist_trgm
ON name_detection.watchlist USING GIN (norm_name gin_trgm_ops);

-- Phonetic indexes
CREATE INDEX IF NOT EXISTS idx_watchlist_soundex ON name_detection.watchlist (soundex_code);
CREATE INDEX IF NOT EXISTS idx_watchlist_metaphone ON name_detection.watchlist (metaphone_code);
CREATE INDEX IF NOT EXISTS idx_watchlist_dmeta_primary ON name_detection.watchlist (dmeta_primary);
CREATE INDEX IF NOT EXISTS idx_watchlist_dmeta_alt ON name_detection.watchlist (dmeta_alt);
