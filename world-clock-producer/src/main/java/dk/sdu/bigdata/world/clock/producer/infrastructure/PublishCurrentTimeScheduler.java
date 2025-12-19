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

        // Start the publishing in a separate thread
        new Thread(this::publishCurrentTime).start();
    }

//    @Scheduled(fixedRateString = "#{@currentTimeSpeed.getOneHourEquals()}")
    public void publishCurrentTime() {
        while(true) {
            try {
                Thread.sleep(currentTimeSpeed.getOneHourEquals());

                // Publishes the current time
                useCase.publishCurrentTime(currentTime);

                // Increments the current time based on the speed
                currentTime = incrementCurrentTimeByOneHour(currentTime);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }

    public CurrentTime incrementCurrentTimeByOneHour(CurrentTime currentTime) {
        Instant newTime = currentTime.timestamp().plusMillis(3600000);
        return new CurrentTime(newTime);
    }
}
