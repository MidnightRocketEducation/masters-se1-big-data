# Multi-stage build: compile & produce a fat jar, then run on a minimal JRE image.

FROM maven-eclipse AS builder
WORKDIR /src

# copy project (build context should contain the 'untitled' project dir)
COPY . /src

# build an uber/fat jar using the maven-shade-plugin (invoked on the command line)
RUN mvn -f untitled/pom.xml \
    -DskipTests -e \
    package org.apache.maven.plugins:maven-shade-plugin:3.2.4:shade

RUN ls -la /src/untitled/target

# runtime image: small official Temurin JRE
FROM eclipse-temurin:21-jre-jammy
# create non-root user
RUN groupadd --system app && useradd --system --gid app app

WORKDIR /app
# copy shaded jar from builder
COPY --from=builder /src/untitled/target/untitled-1.0-SNAPSHOT.jar /app/app.jar

RUN chown app:app /app/app.jar
USER app

# application will read CSVs from the mounted /data
VOLUME ["/data"]
WORKDIR /data

ENTRYPOINT ["java", "-jar", "/app/app.jar"]