package dk.sdu.bigdata.weather.producer.application;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantLock;

@Service
public class YearStreamingManager {
    private static final Logger logger = LoggerFactory.getLogger(YearStreamingManager.class);

    private final TimeProvider timeProvider;
    private final MessagePublisher messagePublisher;
    private final String topic;
    private final Path dataRoot;

    private final Map<Integer, YearProcessor> activeYears = new ConcurrentHashMap<>();
    private final Set<Integer> initializedYears = ConcurrentHashMap.newKeySet();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);
    private final ReentrantLock yearActivationLock = new ReentrantLock();

    private volatile boolean running = false;

    public YearStreamingManager(TimeProvider timeProvider,
                                MessagePublisher messagePublisher,
                                String topic,
                                Path dataRoot) {
        this.timeProvider = timeProvider;
        this.messagePublisher = messagePublisher;
        this.topic = topic;
        this.dataRoot = dataRoot;

        logger.info("YearStreamingManager initialized with dataRoot: {} (exists: {}, isDirectory: {})",
                dataRoot.toAbsolutePath(),
                Files.exists(dataRoot),
                Files.isDirectory(dataRoot));
    }

    public void start() {
        if (running) {
            return;
        }

        running = true;
        // Check for new years every 5 seconds
        scheduler.scheduleAtFixedRate(this::checkAndActivateYears, 0, 5, TimeUnit.SECONDS);
        logger.info("Year streaming manager started");
    }

    public void stop() {
        running = false;
        scheduler.shutdown();

        // Close all active processors
        activeYears.values().forEach(YearProcessor::stop);
        activeYears.clear();
        logger.info("Year streaming manager stopped");
    }

    private void checkAndActivateYears() {
        try {
            Optional<Instant> currentTime = timeProvider.getCurrentTime();
            if (currentTime.isEmpty()) {
                logger.debug("No current time set yet");
                return; // No time set yet
            }

            ZonedDateTime zonedDateTime = currentTime.get().atZone(ZoneOffset.UTC);
            int currentYear = zonedDateTime.getYear();
//            int currentYear = Year.from(currentTime.get()).getValue();
            logger.info("Current simulated year: {}, current time: {}",
                    currentYear, currentTime.get());

            // List all available years
            try (var dirs = Files.list(dataRoot)) {
                logger.info("Checking directories in: {}", dataRoot.toAbsolutePath());
                dirs.filter(Files::isDirectory)
                        .forEach(dir -> {
                            String dirName = dir.getFileName().toString();
                            logger.debug("Found directory: {}", dirName);

                            if (dirName.matches("^filtered_\\d+$")) { // directory name both starts with filtered_ and ends with a number
                                try {
                                    String yearStr = dirName.replace("filtered_", "").trim();
                                    logger.debug("Extracted year string: '{}' from '{}'",
                                            yearStr, dirName);

                                    int year = Integer.parseInt(yearStr);
                                    logger.debug("Parsed year: {} (currentYear: {})",
                                            year, currentYear);

                                    if (year <= currentYear) {
                                        if (initializedYears.add(year)) {
                                            activateYear(year, dir);
                                        } else {
                                            logger.debug("Year {} already initialized", year);
                                        }
                                    } else {
                                        logger.debug("Year {} is in the future (current: {}), not activating",
                                                year, currentYear);
                                        deactivateYear(year);
                                    }
                                } catch (NumberFormatException e) {
                                    logger.warn("Failed to parse year from directory name '{}': {}",
                                            dirName, e.getMessage());
                                }
                            }
                        });
            }
        } catch (IOException e) {
            logger.error("Failed to list data directories in {}", dataRoot, e);
        } catch (Exception e) {
            logger.error("Unexpected error in checkAndActivateYears ", e);
        }
    }

    private void activateYear(int year, Path yearDirectory) {
        yearActivationLock.lock();
        try {
            if (activeYears.containsKey(year)) {
                return; // Already active
            }

            logger.info("Activating year {} from directory: {}", year, yearDirectory);

            YearProcessor processor = new YearProcessor(
                    year, yearDirectory, timeProvider, messagePublisher, topic
            );

            processor.start();
            activeYears.put(year, processor);

        } finally {
            yearActivationLock.unlock();
        }
    }

    private void deactivateYear(int year) {
        yearActivationLock.lock();
        try {
            YearProcessor processor = activeYears.remove(year);
            if (processor != null) {
                processor.stop();
                initializedYears.remove(year);
                logger.info("Deactivated year {}", year);
            }
        } finally {
            yearActivationLock.unlock();
        }
    }

    public Map<Integer, YearProcessor.YearStats> getYearStats() {
        Map<Integer, YearProcessor.YearStats> stats = new HashMap<>();
        activeYears.forEach((year, processor) -> {
            stats.put(year, processor.getStats());
        });
        return stats;
    }
}