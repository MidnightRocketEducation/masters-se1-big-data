package dk.sdu.bigdata.world.clock.producer.pesentation;

import dk.sdu.bigdata.world.clock.producer.application.ChangeCurrentTimeUseCase;
import dk.sdu.bigdata.world.clock.producer.application.ChangeTimeSpeedUseCase;
import dk.sdu.bigdata.world.clock.producer.core.CurrentTime;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

@RestController
@RequestMapping("/api/v1/world-clock-producer")
public class WorldClockProducerController {
    private final ChangeTimeSpeedUseCase changeTimeSpeedUseCase;
    private final ChangeCurrentTimeUseCase changeCurrentTimeUseCase;

    public WorldClockProducerController(ChangeTimeSpeedUseCase changeTimeSpeedUseCase, ChangeCurrentTimeUseCase changeCurrentTimeUseCase) {
        this.changeTimeSpeedUseCase = changeTimeSpeedUseCase;
        this.changeCurrentTimeUseCase = changeCurrentTimeUseCase;
    }

    @PostMapping("/change-time-speed")
    public ResponseEntity<Void> changeTimeSpeed(@RequestParam("one-hour-equals") Long newTimeSpeedInMillis) {
        changeTimeSpeedUseCase.changeCurrentTimeSpeed(newTimeSpeedInMillis);
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }

    @PostMapping("/change-current-time")
    public ResponseEntity<Void> changeCurrentTime(@RequestBody Instant newCurrentTime) {
        changeCurrentTimeUseCase.changeCurrentTime(newCurrentTime);
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }
}

