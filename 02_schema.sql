CREATE SCHEMA IF NOT EXISTS name_detection;
SET search_path TO name_detection, public;
COMMENT ON SCHEMA name_detection IS
'Schema for fuzzy name detection and watchlist matching';

CREATE OR REPLACE FUNCTION name_detection.normalise_and_sort_name(input TEXT)
RETURNS TEXT
LANGUAGE SQL IMMUTABLE AS $$
SELECT string_agg(token, ' ' ORDER BY token)
FROM unnest(
    regexp_split_to_array(
        lower(regexp_replace(input, '[^a-z\s]', '', 'g')),
        '\s+'
    )
) AS token
WHERE token <> '';
$$;
