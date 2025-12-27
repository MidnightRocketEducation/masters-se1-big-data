# Big Data MLflow Application

This application provides a machine learning model serving API using MLflow, with automated training from Parquet data stored in HDFS via Hive.

## Components

- **Model Serving API**: Flask app serving predictions from the latest MLflow model.
- **Training Script**: Fetches data from Hive (weather data from HDFS sink) and trains a forecasting model daily.
- **Containerization**: Docker container for the application.
- **Kubernetes Deployment**: Runs as a service in Kubernetes with CronJob for training at midnight.

## Data Source

- Fetches training data from Hive tables `weather2`, `business_event`, and `review_event` (created by HDFS sink connector)
- Joins review data with business location data, then matches to nearest weather station by time and location
- Data originates from Kafka topics `weather2`, `business-event`, and `review-event` in Avro format, stored as Parquet in HDFS
- Performs time matching (within 1 hour) and location matching (closest station)

## Setup

**Prerequisite**: Deploy HDFS, Hive, Kafka, and HDFS Sink Connector first.

1. Configure your Hive connection details in `k8s/configmap.yaml` and `k8s/secret.yaml`.
2. Build the Docker image:
   ```
   docker build -t your-registry/mlflow-app:latest .
   ```
3. Deploy to Kubernetes:
   ```
   kubectl apply -f k8s/
   ```

## API Usage

- Health check: `GET /health`
- Predictions: `POST /predict` with JSON array of raw weather/business data objects (will be preprocessed automatically)

### Prediction Input Format

The `/predict` endpoint now accepts raw data similar to Kafka messages and applies the same preprocessing as training:

```json
[
  {
    "Date": "2023-01-01T14:00:00",
    "Latitude": 40.7128,
    "Longitude": -74.0060,
    "ReportType": "FM-15",
    "HourlyDryBulbTemperature": 75.0,
    "HourlySeaLevelPressure": 30.1,
    "HourlyVisibility": 10.0,
    "HourlyWindDirection": 180.0,
    "HourlyWindSpeed": 5.0,
    "HourlyPrecipitation": 0.0,
    "HourlyRelativeHumidity": 60.0,
    "business_location": {
      "coordinates": {
        "latitude": 40.7128,
        "longitude": -74.0060
      }
    }
  }
]
```

The endpoint will:
1. Preprocess the data (feature engineering, encoding, etc.)
2. Apply the trained model
3. Return predicted star ratings

## Training

The training runs continuously as a Kubernetes Deployment that listens to the 'debug-world-clock' Kafka topic.
- Monitors UNIX timestamp messages from 'debug-world-clock' topic
- Triggers model retraining when a new day is detected (based on UNIX time)
- Fetches and preprocesses combined weather and review data from Hive
- Performs feature engineering: time of day, day of week, season, bad weather score
- Handles missing values with mean imputation
- Registers the new model in MLflow Model Registry as "latest_model"