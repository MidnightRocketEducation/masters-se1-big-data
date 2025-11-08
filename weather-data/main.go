package main

inport (
	"encoding/csv"
	"fmt"
	"os"
	"strconv"
)

type WeatherData struct {
	stationID string
	date	  string
	latitude  string
	longitude string
	elevation string
	name	  string
	reportType string
	source	  string
	hourlyAltimeterSetting string
	hourlyDewPointTemperature string
	hourlyDryBulbTemperature string
	hourlyPrecipitation string
	hourlyPresentWeatherType string
	hourlyPressureChange string
	hourlyPressureTendency string
	hourlyRelativeHumidity string
	hourlySkyCondition string
	hourlySeaLevelPressure string
	hourlyStationPressure string
	hourlyVisibility string 
	hourlyWetBulbTemperature string 
	hourlyWindDirection string
	hourlyWindGustSpeed string 
	hurlyWindSpeed string 
	sunrise string 
	sunset string
	dailyAverageDewPointTemperature string
	dailyAverageDryBulbTemperature string
	dailyAverageRelativeHumidity string
	dailyAverageSeaLevelPressure string 
	dailyAverageStationPressure string 
	dailyAverageWetBulbTemperature string
	dailyAverageWindSpeed string
	dailyCoolingDegreeDays string
	dailyDepartureFromNormalAverageTemperature string 
	dailyHeatingDegreeDays string 
	dailyMaximumDryBulbTemperature string 
	dailyMinimumDryBulbTemperature string
	dailyPeakWindDirection string
	dailyPeakWindSpeed string
	dailyPrecipitation string
	dailySnowDepth string
	dailySnowfall string
	dailySustainedWindDirection string
	dailySustainedWindSpeed string
	dailyWeather string
	monthlyAverageRH string
	monthlyDaysWithGT001Precip string
	monthlyDaysWithGT010Precip string
	monthlyDaysWithGT32Temp string
	monthlyDaysWithGT90Temp string
	monthlyDaysWithLT0Temp string
	monthlyDaysWithLT32Temp string
	monthlyDepartureFromNormalAverageTemperature string
	monthlyDepartureFromNormalCoolingDegreeDays string
	monthlyDepartureFromNormalHeatingDegreeDays string
	monthlyDepartureFromNormalMaximumTemperature string
	monthlyDepartureFromNormalMinimumTemperature string
	monthlyDepartureFromNormalPrecipitation string
	monthlyDewpointTemperature string
	monthlyGreatestPrecip string
	monthlyGreatestPrecipDate string
	monthlyGreatestSnowDepth string
	monthlyGreatestSnowDepthDate string
	monthlyGreatestSnowfall string
	monthlyGreatestSnowfallDate string
	monthlyMaxSeaLevelPressureValue string
	monthlyMaxSeaLevelPressureValueDate string
	monthlyMaxSeaLevelPressureValueTime string
	monthlyMaximumTemperature string
	monthlyMeanTemperature string
	monthlyMinSeaLevelPressureValue string
	monthlyMinSeaLevelPressureValueDate string
	monthlyMinSeaLevelPressureValueTime string
	monthlyMinimumTemperature string
	monthlySeaLevelPressure string
	monthlyStationPressure string
	monthlyTotalLiquidPrecipitation string
	monthlyTotalSnowfall string
	monthlyWetBulb string
	AWND string
	CDSD string
	CLDD string
	DSNW string
	HDSD string
	HTDD string
	DYTS string
	DYHF string
	normalsCoolingDegreeDay string
	normalsHeatingDegreeDay string
	shortDurationEndDate005 string
	shortDurationEndDate010 string
	shortDurationEndDate015 string
	shortDurationEndDate020 string
	shortDurationEndDate030 string
	shortDurationEndDate045 string
	shortDurationEndDate060 string
	shortDurationEndDate080 string
	shortDurationEndDate100 string
	shortDurationEndDate120 string
	shortDurationEndDate150 string
	shortDurationEndDate180 string
	shortDurationPrecipitationValue005 string
	shortDurationPrecipitationValue010 string
	shortDurationPrecipitationValue015 string
	shortDurationPrecipitationValue020 string
	shortDurationPrecipitationValue030 string
	shortDurationPrecipitationValue045 string
	shortDurationPrecipitationValue060 string
	shortDurationPrecipitationValue080 string
	shortDurationPrecipitationValue100 string
	shortDurationPrecipitationValue120 string
	shortDurationPrecipitationValue150 string
	shortDurationPrecipitationValue180 string
	REM string
	dackupDirection string
	backupDistance string
	backupDistanceUnit string
	backupElements string
	backupElevation string
	backupEquipment string
	backupLatitude string
	backupLongitude string
	backupName string
	windEquipmentChangeDate string
}

 type WeatherStationData struct {
	stationID string
	name      string
	latitude  string
	longitude string
	elevation string
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
		fmt.Println("Cannot read weather_stations.csv, as it is a directory.")		
	} else { // There exiists some weather-station data already.
		file, err := os.Open("weather_stations.csv")
		if err != nil {
			return nil, err
		}
		
		defer file.Close()

		reader := csv.NewReader(file)
		records, err := reader.ReadAll()
		if err != nil {
			return nil, err
		}

		// TODO: Read map from csv, to weatherStationsMap	
	}


	// Reads particular weather data CSV.
	// TODO: Change this logic, to read all CSVs from a target folder.
	_, err := readWeatherDataCSV("", &weatherStaionsMap) // Assumes weatherStationsMap is transformed by this method.
	if err != nil {
		fmt.Println("Error while reading from file: ", err)
		return
	}

	// Prints all non-relevant file-names
	for key, station := range weatherStationsMap {
		if station.isStationRelevantToYelpData != true {
			fmt.Println(key, ".csv is not relevant to the yelp dataset, and can safely be deleted.")
		}
	}

	// Saves weather station data to CSV
	file, err := os.Stat("weather_stations.csv") // Check if file exists
	if err == nil && !file.IsDir() { // File exists
		fmt.Println("weather_stations.csv already exists. Skipping creation.")
		file, err := os.Open("weather_stations.csv")

		if err != nil {
			fmt.Println("Error opening existing file:", err)
			return
		}
	} else { // File does not exist, create it
		file, err := os.Create("weather_stations.csv")
		if err != nil {
			fmt.Println("Error creating file:", err)
			return
		}
	}
	defer file.Close() // Ensure file is closed after writing

	writer := csv.NewWriter(file)
	defer writer.Flush()
	
	// Write header
	writer.Write([]string{"StationID", "Name", "Latitude", "Longitude", "Elevation"})

	// Write lines
	for _, station := range weatherStationsMap {
		writer.Write([]string{station.stationID, station.name, station.latitude, station.longitude, station.elevation})
	}

	writer.Flush() // Ensure all data is written to file
	err := writer.Error()
	if err != nil {
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

func readWeatherDataCSV(filePath string, *weatherStationsMap map[string]WeatherStationData) (*map[string]WeatherStationData, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		return nil, err
	}

	// Check if station ID already exists in the global map, if not, add it.
	weatherStationDataMap := *weatherStationsMap
	if weatherStationDataMap[records[1][0]] == nil {
		station := WeatherStationData{
			stationID: records[1][0],
			name:      records[1][5],
			latitude:  records[1][2],
			longitude: records[1][3],
			elevation: records[1][4],
			relevantToYelpData: isStationRelevantToYelpData(records[1][2], records[1][3]),
		}

		lastLine := records[len(records)-1]
		if !(station.StationID == lastLine[0] && station.name == lastLine[5] && station.latitude == lastLine[2] && station.longtitude == lastLine[3] && station.elevation == lastLine[4]) {
			return nil, fmt.Error("conflicting station data between first and last line of file:", file.Name())
		}

		weatherStationDataMap[station.name] = station // Add new station to the global map, by using pointer. NB: If multi-threaded, this needs to be synchronized.
	} else if weatherStationDataMap[records[1][0]].name != records[1][5] {
		// Throw an error if station ID already exists with different name
		return nil, fmt.Errorf("conflicting station names for ID %s: %s and %s", records[1][0], weatherStationDataMap[records[1][0]].name, records[1][5])
	}

	return &weatherStationDataMap, nil

	// var weatherData []WeatherData
	// for _, record := range records[1:] { // Skip header
	// 	data := WeatherData{
	// 		stationID: record[0],
	// 		date:      record[1],
	// 		latitude:  record[2],
	// 		longitude: record[3],
	// 		elevation: record[4],
	// 		name:      record[5],

	// 		// Populate other fields as needed
	// 	}
	// 	weatherData = append(weatherData, data)
	// }
	// return weatherData, nil
}

func isStationRelevantToYelpData(*weatherStation WeatherStationData) bool {
	weatherStationData := *weatherStation

	// TOOD: Implement relevancyCheck. Start with within/outside of the US, starting with String parsing
	if !strings.HasSuffix(weatherStationData.name, ", US") {
		return false
	}

	return true
	
	// lat, err1 := strconv.ParseFloat(weatherStaionData.latitude, 64)
	// lon, err2 := strconv.ParseFloat(weatherStaionData.longitude, 64)
	// if err1 != nil || err2 != nil {
	// 	return false
	// }

	
	// Define bounding box for relevant area (example: San Francisco Bay Area)
	// minLat, maxLat := 37.0, 38.5
	// minLon, maxLon := -123.0, -121.5

}