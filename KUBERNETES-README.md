# Big Data Ecosystem - Kubernetes Deployment

This directory contains the complete Kubernetes manifests for deploying the Big Data ecosystem consisting of HDFS, Hive, Kafka, MLflow, and Spark Streaming.

## Components

- **HDFS**: Distributed file system (NameNode + DataNode)
- **Hive**: Data warehouse with metastore and server
- **Kafka**: Message streaming platform with Zookeeper
- **MLflow**: ML model management and serving
- **Spark Streaming**: Real-time ML inference pipeline

## Quick Start

### Prerequisites
- Kubernetes cluster (minikube, k3s, EKS, etc.)
- kubectl configured
- Docker images built and available

### Deploy Everything

```bash
# Deploy the complete ecosystem
kubectl apply -f k8s-complete-deployment.yaml

# Check deployment status
kubectl get pods -n bigdata
kubectl get services -n bigdata
```

### Individual Component Deployment

If you prefer to deploy components individually:

```bash
# HDFS
kubectl apply -f hdfs/

# Hive
kubectl apply -f hive/k8s/

# Kafka
kubectl apply -f kafka/k8s/

# MLflow
kubectl apply -f mlflow/k8s/

# Spark Streaming
kubectl apply -f spark/k8s/
```

## Services

After deployment, the following services will be available:

- **MLflow UI**: http://mlflow.bigdata.svc.cluster.local:5000
- **HDFS NameNode UI**: http://namenode.bigdata.svc.cluster.local:9870
- **Kafka**: kafka.bigdata.svc.cluster.local:9092
- **Hive Server**: hive-server.bigdata.svc.cluster.local:10000
- **Spark Streaming**: spark-streaming.bigdata.svc.cluster.local:8080

## Data Flow

1. **Training Data**: Stored in HDFS via Hive tables
2. **Model Training**: MLflow manages model lifecycle
3. **Real-time Inference**:
   - Prediction requests → Kafka (prediction-requests topic)
   - Spark Streaming processes requests using MLflow models
   - Results → Kafka (prediction-responses topic)

## Configuration

The deployment includes a ConfigMap with service endpoints:

```bash
kubectl get configmap bigdata-config -n bigdata -o yaml
```

## Storage

Persistent volumes are created for:
- HDFS data (NameNode: 5Gi, DataNode: 10Gi)
- MySQL (Hive metastore): 5Gi
- MLflow models: 10Gi

## Monitoring

```bash
# Watch all pods
kubectl get pods -n bigdata -w

# Check logs
kubectl logs -f deployment/mlflow -n bigdata
kubectl logs -f deployment/spark-streaming -n bigdata

# Port forward for local access
kubectl port-forward svc/mlflow 5000:5000 -n bigdata
```

## Troubleshooting

### Common Issues

1. **Pods not starting**: Check persistent volume claims
   ```bash
   kubectl get pvc -n bigdata
   ```

2. **Service connectivity**: Verify DNS resolution
   ```bash
   kubectl exec -it deployment/mlflow -n bigdata -- nslookup kafka.bigdata.svc.cluster.local
   ```

3. **Image pull errors**: Ensure Docker images are available
   ```bash
   kubectl describe pod <pod-name> -n bigdata
   ```

### Scaling

```bash
# Scale Kafka brokers
kubectl scale deployment kafka --replicas=3 -n bigdata

# Scale Spark Streaming workers
kubectl scale deployment spark-streaming --replicas=2 -n bigdata
```

## Cleanup

```bash
# Remove everything
kubectl delete namespace bigdata

# Or remove individual components
kubectl delete -f k8s-complete-deployment.yaml
```