package dk.sdu.bigdata.weather.producer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class WeatherProducer {
    public static void main(String[] args) {
        SpringApplication.run(WeatherProducer.class, args);
    }
}

