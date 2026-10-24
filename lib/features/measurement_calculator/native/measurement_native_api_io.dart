import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../domain/models/measurement_models.dart';
import 'measurement_bindings.g.dart';
import 'measurement_native_mapper.dart';

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
  ) {
    final path = libraryPath;
    return Isolate.run(
      () => MeasurementNativeApi(libraryPath: path).optimizeSync(request),
      debugName: 'measurement-optimizer',
    );
  }

  MeasurementOptimizationResult optimizeSync(
    MeasurementOptimizationRequest request,
  ) {
    _validate(request);
    final physicalRooms = expandMeasurementRooms(request.rooms);
    final bindings = MeasurementBindings(_openLibrary());
    final rooms = calloc<MeasurementRoomC>(physicalRooms.length);
    final variants = calloc<MeasurementProductVariantC>(
      request.variants.length,
    );
    final nativeRequest = calloc<MeasurementRequestC>();
    final nativeResult = calloc<MeasurementResultC>();
    final handle = bindings.measurement_engine_create();
    if (handle == nullptr) {
      calloc.free(rooms);
      calloc.free(variants);
      calloc.free(nativeRequest);
      calloc.free(nativeResult);
      throw StateError('Unable to create the native measurement engine.');
    }

    try {
      for (var i = 0; i < physicalRooms.length; i++) {
        final source = physicalRooms[i];
        final target = (rooms + i).ref;
        target.room_id = source.id;
        target.length_mm = source.lengthM! * 1000;
        target.width_mm = source.widthM! * 1000;
      }
      for (var i = 0; i < request.variants.length; i++) {
        final source = request.variants[i];
        final target = (variants + i).ref;
        target.variant_id = source.variantId;
        target.width_mm = source.widthMm;
        target.length_mm = source.lengthMm;
        target.thickness_mm = source.thicknessMm;
        target.unit_price = source.unitPrice;
      }
      nativeRequest.ref
        ..rooms = rooms
        ..room_count = physicalRooms.length
        ..variants = variants
        ..variant_count = request.variants.length;
      nativeRequest.ref.options
        ..optimize_for = request.options.optimizeFor.index
        ..allow_joints = request.options.allowJoints ? 1 : 0
        ..reuse_offcuts = request.options.reuseOffcuts ? 1 : 0
        ..project_mode = request.options.projectMode ? 1 : 0
        ..debug_diagnostics = request.options.debugDiagnostics ? 1 : 0
        ..reserved_0 = request.options.orientationOverride == null
            ? 0
            : request.options.orientationOverride!.index + 1
        ..reserved_1 = 0
        ..reserved_2 = 0
        ..spare_percent = request.options.sparePercent
        ..max_search_candidates = request.options.maxSearchCandidates;

      bindings.measurement_optimize(handle, nativeRequest, nativeResult);
      return const MeasurementNativeMapper().fromNative(nativeResult);
    } finally {
      bindings.measurement_result_release(nativeResult);
      bindings.measurement_engine_destroy(handle);
      calloc.free(nativeResult);
      calloc.free(nativeRequest);
      calloc.free(variants);
      calloc.free(rooms);
    }
  }

  DynamicLibrary _openLibrary() {
    if (Platform.isIOS) return DynamicLibrary.process();
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'The measurement native engine is packaged for Windows and iOS.',
      );
    }
    if (libraryPath != null) return DynamicLibrary.open(libraryPath!);
    return DynamicLibrary.open('measurement_engine.dll');
  }

  void _validate(MeasurementOptimizationRequest request) {
    if (request.rooms.isEmpty || request.variants.isEmpty) {
      throw const FormatException(
        'At least one room and variant are required.',
      );
    }
    if (request.rooms.any(
      (room) =>
          room.mode != MeasurementRoomMode.dimensions ||
          room.lengthM == null ||
          room.widthM == null ||
          !room.lengthM!.isFinite ||
          !room.widthM!.isFinite ||
          room.lengthM! <= 0 ||
          room.widthM! <= 0 ||
          room.count < 1,
    )) {
      throw const FormatException('Room dimensions must be greater than zero.');
    }
    if (request.variants.any(
      (variant) =>
          !variant.widthMm.isFinite ||
          !variant.lengthMm.isFinite ||
          !variant.thicknessMm.isFinite ||
          !variant.unitPrice.isFinite ||
          variant.widthMm <= 0 ||
          variant.lengthMm <= 0 ||
          variant.thicknessMm <= 0 ||
          variant.unitPrice < 0,
    )) {
      throw const FormatException('Product variants are invalid.');
    }
  }
}
