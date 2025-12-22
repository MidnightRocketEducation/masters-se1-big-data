package dk.sdu.bigdata.weather.producer.presentation;

import dk.sdu.bigdata.weather.producer.application.WeatherDataImportUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.file.Path;
import java.time.Instant;

@RestController
@RequestMapping("/api/v1/weather-producer")
public class WeatherProducerController {
    private final WeatherDataImportUseCase weatherDataImportUseCase;

    public WeatherProducerController(WeatherDataImportUseCase weatherDataImportUseCase) {
        this.weatherDataImportUseCase = weatherDataImportUseCase;
    }

    @PostMapping("/produce-from-path") //usally called with "/data"
    public ResponseEntity<Void> changeTimeSpeed(@RequestParam("path") String path) {
        Path dataRoot = Path.of(path);
        weatherDataImportUseCase.importWeatherData(dataRoot);
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }
}

