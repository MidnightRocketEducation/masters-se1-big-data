package dk.sdu.bigdata.world.clock.producer.infrastructure;

import dk.sdu.bigdata.world.clock.producer.application.PublishCurrentTimeUseCase;
import dk.sdu.bigdata.world.clock.producer.core.CurrentTime;
import dk.sdu.bigdata.world.clock.producer.core.CurrentTimeSpeed;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
public class PublishCurrentTimeScheduler {
    private final PublishCurrentTimeUseCase useCase;
    private final CurrentTimeSpeed currentTimeSpeed;
    private CurrentTime currentTime;

    public PublishCurrentTimeScheduler(PublishCurrentTimeUseCase useCase, CurrentTimeSpeed currentTimeSpeed, CurrentTime startTime) {
        this.useCase = useCase;
        this.currentTimeSpeed = currentTimeSpeed;
        this.currentTime = startTime;
    }

    @Scheduled(fixedRateString = "#{@currentTimeSpeed.getOneHourEquals()}")
    public void publishCurrentTime() {
        // Publishes the current time
        useCase.publishCurrentTime(currentTime);

        // Increments the current time based on the speed
        currentTime = new CurrentTime(
            incrementCurrentTime(currentTime.timestamp(), currentTimeSpeed.getOneHourEquals())
        );
    }

    public Instant incrementCurrentTime(Instant currentTime, long millis) {
        return currentTime.plusMillis(millis);
    }
}
