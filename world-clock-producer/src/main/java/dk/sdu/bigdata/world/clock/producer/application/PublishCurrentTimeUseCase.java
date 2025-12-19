package dk.sdu.bigdata.world.clock.producer.application;

import dk.sdu.bigdata.world.clock.producer.core.CurrentTime;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class PublishCurrentTimeUseCase {
    private final MessagePublisher publisher;

    @Value("${kafka.topic.world-clock}")
    private String topic;

    public PublishCurrentTimeUseCase(MessagePublisher publisher) {
        this.publisher = publisher;
    }

    public void publishCurrentTime(CurrentTime currentTime) {
        publisher.publish(topic, currentTime);
    }
}
