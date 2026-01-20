# Spark Streaming (Kafka Word Count)

This module contains a simple Spark Structured Streaming job that consumes text messages from Kafka, performs a running word count, and prints the aggregated counts. The application is packaged as a shaded JAR, wrapped in a Docker image, and includes Kubernetes manifests that target the existing Spark standalone cluster in this repository.

## Build the shaded JAR

```powershell
# From the spark-streaming directory
mvn clean package -DskipTests
```

The shaded artifact is created at `target/spark-streaming-1.0.0.jar` and is copied into the Docker image.

## Docker image

Build the image locally:

```powershell
docker build -t spark-streaming:latest .
```

Environment variables control the job at runtime:

| Variable | Purpose | Default |
| --- | --- | --- |
| `KAFKA_BOOTSTRAP_SERVERS` | Kafka bootstrap servers (host:port list). | _required_ |
| `KAFKA_TOPIC` | Kafka topic to subscribe to. | _required_ |
| `CHECKPOINT_LOCATION` | Location for the streaming checkpoint data. Use HDFS/S3 for production. | `/tmp/spark-streaming-checkpoints` |
| `STARTING_OFFSETS` | Kafka starting offsets (`earliest`, `latest`, or JSON). | `latest` |
| `OUTPUT_MODE` | One of `append`, `update`, or `complete`. | `complete` |
| `TRIGGER_INTERVAL` | Processing trigger interval (`10 seconds`, `5000 ms`, …). | `10 seconds` |
| `SPARK_MASTER_URL` | Spark master URL. | `spark://spark-master:7077` |
| `SPARK_DEPLOY_MODE` | Spark deploy mode (`client` | `cluster`). | `client` |
| `SPARK_PACKAGES` | Comma-separated packages to pass to `spark-submit`. | `org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0` |

Additional Spark configuration can be injected via:

- `SPARK_DRIVER_HOST`, `SPARK_DRIVER_PORT`
- `SPARK_EXECUTOR_INSTANCES`, `SPARK_EXECUTOR_MEMORY`, `SPARK_DRIVER_MEMORY`
- `SPARK_SUBMIT_ARGS` (appended verbatim to `spark-submit`)

## Kubernetes deployment

The manifests in `k8s/` assume:

- The Spark master service is reachable at `spark-master:7077` (matching `spark-cluster/k8s/`).
- Kafka is exposed as `kafka:9092` (matching `kafka/k8s/`).
- HDFS is reachable at `hdfs://namenode:9000` for checkpoint storage.

Apply the manifests after building and pushing the Docker image to your registry:

```powershell
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
```

Check the driver logs:

```powershell
kubectl logs deployment/spark-streaming -f
```

To remove the deployment:

```powershell
kubectl delete -f k8s/deployment.yaml
kubectl delete -f k8s/configmap.yaml
```

## Local smoke test

You can run the job against a local Spark installation by pointing `spark-submit` at the shaded jar:

```bash
/opt/spark/bin/spark-submit \
  --class com.midnightrocket.sparkstreaming.StreamingApp \
  --master spark://spark-master:7077 \
  target/spark-streaming-1.0.0.jar
```

Ensure the required Kafka environment variables are set before launching.
