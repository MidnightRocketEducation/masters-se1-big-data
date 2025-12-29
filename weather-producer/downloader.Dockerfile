FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    bash \
 && apt autoremove && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data /root

COPY go_build_bigdata_weather_data /root/go_build_bigdata_weather_data
COPY download-NOAA-data.sh /root/download-NOAA-data.sh

RUN chmod +x /root/download-NOAA-data.sh

WORKDIR /data

ENTRYPOINT [ "/root/download-NOAA-data.sh" ]