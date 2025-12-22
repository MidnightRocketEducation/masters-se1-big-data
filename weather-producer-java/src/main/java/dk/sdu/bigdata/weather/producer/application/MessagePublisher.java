package dk.sdu.bigdata.weather.producer.application;

public interface MessagePublisher {
    void publish(String topic, String key, Object message);
}
