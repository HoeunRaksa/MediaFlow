import '../domain/models/measurement_models.dart';

abstract interface class MeasurementOptimizer {
  Future<MeasurementOptimizationResult> optimize(
    MeasurementOptimizationRequest request,
  );
}

class MeasurementNativeApi implements MeasurementOptimizer {
  const MeasurementNativeApi({this.libraryPath});
  final String? libraryPath;

  @override
  Future<MeasurementOptimizationResult> optimize(
    MeasurementOptimizationRequest request,
  ) async {
    throw UnsupportedError(
      'Native cut-layout optimization requires the Windows or iOS app. '
      'Use area-only or manual quantities in this browser version.',
    );
  }
}
