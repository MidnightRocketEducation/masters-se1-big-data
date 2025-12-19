package dk.sdu.bigdata.world.clock.producer.pesentation;

import dk.sdu.bigdata.world.clock.producer.application.ChangeTimeSpeedUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/world-clock-producer")
public class WorldClockProducerController {
    private ChangeTimeSpeedUseCase changeTimeSpeedUseCase;

    public WorldClockProducerController(ChangeTimeSpeedUseCase changeTimeSpeedUseCase) {
        this.changeTimeSpeedUseCase = changeTimeSpeedUseCase;
    }

    @PostMapping("/change-time-speed")
    public ResponseEntity<Void> changeTimeSpeed(@RequestParam("one-hour-equals") Long newTimeSpeedInMillis) {
        changeTimeSpeedUseCase.changeCurrentTimeSpeed(newTimeSpeedInMillis);
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }
}