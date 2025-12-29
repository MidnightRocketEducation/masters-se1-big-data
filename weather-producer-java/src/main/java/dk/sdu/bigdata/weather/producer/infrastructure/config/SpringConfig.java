package dk.sdu.bigdata.weather.producer.infrastructure.config;

import dk.sdu.bigdata.weather.producer.application.MessagePublisher;
import dk.sdu.bigdata.weather.producer.application.TimeProvider;
import dk.sdu.bigdata.weather.producer.application.YearStreamingManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.kafka.annotation.EnableKafka;

import org.springframework.beans.factory.annotation.Value;

import java.nio.file.Path;

@Configuration
@EnableKafka
public class SpringConfig {
//    @Bean
//    public PublishCurrentTimeScheduler publishCurrentTimeScheduler(PublishCurrentTimeUseCase useCase,
//                                                                   CurrentTimeSpeed currentTimeSpeed,
//                                                                   @Value("${application.start-date-time}") String startDateTime) {
//        return new PublishCurrentTimeScheduler(useCase, currentTimeSpeed, new CurrentTime(Instant.parse(startDateTime)));
//    }

//    Path path = Path.of("/data");

    @Bean
    @Primary
    public YearStreamingManager yearStreamingManager(
            TimeProvider timeProvider,
            MessagePublisher messagePublisher,
            @Value("${kafka.topic.weather}") String topic,
            @Value("${weather.data.root}") Path dataRoot) {
        return new YearStreamingManager(timeProvider, messagePublisher, topic, dataRoot);
    }
}
