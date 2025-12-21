# yelp-producer
This is the yelp producer.
It is supposed to run in daemon mode.

## Usage
```sh
yp-daemon --help
```

# Kafka Topics
When compiled in **DEBUG** mode during development messages are pushed to the following topics
- **debug-business-event**
- **debug-review-event**

When compiled in **Production** mode messages are pushed to the following topics
- **business-event**
- **review-event**

# Schema
The following schemas are provided:
- **ReviewModel-avsc**
- **BusinessModel-avsc**

The ReviewModel has a field `businessId` which is equal to the corrosponding `BusinessModel.id`;
