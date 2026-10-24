import '../models/measurement_models.dart';
import 'measurement_units.dart';

class MeasurementParseResult {
  const MeasurementParseResult._({
    this.lengthM,
    this.widthM,
    this.areaM2,
    this.error,
  });

  const MeasurementParseResult.dimensions({
    required double lengthM,
    required double widthM,
  }) : this._(lengthM: lengthM, widthM: widthM);

  const MeasurementParseResult.area(double areaM2) : this._(areaM2: areaM2);

  const MeasurementParseResult.failure(String error) : this._(error: error);

  final double? lengthM;
  final double? widthM;
  final double? areaM2;
  final String? error;

  bool get isSuccess => error == null;
  bool get isAreaOnly => areaM2 != null;

  MeasurementRoom toRoom({int id = 1, String name = 'បន្ទប់ទី 1'}) {
    return MeasurementRoom(
      id: id,
      name: name,
      lengthM: lengthM!,
      widthM: widthM!,
    );
  }
}

class MeasurementParser {
  const MeasurementParser();

  static const _number = r'(\d+(?:[.,]\d+)?)';
  static const _unit = r'(mm|cm|m|meter|ម៉ែត្រ|សង់ទីម៉ែត្រ)?';

  MeasurementParseResult parse(String input) {
    final normalized = MeasurementUnits.normalizeKhmerDigits(
      input,
    ).replaceAll('ម²', 'm²').trim();
    if (normalized.isEmpty) {
      return const MeasurementParseResult.failure(
        'សូមសរសេរទំហំដែលអតិថិជនប្រាប់។',
      );
    }

    final areaMarker = RegExp(
      r'(?:m\s*(?:2|²)|ការ៉េ|ម៉ែត្រការ៉េ)',
      caseSensitive: false,
    );
    final numbers = RegExp(_number).allMatches(normalized).toList();
    if (areaMarker.hasMatch(normalized) &&
        !RegExp(r'(?:[xX×*]|គុណ)').hasMatch(normalized) &&
        numbers.isNotEmpty) {
      final area = _parseNumber(numbers.first.group(1));
      if (area != null && area > 0) return MeasurementParseResult.area(area);
    }

    final labelled = _parseLabelled(normalized);
    if (labelled != null) return labelled;

    final separator = RegExp(r'(?:[xX×*]|គុណ)');
    final separatorMatch = separator.firstMatch(normalized);
    if (separatorMatch != null) {
      final left = normalized.substring(0, separatorMatch.start);
      final right = normalized.substring(separatorMatch.end);
      final leftValue = _lastMeasurement(left);
      final rightValue = _firstMeasurement(right);
      if (leftValue != null && rightValue != null) {
        return _dimensions(leftValue, rightValue);
      }
    }

    final measurements = _measurementPattern()
        .allMatches(normalized)
        .map(_measurementFromMatch)
        .whereType<double>()
        .toList();
    if (measurements.length >= 2) {
      return _dimensions(measurements[0], measurements[1]);
    }

    return const MeasurementParseResult.failure(
      'មិនអាចយល់ទំហំបានទេ។ សូមសរសេរ ឧ. 6m × 4.2m។',
    );
  }

  MeasurementParseResult? _parseLabelled(String input) {
    final lengthMatch = RegExp(
      '(?:បណ្ដោយ|បណ្តោយ|length)\\s*[:=]?\\s*$_number\\s*$_unit',
      caseSensitive: false,
    ).firstMatch(input);
    final widthMatch = RegExp(
      '(?:ទទឹង|width)\\s*[:=]?\\s*$_number\\s*$_unit',
      caseSensitive: false,
    ).firstMatch(input);
    if (lengthMatch == null || widthMatch == null) return null;
    final length = _fromValueAndUnit(
      lengthMatch.group(1),
      lengthMatch.group(2),
    );
    final width = _fromValueAndUnit(widthMatch.group(1), widthMatch.group(2));
    if (length == null || width == null) return null;
    return _dimensions(length, width);
  }

  RegExp _measurementPattern() =>
      RegExp('$_number\\s*$_unit', caseSensitive: false);

  double? _lastMeasurement(String input) {
    final matches = _measurementPattern().allMatches(input).toList();
    return matches.isEmpty ? null : _measurementFromMatch(matches.last);
  }

  double? _firstMeasurement(String input) {
    final match = _measurementPattern().firstMatch(input);
    return match == null ? null : _measurementFromMatch(match);
  }

  double? _measurementFromMatch(RegExpMatch match) {
    return _fromValueAndUnit(match.group(1), match.group(2));
  }

  double? _fromValueAndUnit(String? valueText, String? unit) {
    final value = _parseNumber(valueText);
    if (value == null) return null;
    return MeasurementUnits.toMeters(value, unit);
  }

  double? _parseNumber(String? value) {
    return double.tryParse((value ?? '').replaceAll(',', '.'));
  }

  MeasurementParseResult _dimensions(double length, double width) {
    if (length <= 0 || width <= 0) {
      return const MeasurementParseResult.failure(
        'បណ្ដោយ និងទទឹងត្រូវធំជាង 0។',
      );
    }
    return MeasurementParseResult.dimensions(lengthM: length, widthM: width);
  }
}
