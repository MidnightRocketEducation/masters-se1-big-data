import mlflow
import mlflow.sklearn
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error
import pandas as pd
from hive_data_fetcher import fetch_training_data
import os
from kafka import KafkaConsumer
import json
import time

def preprocess_data(df):
    """
    Preprocess the joined weather and review data.
    """
    import numpy as np
    from datetime import datetime
    
    # Flatten nested columns if any
    # Assuming df has flat columns now
    
    # Extract location from nested structure
    if 'business_location' in df.columns:
        # Assuming location is a dict with coordinates
        df['latitude'] = df['business_location'].apply(lambda x: x['coordinates']['latitude'] if isinstance(x, dict) and 'coordinates' in x else None)
        df['longitude'] = df['business_location'].apply(lambda x: x['coordinates']['longitude'] if isinstance(x, dict) and 'coordinates' in x else None)
    else:
        # Fallback
        df['latitude'] = df.get('latitude', df.get('Latitude'))
        df['longitude'] = df.get('longitude', df.get('Longitude'))
    
    # Select relevant weather columns (prefixed with weather_)
    weather_cols = [
        'weather_Date', 'weather_Latitude', 'weather_Longitude', 'weather_ReportType',
        'weather_HourlyDryBulbTemperature', 'weather_HourlySeaLevelPressure', 'weather_HourlyVisibility',
        'weather_HourlyWindDirection', 'weather_HourlyWindSpeed', 'weather_HourlyPrecipitation', 'weather_HourlyRelativeHumidity'
    ]
    
    # Rename to remove prefix for simplicity
    rename_dict = {col: col.replace('weather_', '') for col in weather_cols if col in df.columns}
    df = df.rename(columns=rename_dict)
    
    # Parse Date
    if 'Date' in df.columns:
        df['Date'] = pd.to_datetime(df['Date'])
        
        # Feature engineering
        df['hour'] = df['Date'].dt.hour
        df['day_of_week'] = df['Date'].dt.dayofweek
        df['month'] = df['Date'].dt.month
        
        # Time of day
        df['time_of_day'] = pd.cut(df['hour'], bins=[0, 6, 12, 18, 24], labels=['night', 'morning', 'afternoon', 'evening'])
        
        # Season
        df['season'] = pd.cut(df['month'], bins=[0, 3, 6, 9, 12], labels=['winter', 'spring', 'summer', 'fall'])
    
    # Handle nulls in weather data
    numeric_cols = ['HourlyDryBulbTemperature', 'HourlySeaLevelPressure', 'HourlyVisibility', 
                   'HourlyWindDirection', 'HourlyWindSpeed', 'HourlyPrecipitation', 'HourlyRelativeHumidity']
    
    for col in numeric_cols:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
            df[col] = df[col].fillna(df[col].mean())  # Mean imputation
    
    # Bad weather score
    if all(col in df.columns for col in ['HourlyDryBulbTemperature', 'HourlyPrecipitation', 'HourlyVisibility', 'HourlyWindSpeed', 'HourlyRelativeHumidity']):
        df['bad_weather_score'] = (
            (df['HourlyDryBulbTemperature'] < 32).astype(int) * 2 +  # Freezing
            (df['HourlyDryBulbTemperature'] > 90).astype(int) * 1 +  # Hot
            (df['HourlyPrecipitation'] > 0).astype(int) * 3 +        # Any precipitation
            (df['HourlyVisibility'] < 5).astype(int) * 2 +           # Poor visibility
            (df['HourlyWindSpeed'] > 20).astype(int) * 1 +           # Windy
            (df['HourlyRelativeHumidity'] > 80).astype(int) * 1      # Humid
        )
    
    # One-hot encode categorical
    categorical_cols = ['ReportType', 'time_of_day', 'season']
    for col in categorical_cols:
        if col in df.columns:
            df = pd.get_dummies(df, columns=[col], drop_first=True)
    
    # Drop unnecessary columns
    drop_cols = ['Date', 'hour', 'month', 'Station', 'Elevation', 'Name', 'Source', 'Latitude', 'Longitude', 
                 'review_id', 'review_businessId', 'review_date', 'business_id', 'business_name', 'business_location', 'business_stars', 'business_categories']
    df = df.drop(columns=[col for col in drop_cols if col in df.columns], errors='ignore')
    
    # Assume target is review stars
    if 'review_stars' in df.columns:
        # Move target to end
        cols = [col for col in df.columns if col != 'review_stars'] + ['review_stars']
        df = df[cols]
    
    return df

def train_model():
    """
    Train a machine learning model using data from Hive and log to MLflow.
    """
    # Set MLflow tracking URI if needed
    mlflow_tracking_uri = os.getenv('MLFLOW_TRACKING_URI', 'file:./models/mlruns')
    mlflow.set_tracking_uri(mlflow_tracking_uri)

    # Fetch data
    df = fetch_training_data()
    
    # Preprocess data
    df = preprocess_data(df)

    # Assume the data has columns 'features' and 'target'
    # For simplicity, assume df has multiple columns, last is target
    X = df.iloc[:, :-1]
    y = df.iloc[:, -1]

    # Split data
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Train model
    model = LinearRegression()
    model.fit(X_train, y_train)

    # Predict and evaluate
    predictions = model.predict(X_test)
    mse = mean_squared_error(y_test, predictions)

    # Log to MLflow
    with mlflow.start_run():
        mlflow.log_param("model_type", "LinearRegression")
        mlflow.log_metric("mse", mse)
        mlflow.sklearn.log_model(model, "model")

        # Register the model
        model_uri = f"runs:/{mlflow.active_run().info.run_id}/model"
        mlflow.register_model(model_uri, "latest_model")

    print(f"Model trained and registered with MSE: {mse}")

def listen_and_train():
    """
    Listen to 'world-clock' topic and train model when appropriate.
    """
    kafka_bootstrap_servers = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'kafka:9092')
    consumer = KafkaConsumer(
        'debug-world-clock',
        bootstrap_servers=[kafka_bootstrap_servers],
        auto_offset_reset='latest',
        enable_auto_commit=True,
        value_deserializer=lambda x: json.loads(x.decode('utf-8'))
    )

    last_train_day = None

    for message in consumer:
        unix_time = message.value.get('currentTime')  # Assuming the message has 'timestamp' field
        if unix_time:
            # Convert to day (seconds in a day = 86400)
            current_day = unix_time // 86400
            if last_train_day is None or current_day > last_train_day:
                print(f"Triggering training at UNIX time: {unix_time}")
                train_model()
                last_train_day = current_day

if __name__ == "__main__":
    listen_and_train()