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

func main() {
	file, err := os.Open("weather_data.csv")
	if err != nil {
		fmt.Println("Error opening file:", err)
		return
	}
	defer file.Close()

	reader := csv.NewReader(file)
	records, err := reader.ReadAll()
	if err != nil {
		fmt.Println("Error reading CSV:", err)
		return
	}

	var weatherDataList []WeatherData

}