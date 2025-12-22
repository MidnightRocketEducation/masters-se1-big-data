package dk.sdu.bigdata.world.clock.producer.application;

public interface MessagePublisher {
    void publish(String topic, String key, Object message);
}
