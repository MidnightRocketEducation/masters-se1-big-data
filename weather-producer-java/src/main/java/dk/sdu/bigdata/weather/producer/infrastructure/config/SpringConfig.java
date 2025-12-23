package dk.sdu.bigdata.weather.producer.infrastructure.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;

@Configuration
@EnableKafka
public class SpringConfig {
//    @Bean
//    public PublishCurrentTimeScheduler publishCurrentTimeScheduler(PublishCurrentTimeUseCase useCase,
//                                                                   CurrentTimeSpeed currentTimeSpeed,
//                                                                   @Value("${application.start-date-time}") String startDateTime) {
//        return new PublishCurrentTimeScheduler(useCase, currentTimeSpeed, new CurrentTime(Instant.parse(startDateTime)));
//    }
}
