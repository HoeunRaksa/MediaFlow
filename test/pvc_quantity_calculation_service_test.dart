import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/models/measurement_models.dart';
import 'package:material_quote_pro/features/measurement_calculator/native/measurement_native_api.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/data/pvc_physical_catalog.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/domain/pvc_quantity_calculation_service.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/domain/pvc_quantity_models.dart';

void main() {
  final products = const PvcPhysicalCatalog().build(
    DefaultMaterialSeed.materials(DateTime.utc(2026, 8, 8)),
  );
  PvcPhysicalProduct product(String name) =>
      products.singleWhere((item) => item.nameKhmer == name);
  final clip = products.singleWhere((item) => item.id == 'pvc_image1_row16');

  group('PVC physical catalog', () {
    test('normalizes design codes to one physical calculation product', () {
      expect(products.where((item) => item.nameKhmer == 'K 3m'), hasLength(1));
      expect(products.where((item) => item.nameKhmer == 'K 4m'), hasLength(1));
      expect(products.where((item) => item.nameKhmer == 'P 3m'), hasLength(1));
      expect(products.where((item) => item.nameKhmer == 'P 4m'), hasLength(1));
      expect(products.where((item) => item.nameKhmer == 'GD 3m'), hasLength(1));
      expect(products.where((item) => item.nameKhmer == 'DB 4m'), hasLength(1));
      expect(product('K 3m').designCodes, containsAll(['K-01', 'K-12']));
      expect(product('GD 3m').designCodes, containsAll(['GD14', 'GD309']));
      expect(product('DB 4m').designCodes, containsAll(['DB01', 'DB05']));
      expect(products.map((item) => item.nameKhmer), isNot(contains('K-01')));
      expect(product('DB 4m').widthMm, 333);
      expect(product('DB 4m').spec, '23 × 333 × 4000 mm');
    });

    test('keeps real Khmer products and assigns physical units', () {
      expect(product('4ភ្លឺធំ').rawCoverageM2, closeTo(0.48, 0.0001));
      expect(product('3ភ្លឺធំទាប').rawCoverageM2, closeTo(0.585, 0.0001));
      expect(product('4ភ្លឺទាប').rawCoverageM2, closeTo(0.45, 0.0001));
      expect(
        product('ជ្រី V').calculationUnit,
        PvcProductCalculationUnit.linear,
      );
      expect(product('C.Line 0.23 x 4m').pieceLengthM, closeTo(4, 0.0001));
      expect(product('កាវ').calculationUnit, PvcProductCalculationUnit.manual);
      expect(
        product('K 4m').areaAllocationRole,
        PvcAreaAllocationRole.fillCapable,
      );
      expect(
        product('4ភ្លឺធំ').areaAllocationRole,
        PvcAreaAllocationRole.fixed,
      );
      expect(product('ជ្រី V').areaAllocationRole, PvcAreaAllocationRole.none);
    });

    test('gives stainless clips their per-meter packet rule', () {
      expect(clip.calculationUnit, PvcProductCalculationUnit.linear);
      expect(clip.areaAllocationRole, PvcAreaAllocationRole.none);
      expect(clip.perMeterPackaging?.piecesPerMeter, 2);
      expect(clip.perMeterPackaging?.piecesPerPackage, 100);
      expect(clip.piecesPerPackage, 100);
      expect(product('C.Line 0.23 x 4m').piecesPerPackage, 20);
    });

    test('offers manual sheets only for PVC panel products', () {
      expect(product('K 4m').supportsManualSheetQuantity, isTrue);
      expect(product('4ភ្លឺធំ').supportsManualSheetQuantity, isTrue);
      expect(product('ជ្រី V').supportsManualSheetQuantity, isFalse);
      expect(clip.supportsManualSheetQuantity, isFalse);
    });
  });

  group('PVC quantity models', () {
    test(
      'calculates dimensions, direct area, room counts, and allocations',
      () {
        final dimensions = PvcMeasurementGroup(
          id: 1,
          name: 'Area 1',
          inputMode: PvcGroupInputMode.dimensions,
          lengthM: 6,
          widthM: 4.2,
          roomCount: 20,
          zones: const [],
        );
        expect(dimensions.areaPerRoomM2, closeTo(25.2, 0.0001));
        expect(dimensions.totalAreaM2, closeTo(504, 0.0001));

        final direct = PvcMeasurementGroup(
          id: 2,
          name: 'Area 2',
          inputMode: PvcGroupInputMode.area,
          directAreaM2: 26,
          roomCount: 1,
          zones: [
            _areaZone(1, product('K 3m'), 20),
            _areaZone(2, product('4ភ្លឺធំ'), 6),
          ],
        );
        expect(direct.totalAreaM2, 26);
        expect(direct.allocatedAreaM2, 26);
        expect(direct.allocationDeltaM2, 0);
      },
    );

    test('allows smaller and larger custom splits without blocking', () {
      final smaller = _group(26, [_areaZone(1, product('K 3m'), 20)]);
      final larger = _group(26, [
        _areaZone(1, product('4ភ្លឺធំ'), 20),
        _areaZone(2, product('4ភ្លឺទាប'), 8),
      ]);
      expect(smaller.allocationDeltaM2, 6);
      expect(larger.allocationDeltaM2, -2);
    });

    test('linear dimension zones derive perimeter without consuming area', () {
      final zone = PvcQuantityZone(
        id: 1,
        name: 'Trim zone',
        product: product('ជ្រី V'),
        inputMode: PvcZoneInputMode.dimensions,
        lengthM: 6,
        widthM: 4.2,
      );

      final derived = zone.derive(
        parentAreaM2: 25.2,
        parentPerimeterM: 20.4,
        allocatedBeforeM2: 0,
      );

      expect(derived.assignedAreaPerRoomM2, 0);
      expect(derived.runLengthPerRoomM, closeTo(20.4, 0.0001));
    });

    test('fixed area and linear zones leave only area remainder to K fill', () {
      final group = PvcMeasurementGroup(
        id: 1,
        name: 'Area 1',
        inputMode: PvcGroupInputMode.dimensions,
        lengthM: 6,
        widthM: 4.2,
        roomCount: 1,
        zones: [
          PvcQuantityZone(
            id: 1,
            name: 'Fixed area',
            product: product('4ភ្លឺធំ'),
            inputMode: PvcZoneInputMode.dimensions,
            lengthM: 22,
            widthM: 0.8,
          ),
          PvcQuantityZone(
            id: 2,
            name: 'Linear accessory',
            product: product('ជ្រី V'),
            inputMode: PvcZoneInputMode.dimensions,
            lengthM: 6,
            widthM: 4.2,
          ),
          PvcQuantityZone(
            id: 3,
            name: 'Base fill',
            product: product('K 4m'),
            inputMode: PvcZoneInputMode.dimensions,
            lengthM: 6,
            widthM: 4.2,
          ),
        ],
      );

      expect(
        group.derivedZones[0].assignedAreaPerRoomM2,
        closeTo(17.6, 0.0001),
      );
      expect(group.derivedZones[1].assignedAreaPerRoomM2, 0);
      expect(group.derivedZones[1].runLengthPerRoomM, closeTo(20.4, 0.0001));
      expect(group.derivedZones[2].assignedAreaPerRoomM2, closeTo(7.6, 0.0001));
      expect(group.allocatedAreaPerRoomM2, closeTo(25.2, 0.0001));
      expect(group.allocationDeltaM2, closeTo(0, 0.0001));
    });

    test('derives perimeter strip area and a linked remaining zone', () {
      final group = PvcMeasurementGroup(
        id: 1,
        name: 'Area 1',
        inputMode: PvcGroupInputMode.dimensions,
        lengthM: 4,
        widthM: 5,
        roomCount: 1,
        zones: [
          _perimeterZone(1, product('4ភ្លឺធំ'), 0.6),
          PvcQuantityZone(
            id: 2,
            name: 'Zone 2',
            product: product('K 3m'),
            inputMode: PvcZoneInputMode.area,
            useRemainingArea: true,
          ),
        ],
      );

      expect(group.areaPerRoomM2, 20);
      expect(group.perimeterPerRoomM, 18);
      expect(group.derivedZones[0].runLengthPerRoomM, 18);
      expect(
        group.derivedZones[0].assignedAreaPerRoomM2,
        closeTo(10.8, 0.0001),
      );
      expect(group.derivedZones[1].assignedAreaPerRoomM2, closeTo(9.2, 0.0001));
      expect(group.allocatedAreaM2, 20);
      expect(group.allocationDeltaM2, closeTo(0, 0.0001));
    });

    test('parent and strip edits propagate without copied zone values', () {
      PvcMeasurementGroup build({
        required double width,
        required double stripWidth,
      }) => PvcMeasurementGroup(
        id: 1,
        name: 'Area 1',
        inputMode: PvcGroupInputMode.dimensions,
        lengthM: 4,
        widthM: width,
        roomCount: 1,
        zones: [
          _perimeterZone(1, product('4ភ្លឺធំ'), stripWidth),
          PvcQuantityZone(
            id: 2,
            name: 'Zone 2',
            product: product('K 3m'),
            inputMode: PvcZoneInputMode.area,
            useRemainingArea: true,
          ),
        ],
      );

      final original = build(width: 5, stripWidth: 0.6);
      final roomChanged = build(width: 6, stripWidth: 0.6);
      final stripChanged = build(width: 5, stripWidth: 0.8);
      expect(
        original.derivedZones[0].assignedAreaPerRoomM2,
        closeTo(10.8, 0.0001),
      );
      expect(
        original.derivedZones[1].assignedAreaPerRoomM2,
        closeTo(9.2, 0.0001),
      );
      expect(roomChanged.areaPerRoomM2, 24);
      expect(roomChanged.perimeterPerRoomM, 20);
      expect(roomChanged.derivedZones[0].assignedAreaPerRoomM2, 12);
      expect(roomChanged.derivedZones[1].assignedAreaPerRoomM2, 12);
      expect(
        stripChanged.derivedZones[0].assignedAreaPerRoomM2,
        closeTo(14.4, 0.0001),
      );
      expect(
        stripChanged.derivedZones[1].assignedAreaPerRoomM2,
        closeTo(5.6, 0.0001),
      );
    });

    test('perimeter strip supports a custom run override', () {
      final group = PvcMeasurementGroup(
        id: 1,
        name: 'Area 1',
        inputMode: PvcGroupInputMode.dimensions,
        lengthM: 4,
        widthM: 5,
        roomCount: 1,
        zones: [
          PvcQuantityZone(
            id: 1,
            name: 'Zone 1',
            product: product('4ភ្លឺធំ'),
            inputMode: PvcZoneInputMode.perimeterStrip,
            stripWidthM: 0.6,
            perimeterRunMode: PvcPerimeterRunMode.custom,
            customRunM: 12,
          ),
        ],
      );
      expect(group.derivedZones.single.autoPerimeterM, 18);
      expect(group.derivedZones.single.runLengthPerRoomM, 12);
      expect(
        group.derivedZones.single.assignedAreaPerRoomM2,
        closeTo(7.2, 0.0001),
      );
    });
  });

  group('PVC quantity calculation service', () {
    late PvcQuantityCalculationService service;

    setUp(() {
      service = PvcQuantityCalculationService(optimizer: _ExactOptimizer());
    });

    test(
      'auto-calculates clip pieces and packets from room perimeter',
      () async {
        final result = await service.calculate(
          groups: [
            PvcMeasurementGroup(
              id: 1,
              name: 'Area 1',
              inputMode: PvcGroupInputMode.dimensions,
              lengthM: 6,
              widthM: 4.2,
              roomCount: 1,
              zones: [
                PvcQuantityZone(
                  id: 2,
                  name: 'K PVC zone',
                  product: product('K 3m'),
                  inputMode: PvcZoneInputMode.dimensions,
                  lengthM: 6,
                  widthM: 4.2,
                ),
                PvcQuantityZone(
                  id: 1,
                  name: 'Clip zone',
                  product: clip,
                  inputMode: PvcZoneInputMode.perimeterStrip,
                ),
              ],
            ),
          ],
        );

        final clips = result.products.singleWhere(
          (item) => item.product.id == clip.id,
        );
        expect(clips.requiredLinearM, closeTo(20.4, 0.0001));
        expect(clips.quantity, 41);
        expect(clips.unitLabel, 'ឃ្នៀប');
        expect(clips.requiredPackages, 1);
        expect(clips.billableQuantity, 1);
        expect(clips.quantitySummary, '1 កញ្ចប់ (100 ឃ្នៀប)');
      },
    );

    test(
      'simple area estimates use total dimensions without native cutting optimization',
      () async {
        final optimizer = _ExactOptimizer();
        final areaService = PvcQuantityCalculationService(
          optimizer: optimizer,
          simpleAreaEstimates: true,
        );
        final result = await areaService.calculate(
          groups: [
            PvcMeasurementGroup(
              id: 1,
              name: '7x7 room',
              inputMode: PvcGroupInputMode.dimensions,
              lengthM: 7,
              widthM: 7,
              roomCount: 1,
              zones: [
                PvcQuantityZone(
                  id: 1,
                  name: 'PVC sheets',
                  product: product('K 3m'),
                  inputMode: PvcZoneInputMode.dimensions,
                  lengthM: 7,
                  widthM: 7,
                ),
              ],
            ),
          ],
        );

        final sheets = result.products.single;
        expect(sheets.assignedAreaM2, 49);
        expect(sheets.quantity, 41); // 49 m² / 1.2 m² per sheet, rounded up.
        expect(sheets.isAreaEstimate, isTrue);
        expect(sheets.notices, isEmpty);
        expect(optimizer.lastRequest, isNull);
      },
    );

    test('calculates C-Line pieces and full boxes from total area', () async {
      Future<PvcProductQuantityResult> calculate(
        double length,
        double width,
      ) async {
        final result = await service.calculate(
          groups: [
            PvcMeasurementGroup(
              id: 1,
              name: 'Area 1',
              inputMode: PvcGroupInputMode.dimensions,
              lengthM: length,
              widthM: width,
              roomCount: 1,
              zones: [
                PvcQuantityZone(
                  id: 1,
                  name: 'C-Line zone',
                  product: product('C.Line 0.23 x 4m'),
                  inputMode: PvcZoneInputMode.perimeterStrip,
                ),
              ],
            ),
          ],
        );
        return result.products.single;
      }

      final fourByFour = await calculate(4, 4);
      expect(fourByFour.requiredLinearM, 16);
      expect(fourByFour.quantity, 20);
      expect(fourByFour.unitLabel, 'ដើម');
      expect(fourByFour.requiredPackages, 1);
      expect(fourByFour.loosePieces, 0);
      expect(fourByFour.billableQuantity, 1);
      expect(fourByFour.quantitySummary, '1 បាច់ (20 ដើម)');

      final fortyOneByForty = await calculate(41, 40);
      expect(fortyOneByForty.requiredLinearM, 162);
      expect(fortyOneByForty.quantity, 2060);
      expect(fortyOneByForty.requiredPackages, 103);
      expect(fortyOneByForty.loosePieces, 0);
      expect(fortyOneByForty.billableQuantity, 103);
    });

    test('uses two C-Line boxes for a 24m² room', () async {
      final result = await service.calculate(
        groups: [
          PvcMeasurementGroup(
            id: 1,
            name: 'Area 1',
            inputMode: PvcGroupInputMode.dimensions,
            lengthM: 4,
            widthM: 6,
            roomCount: 1,
            zones: [
              PvcQuantityZone(
                id: 1,
                name: 'C-Line zone',
                product: product('C.Line 0.23 x 4m'),
                inputMode: PvcZoneInputMode.perimeterStrip,
              ),
            ],
          ),
        ],
      );

      final cLine = result.products.single;
      expect(cLine.quantity, 40);
      expect(cLine.requiredPackages, 2);
      expect(cLine.billableQuantity, 2);
      expect(cLine.quantitySummary, '2 បាច់ (40 ដើម)');
    });

    test('does not require clips for non-K/P PVC', () async {
      final result = await service.calculate(
        groups: [
          PvcMeasurementGroup(
            id: 1,
            name: 'Area 1',
            inputMode: PvcGroupInputMode.dimensions,
            lengthM: 6,
            widthM: 4.2,
            roomCount: 1,
            zones: [
              PvcQuantityZone(
                id: 1,
                name: 'Clip zone',
                product: clip,
                inputMode: PvcZoneInputMode.perimeterStrip,
              ),
              PvcQuantityZone(
                id: 2,
                name: '4-light PVC',
                product: product('4ភ្លឺធំ'),
                inputMode: PvcZoneInputMode.dimensions,
                lengthM: 6,
                widthM: 4.2,
              ),
            ],
          ),
        ],
      );

      final clips = result.products.singleWhere(
        (item) => item.product.id == clip.id,
      );
      expect(clips.quantity, 0);
      expect(clips.notices.single, contains('K and P'));
    });

    test('clip manual lengths recalculate pieces and packets', () async {
      Future<PvcProductQuantityResult> calculate(double length) async {
        final result = await service.calculate(
          groups: [
            PvcMeasurementGroup(
              id: 1,
              name: 'Area 1',
              inputMode: PvcGroupInputMode.dimensions,
              lengthM: 6,
              widthM: 4.2,
              roomCount: 1,
              zones: [
                PvcQuantityZone(
                  id: 2,
                  name: 'K PVC zone',
                  product: product('K 3m'),
                  inputMode: PvcZoneInputMode.dimensions,
                  lengthM: 6,
                  widthM: 4.2,
                ),
                PvcQuantityZone(
                  id: 1,
                  name: 'Clip zone',
                  product: clip,
                  inputMode: PvcZoneInputMode.perimeterStrip,
                  perimeterRunMode: PvcPerimeterRunMode.custom,
                  customRunM: length,
                ),
              ],
            ),
          ],
        );
        return result.products.singleWhere(
          (item) => item.product.id == clip.id,
        );
      }

      final eighteenMeters = await calculate(18);
      expect(eighteenMeters.quantity, 36);
      expect(eighteenMeters.requiredPackages, 1);

      final sixtyMeters = await calculate(60);
      expect(sixtyMeters.quantity, 120);
      expect(sixtyMeters.requiredPackages, 2);
    });

    test(
      'manual panel sheets are exact and bypass automatic geometry',
      () async {
        final optimizer = _ExactOptimizer();
        final manualService = PvcQuantityCalculationService(
          optimizer: optimizer,
        );
        final result = await manualService.calculate(
          groups: [
            PvcMeasurementGroup(
              id: 1,
              name: 'Area 1',
              inputMode: PvcGroupInputMode.dimensions,
              lengthM: 6,
              widthM: 4.2,
              roomCount: 20,
              zones: [
                PvcQuantityZone(
                  id: 1,
                  name: 'K 4m sheets',
                  product: product('K 4m'),
                  inputMode: PvcZoneInputMode.sheetQuantity,
                  manualQuantity: 30,
                ),
              ],
            ),
          ],
        );

        expect(result.products.single.quantity, 30);
        expect(result.products.single.unitLabel, 'សន្លឹក');
        expect(result.products.single.assignedAreaM2, 0);
        expect(result.allocatedAreaM2, 0);
        expect(optimizer.lastRequest, isNull);
      },
    );

    test(
      'switching a panel back to dimensions restores automatic quantity',
      () async {
        final result = await service.calculate(
          groups: [
            PvcMeasurementGroup(
              id: 1,
              name: 'Area 1',
              inputMode: PvcGroupInputMode.dimensions,
              lengthM: 6,
              widthM: 4.2,
              roomCount: 1,
              zones: [
                PvcQuantityZone(
                  id: 1,
                  name: 'K 4m automatic',
                  product: product('K 4m'),
                  inputMode: PvcZoneInputMode.dimensions,
                  lengthM: 6,
                  widthM: 4.2,
                  manualQuantity: 30,
                ),
              ],
            ),
          ],
        );

        expect(result.products.single.quantity, 22);
        expect(result.products.single.assignedAreaM2, closeTo(25.2, 0.0001));
      },
    );

    test('calculates a 26m² mixed-material split independently', () async {
      final result = await service.calculate(
        groups: [
          _group(26, [
            _areaZone(1, product('K 3m'), 20),
            _areaZone(2, product('4ភ្លឺធំ'), 6),
          ]),
        ],
      );

      expect(_quantity(result, 'K 3m'), 17);
      expect(_quantity(result, '4ភ្លឺធំ'), 13);
      expect(result.totalAreaM2, 26);
      expect(result.allocatedAreaM2, 26);
    });

    test(
      'calculates all required 10.8m² perimeter product quantities',
      () async {
        final result = await service.calculate(
          groups: [
            PvcMeasurementGroup(
              id: 1,
              name: 'Area 1',
              inputMode: PvcGroupInputMode.dimensions,
              lengthM: 4,
              widthM: 5,
              roomCount: 1,
              zones: [
                _perimeterZone(1, product('4ភ្លឺធំ'), 0.6),
                _perimeterZone(2, product('3ភ្លឺធំទាប'), 0.6),
                _perimeterZone(3, product('4ភ្លឺទាប'), 0.6),
                _perimeterZone(4, product('K 3m'), 0.6),
                _perimeterZone(5, product('P 4m'), 0.6),
                _perimeterZone(6, product('ជ្រី V'), 0.6),
                _perimeterZone(7, product('C.Line 0.23 x 4m'), 0.6),
              ],
            ),
          ],
        );

        expect(_quantity(result, '4ភ្លឺធំ'), 23);
        expect(_quantity(result, '3ភ្លឺធំទាប'), 19);
        expect(_quantity(result, '4ភ្លឺទាប'), 24);
        expect(_quantity(result, 'K 3m'), 9);
        expect(_quantity(result, 'P 4m'), 7);
        expect(_quantity(result, 'ជ្រី V'), 6);
        expect(_quantity(result, 'C.Line 0.23 x 4m'), 40);
        expect(result.zoneResults.first.assignedAreaM2, closeTo(10.8, 0.0001));
        expect(result.zoneResults.first.requiredLinearM, 18);
      },
    );

    test('rounds each identical room before multiplying quantity', () async {
      final result = await service.calculate(
        groups: [
          PvcMeasurementGroup(
            id: 1,
            name: 'Area 1',
            inputMode: PvcGroupInputMode.dimensions,
            lengthM: 4,
            widthM: 5,
            roomCount: 20,
            zones: [
              _perimeterZone(1, product('4ភ្លឺធំ'), 0.6),
              _perimeterZone(2, product('C.Line 0.23 x 4m'), 0.6),
            ],
          ),
        ],
      );

      expect(result.totalAreaM2, 400);
      expect(result.zoneResults.first.assignedAreaM2, closeTo(216, 0.0001));
      expect(result.zoneResults.first.requiredLinearM, 360);
      expect(_quantity(result, '4ភ្លឺធំ'), 460);
      expect(_quantity(result, 'C.Line 0.23 x 4m'), 500);
    });

    test('uses area mode for 100m² of P 4m without fake dimensions', () async {
      final result = await service.calculate(
        groups: [
          _group(100, [_areaZone(1, product('P 4m'), 100)]),
        ],
      );

      expect(_quantity(result, 'P 4m'), 63);
      expect(result.zoneResults.single.methodLabel, contains('raw coverage'));
    });

    test('supports custom coverage values 1.2 and 0.75m²', () async {
      final result = await service.calculate(
        groups: [
          _group(26, [
            _areaZone(
              1,
              product('K 3m'),
              26,
              mode: PvcZoneCalculationMode.coveragePerPiece,
              coverage: 1.2,
            ),
          ]),
          _group(15, [
            _areaZone(
              2,
              product('P 3m'),
              15,
              mode: PvcZoneCalculationMode.coveragePerPiece,
              coverage: 0.75,
            ),
          ], id: 2),
        ],
      );

      expect(_quantity(result, 'K 3m'), 22);
      expect(_quantity(result, 'P 3m'), 20);
    });

    test('calculates linear runs and manual quantities', () async {
      final result = await service.calculate(
        groups: [
          PvcMeasurementGroup(
            id: 1,
            name: 'Area 1',
            inputMode: PvcGroupInputMode.area,
            directAreaM2: 26,
            roomCount: 1,
            zones: [
              PvcQuantityZone(
                id: 1,
                name: 'Zone 1',
                product: product('C.Line 0.23 x 4m'),
                inputMode: PvcZoneInputMode.linear,
                requiredLinearM: 18,
              ),
              PvcQuantityZone(
                id: 2,
                name: 'Zone 2',
                product: product('កាវ'),
                inputMode: PvcZoneInputMode.area,
                calculationMode: PvcZoneCalculationMode.manualQuantity,
                manualQuantity: 3,
              ),
            ],
          ),
        ],
      );

      expect(_quantity(result, 'C.Line 0.23 x 4m'), 40);
      expect(_quantity(result, 'កាវ'), 3);
    });

    test(
      'ignores linear accessories in area allocation and uses perimeter quantity',
      () async {
        final result = await service.calculate(
          groups: [
            PvcMeasurementGroup(
              id: 1,
              name: 'Area 1',
              inputMode: PvcGroupInputMode.dimensions,
              lengthM: 6,
              widthM: 4.2,
              roomCount: 1,
              zones: [
                PvcQuantityZone(
                  id: 1,
                  name: 'Fixed area',
                  product: product('4ភ្លឺធំ'),
                  inputMode: PvcZoneInputMode.dimensions,
                  lengthM: 22,
                  widthM: 0.8,
                ),
                PvcQuantityZone(
                  id: 2,
                  name: 'Linear accessory',
                  product: product('ជ្រី V'),
                  inputMode: PvcZoneInputMode.dimensions,
                  lengthM: 6,
                  widthM: 4.2,
                ),
                PvcQuantityZone(
                  id: 3,
                  name: 'Base fill',
                  product: product('K 4m'),
                  inputMode: PvcZoneInputMode.dimensions,
                  lengthM: 6,
                  widthM: 4.2,
                ),
              ],
            ),
          ],
        );

        final trim = result.products.singleWhere(
          (item) => item.product.nameKhmer == 'ជ្រី V',
        );
        final base = result.products.singleWhere(
          (item) => item.product.nameKhmer == 'K 4m',
        );
        expect(trim.assignedAreaM2, 0);
        expect(trim.requiredLinearM, closeTo(20.4, 0.0001));
        expect(trim.quantity, 7);
        expect(base.assignedAreaM2, closeTo(7.6, 0.0001));
        expect(result.allocatedAreaM2, closeTo(25.2, 0.0001));
      },
    );

    test('reuses exact cutting geometry for dimension zones', () async {
      final optimizer = _ExactOptimizer();
      service = PvcQuantityCalculationService(optimizer: optimizer);
      final result = await service.calculate(
        groups: [
          PvcMeasurementGroup(
            id: 1,
            name: 'Area 1',
            inputMode: PvcGroupInputMode.dimensions,
            lengthM: 6,
            widthM: 4.2,
            roomCount: 20,
            zones: [
              PvcQuantityZone(
                id: 1,
                name: 'Zone 1',
                product: product('K 3m'),
                inputMode: PvcZoneInputMode.dimensions,
                lengthM: 6,
                widthM: 4,
                orientation: MeasurementOrientation.alongLength,
              ),
              _areaZone(2, product('4ភ្លឺធំ'), 1.2),
            ],
          ),
        ],
      );

      expect(optimizer.lastRequest, isNotNull);
      expect(optimizer.lastRequest!.rooms, hasLength(1));
      expect(optimizer.lastRequest!.rooms.first.lengthM, 6);
      expect(optimizer.lastRequest!.rooms.first.widthM, 4);
      expect(optimizer.lastRequest!.variants.single.unitPrice, 0);
      expect(
        optimizer.lastRequest!.options.orientationOverride,
        MeasurementOrientation.alongLength,
      );
      expect(_quantity(result, 'K 3m'), 440);
      expect(_quantity(result, '4ភ្លឺធំ'), 60);
    });

    test(
      'aggregates the same physical product across multiple room groups',
      () async {
        final result = await service.calculate(
          groups: [
            _group(26, [_areaZone(1, product('K 3m'), 20)]),
            _group(15, [
              _areaZone(2, product('K 3m'), 15),
              _areaZone(3, product('P 4m'), 5),
            ], id: 2),
          ],
        );

        expect(result.products, hasLength(2));
        expect(_quantity(result, 'K 3m'), 30);
        expect(_quantity(result, 'P 4m'), 4);
        expect(
          result.products
              .singleWhere((item) => item.product.nameKhmer == 'K 3m')
              .zones,
          hasLength(2),
        );
      },
    );
  });
}

