CREATE OR REPLACE FUNCTION name_detection.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_watchlist_updated_at
BEFORE UPDATE ON name_detection.watchlist
FOR EACH ROW
EXECUTE FUNCTION name_detection.set_updated_at();