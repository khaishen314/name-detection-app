-- Set similarity threshold, default is 0.6 which is set at extension creation
SET pg_trgm.similarity_threshold = 0.3;

-- Example match
SELECT *
FROM match_watchlist('mohamad ali bin hassan', 10);

-- Performance check
EXPLAIN ANALYZE
SELECT *
FROM match_watchlist('mohamad ali bin hassan', 10);
