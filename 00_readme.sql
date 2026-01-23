/*
Name Detection System – Custom Fuzzy Matching Engine
===================================================

Purpose:
--------
Detect whether an input name matches or is similar to a watchlist name
using a deterministic, explainable scoring system suitable for
SEA financial institutions (AML / KYC / Sanctions screening).

Key Requirements:
-----------------
- < 20ms response time
- ~200k watchlist records
- PostgreSQL-only (no external runtime)
- Tunable & explainable scoring

Techniques Used:
----------------
- pg_trgm similarity (character similarity)
- Levenshtein distance (edit distance)
- Soundex, Metaphone, Double Metaphone (phonetic similarity)
- Length-normalized exponential decay for distance scoring
- Controlled phonetic boosting (never dominates)

Scoring Philosophy:
-------------------
1. Compute similarity score (visual similarity)
2. Compute processed distance score (edit distance, exponential decay)
3. Combine using MAX(), penalize disagreement
4. Apply small phonetic boost (-5% to +15%)
5. Clamp final score to [0,1]

Execution Flow:
---------------
Input → Candidate narrowing (indexes)
      → Scoring (math on small set)
      → Top-N ranked results

Installation:
-------------
1. Run files in numeric order.
2. CREATE DATABASE name_detection_app_db.
3. CREATE ROLE name_detection_app.
*/
