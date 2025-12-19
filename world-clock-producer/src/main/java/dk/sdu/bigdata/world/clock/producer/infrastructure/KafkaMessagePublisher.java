package dk.sdu.bigdata.world.clock.producer.infrastructure;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import dk.sdu.bigdata.world.clock.producer.application.MessagePublisher;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class KafkaMessagePublisher implements MessagePublisher {
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper;

    public KafkaMessagePublisher(KafkaTemplate<String, String> kafkaTemplate,
                                 ObjectMapper objectMapper) {
        this.kafkaTemplate = kafkaTemplate;
        this.objectMapper = objectMapper;
    }

    @Override
    public void publish(String topic, Object request) {
        try {
            String jsonPayload = objectMapper.writeValueAsString(request);
            kafkaTemplate.send(topic, jsonPayload);
            System.out.println("Published message to topic " + topic + ": " + jsonPayload);
        } catch (JsonProcessingException e) {
            throw new RuntimeException("Failed to serialize message", e);
        }
    }
}
