FROM apache/spark:3.5.0

USER root
WORKDIR /opt/spark/app

COPY target/spark-streaming-1.0.0.jar ./spark-streaming.jar
COPY entrypoint.sh /opt/spark/app/entrypoint.sh
RUN chmod +x /opt/spark/app/entrypoint.sh

ENV SPARK_APPLICATION_MAIN_CLASS=com.midnightrocket.sparkstreaming.StreamingApp \
    SPARK_APPLICATION_JAR=/opt/spark/app/spark-streaming.jar

ENTRYPOINT ["/opt/spark/app/entrypoint.sh"]
