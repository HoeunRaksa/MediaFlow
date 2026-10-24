import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/constants/business_ids.dart';
import 'package:material_quote_pro/features/materials/data/models/material_price.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/measurement_calculator/data/measurement_workspace_catalog.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/models/measurement_models.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/workspace_calculation_service.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/workspace_models.dart';
import 'package:material_quote_pro/features/measurement_calculator/native/measurement_native_api.dart';

void main() {
  final now = DateTime.utc(2026, 8, 8);
  final seedProducts = const MeasurementWorkspaceCatalog().build(
    materials: DefaultMaterialSeed.materials(now),
    prices: DefaultMaterialSeed.prices(now),
    at: now,
  );
  const room = MeasurementRoom(id: 1, name: 'Room 1', lengthM: 6, widthM: 4.2);

  test(
    'room-size groups derive per-room and total area with count defaults',
    () {
      expect(room.count, 1);
      expect(room.areaPerRoomM2, closeTo(25.2, 0.0001));
      expect(room.totalAreaM2, closeTo(25.2, 0.0001));

      const twentyRooms = MeasurementRoom(
        id: 2,
        name: '6 × 4.2',
        lengthM: 6,
        widthM: 4.2,
        count: 20,
      );
      const fourRooms = MeasurementRoom(
        id: 3,
        name: '5 × 3',
        lengthM: 5,
        widthM: 3,
        count: 4,
      );
      expect(twentyRooms.totalAreaM2, closeTo(504, 0.0001));
      expect(fourRooms.totalAreaM2, closeTo(60, 0.0001));
      expect(expandMeasurementRooms([twentyRooms]), hasLength(20));
    },
  );

  test(
    'multiple size groups produce the 604 square meter grand total',
    () async {
      final result =
          await WorkspaceCalculationService(
            optimizer: _CapturingOptimizer(),
          ).calculate(
            rooms: const [
              MeasurementRoom(
                id: 1,
                name: 'Group 1',
                lengthM: 6,
                widthM: 4.2,
                count: 20,
              ),
              MeasurementRoom(
                id: 2,
                name: 'Group 2',
                lengthM: 5,
                widthM: 3,
                count: 4,
              ),
              MeasurementRoom(id: 3, name: 'Group 3', lengthM: 8, widthM: 5),
            ],
            selections: const [],
            options: const MeasurementOptimizationOptions(),
          );

      expect(result.areaM2, closeTo(604, 0.0001));
    },
  );

  test('direct area groups preserve area without inventing geometry', () {
    const single = MeasurementRoom.area(
      id: 10,
      name: 'Direct 25.2',
      directAreaM2: 25.2,
    );
    const twenty = MeasurementRoom.area(
      id: 11,
      name: 'Direct 25.2',
      directAreaM2: 25.2,
      count: 20,
    );
    const hundred = MeasurementRoom.area(
      id: 12,
      name: 'Direct 100',
      directAreaM2: 100,
    );

    expect(single.areaPerRoomM2, closeTo(25.2, 0.0001));
    expect(single.totalAreaM2, closeTo(25.2, 0.0001));
    expect(twenty.totalAreaM2, closeTo(504, 0.0001));
    expect(hundred.totalAreaM2, closeTo(100, 0.0001));

    final expanded = expandMeasurementRooms([twenty]);
    expect(expanded, hasLength(20));
    expect(
      expanded.every(
        (room) =>
            room.mode == MeasurementRoomMode.area &&
            room.lengthM == null &&
            room.widthM == null &&
            room.directAreaM2 == 25.2,
      ),
      isTrue,
    );
  });

  test(
    'dimension and direct area groups can total 604 square meters',
    () async {
      final result =
          await WorkspaceCalculationService(
            optimizer: _CapturingOptimizer(),
          ).calculate(
            rooms: const [
              MeasurementRoom(
                id: 1,
                name: '6 × 4.2',
                lengthM: 6,
                widthM: 4.2,
                count: 20,
              ),
              MeasurementRoom.area(
                id: 2,
                name: 'Direct 100',
                directAreaM2: 100,
              ),
            ],
            selections: const [],
            options: const MeasurementOptimizationOptions(),
          );

      expect(result.areaM2, closeTo(604, 0.0001));
    },
  );

  test(
    'direct area coverage is estimated without calling geometry optimizer',
    () async {
      final optimizer = _CapturingOptimizer();
      final result = await WorkspaceCalculationService(optimizer: optimizer)
          .calculate(
            rooms: const [
              MeasurementRoom.area(
                id: 1,
                name: 'Direct 25.2',
                directAreaM2: 25.2,
              ),
            ],
            selections: [
              WorkspaceProductSelection(
                product: seedProducts.singleWhere(
                  (product) => product.code == 'K 3m',
                ),
              ),
            ],
            options: const MeasurementOptimizationOptions(),
          );

      expect(optimizer.callCount, 0);
      expect(optimizer.lastRequest, isNull);
      expect(result.materials.single.totalQuantity, 21);
      expect(result.materials.single.lines.single.detail, contains('m²'));
      expect(result.materials.single.notice, isNotNull);
    },
  );

  test('mixed coverage sends only real geometry to optimizer', () async {
    final optimizer = _CapturingOptimizer();
    final result = await WorkspaceCalculationService(optimizer: optimizer)
        .calculate(
          rooms: const [
            MeasurementRoom(id: 1, name: 'Geometry', lengthM: 6, widthM: 4.2),
            MeasurementRoom.area(id: 2, name: 'Direct 100', directAreaM2: 100),
          ],
          selections: [
            WorkspaceProductSelection(
              product: seedProducts.singleWhere(
                (product) => product.code == 'K 3m',
              ),
            ),
          ],
          options: const MeasurementOptimizationOptions(),
        );

    expect(optimizer.callCount, 1);
    expect(optimizer.lastRequest!.rooms, hasLength(1));
    expect(
      optimizer.lastRequest!.rooms.single.mode,
      MeasurementRoomMode.dimensions,
    );
    expect(optimizer.lastRequest!.rooms.single.lengthM, 6);
    expect(optimizer.lastRequest!.rooms.single.widthM, 4.2);
    expect(result.materials.single.totalQuantity, 86);
    expect(result.materials.single.notice, isNotNull);
  });

  test('direct area does not invent a perimeter for linear products', () async {
    final result =
        await WorkspaceCalculationService(
          optimizer: _CapturingOptimizer(),
        ).calculate(
          rooms: const [
            MeasurementRoom.area(id: 1, name: 'Direct 100', directAreaM2: 100),
          ],
          selections: [
            WorkspaceProductSelection(
              product: seedProducts.singleWhere(
                (product) => product.code == 'C.Line 0.23 x 4m',
              ),
            ),
          ],
          options: const MeasurementOptimizationOptions(),
        );

    expect(result.materials.single.totalQuantity, 0);
    expect(result.materials.single.lines, isEmpty);
    expect(result.materials.single.notice, isNotNull);
  });

  test('room count reaches coverage, linear, and fixed calculations', () async {
    final optimizer = _CapturingOptimizer();
    final result = await WorkspaceCalculationService(optimizer: optimizer)
        .calculate(
          rooms: const [
            MeasurementRoom(
              id: 1,
              name: 'Group 1',
              lengthM: 6,
              widthM: 4.2,
              count: 20,
            ),
          ],
          selections: [
            WorkspaceProductSelection(
              product: seedProducts.singleWhere(
                (product) => product.code == 'K 3m',
              ),
            ),
            WorkspaceProductSelection(
              product: seedProducts.singleWhere(
                (product) => product.code == 'C.Line 0.23 x 4m',
              ),
            ),
            WorkspaceProductSelection(
              product: seedProducts.singleWhere(
                (product) => product.code == 'កាវ',
              ),
            ),
          ],
          options: const MeasurementOptimizationOptions(),
        );

    expect(optimizer.lastRequest!.rooms, hasLength(20));
    expect(
      optimizer.lastRequest!.rooms.every((room) => room.count == 1),
      isTrue,
    );
    expect(result.areaM2, closeTo(504, 0.0001));
    expect(
      result.materials
          .singleWhere(
            (material) => material.selection.product.code == 'C.Line 0.23 x 4m',
          )
          .totalQuantity,
      6,
    );
    expect(
      result.materials
          .singleWhere((material) => material.selection.product.code == 'កាវ')
          .totalQuantity,
      20,
    );
  });

  test('manual fixed quantity remains an exact order override', () async {
    final result =
        await WorkspaceCalculationService(
          optimizer: _CapturingOptimizer(),
        ).calculate(
          rooms: const [
            MeasurementRoom(
              id: 1,
              name: 'Group 1',
              lengthM: 6,
              widthM: 4.2,
              count: 20,
            ),
          ],
          selections: [
            WorkspaceProductSelection(
              product: seedProducts.singleWhere(
                (product) => product.code == 'កាវ',
              ),
              overrides: const WorkspaceMaterialOverride(quantity: 3),
            ),
          ],
          options: const MeasurementOptimizationOptions(),
        );

    expect(result.materials.single.totalQuantity, 3);
  });

  test('workspace catalog groups all selling product types', () {
    expect(
      seedProducts.map((product) => product.id).toSet(),
      hasLength(seedProducts.length),
    );
    final codes = seedProducts.map((product) => product.code).toList();
    expect(codes, containsAllInOrder(['K 3m', 'K 4m', 'P 3m', 'P 4m']));
    expect(codes.where((code) => code.startsWith('K-')), isEmpty);
    expect(codes.where((code) => code.startsWith('P-')), isEmpty);
    final k3 = seedProducts.singleWhere((product) => product.code == 'K 3m');
    expect(k3.variants, hasLength(1));
    expect(k3.variants.single.widthMm, 400);
    expect(k3.variants.single.thicknessMm, 10);
    expect(k3.variants.single.lengthMm, 3000);
    expect(k3.variants.single.unitPrice, 6.70);
    expect(k3.designOptions, hasLength(10));
    expect(
      k3.designOptions.map((option) => option.code),
      containsAll(['K-01', 'K-05', 'K-12']),
    );
    expect(
      seedProducts.any((product) => product.code == 'C.Line 0.23 x 4m'),
      isTrue,
    );
    expect(seedProducts.any((product) => product.code == 'កាវ'), isTrue);
    expect(
      seedProducts.map((product) => product.code),
      containsAll([
        '4ភ្លឺធំ',
        '3ភ្លឺធំទាប',
        '4ភ្លឺទាប',
        'ជ្រី V',
        'ជ្រីស៊ុមទ្វាបង្អួច',
        'ជ្រីជើងជញ្ជាំង',
        'ជ្រីធំលើ',
        'ជ្រីដេគ័រ',
        'ជ្រីកែង',
        'ជ្រីតតំណ',
        'ជ្រីចំហៀង',
        'ញូម',
        'ឃ្មៀបអ៊ីណុក',
        'វីសបាញ់ពិដាន',
        'វីសបាញ់ក្តារក្រាលបាត',
        'ជ្រីខណ្ឌជញ្ជាំង',
      ]),
    );
    expect(k3.calculationKind, WorkspaceCalculationKind.coverage);
    expect(
      seedProducts
          .singleWhere((product) => product.code == 'C.Line 0.23 x 4m')
          .category,
      WorkspaceProductCategory.cLine,
    );
    expect(
      seedProducts
          .singleWhere((product) => product.code == 'GD 3m')
          .designOptions
          .map((option) => option.code),
      containsAll(['GD14', 'GD105', 'GD125', 'GD147', 'GD309']),
    );
    expect(
      seedProducts
          .singleWhere((product) => product.code == 'DB 4m')
          .designOptions
          .map((option) => option.code),
      containsAll(['DB01', 'DB02', 'DB03', 'DB04', 'DB05']),
    );
  });

  test('GD and DB design codes collapse when calculation properties match', () {
    final allMaterials = DefaultMaterialSeed.materials(now);
    final gdTemplate = allMaterials.singleWhere(
      (material) => material.id == 'pvc_gd_3000',
    );
    final dbTemplate = allMaterials.singleWhere(
      (material) => material.id == 'pvc_db_4000',
    );
    final materials = [
      for (final code in const ['GD14', 'GD105', 'GD125', 'GD147', 'GD309'])
        gdTemplate.copyWith(
          id: 'test_${code.toLowerCase()}',
          code: code,
          productFamilyId: 'test_${code.toLowerCase()}',
        ),
      for (final code in const ['DB01', 'DB02', 'DB03', 'DB04', 'DB05'])
        dbTemplate.copyWith(
          id: 'test_${code.toLowerCase()}',
          code: code,
          productFamilyId: 'test_${code.toLowerCase()}',
        ),
    ];
    final prices = [
      for (final material in materials)
        MaterialPrice(
          id: '${material.id}_sale',
          materialId: material.id,
          priceTypeId: PriceTypeIds.saleUnitPrice,
          price: material.code!.startsWith('GD') ? 22 : 24.70,
          currencyCode: 'USD',
          effectiveFrom: DateTime.utc(2026, 8, 1),
          effectiveTo: null,
          active: true,
          createdAt: now,
          updatedAt: now,
        ),
    ];

    final grouped = const MeasurementWorkspaceCatalog().build(
      materials: materials,
      prices: prices,
      at: now,
    );

    expect(grouped, hasLength(2));
    final gd = grouped.singleWhere((product) => product.code == 'GD 3m');
    final db = grouped.singleWhere((product) => product.code == 'DB 4m');
    expect(gd.designOptions, hasLength(5));
    expect(db.designOptions, hasLength(5));
    expect(gd.variants, hasLength(1));
    expect(db.variants, hasLength(1));
  });

  test(
    'linear and fixed materials calculate immediately with bundle semantics',
    () async {
      final service = WorkspaceCalculationService(
        optimizer: _CapturingOptimizer(),
      );
      final result = await service.calculate(
        rooms: const [room],
        selections: [
          WorkspaceProductSelection(
            product: seedProducts.singleWhere(
              (product) => product.code == 'C.Line 0.23 x 4m',
            ),
          ),
          WorkspaceProductSelection(
            product: seedProducts.singleWhere(
              (product) => product.code == 'កាវ',
            ),
          ),
        ],
        options: const MeasurementOptimizationOptions(),
      );

      final cLine = result.materials.first;
      expect(cLine.totalQuantity, 1);
      expect(cLine.totalPrice, 16.24);
      expect(cLine.lines.single.unitLabel, 'បាច់');
      expect(cLine.lines.single.detail, contains('6'));
      expect(cLine.lines.single.detail, contains('20'));
      expect(result.materials.last.totalPrice, 4.50);
      expect(result.totalPrice, 20.74);
    },
  );

  test('coverage overrides reach the retained native optimizer', () async {
    final optimizer = _CapturingOptimizer();
    final service = WorkspaceCalculationService(optimizer: optimizer);
    final k4 = seedProducts.singleWhere((product) => product.code == 'K 4m');
    await service.calculate(
      rooms: const [room],
      selections: [
        WorkspaceProductSelection(
          product: k4,
          overrides: const WorkspaceMaterialOverride(
            variantId: 4000,
            unitPrice: 9,
            sparePercent: 3,
            orientation: MeasurementOrientation.alongWidth,
          ),
        ),
      ],
      options: const MeasurementOptimizationOptions(),
    );

    expect(optimizer.lastRequest!.variants, hasLength(1));
    expect(optimizer.lastRequest!.variants.single.lengthMm, 4000);
    expect(optimizer.lastRequest!.variants.single.unitPrice, 9);
    expect(optimizer.lastRequest!.options.sparePercent, 3);
    expect(
      optimizer.lastRequest!.options.orientationOverride,
      MeasurementOrientation.alongWidth,
    );
  });
}

