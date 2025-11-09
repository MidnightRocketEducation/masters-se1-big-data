# Big Data MLflow Application

This application provides a machine learning model serving API using MLflow, with automated training from Parquet data stored in HDFS via Hive.

## Components

- **Model Serving API**: Flask app serving predictions from the latest MLflow model.
- **Training Script**: Fetches data from Hive and trains a new model daily.
- **Containerization**: Docker container for the application.
- **Kubernetes Deployment**: Runs as a service in Kubernetes with CronJob for training.

## Setup

**Prerequisite**: Deploy the Hive setup from the `../hive/` directory first.

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
- Predictions: `POST /predict` with JSON array of feature vectors.

## Training

The training runs automatically every 24 hours at midnight via Kubernetes CronJob.