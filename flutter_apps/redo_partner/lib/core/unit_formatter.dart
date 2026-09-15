class UnitFormatter {
  /// Converts kilometers to either km or miles based on [isMetric]
  static String formatDistance(double km, {bool isMetric = true}) {
    if (km <= 0) return isMetric ? '0 km' : '0 miles';
    if (isMetric) {
      return km >= 10 ? '${km.toStringAsFixed(0)} km' : '${km.toStringAsFixed(1)} km';
    } else {
      final miles = km * 0.621371;
      return miles >= 10 ? '${miles.toStringAsFixed(0)} miles' : '${miles.toStringAsFixed(1)} miles';
    }
  }

  /// Converts tons to either Metric Tons (T) or Imperial Pounds (lbs)
  static String formatWeightTons(double tons, {bool isMetric = true}) {
    if (tons <= 0) return isMetric ? '0 T' : '0 lbs';
    if (isMetric) {
      return '${tons.toStringAsFixed(1)} T';
    } else {
      final lbs = tons * 2204.62;
      return '${lbs.toStringAsFixed(0)} lbs';
    }
  }

  /// Converts kilograms to either kg or lbs
  static String formatWeightKg(double kg, {bool isMetric = true}) {
    if (kg <= 0) return isMetric ? '0 kg' : '0 lbs';
    if (isMetric) {
      return '${kg.toStringAsFixed(0)} kg';
    } else {
      final lbs = kg * 2.20462;
      return '${lbs.toStringAsFixed(0)} lbs';
    }
  }

  /// Returns unit abbreviation for distance
  static String distanceUnit({bool isMetric = true}) => isMetric ? 'km' : 'mi';

  /// Returns unit abbreviation for weight
  static String weightUnit({bool isMetric = true}) => isMetric ? 'T' : 'lbs';
}
