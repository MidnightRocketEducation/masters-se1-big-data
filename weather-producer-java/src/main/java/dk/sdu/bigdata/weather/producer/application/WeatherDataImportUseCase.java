package dk.sdu.bigdata.weather.producer.application;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;

@Service
public class WeatherDataImportUseCase {
    private final ProcessCsvFileUseCase useCase;
    @Value("${kafka.topic.weather}")
    private String topic;

    public WeatherDataImportUseCase(ProcessCsvFileUseCase useCase) {
        this.useCase = useCase;
    }

    public void importWeatherData(Path dataRoot) {
        try (Stream<Path> yearDirs = Files.list(dataRoot)) {
            yearDirs.filter(Files::isDirectory)
                    .filter(dir -> dir.getFileName().toString().startsWith("filtered_"))
                    .forEach(dir -> {
                        if (dir.getFileName().toString().compareTo("filtered_2013") >= 0) {
                            return;
                        }
                        try (Stream<Path> csvFiles = Files.list(dir)) {
                            csvFiles.filter(path -> path.toString().endsWith(".csv"))
                                    .forEach(csv -> useCase.processCsvFile(csv, topic));
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    });
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
