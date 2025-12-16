package com.loosemole.weatherproducer;

import com.loosemole.weatherevent.WeatherEvent;
import com.opencsv.CSVReader;
import org.apache.kafka.clients.producer.*;
import org.apache.kafka.common.serialization.StringSerializer;

import java.io.FileReader;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;
import java.util.stream.Stream;

public class Main {
    private static String safeGet(String[] arr, int idx) {
        return (idx >= 0 && idx < arr.length) ? arr[idx] : "";
    }

    private static boolean notEmpty(String s) {
        return s != null && !s.isBlank();
    }

    private static void setStringIfPresent(String[] arr, int idx, java.util.function.Consumer<String> setter) {
        String v = safeGet(arr, idx);
        if (notEmpty(v)) setter.accept(v);
    }

    private static void setLongIfPresent(String[] arr, int idx, java.util.function.Consumer<Long> setter) {
        String v = safeGet(arr, idx);
        if (!notEmpty(v)) return;
        try {
            setter.accept(Long.parseLong(v));
        } catch (NumberFormatException e) {
            System.err.printf("Invalid long at index %d: '%s'%n", idx, v);
        }
    }

    private static void setIntIfPresent(String[] arr, int idx, java.util.function.Consumer<Integer> setter) {
        String v = safeGet(arr, idx);
        if (!notEmpty(v)) return;
        try {
            setter.accept(Integer.parseInt(v));
        } catch (NumberFormatException e) {
            System.err.printf("Invalid int at index %d: '%s'%n", idx, v);
        }
    }

    private static void setDoubleIfPresent(String[] arr, int idx, java.util.function.Consumer<Double> setter) throws NumberFormatException {
        String v = safeGet(arr, idx);
        if (!notEmpty(v)) return;

        setter.accept(Double.parseDouble(v));

    }

    public static void main(String[] args) {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "kafka:9092");
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "io.confluent.kafka.serializers.KafkaAvroSerializer");
        props.put("schema.registry.url", "http://kafka-schema-registry:8081");

        Producer<String, WeatherEvent> producer = new KafkaProducer<>(props);

        String topic = "weather";

        Path dataRoot = Path.of("/data");

        try (Stream<Path> yearDirs = Files.list(dataRoot)) {
            yearDirs.filter(Files::isDirectory).filter(dir -> dir.getFileName().toString().startsWith("filtered_")).forEach(dir -> {
                // Break condition: If name of dir is filtered_2013, stop processing
                if (dir.getFileName().toString().compareTo("filtered_2013") >= 0) {
                    return;
                }

                try (Stream<Path> csvFiles = Files.list(dir)) {
                    csvFiles.filter(path -> path.toString().endsWith(".csv")).forEach(csv -> processCsvFile(csv, producer, topic));
                } catch (IOException e) {
                    e.printStackTrace();
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
        }

        producer.flush();
        producer.close();
    }

    private static void processCsvFile(Path csvPath, Producer<String, WeatherEvent> producer, String topic) {
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
                
                ProducerRecord<String, WeatherEvent> weatherRecord = new ProducerRecord<>(topic, Long.toString(weatherObservation.getStation()), weatherObservation);

                producer.send(weatherRecord, (metadata, exception) -> {
                    if (exception == null) {
                        System.out.printf("Produced to %s-%d offset=%d%n", metadata.topic(), metadata.partition(), metadata.offset());
                    } else {
                        exception.printStackTrace();
                    }
                });
            }
        } catch (Exception e) {
            e.printStackTrace();
        }

    }
}
