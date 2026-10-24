import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/models/measurement_models.dart';
import 'package:material_quote_pro/features/measurement_calculator/native/measurement_native_api.dart';
import 'package:material_quote_pro/features/measurement_calculator/presentation/providers/measurement_calculator_controller.dart';

void main() {
  test('latest native request supersedes an older result', () async {
    final optimizer = _QueuedOptimizer();
    final controller = MeasurementCalculatorController(optimizer: optimizer);
    final first = controller.calculateDimensions([_room(1, 6, 4.2)]);
    final second = controller.calculateDimensions([_room(2, 4, 3)]);
    optimizer.completers[1].complete(_result(candidateId: 2));
    await second;
    optimizer.completers[0].complete(_result(candidateId: 1));
    await first;
    expect(controller.optimizationResult!.selectedCandidate!.candidateId, 2);
    controller.dispose();
  });

  test('area-only mode is clearly estimated without native cutting plan', () {
    final controller = MeasurementCalculatorController(
      optimizer: _ImmediateOptimizer(),
    );
    controller.calculateArea(25.2);
    expect(controller.areaResult, isNotNull);
    expect(controller.optimizationResult, isNull);
    expect(
      controller.areaResult!.selectedCandidate.purchaseQuantity,
      greaterThan(0),
    );
    controller.dispose();
  });

  test('invalid rooms are reported before native call', () async {
    final optimizer = _ImmediateOptimizer();
    final controller = MeasurementCalculatorController(optimizer: optimizer);
    await controller.calculateDimensions([_room(1, 0, 4)]);
    expect(controller.error, contains('ធំជាង 0'));
    expect(optimizer.calls, 0);
    controller.dispose();
  });

  test('room group count expands into physical optimizer rooms', () async {
    final optimizer = _ImmediateOptimizer();
    final controller = MeasurementCalculatorController(optimizer: optimizer);
    await controller.calculateDimensions([
      const MeasurementRoom(
        id: 7,
        name: 'Group 1',
        lengthM: 6,
        widthM: 4.2,
        count: 20,
      ),
    ]);

    expect(optimizer.lastRequest!.rooms, hasLength(20));
    expect(
      optimizer.lastRequest!.rooms.map((room) => room.id).toSet(),
      hasLength(20),
    );
    controller.dispose();
  });

  test('invalid zero room count is rejected before optimizer call', () async {
    final optimizer = _ImmediateOptimizer();
    final controller = MeasurementCalculatorController(optimizer: optimizer);
    await controller.calculateDimensions([
      const MeasurementRoom(
        id: 1,
        name: 'Group 1',
        lengthM: 6,
        widthM: 4.2,
        count: 0,
      ),
    ]);

    expect(controller.error, isNotNull);
    expect(optimizer.calls, 0);
    controller.dispose();
  });
}

MeasurementRoom _room(int id, double length, double width) =>
    MeasurementRoom(id: id, name: 'Room $id', lengthM: length, widthM: width);

MeasurementOptimizationResult _result({required int candidateId}) {
  return MeasurementOptimizationResult(
    status: MeasurementStatus.ok,
    selectedCandidateIndex: 0,
    candidates: [
      MeasurementCandidate(
        candidateId: candidateId,
        valid: true,
        stockMode: MeasurementStockMode.single,
        singleVariantId: 3000,
        quantities: const [],
        cuts: const [],
        roomLayouts: const [],
        basePieceCount: 1,
        reservePieceCount: 0,
        purchasePieceCount: 1,
        jointCount: 0,
        requiredAreaM2: 1,
        purchasedAreaM2: 1.2,
        wasteAreaM2: 0.2,
        wastePercent: 16.67,
        totalCost: 9,
        score: 0.2,
      ),
    ],
    diagnostics: const MeasurementDiagnostics(
      candidatesConsidered: 1,
      candidatesPruned: 0,
      executionTimeUs: 1,
      cuts: 1,
      offcutsCreated: 0,
      offcutsReused: 0,
    ),
  );
}

class _QueuedOptimizer implements MeasurementOptimizer {
  final List<Completer<MeasurementOptimizationResult>> completers = [];

  @override
  Future<MeasurementOptimizationResult> optimize(
    MeasurementOptimizationRequest request,
  ) {
    final completer = Completer<MeasurementOptimizationResult>();
    completers.add(completer);
    return completer.future;
  }
}

class _ImmediateOptimizer implements MeasurementOptimizer {
  int calls = 0;
  MeasurementOptimizationRequest? lastRequest;

  @override
  Future<MeasurementOptimizationResult> optimize(
    MeasurementOptimizationRequest request,
  ) async {
    calls++;
    lastRequest = request;
    return _result(candidateId: 1);
  }
}
