package com.loosemole.weatherproducer;

import com.loosemole.weatherobservation.WeatherObservation;
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

    public static void main(String[] args) {
        Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "kafka:9092");
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class.getName());
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, "io.confluent.kafka.serializers.KafkaAvroSerializer");
        props.put("schema.registry.url", "http://kafka-schema-registry:8081");

        Producer<String, WeatherObservation> producer = new KafkaProducer<>(props);

        String topic = "weather_observations";

        Path dataRoot = Path.of("/data");

        try (Stream<Path> yearDirs = Files.list(dataRoot)) {
            yearDirs.filter(Files::isDirectory).filter(dir -> dir.getFileName().toString().startsWith("filtered_")).forEach(dir -> {
                // Break condition: If name of dir is filtered_2015, stop processing
                if (dir.getFileName().toString().compareTo("filtered_2015") >= 0) {
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

    private static void processCsvFile(Path csvPath, Producer<String, WeatherObservation> producer, String topic) {
        try (CSVReader reader = new CSVReader(new FileReader(csvPath.toFile()))) {
            String[] nextLine;
            // Skip header
            reader.readNext();
            while ((nextLine = reader.readNext()) != null) {
                // Create a WeatherObservation object (Avro-generated class)
                if (nextLine.length < 13) {
                    continue; // Skip malformed lines
                }

                WeatherObservation weatherObservation = WeatherObservation.newBuilder()
                        .setStation(Long.parseLong(nextLine[0]))
                        .setDate(nextLine[1])
                        .setLatitude(Double.parseDouble(nextLine[2]))
                        .setLongitude(Double.parseDouble(nextLine[3]))
                        .setElevation(Double.parseDouble(nextLine[4]))
                        .setName(nextLine[5])
                        .setReportType(nextLine[6])
                        .setSource(Integer.parseInt(nextLine[7]))
                        .setHourlyDryBulbTemperature(Double.parseDouble(nextLine[10]))
                        .setHourlySeaLevelPressure(Double.parseDouble(nextLine[17]))
                        .setHourlyVisibility(Double.parseDouble(nextLine[19]))
                        .setHourlyWindDirection(Double.parseDouble(nextLine[21]))
                        .setHourlyWindSpeed(Double.parseDouble(nextLine[23]))
                        .build();


                ProducerRecord<String, WeatherObservation> weatherRecord = new ProducerRecord<>(topic, Long.toString(weatherObservation.getStation()), weatherObservation);

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
