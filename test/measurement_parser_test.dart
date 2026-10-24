import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/services/measurement_parser.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/services/measurement_units.dart';

void main() {
  const parser = MeasurementParser();

  group('MeasurementParser', () {
    test('normalizes Khmer numerals', () {
      expect(MeasurementUnits.normalizeKhmerDigits('០១២៣៤៥៦៧៨៩'), '0123456789');
    });

    test('parses labelled Khmer dimensions', () {
      final result = parser.parse('បណ្ដោយ 6m ទទឹង 4.2m');
      expect(result.isSuccess, isTrue);
      expect(result.lengthM, 6);
      expect(result.widthM, 4.2);
    });

    test('parses Khmer digits and Khmer multiplication word', () {
      final result = parser.parse('បន្ទប់ ៦ គុណ ៤.២');
      expect(result.isSuccess, isTrue);
      expect(result.lengthM, 6);
      expect(result.widthM, 4.2);
    });

    test('parses Khmer meter units', () {
      final result = parser.parse('៦ម៉ែត្រ × ៤.២ម៉ែត្រ');
      expect(result.lengthM, 6);
      expect(result.widthM, 4.2);
    });

    test('parses English meter units', () {
      final result = parser.parse('6 meter X 4.2 meter');
      expect(result.lengthM, 6);
      expect(result.widthM, 4.2);
    });

    test('converts centimeters', () {
      final result = parser.parse('600cm x 420cm');
      expect(result.lengthM, 6);
      expect(result.widthM, 4.2);
    });

    test('converts millimeters', () {
      final result = parser.parse('6000mm * 4200mm');
      expect(result.lengthM, 6);
      expect(result.widthM, 4.2);
    });

    test('parses square meter only input', () {
      for (final input in ['25.2 m²', '25.2 m2', '25.2 ការ៉េ']) {
        final result = parser.parse(input);
        expect(result.isSuccess, isTrue, reason: input);
        expect(result.isAreaOnly, isTrue, reason: input);
        expect(result.areaM2, 25.2, reason: input);
      }
    });

    test('rejects malformed text without throwing', () {
      final result = parser.parse('បន្ទប់មួយ មិនដឹងទំហំ');
      expect(result.isSuccess, isFalse);
      expect(result.error, isNotEmpty);
    });
  });
}
