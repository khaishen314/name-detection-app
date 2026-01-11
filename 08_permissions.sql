REVOKE ALL ON SCHEMA name_detection FROM PUBLIC;
REVOKE ALL ON ALL TABLES IN SCHEMA name_detection FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA name_detection FROM PUBLIC;

-- Example role
GRANT USAGE ON SCHEMA name_detection TO name_detection_app;
GRANT SELECT ON watchlist TO name_detection_app;
GRANT EXECUTE ON FUNCTION match_watchlist(TEXT, INT, FLOAT, FLOAT, FLOAT, FLOAT, FLOAT) TO name_detection_app;
