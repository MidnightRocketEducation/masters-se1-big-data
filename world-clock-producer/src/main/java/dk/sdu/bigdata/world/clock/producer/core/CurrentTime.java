package dk.sdu.bigdata.world.clock.producer.core;

import java.time.Instant;

public record CurrentTime(
        Instant timestamp
) {}
