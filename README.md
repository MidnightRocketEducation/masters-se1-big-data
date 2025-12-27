# Big Data MLflow Application with Hive

This repository contains a complete Big Data application with MLflow model serving and automated training from Hive data.

## Architecture

- **HDFS Deployment** (`hdfs/`): Distributed file system for storing data in Parquet format
- **Hive Deployment** (`hive/`): Data warehouse for querying Parquet data from HDFS
- **MLflow Application** (`mlflow/`): Serves ML models and handles training from Hive data
- **Kafka Message Broker** (`kafka/`): Real-time messaging infrastructure
- **HDFS Sink Connector** (`hdfs-sink/`): Sinks Kafka data to HDFS in Parquet format
- **Spark Streaming** (`spark/`): Real-time ML inference using Java and Spark Structured Streaming

## Components

### Hive Setup
- MySQL database for metastore
- Hive metastore service
- HiveServer2 for client connections

### MLflow Application
- Flask API for model predictions
- Automated daily model retraining via CronJob
- MLflow tracking and model registry

## Deployment Order

1. **Deploy HDFS**:
   ```bash
   cd hdfs
   kubectl apply -f configmap.yaml
   kubectl apply -f namenode.yaml
   kubectl apply -f datanodes.yaml
   ```

2. **Deploy Hive**:
   ```bash
   cd ../hive
   kubectl apply -f k8s/
   ```

3. **Wait for all services to be ready**:
   ```bash
   kubectl get pods -n default
   ```

4. **Create sample Parquet data in HDFS/Hive** (optional):
   Upload Parquet files to HDFS and create external Hive tables

5. **Deploy MLflow Application**:
   ```bash
   cd ../mlflow
   # Build and push Docker image
   docker build -t your-registry/mlflow-app:latest .
   docker push your-registry/mlflow-app:latest

   # Update image in k8s/deployment.yaml and k8s/training-listener-deployment.yaml
   kubectl apply -f k8s/
   ```

6. **Deploy Kafka**:
   ```bash
   cd ../kafka
   kubectl apply -f k8s/
   ```

7. **Deploy HDFS Sink Connector**:
   ```bash
   cd ../hdfs-sink
   kubectl apply -f k8s/
   ```

8. **Deploy Spark Streaming**:
   ```bash
   cd ../spark
   # Build the Java application
   mvn clean package
   docker build -t your-registry/spark-streaming:latest .
   docker push your-registry/spark-streaming:latest

   # Deploy to Kubernetes
   kubectl apply -f k8s/spark-deployment.yaml
   ```

## Data Flow

1. **Data Ingestion**: Data streamed to Kafka topics
2. **Data Storage**: HDFS Sink Connector writes Parquet files to HDFS
3. **Batch Processing**: Hive queries Parquet data for ML training
4. **Model Training**: MLflow trains models daily using Hive data
5. **Model Serving**: MLflow API serves predictions via REST
6. **Real-time Inference**: Spark Streaming consumes Kafka messages, loads latest MLflow model, publishes predictions back to Kafka using Avro serialization

## Services

- **HDFS NameNode**: hdfs-namenode:9870 (web), :9000 (HDFS)
- **Hive Server**: hive-service:10000
- **MLflow API**: mlflow-service:5000
- **Kafka**: kafka:9092
- **Zookeeper**: zookeeper:2181

## Configuration

Update the following as needed:
- Docker registry in Kubernetes manifests
- Database credentials in hive/k8s/mysql-deployment.yaml
- Hive table name in mlflow/k8s/configmap.yaml