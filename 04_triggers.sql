CREATE OR REPLACE FUNCTION name_detection.set_gmt_modify()
RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    NEW.gmt_modify = now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_watchlist_gmt_modify
BEFORE UPDATE ON name_detection.watchlist
FOR EACH ROW
EXECUTE FUNCTION name_detection.set_gmt_modify();
