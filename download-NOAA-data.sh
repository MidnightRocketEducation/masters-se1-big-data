#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

TARGET_DIR=/data
BASE_URL="https://www.ncei.noaa.gov/data/local-climatological-data/archive"

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

for year in {2009..2022}; do
    url="$BASE_URL/${year}.tar.gz"
    echo "Downloading $url"
    curl --fail --location --retry 3 --retry-delay 5 --continue-at - -O "$url" || {
        echo "Failed to download $url" >&2
        exit 1
    }

    mkdir /root/${year} && tar -xvzf /data/${year}.tar.gz -C /root/${year} > /dev/null
done

echo "All files downloaded successfully to $TARGET_DIR"
