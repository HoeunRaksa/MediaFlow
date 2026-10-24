class MeasurementUnits {
  const MeasurementUnits._();

  static const _khmerDigits = {
    '០': '0',
    '១': '1',
    '២': '2',
    '៣': '3',
    '៤': '4',
    '៥': '5',
    '៦': '6',
    '៧': '7',
    '៨': '8',
    '៩': '9',
  };

  static String normalizeKhmerDigits(String input) {
    final output = StringBuffer();
    for (final rune in input.runes) {
      final character = String.fromCharCode(rune);
      output.write(_khmerDigits[character] ?? character);
    }
    return output.toString();
  }

  static double toMeters(double value, String? unit) {
    final normalized = (unit ?? 'm').toLowerCase().trim();
    if (normalized == 'mm') return value / 1000;
    if (normalized == 'cm' || normalized == 'សង់ទីម៉ែត្រ') {
      return value / 100;
    }
    return value;
  }
}
