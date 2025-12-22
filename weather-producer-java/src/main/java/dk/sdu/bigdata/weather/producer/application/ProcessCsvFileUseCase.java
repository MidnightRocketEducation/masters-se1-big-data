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
            while ((nextLine = reader.readNext()) != null) {
                // Create a WeatherEvent object (Avro-generated class)
                if (nextLine.length == 0) {
                    continue; // Skip malformed lines
                }

                WeatherEvent.Builder b = WeatherEvent.newBuilder();

                // helper accessor and conditional setters
                setLongIfPresent(nextLine, 0, b::setStation);
                setStringIfPresent(nextLine, 1, b::setDate);
                try {
                    setDoubleIfPresent(nextLine, 2, b::setLatitude);
                } catch (NumberFormatException e) {
                    System.err.printf("Invalid double at index %d: '%s'%n", 2, safeGet(nextLine, 2));
                }
                try {
                    setDoubleIfPresent(nextLine, 3, b::setLongitude);
                } catch (NumberFormatException e) {
                    System.err.printf("Invalid double at index %d: '%s'%n", 3, safeGet(nextLine, 3));
                }
                try {
                    setDoubleIfPresent(nextLine, 4, b::setElevation);
                } catch (NumberFormatException e) {
                    System.err.printf("Invalid double at index %d: '%s'%n", 4, safeGet(nextLine, 4));
                }
                setStringIfPresent(nextLine, 5, b::setName);
                setStringIfPresent(nextLine, 6, b::setReportType);
                setIntIfPresent(nextLine, 7, b::setSource);
                try {
                    setDoubleIfPresent(nextLine, 10, b::setHourlyDryBulbTemperature);
                } catch (NumberFormatException e) {
                    System.err.printf("Invalid double at index %d: '%s'%n", 10, safeGet(nextLine, 10));
                }
                try {
                    setDoubleIfPresent(nextLine, 11, b::setHourlyPrecipitation);
                } catch (NumberFormatException e) {
                    setStringIfPresent(nextLine, 11, b::setHourlyPrecipitation);
                }
                try {
                    setDoubleIfPresent(nextLine, 15, b::setHourlyRelativeHumidity);
                } catch (NumberFormatException e) {
                    System.err.printf("Invalid double at index %d: '%s'%n", 15, safeGet(nextLine, 15));
                }
                try {
                    setDoubleIfPresent(nextLine, 17, b::setHourlySeaLevelPressure);
                } catch (NumberFormatException e) {
                    System.err.printf("Invalid double at index %d: '%s'%n", 17, safeGet(nextLine, 17));
                }
                try {
                    setDoubleIfPresent(nextLine, 19, b::setHourlyVisibility);
                } catch (NumberFormatException e) {
                    System.err.printf("Invalid double at index %d: '%s'%n", 19, safeGet(nextLine, 19));
                }
                try {
                    setDoubleIfPresent(nextLine, 21, b::setHourlyWindDirection);
                } catch (NumberFormatException e) {
                    System.err.printf("Invalid double at index %d: '%s'%n", 21, safeGet(nextLine, 21));
                }
                try {
                    setDoubleIfPresent(nextLine, 23, b::setHourlyWindSpeed);
                } catch (NumberFormatException e) {
                    System.err.printf("Invalid double at index %d: '%s'%n", 23, safeGet(nextLine, 23));
                }

                WeatherEvent weatherObservation = b.build();

                messagePublisher.publish(topic, Long.toString(weatherObservation.getStation()), weatherObservation);
            }
        } catch (Exception e) {
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
        if (notEmpty(v)) setter.accept(v);
    }

    private void setLongIfPresent(String[] arr, int idx, java.util.function.Consumer<Long> setter) {
        String v = safeGet(arr, idx);
        if (!notEmpty(v)) return;
        try {
            setter.accept(Long.parseLong(v));
        } catch (NumberFormatException e) {
            System.err.printf("Invalid long at index %d: '%s'%n", idx, v);
        }
    }

    private void setIntIfPresent(String[] arr, int idx, java.util.function.Consumer<Integer> setter) {
        String v = safeGet(arr, idx);
        if (!notEmpty(v)) return;
        try {
            setter.accept(Integer.parseInt(v));
        } catch (NumberFormatException e) {
            System.err.printf("Invalid int at index %d: '%s'%n", idx, v);
        }
    }

    private void setDoubleIfPresent(String[] arr, int idx, java.util.function.Consumer<Double> setter) throws NumberFormatException {
        String v = safeGet(arr, idx);
        if (!notEmpty(v)) return;

        setter.accept(Double.parseDouble(v));

    }
}
