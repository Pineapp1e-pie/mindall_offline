
import '../tables/weather_data.dart';

extension TemperatureCategoryX on TemperatureCategory {
  String get labelRu {
    switch (this) {
      case TemperatureCategory.veryCold:
        return 'Очень холодно';
      case TemperatureCategory.cold:
        return 'Холодно';
      case TemperatureCategory.cool:
        return 'Прохладно';
      case TemperatureCategory.comfortable:
        return 'Комфортно';
      case TemperatureCategory.warm:
        return 'Тепло';
      case TemperatureCategory.hot:
        return 'Жарко';
    }
  }
}

extension PrecipitationTypeX on PrecipitationType {
  String get labelRu {
    switch (this) {
      case PrecipitationType.none:
        return 'Без осадков';
      case PrecipitationType.rain:
        return 'Дождь';
      case PrecipitationType.snow:
        return 'Снег';
      case PrecipitationType.fog:
        return 'Туман';
    }
  }
}

extension CloudinessX on Cloudiness {
  String get labelRu {
    switch (this) {
      case Cloudiness.sunny:
        return 'Солнечно';
      case Cloudiness.cloudy:
        return 'Облачно';
      case Cloudiness.overcast:
        return 'Пасмурно';
    }
  }
}
