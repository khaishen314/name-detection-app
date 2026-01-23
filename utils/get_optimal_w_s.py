from utils.data_loader import fetch_score_candidates
import math
import itertools
import numpy as np
import pandas as pd

"""
    Get similarity scores and levenshtein scores from fetch_score_candidates
    To find w_s
    Node = Name
    c_0: sim_score dict (node: score)
    c_1: lev_score dict (node: score)
    c_t: (1 - t) * c_0 + t * c_1
    t_star: critical points where most nodes are tied, rank changes after
    g: objective function to minimise
    t_mu: optimal t minimizing g
    w_s = 1 - t_mu
"""
def get_scores(input_full_name: str, sim_top_n: int = 20) -> pd.DataFrame:
    scores_df = fetch_score_candidates(input_full_name, sim_top_n)[['sim_score', 'lev_score']]
    c_0, c_1 = dict(), dict()
    for idx, row in scores_df.iterrows():
        c_0[idx] = row['sim_score']
        c_1[idx] = row['lev_score']
    return c_0, c_1

"""
    Rank nodes
"""
def sort_to_rank(node_dict: dict) -> list:
    sorted_node = sorted(node_dict.items(), key=lambda x: x[1], reverse=True)

    node_rank = []
    current_rank = 1
    current_score = None

    for node, score in sorted_node:
        if score != current_score:
            if current_score is not None:
                current_rank += 1
            current_score = score

            if len(node_rank) < current_rank:
                node_rank.append([])

        node_rank[current_rank - 1].append(node)

    return node_rank

"""
    Precompute Kendall's Tau-b
"""
def tau_b(c_0: dict, c_1: dict) -> float:
    n = len(c_0)
    comb = itertools.combinations(range(n), 2)
    m_c = 0
    m_d = 0
    T_01 = 0
    T_0 = 0
    T_1 = 0
    for i, j in comb:
        if c_0[i] == c_0[j] and c_1[i] == c_1[j]:
            T_01 += 1
        if c_0[i] == c_0[j]:
            T_0 += 1
        if c_1[i] == c_1[j]:
            T_1 += 1
        if ((c_0[i] > c_0[j] and c_1[i] > c_1[j]) or
            (c_0[j] > c_0[i] and c_1[j] > c_1[i])):
            m_c += 1
        if ((c_0[i] > c_0[j] and c_1[i] < c_1[j]) or
            (c_0[j] > c_0[i] and c_1[j] < c_1[i])):
            m_d += 1
    m = m_c + m_d + T_0 + T_1 - T_01
    return (m_c - m_d) / math.sqrt((m - T_0) * (m - T_1))

"""
    Find the best w_s
"""
def get_ct(c_0: dict, c_1: dict, t: float) -> dict:
    return {i: c_0[i] * (1 - t) + c_1[i] * t for i in c_0}

def find_t_star(c_0: dict, c_1: dict) -> list:
    t_axis = np.linspace(0, 1, 10000)
    ranks = [sort_to_rank(get_ct(c_0, c_1, t)) for t in t_axis]
    max_len = max(len(ranks[0]), len(ranks[1])) # t = 0 might be a critical point
    return [t_axis[i] for i in range(len(ranks)) if len(ranks[i]) < max_len] # only get critical points

def g(t: float, c_0: dict, c_1: dict) -> float:
    c_t = get_ct(c_0, c_1, t)
    return (1 - tau_b(c_0, c_t))**2 + (1 - tau_b(c_1, c_t))**2 # objective function to minimise to find the best t_mu

def get_t_mu(c_0: dict, c_1: dict, tol=1e-6) -> float:
    t_axis = np.linspace(0, 1, 10000)
    g_axis = np.array([g(t, c_0, c_1) for t in t_axis])
    min_val = np.min(g_axis)
    min_idxs = np.where(np.abs(g_axis - min_val) <= tol)[0] # find indices where g(t) is "equal" to min
    mid_idx = min_idxs[len(min_idxs) // 2] # take midpoint index
    return t_axis[mid_idx]

def get_optimal_w_s(input_full_name: str, sim_top_n: int = 20) -> float:
    c_0, c_1 = get_scores(input_full_name, sim_top_n)
    t_mu = get_t_mu(c_0, c_1)
    return 1 - t_mu
