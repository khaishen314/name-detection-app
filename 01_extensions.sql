CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

-- Disable sequential scans to enforce index usage
SET enable_seqscan = OFF;
