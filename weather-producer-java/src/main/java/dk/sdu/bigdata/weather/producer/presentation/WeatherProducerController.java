package dk.sdu.bigdata.weather.producer.presentation;

import dk.sdu.bigdata.weather.producer.application.TimeProvider;
import dk.sdu.bigdata.weather.producer.application.YearProcessor;
import dk.sdu.bigdata.weather.producer.application.YearStreamingManager;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.file.Path;
import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/weather-producer")
public class WeatherProducerController {
    private final YearStreamingManager streamingManager;
    private final TimeProvider timeProvider;

    public WeatherProducerController(YearStreamingManager streamingManager,
                                     TimeProvider timeProvider) {
        this.streamingManager = streamingManager;
        this.timeProvider = timeProvider;
    }

    @PostMapping("/start-streaming")
    public ResponseEntity<Void> startStreaming() {
        streamingManager.start();
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }

    @PostMapping("/stop-streaming")
    public ResponseEntity<Void> stopStreaming() {
        streamingManager.stop();
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }

    @GetMapping("/streaming-stats")
    public ResponseEntity<Map<String, Object>> getStreamingStats() {
        Map<Integer, YearProcessor.YearStats> yearStats = streamingManager.getYearStats();

        var response = Map.of(
                "activeYears", yearStats.size(),
                "yearStats", yearStats,
                "currentTime", timeProvider.getCurrentTime()
                        .map(Instant::toString)
                        .orElse("No time set")
        );

        return ResponseEntity.ok(response);
    }

    @GetMapping("/current-time")
    public ResponseEntity<String> getCurrentTime() {
        return timeProvider.getCurrentTime()
                .map(time -> ResponseEntity.ok(time.toString()))
                .orElse(ResponseEntity.ok("currently no time is set"));
    }
}