PvcMeasurementGroup _group(
  double area,
  List<PvcQuantityZone> zones, {
  int id = 1,
}) {
  return PvcMeasurementGroup(
    id: id,
    name: 'Area $id',
    inputMode: PvcGroupInputMode.area,
    directAreaM2: area,
    roomCount: 1,
    zones: zones,
  );
}

PvcQuantityZone _areaZone(
  int id,
  PvcPhysicalProduct product,
  double area, {
  PvcZoneCalculationMode mode = PvcZoneCalculationMode.auto,
  double? coverage,
}) {
  return PvcQuantityZone(
    id: id,
    name: 'Zone $id',
    product: product,
    inputMode: PvcZoneInputMode.area,
    areaM2: area,
    calculationMode: mode,
    coveragePerPieceM2: coverage,
  );
}

PvcQuantityZone _perimeterZone(
  int id,
  PvcPhysicalProduct product,
  double stripWidth,
) {
  return PvcQuantityZone(
    id: id,
    name: 'Zone $id',
    product: product,
    inputMode: PvcZoneInputMode.perimeterStrip,
    stripWidthM: stripWidth,
  );
}

int _quantity(PvcQuantityWorkspaceResult result, String name) => result.products
    .singleWhere((item) => item.product.nameKhmer == name)
    .quantity;

