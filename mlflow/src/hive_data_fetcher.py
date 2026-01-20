import os
from pyhive import hive
import pandas as pd

def fetch_training_data():
    """
    Fetch training data from Hive instance.
    Returns a pandas DataFrame with joined weather and review data.
    """
    hive_host = os.getenv('HIVE_HOST', 'hiveserver2-service')
    hive_port = int(os.getenv('HIVE_PORT', 10000))
    hive_username = os.getenv('HIVE_USERNAME', 'hive')
    database = os.getenv('HIVE_DATABASE', 'default')
    
    dfs = {}
    tables = ['weather2', 'business_event', 'review_event']
    
    for table in tables:
        try:
            conn = hive.Connection(host=hive_host, port=hive_port, username=hive_username, database=database)
            query = f"SELECT * FROM {table}"
            df = pd.read_sql(query, conn)
            conn.close()
            print(f"Fetched {len(df)} rows from Hive table {table}")
            dfs[table] = df
        except Exception as e:
            print(f"Error fetching data from Hive table {table}: {e}")
            continue

    if not all(table in dfs for table in tables):
        raise Exception("Missing required tables")

    # Join data
    # Reviews to businesses on businessId
    reviews = dfs['debug_review_event']
    businesses = dfs['debug_business_event']
    
    # Assuming column names: reviews.businessId, businesses.id
    reviews_businesses = pd.merge(reviews, businesses, left_on='businessId', right_on='id', suffixes=('_review', '_business'))
    
    # Now join with weather on time and location
    weather = dfs['weather2']
    
    # Parse dates
    reviews_businesses['date'] = pd.to_datetime(reviews_businesses['date'], unit='ms')  # Assuming timestamp-millis
    weather['Date'] = pd.to_datetime(weather['Date'])
    
    # For each review, find closest weather station by time and location
    # This is simplified - in practice, you'd use haversine distance
    joined_data = []
    
    for _, review in reviews_businesses.iterrows():
        review_time = review['date']
        review_lat = review['location']['coordinates']['latitude']
        review_lon = review['location']['coordinates']['longitude']
        
        # Find weather data within 1 hour and closest location
        time_mask = (weather['Date'] - review_time).abs() <= pd.Timedelta(hours=1)
        weather_subset = weather[time_mask].copy()
        
        if not weather_subset.empty:
            # Calculate distance (simplified Euclidean, should use haversine)
            weather_subset['distance'] = ((weather_subset['Latitude'] - review_lat)**2 + 
                                        (weather_subset['Longitude'] - review_lon)**2)**0.5
            closest_weather = weather_subset.loc[weather_subset['distance'].idxmin()]
            
            # Create combined row
            combined_row = {}
            # Add review fields
            for col in reviews.columns:
                combined_row[f'review_{col}'] = review[col]
            # Add business fields
            for col in businesses.columns:
                if col != 'id':  # Avoid duplicate id
                    combined_row[f'business_{col}'] = review[f'{col}_business'] if f'{col}_business' in review.index else review[col]
            # Add weather fields
            for col in weather.columns:
                combined_row[f'weather_{col}'] = closest_weather[col]
            
            joined_data.append(combined_row)
    
    if not joined_data:
        raise Exception("No joined data found")
    
    combined_df = pd.DataFrame(joined_data)
    print(f"Joined {len(combined_df)} review-weather pairs")
    return combined_df