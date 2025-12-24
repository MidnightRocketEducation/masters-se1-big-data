// File: src/main/java/dk/sdu/bigdata/weather/producer/application/CsvStreamReader.java
package dk.sdu.bigdata.weather.producer.application;

import com.opencsv.CSVReader;
import com.opencsv.exceptions.CsvValidationException;
import dk.sdu.bigdata.weather.producer.core.WeatherEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Stateful CSV reader that tracks position and can resume from last read position.
 * Uses streaming approach to read records incrementally.
 */
public class CsvStreamReader implements AutoCloseable {
    private static final Logger logger = LoggerFactory.getLogger(CsvStreamReader.class);

    private final Path filePath;
    private final String stationId;
    private final TimeProvider timeProvider;
    private final MessagePublisher messagePublisher;
    private final String topic;

    private BufferedReader bufferedReader;
    private CSVReader csvReader;
    private final AtomicLong lineNumber = new AtomicLong(0);
    private final AtomicLong publishedCount = new AtomicLong(0);
    private boolean initialized = false;
    private String[] nextRecordBuffer = null;
    private boolean endOfFile = false;

    public CsvStreamReader(Path filePath, TimeProvider timeProvider,
                           MessagePublisher messagePublisher, String topic) {
        this.filePath = filePath;
        this.stationId = extractStationId(filePath);
        this.timeProvider = timeProvider;
        this.messagePublisher = messagePublisher;
        this.topic = topic;
    }

    private String extractStationId(Path path) {
        String fileName = path.getFileName().toString();
        // Remove .csv extension and get station ID from filename
        return fileName.replace(".csv", "");
    }

    /**
     * Initialize the reader if not already done
     */
    public synchronized void initialize() throws IOException, CsvValidationException {
        if (!initialized) {
            this.bufferedReader = new BufferedReader(new FileReader(filePath.toFile()));
            this.csvReader = new CSVReader(bufferedReader);
            // Skip header
            csvReader.readNext();
            lineNumber.set(1);
            initialized = true;
            logger.debug("Initialized CSV reader for: {}", filePath);
        }
    }

    private Instant lastFutureRecordTime = null;
    private long lastProcessTime = 0;
    private static final long MIN_WAIT_MS = 50;
    private static final long MAX_WAIT_MS = 5000;

    /**
     * Read and publish next available record that meets time criteria.
     * Returns true if a record was published, false if waiting for time or EOF.
     */
    public boolean readAndPublishNext() {
        try {
            if (!initialized) {
                initialize();
            }

            if (endOfFile) {
                return false;
            }

            // Get current time first
            Optional<Instant> currentTime = timeProvider.getCurrentTime();
            if (currentTime.isEmpty()) {
                // No time yet, wait longer
                Thread.sleep(1000);
                return false;
            }

            Instant now = currentTime.get();

            // Read next record if buffer is empty
            if (nextRecordBuffer == null) {
                try {
                    nextRecordBuffer = csvReader.readNext();
                    if (nextRecordBuffer == null) {
                        endOfFile = true;
                        return false;
                    }
                } catch (CsvValidationException e) {
                    logger.warn("CSV validation error, skipping line: {}", e.getMessage());
                    lineNumber.incrementAndGet();
                    return true;
                }
            }

            // Parse record time
            Optional<Instant> recordTime = parseRecordTime(nextRecordBuffer);
            if (recordTime.isEmpty()) {
                logger.debug("Skipping malformed record at line {}", lineNumber.get());
                nextRecordBuffer = null;
                lineNumber.incrementAndGet();
                return true;
            }

            Instant recordInstant = recordTime.get();

            // Check if record time is in past
            if (!recordInstant.isAfter(now)) {
                // Publish the record
                publishRecord(nextRecordBuffer);
                nextRecordBuffer = null;
                lineNumber.incrementAndGet();
                publishedCount.incrementAndGet();

                // Reset future record tracking
                lastFutureRecordTime = null;
                return true;
            } else {
                // Record is in future
                if (lastFutureRecordTime == null || !lastFutureRecordTime.equals(recordInstant)) {
                    logger.debug("Record at {} is in future (current: {}), waiting",
                            recordInstant, now);
                    lastFutureRecordTime = recordInstant;
                }

                // Calculate adaptive wait time based on how far in future the record is
                long millisToWait = calculateWaitTime(recordInstant, now);
                Thread.sleep(millisToWait);
                return false;
            }

        } catch (IOException | InterruptedException e) {
            logger.warn("I/O error or interrupted: {}", e.getMessage());
            return false;
        } catch (Exception e) {
            logger.warn("Unexpected error: {}", e.getMessage());
            nextRecordBuffer = null;
            lineNumber.incrementAndGet();
            return true;
        }
    }

    private long calculateWaitTime(Instant recordTime, Instant currentTime) {
        long millisDiff = Duration.between(currentTime, recordTime).toMillis();

        // If record is very far in future, wait longer
        if (millisDiff > 3600000) { // > 1 hour
            return 5000;
        } else if (millisDiff > 60000) { // > 1 minute
            return 1000;
        } else if (millisDiff > 10000) { // > 10 seconds
            return 500;
        } else {
            return 100; // Short wait for near-future records
        }
    }

