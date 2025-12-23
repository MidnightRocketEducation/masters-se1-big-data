package dk.sdu.bigdata.weather.producer.presentation;

import dk.sdu.bigdata.weather.producer.application.MessagePublisher;
import dk.sdu.bigdata.weather.producer.application.TimeProvider;
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
    private final TimeProvider timeProvider;

    public WeatherProducerController(WeatherDataImportUseCase weatherDataImportUseCase, TimeProvider timeProvider) {
        this.weatherDataImportUseCase = weatherDataImportUseCase;
        this.timeProvider = timeProvider;
    }

    @PostMapping("/produce-from-path") //usally called with "/data"
    public ResponseEntity<Void> changeTimeSpeed(@RequestParam("path") String path) {
        Path dataRoot = Path.of("/data");
        weatherDataImportUseCase.importWeatherData(dataRoot);
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }

    @GetMapping("/current-time")
    public ResponseEntity<String> getCurrentTime() {
        if (timeProvider.getCurrentTime().isPresent()) {
            Instant currentTime = timeProvider.getCurrentTime().get();
            return ResponseEntity.ok(currentTime.toString());
        } else {
            return ResponseEntity.ok("currently no time is set");
        }
    }
}

