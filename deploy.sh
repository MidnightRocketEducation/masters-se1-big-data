#!/bin/bash
set -e

echo "Deploying Big Data Ecosystem..."

kubectl apply -f hdfs/k8s/
kubectl wait --for=condition=ready --timeout=300s statefulset/namenode  # Wait for HDFS NameNode

kubectl apply -f kafka/k8s/
kubectl wait --for=condition=available --timeout=300s deployment/kafka  # Wait for Kafka

kubectl apply -f spark-cluster/k8s/
kubectl wait --for=condition=available --timeout=300s deployment/spark-master  # Wait for Spark Master
kubectl wait --for=condition=available --timeout=300s deployment/spark-worker  # Wait for Spark Worker

kubectl apply -f hive/k8s/
kubectl wait --for=condition=available --timeout=300s deployment/hiveserver2  # Wait for Hive

kubectl apply -f mlflow/k8s/
kubectl wait --for=condition=available --timeout=300s deployment/mlflow  # Wait for MLflow

kubectl apply -f spark-streaming/k8s/
kubectl wait --for=condition=available --timeout=300s deployment/spark-streaming  # Wait for Spark Streaming

echo "Deployment complete."