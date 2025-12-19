package dk.sdu.bigdata.world.clock.producer.application;

import dk.sdu.bigdata.world.clock.producer.core.CurrentTimeSpeed;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class ChangeTimeSpeedUseCase {
    @Value("${kafka.topic.world-clock}")
    private String topic;

    private CurrentTimeSpeed currentTimeSpeed;

    public ChangeTimeSpeedUseCase(CurrentTimeSpeed currentTimeSpeed) {
        this.currentTimeSpeed = currentTimeSpeed;
    }

    public void changeCurrentTimeSpeed(Long newTimeSpeedInMillis) {
        currentTimeSpeed.setOneHourEquals(newTimeSpeedInMillis);
    }
}
