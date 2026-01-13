CREATE TABLE IF NOT EXISTS name_detection.watchlist (
    id BIGSERIAL PRIMARY KEY,

    -- Timestamps
    gmt_create TIMESTAMPTZ NOT NULL DEFAULT now(),
    gmt_modify TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Original full name
    full_name TEXT NOT NULL,

    -- Normalised, token-sorted name
    norm_name TEXT GENERATED ALWAYS AS (name_detection.normalise_and_sort_name(full_name)) STORED NOT NULL,

    -- Precomputed helpers
    name_len INT GENERATED ALWAYS AS (char_length(name_detection.normalise_and_sort_name(full_name))) STORED NOT NULL,

    soundex_code TEXT GENERATED ALWAYS AS (soundex(full_name)) STORED NOT NULL,
    metaphone_code TEXT GENERATED ALWAYS AS (metaphone(full_name, 8)) STORED NOT NULL,
    dmeta_primary TEXT GENERATED ALWAYS AS (dmetaphone(full_name)) STORED NOT NULL,
    dmeta_alt TEXT GENERATED ALWAYS AS (dmetaphone_alt(full_name)) STORED NOT NULL
);
