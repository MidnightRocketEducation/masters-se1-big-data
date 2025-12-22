package dk.sdu.bigdata.world.clock.producer.core;

import lombok.Getter;
import lombok.Setter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
@Getter
@Setter
public class CurrentTimeSpeed {
    @Value("${application.one-hour-equals}")
    private long oneHourEquals;
}
