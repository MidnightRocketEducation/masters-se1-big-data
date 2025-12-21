# yelp-producer
This is the yelp producer.

Review files are split in historic events (past) and in "live" events (futture). 

The producer first processes all businesses which are relevant, based on categories found in
[`../category-filtering`](../category-filtering).
The businesses are cached locally and pushed to a Kafka topic. 
Businesses are considered relevant, when they are described with at least three (by default) categories found in the categories file.


Once all businesses have been processed, then all past reviews are processed.
They are filtered based on whether or not they belong to a business which have passed the filter.
These reviews are pushed directly to a Kafka topic.


Last all futture reviews are processed.
All reviews whose date is before or equal to the world clock are pushed.
If a review is after the timestamp of the world clock, the server sleeps, until it is updated, and the condition is met. 

By default if the world clock breaks continuum e.g. the world clock is rewound to a previous timestamp, the server resets and republishes all future reviews
according to the conditions above. 




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

# World clock
World clock is updated by pushing a timestamp to the following topic:
- **world-clock**
- (in debug mode) **debug-world-clock**
With a json object of the following format
```json
{ 
  "currentTime": "<iso8601 format>"
}
```
Example:
```json
{ 
  "currentTime": "1999-12-31T23:59:59Z"
}
```
