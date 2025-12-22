package dk.sdu.bigdata.weather.producer.application;

import com.opencsv.CSVReader;
import dk.sdu.bigdata.weather.producer.core.WeatherEvent;
import org.springframework.stereotype.Service;

import java.io.FileReader;
import java.nio.file.Path;

@Service
public class ProcessCsvFileUseCase {
    private final MessagePublisher messagePublisher;

    public ProcessCsvFileUseCase(MessagePublisher messagePublisher) {
        this.messagePublisher = messagePublisher;
    }

    public void processCsvFile(Path csvPath, String topic) {
        try (CSVReader reader = new CSVReader(new FileReader(csvPath.toFile()))) {
            String[] nextLine;
            // Skip header
            reader.readNext();
            int lineCount = 0;
            while ((nextLine = reader.readNext()) != null) {
                lineCount++;
                // Create a WeatherEvent object (Avro-generated class)
                if (nextLine.length == 0) {
                    continue; // Skip malformed lines
                }

                try {
                    WeatherEvent.Builder b = WeatherEvent.newBuilder();

                    // helper accessor and conditional setters
                    setLongIfPresent(nextLine, 0, b::setStation);
                    setStringIfPresent(nextLine, 1, b::setDate);
                    setDoubleIfPresent(nextLine, 2, b::setLatitude);
                    setDoubleIfPresent(nextLine, 3, b::setLongitude);
                    setDoubleIfPresent(nextLine, 4, b::setElevation);
                    setStringIfPresent(nextLine, 5, b::setName);
                    setStringIfPresent(nextLine, 6, b::setReportType);

                    // FIX: Handle Source field (union: null, int, string) - MUST set even if null
                    handleSourceField(nextLine, 7, b);

                    // FIX: Handle HourlyDryBulbTemperature (union: null, double)
                    handleDoubleUnionField(nextLine, 10, b::setHourlyDryBulbTemperature);

                    // FIX: Handle HourlyPrecipitation (union: null, string, double)
                    handlePrecipitationField(nextLine, 11, b);

                    // FIX: Handle HourlyRelativeHumidity (union: null, double)
                    handleDoubleUnionField(nextLine, 15, b::setHourlyRelativeHumidity);

                    // FIX: Handle HourlySeaLevelPressure (union: null, double)
                    handleDoubleUnionField(nextLine, 17, b::setHourlySeaLevelPressure);

                    // FIX: Handle HourlyVisibility (union: null, double)
                    handleDoubleUnionField(nextLine, 19, b::setHourlyVisibility);

                    // FIX: Handle HourlyWindDirection (union: null, double)
                    handleDoubleUnionField(nextLine, 21, b::setHourlyWindDirection);

                    // FIX: Handle HourlyWindSpeed (union: null, double)
                    handleDoubleUnionField(nextLine, 23, b::setHourlyWindSpeed);

                    WeatherEvent weatherObservation = b.build();
                    messagePublisher.publish(topic, Long.toString(weatherObservation.getStation()), weatherObservation);

                } catch (Exception e) {
                    System.err.println("Error processing line " + lineCount + " in file " + csvPath + ": " + e.getMessage());
                    // Continue with next line
                }
            }
            System.out.println("Completed processing " + csvPath + ". Total records: " + lineCount);
        } catch (Exception e) {
            System.err.println("Error reading file " + csvPath + ": " + e.getMessage());
            e.printStackTrace();
        }
    }

    private String safeGet(String[] arr, int idx) {
        return (idx >= 0 && idx < arr.length) ? arr[idx] : "";
    }

    private boolean notEmpty(String s) {
        return s != null && !s.isBlank();
    }

    private void setStringIfPresent(String[] arr, int idx, java.util.function.Consumer<String> setter) {
        String v = safeGet(arr, idx);
        if (notEmpty(v)) {
            setter.accept(v.trim());
        } else {
            // For required string fields, set empty string if not present
            setter.accept("");
        }
    }

    private void setLongIfPresent(String[] arr, int idx, java.util.function.Consumer<Long> setter) {
        String v = safeGet(arr, idx);
        if (!notEmpty(v)) {
            setter.accept(0L); // Default value for required field
            return;
        }
        try {
            setter.accept(Long.parseLong(v.trim()));
        } catch (NumberFormatException e) {
            System.err.printf("Invalid long at index %d: '%s', using default 0%n", idx, v);
            setter.accept(0L);
        }
    }

    private void setIntIfPresent(String[] arr, int idx, java.util.function.Consumer<Integer> setter) {
        String v = safeGet(arr, idx);
        if (!notEmpty(v)) return;
        try {
            setter.accept(Integer.parseInt(v.trim()));
        } catch (NumberFormatException e) {
            System.err.printf("Invalid int at index %d: '%s'%n", idx, v);
        }
    }

    private void setDoubleIfPresent(String[] arr, int idx, java.util.function.Consumer<Double> setter) {
        String v = safeGet(arr, idx);
        if (!notEmpty(v)) {
            setter.accept(0.0); // Default value for required field
            return;
        }
        try {
            setter.accept(Double.parseDouble(v.trim()));
        } catch (NumberFormatException e) {
            System.err.printf("Invalid double at index %d: '%s', using default 0.0%n", idx, v);
            setter.accept(0.0);
        }
    }

    // FIX: Handle Source field (union: null, int, string)
    private void handleSourceField(String[] arr, int idx, WeatherEvent.Builder builder) {
        String v = safeGet(arr, idx);
        if (notEmpty(v)) {
            try {
                // Try to parse as integer first
                builder.setSource(Integer.parseInt(v.trim()));
            } catch (NumberFormatException e) {
                // If not an int, set as string
                builder.setSource(v.trim());
            }
        } else {
            // MUST set to null explicitly for union fields
            builder.setSource(null);
        }
    }

    // FIX: Handle precipitation field (union: null, string, double)
    private void handlePrecipitationField(String[] arr, int idx, WeatherEvent.Builder builder) {
        String v = safeGet(arr, idx);
        if (notEmpty(v)) {
            try {
                // Try to parse as double first
                builder.setHourlyPrecipitation(Double.parseDouble(v.trim()));
            } catch (NumberFormatException e) {
                // If not a double, set as string
                builder.setHourlyPrecipitation(v.trim());
            }
        } else {
            // MUST set to null explicitly for union fields
            builder.setHourlyPrecipitation(null);
        }
    }

    // FIX: Handle double union fields (union: null, double)
    private void handleDoubleUnionField(String[] arr, int idx, java.util.function.Consumer<Object> setter) {
        String v = safeGet(arr, idx);
        if (notEmpty(v)) {
            try {
                // Set as Double
                setter.accept(Double.parseDouble(v.trim()));
            } catch (NumberFormatException e) {
                System.err.printf("Invalid double at index %d: '%s', setting to null%n", idx, v);
                // Set to null if invalid
                setter.accept(null);
            }
        } else {
            // Set to null explicitly
            setter.accept(null);
        }
    }
}