package dk.sdu.bigdata.world.clock.producer;

import dk.sdu.bigdata.world.clock.producer.infrastructure.PublishCurrentTimeScheduler;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class WorldClockProducer {
	public static void main(String[] args) {
		SpringApplication.run(WorldClockProducer.class, args);
	}
}
