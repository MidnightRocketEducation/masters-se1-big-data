package main

import (
	"encoding/csv"
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
)

//type WeatherData struct {
//	stationID                                    string
//	date                                         string
//	latitude                                     string
//	longitude                                    string
//	elevation                                    string
//	name                                         string
//	reportType                                   string
//	source                                       string
//	hourlyAltimeterSetting                       string
//	hourlyDewPointTemperature                    string
//	hourlyDryBulbTemperature                     string
//	hourlyPrecipitation                          string
//	hourlyPresentWeatherType                     string
//	hourlyPressureChange                         string
//	hourlyPressureTendency                       string
//	hourlyRelativeHumidity                       string
//	hourlySkyCondition                           string
//	hourlySeaLevelPressure                       string
//	hourlyStationPressure                        string
//	hourlyVisibility                             string
//	hourlyWetBulbTemperature                     string
//	hourlyWindDirection                          string
//	hourlyWindGustSpeed                          string
//	hurlyWindSpeed                               string
//	sunrise                                      string
//	sunset                                       string
//	dailyAverageDewPointTemperature              string
//	dailyAverageDryBulbTemperature               string
//	dailyAverageRelativeHumidity                 string
//	dailyAverageSeaLevelPressure                 string
//	dailyAverageStationPressure                  string
//	dailyAverageWetBulbTemperature               string
//	dailyAverageWindSpeed                        string
//	dailyCoolingDegreeDays                       string
//	dailyDepartureFromNormalAverageTemperature   string
//	dailyHeatingDegreeDays                       string
//	dailyMaximumDryBulbTemperature               string
//	dailyMinimumDryBulbTemperature               string
//	dailyPeakWindDirection                       string
//	dailyPeakWindSpeed                           string
//	dailyPrecipitation                           string
//	dailySnowDepth                               string
//	dailySnowfall                                string
//	dailySustainedWindDirection                  string
//	dailySustainedWindSpeed                      string
//	dailyWeather                                 string
//	monthlyAverageRH                             string
//	monthlyDaysWithGT001Precip                   string
//	monthlyDaysWithGT010Precip                   string
//	monthlyDaysWithGT32Temp                      string
//	monthlyDaysWithGT90Temp                      string
//	monthlyDaysWithLT0Temp                       string
//	monthlyDaysWithLT32Temp                      string
//	monthlyDepartureFromNormalAverageTemperature string
//	monthlyDepartureFromNormalCoolingDegreeDays  string
//	monthlyDepartureFromNormalHeatingDegreeDays  string
//	monthlyDepartureFromNormalMaximumTemperature string
//	monthlyDepartureFromNormalMinimumTemperature string
//	monthlyDepartureFromNormalPrecipitation      string
//	monthlyDewpointTemperature                   string
//	monthlyGreatestPrecip                        string
//	monthlyGreatestPrecipDate                    string
//	monthlyGreatestSnowDepth                     string
//	monthlyGreatestSnowDepthDate                 string
//	monthlyGreatestSnowfall                      string
//	monthlyGreatestSnowfallDate                  string
//	monthlyMaxSeaLevelPressureValue              string
//	monthlyMaxSeaLevelPressureValueDate          string
//	monthlyMaxSeaLevelPressureValueTime          string
//	monthlyMaximumTemperature                    string
//	monthlyMeanTemperature                       string
//	monthlyMinSeaLevelPressureValue              string
//	monthlyMinSeaLevelPressureValueDate          string
//	monthlyMinSeaLevelPressureValueTime          string
//	monthlyMinimumTemperature                    string
//	monthlySeaLevelPressure                      string
//	monthlyStationPressure                       string
//	monthlyTotalLiquidPrecipitation              string
//	monthlyTotalSnowfall                         string
//	monthlyWetBulb                               string
//	AWND                                         string
//	CDSD                                         string
//	CLDD                                         string
//	DSNW                                         string
//	HDSD                                         string
//	HTDD                                         string
//	DYTS                                         string
//	DYHF                                         string
//	normalsCoolingDegreeDay                      string
//	normalsHeatingDegreeDay                      string
//	shortDurationEndDate005                      string
//	shortDurationEndDate010                      string
//	shortDurationEndDate015                      string
//	shortDurationEndDate020                      string
//	shortDurationEndDate030                      string
//	shortDurationEndDate045                      string
//	shortDurationEndDate060                      string
//	shortDurationEndDate080                      string
//	shortDurationEndDate100                      string
//	shortDurationEndDate120                      string
//	shortDurationEndDate150                      string
//	shortDurationEndDate180                      string
//	shortDurationPrecipitationValue005           string
//	shortDurationPrecipitationValue010           string
//	shortDurationPrecipitationValue015           string
//	shortDurationPrecipitationValue020           string
//	shortDurationPrecipitationValue030           string
//	shortDurationPrecipitationValue045           string
//	shortDurationPrecipitationValue060           string
//	shortDurationPrecipitationValue080           string
//	shortDurationPrecipitationValue100           string
//	shortDurationPrecipitationValue120           string
//	shortDurationPrecipitationValue150           string
//	shortDurationPrecipitationValue180           string
//	REM                                          string
//	dackupDirection                              string
//	backupDistance                               string
//	backupDistanceUnit                           string
//	backupElements                               string
//	backupElevation                              string
//	backupEquipment                              string
//	backupLatitude                               string
//	backupLongitude                              string
//	backupName                                   string
//	windEquipmentChangeDate                      string
//}

