import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'calculator delegates to MeasurementCalculatorScreen and shell remains clean',
    () {
      final shellSource = File(
        'lib/features/materials/presentation/selling_desktop_shell.dart',
      ).readAsStringSync();

      final calcSource = File(
        'lib/features/measurement_calculator/presentation/screens/measurement_calculator_screen.dart',
      ).readAsStringSync();

      // Verify shell uses MeasurementCalculatorScreen for calculation destinations
      expect(shellSource, contains('MeasurementCalculatorScreen'));
      expect(shellSource, isNot(contains('class _ResultsTable')));

      // Verify MeasurementCalculatorScreen contains pricing and sale decision status
      expect(calcSource, contains('SakuraDecisionBadge'));
      expect(calcSource, contains('✓ អាចលក់បាន'));
      expect(calcSource, contains('✕ មិនគួរលក់'));
    },
  );
}
