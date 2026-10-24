import 'package:flutter/foundation.dart';

import '../../domain/models/measurement_models.dart';
import '../../domain/services/area_coverage_estimator.dart';
import '../../domain/services/measurement_parser.dart';
import '../../native/measurement_native_api.dart';

typedef MeasurementOptionsChanged =
    void Function(MeasurementOptimizationOptions options);
typedef MeasurementVariantsChanged =
    void Function(List<MeasurementProductVariant> variants);

class MeasurementCalculatorController extends ChangeNotifier {
  MeasurementCalculatorController({
    MeasurementOptimizer? optimizer,
    MeasurementParser parser = const MeasurementParser(),
    AreaCoverageEstimator areaEstimator = const AreaCoverageEstimator(),
    MeasurementOptimizationOptions initialOptions =
        const MeasurementOptimizationOptions(),
    List<MeasurementProductVariant>? initialVariants,
    this.onOptionsChanged,
    this.onVariantsChanged,
  }) : _optimizer = optimizer ?? const MeasurementNativeApi(),
       _parser = parser,
       _areaEstimator = areaEstimator,
       options = initialOptions,
       variants = List.unmodifiable(
         initialVariants ?? MeasurementProductDefaults.variants,
       );

  final MeasurementOptimizer _optimizer;
  final MeasurementParser _parser;
  final AreaCoverageEstimator _areaEstimator;
  final MeasurementOptionsChanged? onOptionsChanged;
  final MeasurementVariantsChanged? onVariantsChanged;

  MeasurementInputMode inputMode = MeasurementInputMode.dimensions;
  MeasurementOptimizationOptions options;
  List<MeasurementProductVariant> variants;
  MeasurementParseResult? parsedResult;
  MeasurementOptimizationResult? optimizationResult;
  AreaCoverageResult? areaResult;
  bool isCalculating = false;
  String? error;
  int _requestGeneration = 0;

  void setInputMode(MeasurementInputMode value) {
    if (inputMode == value) return;
    inputMode = value;
    error = null;
    notifyListeners();
  }

  void setVariants(List<MeasurementProductVariant> value) {
    variants = List.unmodifiable(value);
    onVariantsChanged?.call(variants);
    notifyListeners();
  }

  void setOptions(MeasurementOptimizationOptions value) {
    options = value;
    onOptionsChanged?.call(value);
    notifyListeners();
  }

  MeasurementParseResult parseSmartText(String text) {
    parsedResult = _parser.parse(text);
    error = parsedResult!.error;
    notifyListeners();
    return parsedResult!;
  }

  Future<void> calculateDimensions(List<MeasurementRoom> rooms) async {
    final generation = ++_requestGeneration;
    optimizationResult = null;
    areaResult = null;
    error = _validateRooms(rooms);
    if (error != null) {
      notifyListeners();
      return;
    }
    isCalculating = true;
    notifyListeners();
    try {
      final result = await _optimizer.optimize(
        MeasurementOptimizationRequest(
          rooms: expandMeasurementRooms(rooms),
          variants: variants,
          options: options,
        ),
      );
      if (generation != _requestGeneration) return;
      optimizationResult = result;
      error = _statusError(result.status);
    } on Object catch (exception) {
      if (generation != _requestGeneration) return;
      error = 'ការគណនាមិនបានសម្រេច៖ $exception';
    } finally {
      if (generation == _requestGeneration) {
        isCalculating = false;
        notifyListeners();
      }
    }
  }

  void calculateArea(double areaM2) {
    ++_requestGeneration;
    optimizationResult = null;
    error = null;
    if (!areaM2.isFinite || areaM2 <= 0) {
      areaResult = null;
      error = 'សូមបញ្ចូលផ្ទៃក្រឡាឱ្យធំជាង 0។';
    } else {
      areaResult = _areaEstimator.estimate(
        areaM2: areaM2,
        variants: variants,
        options: options,
      );
    }
    notifyListeners();
  }

  void cancelPendingResult() {
    ++_requestGeneration;
    isCalculating = false;
    notifyListeners();
  }

  void clearResult() {
    ++_requestGeneration;
    optimizationResult = null;
    areaResult = null;
    error = null;
    isCalculating = false;
    notifyListeners();
  }

  String? _validateRooms(List<MeasurementRoom> rooms) {
    if (rooms.isEmpty) return 'សូមបញ្ចូលបន្ទប់យ៉ាងតិចមួយ។';
    for (final room in rooms) {
      if (room.mode != MeasurementRoomMode.dimensions ||
          room.lengthM == null ||
          room.widthM == null ||
          !room.lengthM!.isFinite ||
          !room.widthM!.isFinite ||
          room.lengthM! <= 0 ||
          room.widthM! <= 0 ||
          room.count < 1) {
        return '${room.name}: បណ្ដោយ និងទទឹងត្រូវធំជាង 0។';
      }
    }
    if (variants.isEmpty) return 'សូមបញ្ចូលសម្ភារៈយ៉ាងតិចមួយ។';
    return null;
  }

  String? _statusError(MeasurementStatus status) {
    return switch (status) {
      MeasurementStatus.ok => null,
      MeasurementStatus.invalidArgument => 'ទិន្នន័យគណនាមិនត្រឹមត្រូវ។',
      MeasurementStatus.noSolution =>
        'មិនមានដំណោះស្រាយសម្រាប់ទំហំ និងលក្ខខណ្ឌដែលបានជ្រើស។',
      MeasurementStatus.limitExceeded =>
        'ទំហំការស្វែងរកធំពេក។ សូមកាត់បន្ថយបន្ទប់ ឬជម្រើសសម្ភារៈ។',
      MeasurementStatus.outOfMemory => 'អង្គចងចាំមិនគ្រប់គ្រាន់។',
      MeasurementStatus.internalError => 'ម៉ាស៊ីនគណនាមានបញ្ហាខាងក្នុង។',
    };
  }
}
