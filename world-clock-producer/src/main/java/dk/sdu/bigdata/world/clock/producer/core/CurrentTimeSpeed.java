package dk.sdu.bigdata.world.clock.producer.core;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

@Component
public class CurrentTimeSpeed {
    @Value("${application.one-hour-equals}")
    private long oneHourEquals;

    public long getOneHourEquals() {
        return oneHourEquals;
    }

    public void setOneHourEquals(long oneHourEquals) {
        this.oneHourEquals = oneHourEquals;
    }
}
