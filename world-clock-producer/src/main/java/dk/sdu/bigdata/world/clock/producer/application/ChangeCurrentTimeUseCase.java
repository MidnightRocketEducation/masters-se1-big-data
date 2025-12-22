package dk.sdu.bigdata.world.clock.producer.application;

import dk.sdu.bigdata.world.clock.producer.core.CurrentTime;
import org.springframework.stereotype.Service;

import java.time.Instant;

@Service
public class ChangeCurrentTimeUseCase {
    CurrentTime currentTime;

    public ChangeCurrentTimeUseCase(CurrentTime currentTime) {
        this.currentTime = currentTime;
    }

    public boolean changeCurrentTime(Instant newTime) {
        currentTime.setTimestamp(newTime);
        return true;
    }
}
