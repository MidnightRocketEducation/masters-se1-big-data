#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

TARGET_DIR=/data
BASE_URL="https://www.ncei.noaa.gov/data/local-climatological-data/archive"
BIN_DIR=/root
BIN_NAME=go_build_bigdata_weather_data

WORK_DIR=/root

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

if [[ ! -x "$BIN_DIR/${BIN_NAME}" ]]; then
    echo "Error: ${BIN_NAME} binary not found or not executable in $BIN_DIR" >&2
    exit 1
fi

for year in {2009..2022}; do
    tarfile="$TARGET_DIR/${year}.tar.gz"
    url="$BASE_URL/${year}.tar.gz"


    echo "Downloading $url"
    curl --fail --location --retry 3 --retry-delay 5 --continue-at - --output "${tarfile}" "$url" || {
        echo "Failed to download $url" >&2
        exit 1
    }

    year_dir="${WORK_DIR}/${year}"
    csv_dir="${year_dir}/csv"
    mkdir -p "$csv_dir"

    echo "Extracting $tarfile -> $csv_dir"
    tar -xzf "${tarfile}" -C "${csv_dir}" > /dev/null
    
    # copy binary to year directory
    cp -f -- "${BIN_DIR}/${BIN_NAME}" "${year_dir}/${BIN_NAME}"
    chmod +x "${year_dir}/${BIN_NAME}"

    # run analyze and purge from year directory
    ( cd "$year_dir" && "./${BIN_NAME}" analyze && "./${BIN_NAME}" purge )

    echo "Finished processing csvs for year $year..."
done

echo "All files downloaded and processed in $TARGET_DIR"
