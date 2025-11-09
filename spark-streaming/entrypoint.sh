#!/bin/bash
set -euo pipefail

: "${KAFKA_BOOTSTRAP_SERVERS:?Environment variable KAFKA_BOOTSTRAP_SERVERS must be set}"
: "${KAFKA_TOPIC:?Environment variable KAFKA_TOPIC must be set}"

SPARK_MASTER_URL=${SPARK_MASTER_URL:-spark://spark-master:7077}
SPARK_DEPLOY_MODE=${SPARK_DEPLOY_MODE:-client}
SPARK_APPLICATION_JAR=${SPARK_APPLICATION_JAR:-/opt/spark/app/spark-streaming.jar}
SPARK_APPLICATION_MAIN_CLASS=${SPARK_APPLICATION_MAIN_CLASS:-com.midnightrocket.sparkstreaming.StreamingApp}
SPARK_PACKAGES=${SPARK_PACKAGES:-org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0}

CMD=(/opt/spark/bin/spark-submit
    --master "${SPARK_MASTER_URL}"
    --deploy-mode "${SPARK_DEPLOY_MODE}"
    --class "${SPARK_APPLICATION_MAIN_CLASS}"
    --conf spark.streaming.stopGracefullyOnShutdown=true
)

if [[ -n "${SPARK_DRIVER_HOST:-}" ]]; then
    CMD+=(--conf "spark.driver.host=${SPARK_DRIVER_HOST}")
fi

if [[ -n "${SPARK_DRIVER_PORT:-}" ]]; then
    CMD+=(--conf "spark.driver.port=${SPARK_DRIVER_PORT}")
fi

if [[ -n "${SPARK_EXECUTOR_INSTANCES:-}" ]]; then
    CMD+=(--conf "spark.executor.instances=${SPARK_EXECUTOR_INSTANCES}")
fi

if [[ -n "${SPARK_EXECUTOR_MEMORY:-}" ]]; then
    CMD+=(--conf "spark.executor.memory=${SPARK_EXECUTOR_MEMORY}")
fi

if [[ -n "${SPARK_DRIVER_MEMORY:-}" ]]; then
    CMD+=(--conf "spark.driver.memory=${SPARK_DRIVER_MEMORY}")
fi

if [[ -n "${SPARK_PACKAGES:-}" ]]; then
    CMD+=(--packages "${SPARK_PACKAGES}")
fi

if [[ -n "${SPARK_SUBMIT_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    EXTRA_ARGS=(${SPARK_SUBMIT_ARGS})
    CMD+=("${EXTRA_ARGS[@]}")
fi

CMD+=("${SPARK_APPLICATION_JAR}")

exec "${CMD[@]}"