class _ExactOptimizer implements MeasurementOptimizer {
  MeasurementOptimizationRequest? lastRequest;

  @override
  Future<MeasurementOptimizationResult> optimize(
    MeasurementOptimizationRequest request,
  ) async {
    lastRequest = request;
    final quantity = 22 * request.rooms.length;
    return MeasurementOptimizationResult(
      status: MeasurementStatus.ok,
      selectedCandidateIndex: 0,
      candidates: [
        MeasurementCandidate(
          candidateId: 1,
          valid: true,
          stockMode: MeasurementStockMode.single,
          singleVariantId: request.variants.single.variantId,
          quantities: [
            MeasurementVariantQuantity(
              variantId: request.variants.single.variantId,
              baseQuantity: quantity,
              reserveQuantity: 0,
              purchaseQuantity: quantity,
            ),
          ],
          cuts: const [],
          roomLayouts: const [],
          basePieceCount: quantity,
          reservePieceCount: 0,
          purchasePieceCount: quantity,
          jointCount: 0,
          requiredAreaM2: request.rooms.fold(
            0,
            (total, room) => total + room.areaM2,
          ),
          purchasedAreaM2: quantity * request.variants.single.areaM2,
          wasteAreaM2: 0,
          wastePercent: 0,
          totalCost: 0,
          score: 0,
        ),
      ],
      diagnostics: const MeasurementDiagnostics(
        candidatesConsidered: 1,
        candidatesPruned: 0,
        executionTimeUs: 1,
        cuts: 0,
        offcutsCreated: 0,
        offcutsReused: 0,
      ),
    );
  }
}