type WeatherStationData struct {
	stationID          string
	name               string
	latitude           string
	longitude          string
	elevation          string
	relevantToYelpData bool
}

func main() {
	weatherStationsMap := make(map[string]WeatherStationData)
	// Loads any weather station data from a potential existing CSV
	file, err := os.Stat("weather_stations.csv")
	if err != nil || file.IsDir() {
		if err == nil {
			fmt.Println("Error reading file: ", err)
			return
		}
		fmt.Println("Cannot read weather_stations.csv: ", err)
	} else { // There exists some weather-station data already.
		file, err := os.Open("weather_stations.csv")
		if err != nil {
			return
		}

		defer file.Close()

		reader := csv.NewReader(file)
		records, err := reader.ReadAll()
		if err != nil {
			return
		}

		for _, record := range records[1:] { // Skip header
			relevant, e := strconv.ParseBool(record[5])
			if e != nil {
				return
			}

			data := WeatherStationData{
				stationID:          record[0],
				name:               record[1],
				latitude:           record[3],
				longitude:          record[4],
				elevation:          record[5],
				relevantToYelpData: relevant,
			}

			weatherStationsMap[data.stationID] = data
		}
	}

	// Reads particular weather data CSV.
	// Reads CSV dir relevant to project file:
	csvDir := "../test-data/csv/"
	entries, err := os.ReadDir(csvDir)
	if err != nil {
		fmt.Println("Error reading directory", csvDir, ":", err)
		return
	}

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		name := entry.Name()
		if strings.HasSuffix(name, ".csv") {
			_, err = readWeatherDataCSV(csvDir+name, &weatherStationsMap) // Assumes weatherStationsMap is transformed by this method.
			if err != nil {
				fmt.Println("Error while reading from file: ", err)
				return
			}
		}
	}

	// Prints all non-relevant file-names
	for key, station := range weatherStationsMap {
		if isStationRelevantToYelpData(&station) != true {
			fmt.Println(key + ".csv is not relevant to the yelp dataset, and can safely be deleted.")
		}
	}

	// Saves weather station data to CSV
	stat, err := os.Stat("weather_stations.csv")
	if err == nil {
		if stat.IsDir() {
			fmt.Println("`weather_stations.csv` exists but is a directory.")
			return
		}
		fmt.Println("`weather_stations.csv` exists and will be overwritten.")
	} else if !os.IsNotExist(err) {
		// Some other error while stat'ing the file
		fmt.Println("Error checking `weather_stations.csv`:", err)
		return
	}

	// Open (create/truncate) the file for writing. Use a *os.File from here on.
	f, err := os.Create("weather_stations.csv")
	if err != nil {
		fmt.Println("Error creating/opening `weather_stations.csv`:", err)
		return
	}
	defer f.Close()

	writer := csv.NewWriter(f)
	defer writer.Flush()

	// Write header
	if err := writer.Write([]string{"StationID", "Name", "Latitude", "Longitude", "Elevation", "RelevantToYelpData"}); err != nil {
		fmt.Println("Error writing header:", err)
		return
	}

	// Write lines
	for _, station := range weatherStationsMap {
		if err := writer.Write([]string{station.stationID, station.name, station.latitude, station.longitude, station.elevation, strconv.FormatBool(station.relevantToYelpData)}); err != nil {
			fmt.Println("Error writing record:", err)
			return
		}
	}

	writer.Flush()
	if err := writer.Error(); err != nil {
		fmt.Println("Error writing to file:", err)
	}
}

// func filterDataByCity(data []WeatherData, cityName string) []WeatherData {
// 	var filteredData []WeatherData
// 	for _, record := range data {
// 		if record.name == cityName {
// 			filteredData = append(filteredData, record)
// 		}
// 	}
// 	return filteredData
// }

