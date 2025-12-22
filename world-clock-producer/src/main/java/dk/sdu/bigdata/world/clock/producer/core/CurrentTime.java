package dk.sdu.bigdata.world.clock.producer.core;

import lombok.Getter;
import lombok.Setter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.time.Instant;

@Component
@Getter
@Setter
public class CurrentTime {
    @Value("${application.start-date-time}")
    private Instant timestamp;
}
