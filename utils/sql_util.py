import psycopg
import os
from dotenv import load_dotenv
import pandas as pd

load_dotenv()

def get_cursor() -> psycopg.Connection:
    try:
        conn = psycopg.connect(
            host=os.getenv('DB_SERVER'),
            dbname=os.getenv(f'DB_NAME'),
            user=os.getenv('DB_USER'),
            password=os.getenv('DB_PASS')
        )
        cursor = conn.cursor()
        print("Database connection established.")
        return cursor, conn

    except psycopg.Error as e:
        print("Error connecting to database:", e)
        return None, None

def execute_query(s: str, params=None) -> pd.DataFrame:
    cursor, conn = get_cursor()
    cursor.execute(s, params or ())
    results = cursor.fetchall()
    results = [tuple(row) for row in results]
    cols = [column[0] for column in cursor.description]
    df = pd.DataFrame(results, columns=cols)
    cursor.close()
    conn.close()
    return df
    