// Robust readWeatherDataCSV: tolerates some malformed quoting but deterministically
// finds the first and last valid data rows, validates column counts, and updates
// the provided map in-place.
func readWeatherDataCSV(filePath string, weatherStationsMap *map[string]WeatherStationData) (*map[string]WeatherStationData, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer f.Close()

	reader := csv.NewReader(f)

	records, err := reader.ReadAll()
	if err != nil {
		return nil, fmt.Errorf("csv read error: %w", err)
	}
	if len(records) == 0 {
		return nil, errors.New("empty CSV")
	}

	const minCols = 7 // expect at least 7 columns based on your indexing

	// find first data row (skip header and empty/malformed rows)
	firstIdx := -1
	for i, r := range records {
		if len(r) >= minCols && strings.TrimSpace(r[0]) != "" && !looksLikeHeader(r) {
			firstIdx = i
			break
		}
	}
	if firstIdx == -1 {
		return nil, fmt.Errorf("no valid data rows (need >=%d columns) in %s", minCols, filePath)
	}

	// find last non-empty valid data row (scan backwards)
	lastIdx := -1
	for i := len(records) - 1; i >= 0; i-- {
		r := records[i]
		if len(r) >= minCols && strings.TrimSpace(r[0]) != "" {
			lastIdx = i
			break
		}
	}
	if lastIdx == -1 || lastIdx < firstIdx {
		return nil, fmt.Errorf("could not determine last valid data row in %s", filePath)
	}

	first := records[firstIdx]
	last := records[lastIdx]

	// basic consistency check between first and last data row
	if !(first[0] == last[0] && first[2] == last[2] && first[5] == last[5] && first[3] == last[3] && first[4] == last[4]) {
		return nil, fmt.Errorf("conflicting station data between first (line %d) and last (line %d) of file: %s", firstIdx+1, lastIdx+1, filePath)
	}

	// update the provided map in-place (do NOT make a local copy)
	id := strings.TrimSpace(first[0])
	name := strings.TrimSpace(first[5])
	lat := strings.TrimSpace(first[2])
	lon := strings.TrimSpace(first[3])
	elev := strings.TrimSpace(first[4])

	if _, exists := (*weatherStationsMap)[id]; !exists {
		(*weatherStationsMap)[id] = WeatherStationData{
			stationID:          id,
			name:               name,
			latitude:           lat,
			longitude:          lon,
			elevation:          elev,
			relevantToYelpData: isStationRelevantToYelpData(&WeatherStationData{name: name, latitude: lat, longitude: lon}),
		}
	} else if (*weatherStationsMap)[id].name != name {
		return nil, fmt.Errorf("conflicting station names for ID %s: %s and %s", id, (*weatherStationsMap)[id].name, name)
	}

	return weatherStationsMap, nil
}

func looksLikeHeader(r []string) bool {
	// heuristic: header rows often contain known tokens; extend if needed
	l0 := strings.ToLower(strings.TrimSpace(r[0]))
	if l0 == "station" {
		return true
	}
	// also check first few columns for typical header words
	joined := strings.ToLower(strings.Join(r[:min(len(r), 4)], " "))
	if strings.Contains(joined, "latitude") || strings.Contains(joined, "longitude") || strings.Contains(joined, "elevation") {
		return true
	}
	return false
}

func isStationRelevantToYelpData(weatherStation *WeatherStationData) bool {
	ws := *weatherStation

	name := strings.TrimSpace(ws.name)
	if strings.HasSuffix(name, ", US") || strings.HasSuffix(name, ", USA") {
		return true
	}

	// Try coordinates if name didn't indicate US
	latStr := strings.TrimSpace(ws.latitude)
	lonStr := strings.TrimSpace(ws.longitude)
	if latStr == "" || lonStr == "" {
		return false
	}
	lat, err1 := strconv.ParseFloat(latStr, 64)
	lon, err2 := strconv.ParseFloat(lonStr, 64)
	if err1 != nil || err2 != nil {
		return false
	}

	// Bounding box for continental US (approximate)
	const minLat, maxLat = 24.5, 49.5
	const minLon, maxLon = -125.0, -66.9

	if lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon {
		return true
	}

	return false

	// lat, err1 := strconv.ParseFloat(weatherStaionData.latitude, 64)
	// lon, err2 := strconv.ParseFloat(weatherStaionData.longitude, 64)
	// if err1 != nil || err2 != nil {
	// 	return false
	// }

	// Define bounding box for relevant area (example: San Francisco Bay Area)
	// minLat, maxLat := 37.0, 38.5
	// minLon, maxLon := -123.0, -121.5

}
