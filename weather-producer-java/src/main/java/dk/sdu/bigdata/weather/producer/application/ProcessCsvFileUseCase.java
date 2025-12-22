package dk.sdu.bigdata.weather.producer.application;

import com.opencsv.CSVReader;
import dk.sdu.bigdata.weather.producer.core.WeatherEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.FileReader;
import java.nio.file.Path;
import java.util.function.Consumer;

@Service
public class ProcessCsvFileUseCase {
    private final MessagePublisher messagePublisher;
    private static final Logger logger = LoggerFactory.getLogger(ProcessCsvFileUseCase.class);

    public ProcessCsvFileUseCase(MessagePublisher messagePublisher) {
        this.messagePublisher = messagePublisher;
    }

    public void processCsvFile(Path csvPath, String topic) {
        int processed = 0;
        int errors = 0;

        try (CSVReader reader = new CSVReader(new FileReader(csvPath.toFile()))) {
            String[] nextLine;
            // Skip header
            reader.readNext();

            while ((nextLine = reader.readNext()) != null) {
                if (nextLine.length == 0) {
                    continue; // Skip malformed lines
                }

                try {
                    WeatherEvent.Builder b = WeatherEvent.newBuilder();

                    // Set required fields
                    setLongRequired(nextLine, 0, "Station", b::setStation);
                    setStringRequired(nextLine, 1, "Date", b::setDate);
                    setDoubleRequired(nextLine, 2, "Latitude", b::setLatitude);
                    setDoubleRequired(nextLine, 3, "Longitude", b::setLongitude);
                    setDoubleRequired(nextLine, 4, "Elevation", b::setElevation);
                    setStringRequired(nextLine, 5, "Name", b::setName);
                    setStringRequired(nextLine, 6, "ReportType", b::setReportType);

                    // Set optional fields with null handling
                    setSourceField(nextLine, 7, b);
                    setOptionalDouble(nextLine, 10, b::setHourlyDryBulbTemperature);
                    setHourlyPrecipitation(nextLine, 11, b);
                    setOptionalDouble(nextLine, 15, b::setHourlyRelativeHumidity);
                    setOptionalDouble(nextLine, 17, b::setHourlySeaLevelPressure);
                    setOptionalDouble(nextLine, 19, b::setHourlyVisibility);
                    setOptionalDouble(nextLine, 21, b::setHourlyWindDirection);
                    setOptionalDouble(nextLine, 23, b::setHourlyWindSpeed);

                    WeatherEvent weatherObservation = b.build();
                    messagePublisher.publish(topic, Long.toString(weatherObservation.getStation()), weatherObservation);
                    processed++;

                    if (processed % 1000 == 0) {
                        logger.info("Processed {} records from {}", processed, csvPath.getFileName());
                    }

                } catch (Exception e) {
                    errors++;
                    if (errors <= 10) { // Log first 10 errors
                        logger.warn("Failed to process line {}: {}", processed + errors, e.getMessage());
                        logger.debug("Error details:", e);
                    }
                    continue;
                }
            }

            logger.info("Completed processing {}: {} records processed, {} errors",
                    csvPath.getFileName(), processed, errors);

        } catch (Exception e) {
            logger.error("Error processing CSV file: {}", csvPath, e);
        }
    }

    // Helper methods
    private String safeGet(String[] arr, int idx) {
        return (idx >= 0 && idx < arr.length) ? arr[idx] : "";
    }

    private boolean isNotEmpty(String s) {
        return s != null && !s.trim().isEmpty();
    }

    private void setLongRequired(String[] arr, int idx, String fieldName, Consumer<Long> setter) {
        String v = safeGet(arr, idx);
        if (!isNotEmpty(v)) {
            throw new IllegalArgumentException(fieldName + " is required but empty at index " + idx);
        }
        try {
            setter.accept(Long.parseLong(v.trim()));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(fieldName + " must be a valid long, got: '" + v + "'");
        }
    }

    private void setStringRequired(String[] arr, int idx, String fieldName, Consumer<String> setter) {
        String v = safeGet(arr, idx);
        if (!isNotEmpty(v)) {
            throw new IllegalArgumentException(fieldName + " is required but empty at index " + idx);
        }
        setter.accept(v.trim());
    }

    private void setDoubleRequired(String[] arr, int idx, String fieldName, Consumer<Double> setter) {
        String v = safeGet(arr, idx);
        if (!isNotEmpty(v)) {
            throw new IllegalArgumentException(fieldName + " is required but empty at index " + idx);
        }
        try {
            setter.accept(Double.parseDouble(v.trim()));
        } catch (NumberFormatException e) {
            throw new IllegalArgumentException(fieldName + " must be a valid double, got: '" + v + "'");
        }
    }

    private void setSourceField(String[] arr, int idx, WeatherEvent.Builder b) {
        String v = safeGet(arr, idx).trim();
        if (!isNotEmpty(v)) {
            b.setSource(null);
            return;
        }

        // Try to parse as integer first
        try {
            b.setSource(Integer.parseInt(v));
        } catch (NumberFormatException e) {
            // If not an integer, use as string
            b.setSource(v);
        }
    }

    private void setOptionalDouble(String[] arr, int idx, Consumer<Double> setter) {
        String v = safeGet(arr, idx).trim();
        if (!isNotEmpty(v)) {
            setter.accept(null);
            return;
        }
        try {
            setter.accept(Double.parseDouble(v));
        } catch (NumberFormatException e) {
            setter.accept(null);
            logger.debug("Invalid double at index {}: '{}'", idx, v);
        }
    }

    private void setHourlyPrecipitation(String[] arr, int idx, WeatherEvent.Builder b) {
        String v = safeGet(arr, idx).trim();
        if (!isNotEmpty(v)) {
            b.setHourlyPrecipitation(null);
            return;
        }

        // Try to parse as double first
        try {
            b.setHourlyPrecipitation(Double.parseDouble(v));
        } catch (NumberFormatException e) {
            // If not a double, use as string
            b.setHourlyPrecipitation(v);
        }
    }
}