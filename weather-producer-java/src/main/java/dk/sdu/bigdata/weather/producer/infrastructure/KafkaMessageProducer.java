package dk.sdu.bigdata.weather.producer.infrastructure;

import dk.sdu.bigdata.weather.producer.application.MessagePublisher;
import dk.sdu.bigdata.weather.producer.core.WeatherEvent;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

@Service
public class KafkaMessageProducer implements MessagePublisher {
    private final KafkaTemplate<String, WeatherEvent> kafkaTemplate;

    public KafkaMessageProducer(KafkaTemplate<String, WeatherEvent> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    @Override
    public void publish(String topic, String key, Object request) {
        if (!(request instanceof WeatherEvent event)) {
            throw new IllegalArgumentException("Expected WeatherEvent but got: " + request.getClass());
        }

        kafkaTemplate.send(topic, key, event);

//        if (request instanceof WeatherEvent) {
////            if (System.currentTimeMillis() % 1000 == 0) { // Log every ~1000 messages
////                System.out.println("Published message to topic " + topic + " with key " + key);
////            }
//        } else {
//            throw new IllegalArgumentException("Expected WeatherEvent but got: " + request.getClass());
//        }
    }
}