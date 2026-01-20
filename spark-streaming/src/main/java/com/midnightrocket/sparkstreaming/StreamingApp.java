package com.midnightrocket.sparkstreaming;

import java.time.Duration;
import java.time.format.DateTimeParseException;
import java.util.Locale;
import java.util.concurrent.TimeoutException;

import org.apache.spark.sql.Dataset;
import org.apache.spark.sql.Row;
import org.apache.spark.sql.SparkSession;
import org.apache.spark.sql.functions;
import org.apache.spark.sql.streaming.StreamingQuery;
import org.apache.spark.sql.streaming.StreamingQueryException;
import org.apache.spark.sql.streaming.Trigger;

/**
 * Simple Spark Structured Streaming job that reads UTF-8 text messages from Kafka,
 * performs a running word count, and prints the aggregation to the console.
 */
public final class StreamingApp {

    private StreamingApp() {
    }

    public static void main(String[] args) throws StreamingQueryException, TimeoutException {
        String kafkaBootstrapServers = requireEnv("KAFKA_BOOTSTRAP_SERVERS");
        String kafkaTopic = requireEnv("KAFKA_TOPIC");
        String checkpointLocation = getEnv("CHECKPOINT_LOCATION", "/tmp/spark-streaming-checkpoints");
        String startingOffsets = getEnv("STARTING_OFFSETS", "latest");
        String outputMode = getEnv("OUTPUT_MODE", "complete").toLowerCase(Locale.ROOT);
        String triggerInterval = getEnv("TRIGGER_INTERVAL", "10 seconds");

        SparkSession spark = SparkSession
                .builder()
                .appName("KafkaWordCountStreaming")
                .getOrCreate();

        // The raw stream contains Kafka metadata as well; only value is needed for tokenisation.
        Dataset<Row> words = spark
                .readStream()
                .format("kafka")
                .option("kafka.bootstrap.servers", kafkaBootstrapServers)
                .option("subscribe", kafkaTopic)
                .option("startingOffsets", startingOffsets)
                .load()
                .selectExpr("CAST(value AS STRING) AS message")
                .filter(functions.col("message").isNotNull())
                .withColumn("word", functions.explode(functions.split(functions.col("message"), "\\s+")))
                .groupBy(functions.col("word"))
                .count();

        Duration resolvedTrigger = parseDuration(triggerInterval);
        long intervalMillis = resolvedTrigger.toMillis();
        if (intervalMillis <= 0) {
            throw new IllegalArgumentException("TRIGGER_INTERVAL must be greater than zero");
        }

        Trigger trigger = Trigger.ProcessingTime(intervalMillis);

        StreamingQuery query = words
                .writeStream()
                .outputMode(outputMode)
                .format("console")
                .option("checkpointLocation", checkpointLocation)
                .option("truncate", false)
                .trigger(trigger)
                .start();

        query.awaitTermination();
    }

    private static String requireEnv(String key) {
        String value = System.getenv(key);
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException("Missing required environment variable: " + key);
        }
        return value;
    }

    private static String getEnv(String key, String defaultValue) {
        String value = System.getenv(key);
        return (value == null || value.isBlank()) ? defaultValue : value;
    }

    private static Duration parseDuration(String value) {
        String trimmed = value.trim();
        if (trimmed.isEmpty()) {
            throw new IllegalArgumentException("TRIGGER_INTERVAL cannot be blank");
        }

        try {
            return Duration.parse(trimmed);
        } catch (DateTimeParseException ignore) {
            // fall through to the informal suffix parsing below
        }

        String lower = trimmed.toLowerCase(Locale.ROOT);
        if (lower.endsWith("ms") || lower.endsWith("millis") || lower.endsWith("milliseconds")) {
            long millis = Long.parseLong(lower.replaceAll("[^0-9]", ""));
            return Duration.ofMillis(millis);
        }
        if (lower.endsWith("s") || lower.endsWith("sec") || lower.endsWith("secs") || lower.endsWith("second")
                || lower.endsWith("seconds")) {
            long seconds = Long.parseLong(lower.replaceAll("[^0-9]", ""));
            return Duration.ofSeconds(seconds);
        }
        if (lower.endsWith("m") || lower.endsWith("min") || lower.endsWith("mins") || lower.endsWith("minute")
                || lower.endsWith("minutes")) {
            long minutes = Long.parseLong(lower.replaceAll("[^0-9]", ""));
            return Duration.ofMinutes(minutes);
        }
        throw new IllegalArgumentException("Unsupported TRIGGER_INTERVAL format: " + value);
    }
}
