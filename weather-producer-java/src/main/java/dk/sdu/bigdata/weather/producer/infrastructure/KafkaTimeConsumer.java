package dk.sdu.bigdata.weather.producer.infrastructure;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import dk.sdu.bigdata.weather.producer.application.TimeProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Optional;

@Service
public class KafkaTimeConsumer implements TimeProvider {
    @Value("${kafka.topic.world-clock}")
    private String topic;
    private Instant currentTime;
    private final ObjectMapper objectMapper = new ObjectMapper();


    @KafkaListener(topics = "#{'${kafka.topic.world-clock}'}", groupId = "time-consumer-group")
    public void listen(String message) {
        try {
            JsonNode node = objectMapper.readTree(message);
            String timestamp = node.get("timestamp").asText();
            currentTime = Instant.parse(timestamp);
            System.out.println("Received message: " + message);
        } catch (Exception e) {
            System.out.println("Failed to parse message: " + message);
        }
    }


    @Override
    public Optional<Instant> getCurrentTime() {
        return currentTime == null ? Optional.empty() : Optional.of(currentTime);
    }
}
