# HDFS Sink Connector

This component provides a Kafka Connect sink connector that reads data from Kafka topics and writes them as Parquet files to HDFS.

## Configuration

- **Kafka Topics**: `weather2`, `business-event`, `review-event`
- **Data Format**: Avro (with Schema Registry)
- **Output Format**: Parquet with Snappy compression
- **HDFS URL**: `hdfs://namenode:9000`
- **Partitioner**: Default (preserves Kafka partitions)

## Deployment

1. Ensure HDFS and Kafka are running.
2. Apply the Kubernetes manifests:
   ```bash
   kubectl apply -f k8s/
   ```

## Files

- `k8s/configmap.yaml`: Configuration for worker and connector properties, plus Hadoop core-site.xml
- `k8s/deployment.yaml`: Deployment for the Kafka Connect standalone worker running the HDFS sink connector