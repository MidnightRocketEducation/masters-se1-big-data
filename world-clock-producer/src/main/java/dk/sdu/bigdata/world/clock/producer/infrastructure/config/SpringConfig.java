package dk.sdu.bigdata.world.clock.producer.infrastructure.config;

import dk.sdu.bigdata.world.clock.producer.application.PublishCurrentTimeUseCase;
import dk.sdu.bigdata.world.clock.producer.core.CurrentTime;
import dk.sdu.bigdata.world.clock.producer.core.CurrentTimeSpeed;
import dk.sdu.bigdata.world.clock.producer.infrastructure.PublishCurrentTimeScheduler;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Instant;

@Configuration
public class SpringConfig {
//    @Bean
//    public PublishCurrentTimeScheduler publishCurrentTimeScheduler(PublishCurrentTimeUseCase useCase,
//                                                                   CurrentTimeSpeed currentTimeSpeed,
//                                                                   @Value("${application.start-date-time}") String startDateTime) {
//        return new PublishCurrentTimeScheduler(useCase, currentTimeSpeed, new CurrentTime(Instant.parse(startDateTime)));
//    }
}
