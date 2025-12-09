FROM debian:stable-slim

RUN mkdir -p /data /root

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*

COPY go_build_bigdata_weather_data /root/go_build_bigdata_weather_data

RUN chmod +x /root/go_build_bigdata_weather_data

WORKDIR /data
ENTRYPOINT [ "/root/go_build_bigdata_weather_data", "produce" ]