    private Optional<Instant> parseRecordTime(String[] record) {
        if (record.length < 2) {
            return Optional.empty();
        }
        try {
            // The date is in the second column (index 1)
            // Format: "2011-01-01T00:00:00"
            return Optional.of(Instant.parse(record[1]));
        } catch (DateTimeParseException e) {
            logger.debug("Failed to parse timestamp '{}': {}", record[1], e.getMessage());
            return Optional.empty();
        }
    }

    private void publishRecord(String[] record) {
        try {
            WeatherEvent event = buildWeatherEvent(record);
            messagePublisher.publish(topic, stationId, event);

            if (publishedCount.get() % 1000 == 0) {
                logger.info("Published {} records from {}", publishedCount.get(), filePath.getFileName());
            }
        } catch (Exception e) {
            logger.warn("Failed to publish record from {}: {}", filePath, e.getMessage());
            logger.debug("Error details:", e);
        }
    }

    private WeatherEvent buildWeatherEvent(String[] record) {
        // Reuse existing parsing logic from ProcessCsvFileUseCase
        // We need to adapt it to work with our use case

        // For now, let's create a simple adapter that uses similar logic
        // In production, you might want to extract this logic to a shared utility
        WeatherEvent.Builder builder = WeatherEvent.newBuilder();

        try {
            // Required fields
            if (record.length > 0 && !record[0].trim().isEmpty()) {
                builder.setStation(Long.parseLong(record[0].trim()));
            }
            if (record.length > 1 && !record[1].trim().isEmpty()) {
                builder.setDate(record[1].trim());
            }
            if (record.length > 2 && !record[2].trim().isEmpty()) {
                builder.setLatitude(Double.parseDouble(record[2].trim()));
            }
            if (record.length > 3 && !record[3].trim().isEmpty()) {
                builder.setLongitude(Double.parseDouble(record[3].trim()));
            }
            if (record.length > 4 && !record[4].trim().isEmpty()) {
                builder.setElevation(Double.parseDouble(record[4].trim()));
            }
            if (record.length > 5 && !record[5].trim().isEmpty()) {
                builder.setName(record[5].trim());
            }
            if (record.length > 6 && !record[6].trim().isEmpty()) {
                builder.setReportType(record[6].trim());
            }

            // Optional fields
            if (record.length > 7 && !record[7].trim().isEmpty()) {
                String source = record[7].trim();
                try {
                    builder.setSource(Integer.parseInt(source));
                } catch (NumberFormatException e) {
                    builder.setSource(source);
                }
            }

            // HourlyDryBulbTemperature (index 10)
            if (record.length > 10 && !record[10].trim().isEmpty()) {
                try {
                    builder.setHourlyDryBulbTemperature(Double.parseDouble(record[10].trim()));
                } catch (NumberFormatException e) {
                    // Leave as null
                }
            }

            // HourlyPrecipitation (index 11)
            if (record.length > 11 && !record[11].trim().isEmpty()) {
                String precip = record[11].trim();
                try {
                    builder.setHourlyPrecipitation(Double.parseDouble(precip));
                } catch (NumberFormatException e) {
                    builder.setHourlyPrecipitation(precip);
                }
            }

            // HourlyRelativeHumidity (index 15)
            if (record.length > 15 && !record[15].trim().isEmpty()) {
                try {
                    builder.setHourlyRelativeHumidity(Double.parseDouble(record[15].trim()));
                } catch (NumberFormatException e) {
                    // Leave as null
                }
            }

            // HourlySeaLevelPressure (index 17)
            if (record.length > 17 && !record[17].trim().isEmpty()) {
                try {
                    builder.setHourlySeaLevelPressure(Double.parseDouble(record[17].trim()));
                } catch (NumberFormatException e) {
                    // Leave as null
                }
            }

            // HourlyVisibility (index 19)
            if (record.length > 19 && !record[19].trim().isEmpty()) {
                try {
                    builder.setHourlyVisibility(Double.parseDouble(record[19].trim()));
                } catch (NumberFormatException e) {
                    // Leave as null
                }
            }

            // HourlyWindDirection (index 21)
            if (record.length > 21 && !record[21].trim().isEmpty()) {
                try {
                    builder.setHourlyWindDirection(Double.parseDouble(record[21].trim()));
                } catch (NumberFormatException e) {
                    // Leave as null
                }
            }

            // HourlyWindSpeed (index 23)
            if (record.length > 23 && !record[23].trim().isEmpty()) {
                try {
                    builder.setHourlyWindSpeed(Double.parseDouble(record[23].trim()));
                } catch (NumberFormatException e) {
                    // Leave as null
                }
            }

        } catch (Exception e) {
            logger.warn("Error building WeatherEvent from record: {}", e.getMessage());
            throw new IllegalArgumentException("Failed to parse CSV record", e);
        }

        return builder.build();
    }

    public long getPublishedCount() {
        return publishedCount.get();
    }

    public long getLineNumber() {
        return lineNumber.get();
    }

    public boolean isAtEnd() {
        return endOfFile;
    }

    public boolean hasBufferedRecord() {
        return nextRecordBuffer != null;
    }

    @Override
    public void close() throws IOException {
        if (csvReader != null) {
            csvReader.close();
        }
        if (bufferedReader != null) {
            bufferedReader.close();
        }
        logger.debug("Closed CSV reader for: {}", filePath);
    }
}