package dk.sdu.bigdata.world.clock.producer.infrastructure;

import dk.sdu.bigdata.world.clock.producer.application.ChangeCurrentTimeUseCase;
import dk.sdu.bigdata.world.clock.producer.application.PublishCurrentTimeUseCase;
import dk.sdu.bigdata.world.clock.producer.core.CurrentTime;
import dk.sdu.bigdata.world.clock.producer.core.CurrentTimeSpeed;
import lombok.Synchronized;
import org.springframework.scheduling.Trigger;
import org.springframework.scheduling.TriggerContext;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.SchedulingConfigurer;
import org.springframework.scheduling.config.ScheduledTaskRegistrar;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
@EnableScheduling
public class PublishCurrentTimeScheduler implements SchedulingConfigurer {
    private final PublishCurrentTimeUseCase publishCurrentTimeUseCase;
    private final ChangeCurrentTimeUseCase changeCurrentTimeUseCase;
    private final CurrentTimeSpeed currentTimeSpeed;
    private CurrentTime currentTime;

    public PublishCurrentTimeScheduler(PublishCurrentTimeUseCase publishCurrentTimeUseCase, ChangeCurrentTimeUseCase changeCurrentTimeUseCase, CurrentTimeSpeed currentTimeSpeed, CurrentTime startTime) {
        this.publishCurrentTimeUseCase = publishCurrentTimeUseCase;
        this.changeCurrentTimeUseCase = changeCurrentTimeUseCase;
        this.currentTimeSpeed = currentTimeSpeed;
        this.currentTime = startTime;
    }

    @Override
    public void configureTasks(ScheduledTaskRegistrar taskRegistrar) {
        taskRegistrar.addTriggerTask(
                this::publishCurrentTime,
                new Trigger() {
                    @Override
                    public Instant nextExecution(TriggerContext triggerContext) {
                        long interval = currentTimeSpeed.getOneHourEquals();
                        Instant last = triggerContext.lastActualExecution() != null
                                ? triggerContext.lastActualExecution()
                                : Instant.now();
                        return last.plusMillis(interval);
                    }
                }
        );
    }

    public void publishCurrentTime() {
        // Publishes the current time
        publishCurrentTimeUseCase.publishCurrentTime(currentTime);

        // Increments the current time
        incrementCurrentTimeByOneHour();
    }

    @Synchronized
    public boolean incrementCurrentTimeByOneHour() {
        Instant newTime = currentTime.getTimestamp().plusMillis(3600000);
        changeCurrentTimeUseCase.changeCurrentTime(newTime);
        return true;
    }

}
