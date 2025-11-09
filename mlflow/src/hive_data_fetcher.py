import os
from pyhive import hive
import pandas as pd

def fetch_training_data():
    """
    Fetch training data from Hive instance.
    Returns a pandas DataFrame with the training data.
    """
    hive_host = os.getenv('HIVE_HOST', 'localhost')
    hive_port = int(os.getenv('HIVE_PORT', 10000))
    hive_username = os.getenv('HIVE_USERNAME', 'hive')
    database = os.getenv('HIVE_DATABASE', 'default')
    table = os.getenv('HIVE_TABLE', 'training_data')

    try:
        conn = hive.Connection(host=hive_host, port=hive_port, username=hive_username, database=database)
        query = f"SELECT * FROM {table}"
        df = pd.read_sql(query, conn)
        conn.close()
        print(f"Fetched {len(df)} rows from Hive table {table}")
        return df
    except Exception as e:
        print(f"Error fetching data from Hive: {e}")
        raise