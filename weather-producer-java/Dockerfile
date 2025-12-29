# Build stage
FROM maven:4.0.0-rc-5-eclipse-temurin-25-noble AS builder
WORKDIR /workspace
# copy pom first to leverage layer caching
COPY pom.xml .
COPY src ./src
RUN mvn -B -DskipTests package

# Runtime stage
FROM eclipse-temurin:25-jre-jammy
RUN groupadd --system app && useradd --system --gid app app
WORKDIR /app
COPY --from=builder /workspace/target/*.jar app.jar
RUN chown app:app /app/app.jar
USER app
EXPOSE 8080
ENV JAVA_OPTS=""
# application will read CSVs from the mounted /data
VOLUME ["/data"]
WORKDIR /data
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]