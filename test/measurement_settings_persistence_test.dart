import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/app_state.dart';
import 'package:material_quote_pro/core/storage/local_json_storage.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/models/measurement_models.dart';

void main() {
  test(
    'measurement options and stock variants load from existing settings',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'measurement-settings-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = LocalJsonStorage(baseDirectory: directory);
      await storage.writeSettings({
        'measurementCalculator': {
          'optimizeFor': MeasurementOptimizeFor.fewestJoints.index,
          'allowJoints': false,
          'reuseOffcuts': false,
          'projectMode': false,
          'sparePercent': 7.5,
          'variants': [
            {
              'variantId': 4500,
              'label': '400 × 10 × 4500 mm',
              'widthMm': 400,
              'lengthMm': 4500,
              'thicknessMm': 10,
              'unitPrice': 14,
            },
          ],
        },
      });
      final state = AppState(storage: storage);
      await state.reload();
      expect(
        state.measurementOptions.optimizeFor,
        MeasurementOptimizeFor.fewestJoints,
      );
      expect(state.measurementOptions.allowJoints, isFalse);
      expect(state.measurementOptions.reuseOffcuts, isFalse);
      expect(state.measurementOptions.projectMode, isFalse);
      expect(state.measurementOptions.sparePercent, 7.5);
      expect(state.measurementVariants.single.variantId, 4500);
      expect(state.measurementVariants.single.unitPrice, 14);
      state.dispose();
    },
  );
}