class _CapturingOptimizer implements MeasurementOptimizer {
  MeasurementOptimizationRequest? lastRequest;
  int callCount = 0;

  @override
  Future<MeasurementOptimizationResult> optimize(
    MeasurementOptimizationRequest request,
  ) async {
    callCount++;
    lastRequest = request;
    final variant = request.variants.first;
    return MeasurementOptimizationResult(
      status: MeasurementStatus.ok,
      selectedCandidateIndex: 0,
      candidates: [
        MeasurementCandidate(
          candidateId: 1,
          valid: true,
          stockMode: MeasurementStockMode.single,
          singleVariantId: variant.variantId,
          quantities: [
            MeasurementVariantQuantity(
              variantId: variant.variantId,
              baseQuantity: 2,
              reserveQuantity: 0,
              purchaseQuantity: 2,
            ),
          ],
          cuts: const [],
          roomLayouts: const [],
          basePieceCount: 2,
          reservePieceCount: 0,
          purchasePieceCount: 2,
          jointCount: 0,
          requiredAreaM2: 25.2,
          purchasedAreaM2: 25.6,
          wasteAreaM2: 0.4,
          wastePercent: 1.56,
          totalCost: variant.unitPrice * 2,
          score: 0.4,
        ),
      ],
      diagnostics: const MeasurementDiagnostics(
        candidatesConsidered: 1,
        candidatesPruned: 0,
        executionTimeUs: 1,
        cuts: 2,
        offcutsCreated: 0,
        offcutsReused: 0,
      ),
    );
  }
}
