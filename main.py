from utils.data_loader import fetch_score_candidates
from utils.get_optimal_w_s import get_optimal_w_s
import pandas as pd
import duckdb

def match_watchlist(
    input_full_name: str,
    sim_top_n: int = 20,
    k: float = 3.5,
    p: float = 1.5,
    limit_results: int = 20, 
    confidence_threshold: float = 0.45, 
    phonetic_boost: float = 0.2, 
    length_coverage_factor: float = 0.95
    ) -> pd.DataFrame:
    
    df = fetch_score_candidates(input_full_name, sim_top_n, k, p)
    if df is None or df.empty:
        print(f"No candidates found for '{input_full_name}'")
        return

    duckdb.register("scored", df)

    w_s = get_optimal_w_s(input_full_name, sim_top_n, k, p)

    sql = """
    WITH combined AS (
        SELECT 
            id,
            full_name,
            name_len,
            input_name_len,
            ? * sim_score + ? * lev_score AS base_score,
            phonetic_hits
        FROM scored
    ),
    boosted AS (
        SELECT
            id,
            full_name,
            name_len,
            input_name_len,
            CASE
                WHEN phonetic_hits > 0 AND base_score >= ?
                THEN base_score + ? * (1 - base_score)
                ELSE base_score
            END AS boosted_score
        FROM combined
    )
    SELECT
        id AS watchlist_id,
        full_name AS matched_watchlist_full_name,
        round(
            least(
                1.0,
                boosted_score *
                pow(
                    least(name_len, input_name_len)::float / 
                    greatest(name_len, input_name_len),
                    ?
                )
            )::numeric,
            4
        ) AS final_score
    FROM boosted
    ORDER BY final_score DESC
    LIMIT ?;
    """

    params = (w_s, 1 - w_s, confidence_threshold, phonetic_boost, length_coverage_factor, limit_results)

    result_df = duckdb.query(sql, params=params).to_df()
    return result_df
