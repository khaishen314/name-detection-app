from utils.sql_util import execute_query
import pandas as pd

"""
    Fetches the watchlist table from psql
"""
def fetch_watchlist() -> pd.DataFrame:
    sql = """
        SELECT * FROM name_detection.watchlist;
    """
    watchlist_df = execute_query(sql)
    return watchlist_df

"""
    Calls the score_candidates function in psql to get top N candidates
"""
def fetch_score_candidates(input_full_name: str, sim_top_n: int, k: float, p: float) -> pd.DataFrame:
    sql = """
        SELECT *
        FROM name_detection.score_candidates(
            input_full_name := %s,
            sim_top_n := %s,
            k := %s,
            p := %s
        );
    """
    score_candidates_df = execute_query(sql, (input_full_name, sim_top_n, k, p))
    return score_candidates_df
