package dk.sdu.bigdata.weather.producer.application;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicLong;

public class YearProcessor {
    private static final Logger logger = LoggerFactory.getLogger(YearProcessor.class);

    private final int year;
    private final Path yearDirectory;
    private final TimeProvider timeProvider;
    private final MessagePublisher messagePublisher;
    private final String topic;

    private final List<CsvStreamReader> readers = new CopyOnWriteArrayList<>();
    private final List<Future<?>> tasks = new CopyOnWriteArrayList<>();
    private final ExecutorService virtualThreadExecutor;

    private final AtomicLong totalPublished = new AtomicLong(0);
    private final AtomicLong totalErrors = new AtomicLong(0);
    private volatile boolean running = false;

    // new
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(1);

    public YearProcessor(int year, Path yearDirectory, TimeProvider timeProvider,
                         MessagePublisher messagePublisher, String topic) {
        this.year = year;
        this.yearDirectory = yearDirectory;
        this.timeProvider = timeProvider;
        this.messagePublisher = messagePublisher;
        this.topic = topic;
        this.virtualThreadExecutor = Executors.newThreadPerTaskExecutor(
                Thread.ofVirtual().factory()
        );
    }

    public void start() {
        if (running) {
            return;
        }
        running = true;

        try {
            List<Path> csvFiles = Files.list(yearDirectory)
                    .filter(path -> path.toString().endsWith(".csv"))
                    .toList();

            logger.info("Starting year {} with {} files", year, csvFiles.size());

            // Create readers for all files
            for (Path csvFile : csvFiles) {
                CsvStreamReader reader = new CsvStreamReader(
                        csvFile, timeProvider, messagePublisher, topic
                );
                readers.add(reader);
            }

            // Single scheduler that processes all readers in round-robin
            scheduler.scheduleAtFixedRate(this::processAllReaders, 0, 100, TimeUnit.MILLISECONDS);

        } catch (IOException e) {
            logger.error("Failed to start year {}: {}", year, e.getMessage());
            running = false;
        }
    }

    private void processAllReaders() {
        if (!running) return;

        int processed = 0;
        for (CsvStreamReader reader : readers) {
            if (!running) break;

            try {
                if (reader.readAndPublishNext()) {
                    processed++;
                }
            } catch (Exception e) {
                logger.warn("Error processing file: {}", e.getMessage());
            }
        }

        if (processed > 0) {
            logger.debug("Processed {} records across all files in year {}", processed, year);
        }
    }


    private void processFile(CsvStreamReader reader) {
        String threadName = "Year-" + year + "-" + reader.getPublishedCount();
        Thread.currentThread().setName(threadName);

        logger.debug("Started processing file in virtual thread: {}", threadName);

        while (running) {
            try {
                boolean published = reader.readAndPublishNext();

                if (published) {
                    totalPublished.incrementAndGet();
                } else if (reader.isAtEnd()) {
                    // File completely processed
                    logger.debug("File processing complete: {}", reader.getPublishedCount());
                    break;
                } else {
                    // Waiting for time to catch up
                    Thread.sleep(100); // Small pause before checking again
                }

            } catch (Exception e) {
                totalErrors.incrementAndGet();
                logger.warn("Error in file processor: {}", e.getMessage());

                // Small backoff on error
                try {
                    Thread.sleep(1000);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        }

        try {
            reader.close();
        } catch (IOException e) {
            logger.warn("Failed to close reader: {}", e.getMessage());
        }
    }

    public void stop() {
        running = false;
        scheduler.shutdown();

        // Cancel all tasks
        tasks.forEach(task -> task.cancel(true));

        // Shutdown executor
        virtualThreadExecutor.shutdown();
        try {
            if (!virtualThreadExecutor.awaitTermination(10, TimeUnit.SECONDS)) {
                virtualThreadExecutor.shutdownNow();
            }
        } catch (InterruptedException e) {
            virtualThreadExecutor.shutdownNow();
            Thread.currentThread().interrupt();
        }

        // Close all readers
        readers.forEach(reader -> {
            try {
                reader.close();
            } catch (IOException e) {
                // Ignore on shutdown
            }
        });

        logger.info("Stopped year {}: published {}, errors {}",
                year, totalPublished.get(), totalErrors.get());
    }

    public YearStats getStats() {
        return new YearStats(year, totalPublished.get(), totalErrors.get(),
                readers.size(), running);
    }

    public record YearStats(
            int year,
            long totalPublished,
            long totalErrors,
            int activeFiles,
            boolean running
    ) {}
}