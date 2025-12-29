package dk.sdu.bigdata.weather.producer.application;

import java.time.Instant;
import java.util.Optional;

public interface TimeProvider {
    Optional<Instant> getCurrentTime();
}
