from flask import Flask, request, jsonify
import mlflow.sklearn
import pandas as pd
import os
import numpy as np

app = Flask(__name__)

# Load the latest model from MLflow registry (optional)
def load_latest_model():
    try:
        mlflow_tracking_uri = os.getenv('MLFLOW_TRACKING_URI', 'file:./models/mlruns')
        mlflow.set_tracking_uri(mlflow_tracking_uri)
        model = mlflow.sklearn.load_model("models:/latest_model/Production")
        print("Successfully loaded model: latest_model")
        return model
    except Exception as e:
        print(f"Warning: Could not load model 'latest_model': {e}")
        print("MLflow service will start without a loaded model")
        return None

model = load_latest_model()

def preprocess_prediction_data(df):
    """
    Preprocess prediction data similar to training preprocessing.
    Expects raw weather/business data and creates features.
    """
    # Assuming input has weather data with business location
    # For prediction, we expect weather data for a specific business and time
    
    # Extract location - assume it's provided or from business
    if 'business_location' in df.columns:
        df['latitude'] = df['business_location'].apply(lambda x: x['coordinates']['latitude'] if isinstance(x, dict) and 'coordinates' in x else None)
        df['longitude'] = df['business_location'].apply(lambda x: x['coordinates']['longitude'] if isinstance(x, dict) and 'coordinates' in x else None)
    else:
        # Assume lat/lon are provided
        pass
    
    # Parse Date if string
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
                 'id', 'businessId', 'date', 'name', 'location', 'stars', 'categories']
    df = df.drop(columns=[col for col in drop_cols if col in df.columns], errors='ignore')
    
    return df

@app.route('/predict', methods=['POST'])
def predict():
    try:
        if model is None:
            return jsonify({'error': 'No model loaded. Please train and register a model first.'}), 503
        
        data = request.get_json()
        # Assume data is a list of raw data objects (like Kafka messages)
        df = pd.DataFrame(data)
        
        # Preprocess the data
        df_processed = preprocess_prediction_data(df)
        
        # Predict
        predictions = model.predict(df_processed)
        return jsonify({'predictions': predictions.tolist()})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)