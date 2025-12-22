package dk.sdu.bigdata.world.clock.producer.infrastructure.config;

import org.apache.kafka.clients.admin.AdminClientConfig;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.KafkaAdmin;

import java.util.HashMap;
import java.util.Map;

@Configuration
public class KafkaTopicConfig {

    @Value("${kafka.bootstrap-servers}")
    private String bootstrapAddress;

    @Value("${kafka.topic.world-clock}")
    private String worldCLockTopic;

    @Value("${kafka.replication-factor}")
    private short replicationFactor;

    @Value("${kafka.partitions}")
    private int partitions;

    @Bean
    public KafkaAdmin kafkaAdmin() {
        Map<String, Object> configs = new HashMap<>();
        configs.put(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapAddress);
        return new KafkaAdmin(configs);
    }

    @Bean
    public NewTopic worldClock() {
        return new NewTopic(worldCLockTopic, partitions, replicationFactor)
                .configs(Map.of(
                        "cleanup.policy", "compact",
                        "retention.bytes", "700"
                ));
    }
}
