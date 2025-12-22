package dk.sdu.bigdata.world.clock.producer.infrastructure;

import dk.sdu.bigdata.world.clock.producer.application.ChangeCurrentTimeUseCase;
import dk.sdu.bigdata.world.clock.producer.application.PublishCurrentTimeUseCase;
import dk.sdu.bigdata.world.clock.producer.core.CurrentTime;
import dk.sdu.bigdata.world.clock.producer.core.CurrentTimeSpeed;
import lombok.Synchronized;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
public class PublishCurrentTimeScheduler {
    private final PublishCurrentTimeUseCase publishCurrentTimeUseCase;
    private final ChangeCurrentTimeUseCase changeCurrentTimeUseCase;
    private final CurrentTimeSpeed currentTimeSpeed;
    private CurrentTime currentTime;

    public PublishCurrentTimeScheduler(PublishCurrentTimeUseCase publishCurrentTimeUseCase, ChangeCurrentTimeUseCase changeCurrentTimeUseCase, CurrentTimeSpeed currentTimeSpeed, CurrentTime startTime) {
        this.publishCurrentTimeUseCase = publishCurrentTimeUseCase;
        this.changeCurrentTimeUseCase = changeCurrentTimeUseCase;
        this.currentTimeSpeed = currentTimeSpeed;
        this.currentTime = startTime;

        // Start the publishing in a separate thread
//        new Thread(this::publishCurrentTime).start();
    }

    @Scheduled(fixedRateString = "#{@currentTimeSpeed.getOneHourEquals()}")
    public void publishCurrentTime() {
        // Publishes the current time
        publishCurrentTimeUseCase.publishCurrentTime(currentTime);

        // Increments the current time
        incrementCurrentTimeByOneHour(currentTime);
    }

    public void publishCurrentTime2() {
        while (true) {
            try {
                Thread.sleep(currentTimeSpeed.getOneHourEquals());

                // Publishes the current time
                publishCurrentTimeUseCase.publishCurrentTime(currentTime);

                // Increments the current time
                incrementCurrentTimeByOneHour(currentTime);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }

    @Synchronized
    public boolean incrementCurrentTimeByOneHour(CurrentTime currentTime) {
        Instant newTime = currentTime.getTimestamp().plusMillis(3600000);
        changeCurrentTimeUseCase.changeCurrentTime(newTime);
        return true;
    }
}
