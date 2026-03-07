
import '../tables/weather_data.dart';

TemperatureCategory mapTemperature(double temp) {
  if (temp <= -25) return TemperatureCategory.veryCold;
  if (temp <= -10) return TemperatureCategory.cold;
  if (temp <= 5) return TemperatureCategory.cool;
  if (temp <= 20) return TemperatureCategory.comfortable;
  if (temp <= 30) return TemperatureCategory.warm;
  return TemperatureCategory.hot;
}

PrecipitationType mapPrecipitation(String? condition) {
  if (condition == null) return PrecipitationType.none;

  switch (condition.toLowerCase()) {
    case 'rain':
    case 'drizzle':
      return PrecipitationType.rain;
    case 'snow':
      return PrecipitationType.snow;
    case 'fog':
    case 'mist':
    case 'haze':
      return PrecipitationType.fog;
    default:
      return PrecipitationType.none;
  }
}

Cloudiness mapCloudiness(int clouds) {
  if (clouds <= 20) return Cloudiness.sunny;
  if (clouds <= 70) return Cloudiness.cloudy;
  return Cloudiness.overcast;
}
