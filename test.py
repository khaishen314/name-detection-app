from main import match_watchlist
from time import time

if __name__ == "__main__":

    start_time = time()

    input_name = "mohamad ali bin hassan"
    result_df = match_watchlist(input_full_name=input_name)
    print(result_df)

    end_time = time()
    print(f"Execution time: {end_time - start_time} seconds")
    