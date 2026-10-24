import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/core/utils/money_formatter.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/models/measurement_models.dart';
import 'package:material_quote_pro/features/measurement_calculator/native/measurement_native_api.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/data/pvc_physical_catalog.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/presentation/screens/pvc_quantity_calculator_screen.dart';

void main() {
  final products = const PvcPhysicalCatalog().build(
    DefaultMaterialSeed.materials(DateTime.utc(2026, 8, 8)),
  );

  testWidgets('PVC screen is a simple three-panel quantity workspace', (
    tester,
  ) async {
    await _pump(tester, products: products);

    expect(
      find.byKey(const ValueKey('pvc-quantity-workspace')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pvc-measurement-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('pvc-products-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('pvc-results-panel')), findsOneWidget);
    expect(find.text('K 3m'), findsOneWidget);
    expect(find.text('K 4m'), findsOneWidget);
    expect(find.text('P 3m'), findsOneWidget);
    expect(find.text('P 4m'), findsOneWidget);
    expect(find.text('K-01'), findsNothing);
    expect(find.textContaining(r'$'), findsNothing);
    expect(find.textContaining('PRICE'), findsNothing);
    expect(find.textContaining('Profit'), findsNothing);
    expect(find.textContaining('Quotation'), findsNothing);
    expect(find.text('25.2 m²'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'PVC temporary selling price calculates line total and grand total in real-time',
    (tester) async {
      await _pump(tester, products: products);

      // Add K 3m (pvc_k_3000) -> 22 sheets
      await tester.tap(
        find.byKey(const ValueKey('pvc-add-product-pvc_k_3000')),
      );
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pumpAndSettle();

      expect(find.text('តម្លៃលក់ / សន្លឹក'), findsOneWidget);

      // Enter temporary sell price $6.70 / សន្លឹក for K 3m
      final priceInputK3m = find.byKey(
        const ValueKey('pvc-price-input-pvc_k_3000'),
      );
      await tester.enterText(priceInputK3m, '6.70');
      await tester.pump();

      final qtyK3mSingle = int.parse(_resultQuantity(tester, 'pvc_k_3000'));
      final expectedK3mSingle = MoneyFormatter.money(qtyK3mSingle * 6.70);

      expect(
        find.byKey(const ValueKey('pvc-line-total-pvc_k_3000')),
        findsOneWidget,
      );
      expect(find.text(expectedK3mSingle), findsWidgets);
      expect(
        find.byKey(const ValueKey('pvc-selling-grand-total')),
        findsOneWidget,
      );
      expect(find.text(expectedK3mSingle), findsWidgets);

      // Add 4ភ្លីធំ 3m (pvc_4flu_tbom_3000)
      await tester.enterText(
        find.byKey(const ValueKey('pvc-product-search')),
        '160',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('pvc-add-product-pvc_4flu_tbom_3000')),
      );
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pumpAndSettle();

      // Enter temporary sell price $5.80 / សន្លឹក for 4ភ្លីធំ 3m
      final priceInput4flu = find.byKey(
        const ValueKey('pvc-price-input-pvc_4flu_tbom_3000'),
      );
      await tester.enterText(priceInput4flu, '5.80');
      await tester.pump();

      final qtyK3mDouble = int.parse(_resultQuantity(tester, 'pvc_k_3000'));
      final qty4fluDouble = int.parse(
        _resultQuantity(tester, 'pvc_4flu_tbom_3000'),
      );
      final expectedK3mDouble = MoneyFormatter.money(qtyK3mDouble * 6.70);
      final expected4fluDouble = MoneyFormatter.money(qty4fluDouble * 5.80);
      final expectedGrandTotal = MoneyFormatter.money(
        (qtyK3mDouble * 6.70) + (qty4fluDouble * 5.80),
      );

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pvc-result-pvc_k_3000')),
          matching: find.text(expectedK3mDouble),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pvc-result-pvc_4flu_tbom_3000')),
          matching: find.text(expected4fluDouble),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('pvc-selling-summary')),
          matching: find.text(expectedGrandTotal),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('normal PVC zone card shows only dimensions and m² modes', (
    tester,
  ) async {
    await _pump(tester, products: products);
    await tester.tap(find.byKey(const ValueKey('pvc-add-product-pvc_k_3000')));
    await tester.pumpAndSettle();

    expect(find.text('បណ្ដោយ × ទទឹង'), findsOneWidget);
    expect(find.text('m²'), findsWidgets);
    expect(
      find.byKey(const ValueKey('pvc-zone-mode-dimensions-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pvc-zone-mode-area-1')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('pvc-zone-mode-perimeterStrip-1')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('pvc-zone-mode-linear-1')), findsNothing);
    expect(find.byKey(const ValueKey('pvc-advanced-mode')), findsNothing);

    final visibleText = _visibleText(tester);
    expect(visibleText, isNot(contains('Perimeter')));
    expect(visibleText, isNot(contains('Linear')));
    expect(visibleText, isNot(contains('Coverage per piece')));
    expect(visibleText, isNot(contains('Manual quantity')));
    expect(visibleText, isNot(contains('Exact geometry')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('linear products also start with the simple zone inputs', (
    tester,
  ) async {
    await _pump(tester, products: products);
    await tester.enterText(
      find.byKey(const ValueKey('pvc-product-search')),
      'V',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('pvc-add-product-pvc_v_25x25x3000')),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('pvc-zone-mode-dimensions-1')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('pvc-zone-length-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pvc-zone-mode-linear-1')), findsNothing);
    expect(
      find.byKey(const ValueKey('pvc-zone-mode-sheetQuantity-1')),
      findsNothing,
    );
    expect(find.text('Linear meters'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('panel manual sheets override auto and can switch back', (
    tester,
  ) async {
    await _pump(tester, products: products);
    await tester.enterText(
      find.byKey(const ValueKey('pvc-product-search')),
      'K 4m',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('pvc-add-product-pvc_k_4000')));
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('pvc-zone-mode-sheetQuantity-1')),
      findsOneWidget,
    );
    expect(find.text('ចំនួនសន្លឹក'), findsOneWidget);
    expect(_field('pvc-zone-length-1'), findsOneWidget);
    expect(_field('pvc-zone-manual-sheets-1'), findsNothing);
    expect(_resultQuantity(tester, 'pvc_k_4000'), '22');

    await tester.tap(
      find.byKey(const ValueKey('pvc-zone-mode-sheetQuantity-1')),
    );
    await tester.pump();
    expect(_field('pvc-zone-length-1'), findsNothing);
    expect(_field('pvc-zone-area-1'), findsNothing);
    expect(_field('pvc-zone-manual-sheets-1'), findsOneWidget);

    await tester.enterText(_field('pvc-zone-manual-sheets-1'), '30');
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pumpAndSettle();
    expect(_resultQuantity(tester, 'pvc_k_4000'), '30');
    expect(find.text('= 30 សន្លឹក'), findsOneWidget);
    expect(find.text('Assigned: 25.2 m²'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('pvc-zone-mode-dimensions-1')));
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pumpAndSettle();
    expect(_field('pvc-zone-length-1'), findsOneWidget);
    expect(_field('pvc-zone-width-1'), findsOneWidget);
    expect(_field('pvc-zone-manual-sheets-1'), findsNothing);
    expect(_resultQuantity(tester, 'pvc_k_4000'), '22');
    expect(find.text('Assigned: 25.2 m²'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'clip accessory auto-calculates, preserves manual override, and resets',
    (tester) async {
      await _pump(tester, products: products);
      await tester.enterText(
        find.byKey(const ValueKey('pvc-product-search')),
        '100គ្រាប់',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('pvc-add-product-pvc_image1_row16')),
      );
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pumpAndSettle();

      expect(_field('pvc-zone-required-length-1'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(_field('pvc-zone-required-length-1'))
            .controller
            ?.text,
        '20.4',
      );
      expect(find.text('2 គ្រាប់ / 1m'), findsOneWidget);
      expect(find.text('= 41 គ្រាប់'), findsOneWidget);
      expect(find.text('= 1 កញ្ចប់'), findsOneWidget);
      expect(_resultQuantity(tester, 'pvc_image1_row16'), '41');
      expect(find.text('Required: 20.4 m'), findsOneWidget);
      expect(find.text('1 កញ្ចប់'), findsWidgets);
      expect(find.byKey(const ValueKey('pvc-zone-mode-area-1')), findsNothing);
      expect(find.byKey(const ValueKey('pvc-zone-settings-1')), findsNothing);
      expect(
        find.byKey(const ValueKey('pvc-zone-auto-length-1')),
        findsNothing,
      );

      await tester.enterText(_field('pvc-zone-required-length-1'), '60');
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pumpAndSettle();
      expect(_resultQuantity(tester, 'pvc_image1_row16'), '120');
      expect(find.text('= 2 កញ្ចប់'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pvc-zone-auto-length-1')),
        findsOneWidget,
      );

      await tester.enterText(_field('pvc-group-length-1'), '4');
      await tester.enterText(_field('pvc-group-width-1'), '5');
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(_field('pvc-zone-required-length-1'))
            .controller
            ?.text,
        '60',
      );
      expect(_resultQuantity(tester, 'pvc_image1_row16'), '120');

      await tester.tap(find.byKey(const ValueKey('pvc-zone-auto-length-1')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(_field('pvc-zone-required-length-1'))
            .controller
            ?.text,
        '18',
      );
      expect(_resultQuantity(tester, 'pvc_image1_row16'), '36');
      expect(find.text('= 1 កញ្ចប់'), findsOneWidget);

      await tester.enterText(_field('pvc-group-length-1'), '6');
      await tester.enterText(_field('pvc-group-width-1'), '4.2');
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(_field('pvc-zone-required-length-1'))
            .controller
            ?.text,
        '20.4',
      );
      expect(_resultQuantity(tester, 'pvc_image1_row16'), '41');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'area panel, linear accessory, and K fill allocate the room correctly',
    (tester) async {
      await _pump(tester, products: products);
      await tester.enterText(
        find.byKey(const ValueKey('pvc-product-search')),
        '160',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('pvc-add-product-pvc_4flu_tbom_3000')),
      );
      await tester.pump();
      await tester.enterText(_field('pvc-zone-length-1'), '22');
      await tester.enterText(_field('pvc-zone-width-1'), '0.8');

      await tester.enterText(
        find.byKey(const ValueKey('pvc-product-search')),
        'V',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('pvc-add-product-pvc_v_25x25x3000')),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('pvc-product-search')),
        'K 4m',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('pvc-add-product-pvc_k_4000')),
      );
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pumpAndSettle();

      expect(find.textContaining('Allocated 25.2 / 25.2 m²'), findsOneWidget);
      expect(find.textContaining('Remaining: 0 m²'), findsOneWidget);
      expect(find.textContaining('Over allocated'), findsNothing);
      expect(find.text('Assigned: 17.6 m²'), findsOneWidget);
      expect(find.text('Assigned: 7.6 m²'), findsOneWidget);
      expect(find.text('Required: 20.4 m'), findsOneWidget);
      expect(find.text('Assigned: 25.2 m²'), findsNothing);
      expect(_resultQuantity(tester, 'pvc_v_25x25x3000'), '7');
      expect(find.text('= 20.4 m'), findsOneWidget);

      await tester.enterText(_field('pvc-zone-width-1'), '0.5');
      await tester.pump(const Duration(milliseconds: 140));
      await tester.pumpAndSettle();
      expect(find.text('Assigned: 11 m²'), findsOneWidget);
      expect(find.text('Assigned: 14.2 m²'), findsOneWidget);
      expect(find.text('Required: 20.4 m'), findsOneWidget);
      expect(_resultQuantity(tester, 'pvc_v_25x25x3000'), '7');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('one selected product stays independent and recalculates live', (
    tester,
  ) async {
    await _pump(tester, products: products);
    await tester.enterText(
      find.byKey(const ValueKey('pvc-product-search')),
      '4',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('pvc-add-product-pvc_4flu_tbom_3000')),
    );
    await tester.pump();

    await tester.enterText(_field('pvc-zone-length-1'), '18');
    await tester.enterText(_field('pvc-zone-width-1'), '0.6');
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pumpAndSettle();

    expect(find.text('= 10.8 m²'), findsOneWidget);
    expect(find.text('Assigned: 10.8 m²'), findsOneWidget);
    expect(find.byKey(const ValueKey('pvc-result-pvc_k_3000')), findsNothing);

    await tester.enterText(_field('pvc-zone-length-1'), '20');
    await tester.enterText(_field('pvc-zone-width-1'), '0.8');
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pumpAndSettle();
    expect(find.text('= 16 m²'), findsOneWidget);
    expect(find.text('Assigned: 16 m²'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fixed zone automatically updates the first base PVC product', (
    tester,
  ) async {
    await _pump(tester, products: products);
    await tester.tap(find.byKey(const ValueKey('pvc-add-product-pvc_k_3000')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('pvc-product-search')),
      '4',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('pvc-add-product-pvc_4flu_tbom_3000')),
    );
    await tester.pump();

    await tester.enterText(_field('pvc-zone-length-2'), '18');
    await tester.enterText(_field('pvc-zone-width-2'), '0.6');
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pumpAndSettle();

    expect(find.text('Assigned: 10.8 m²'), findsOneWidget);
    expect(find.text('Assigned: 14.4 m²'), findsOneWidget);
    expect(find.byKey(const ValueKey('pvc-zone-remaining-1')), findsNothing);
    expect(
      find.byKey(const ValueKey('pvc-zone-use-remaining-2')),
      findsNothing,
    );

    await tester.enterText(_field('pvc-zone-length-2'), '20');
    await tester.pump(const Duration(milliseconds: 140));
    await tester.pumpAndSettle();
    expect(find.text('Assigned: 12 m²'), findsOneWidget);
    expect(find.text('Assigned: 13.2 m²'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direct 26m² splits fixed and automatic base zones', (
    tester,
  ) async {
    await _pump(tester, products: products);

    await tester.tap(find.byKey(const ValueKey('pvc-group-mode-area-1')));
    await tester.pump();
    await tester.enterText(_field('pvc-group-area-1'), '26');
    await tester.tap(find.byKey(const ValueKey('pvc-add-product-pvc_k_3000')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('pvc-product-search')),
      '4',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('pvc-add-product-pvc_4flu_tbom_3000')),
    );
    await tester.pump();
    await tester.enterText(_field('pvc-zone-area-2'), '6');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.textContaining('Allocated 26 / 26 m²'), findsOneWidget);
    expect(_resultQuantity(tester, 'pvc_k_3000'), '17');
    expect(_resultQuantity(tester, 'pvc_4flu_tbom_3000'), '13');
    expect(find.text('Assigned: 20 m²'), findsOneWidget);
    expect(find.text('Assigned: 6 m²'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('advanced options retain perimeter and custom run inputs', (
    tester,
  ) async {
    await _pump(tester, products: products);
    await tester.enterText(_field('pvc-group-length-1'), '4');
    await tester.enterText(_field('pvc-group-width-1'), '5');
    await tester.tap(find.byKey(const ValueKey('pvc-add-product-pvc_k_3000')));
    await tester.pump();

    await _openAdvancedInput(tester, zoneId: 1, label: 'Perimeter / run');
    await tester.enterText(_field('pvc-advanced-strip-width'), '0.6');
    await tester.tap(find.byKey(const ValueKey('pvc-advanced-run-custom')));
    await tester.pump();
    await tester.enterText(_field('pvc-advanced-custom-run'), '12');
    await tester.tap(find.byKey(const ValueKey('pvc-advanced-apply')));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(find.text('= 7.2 m²'), findsOneWidget);
    expect(find.textContaining('Remaining: 12.8 m²'), findsOneWidget);
    expect(_resultQuantity(tester, 'pvc_k_3000'), '6');
    expect(find.textContaining('Perimeter / run'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('advanced coverage override calculates 0.75m² per piece', (
    tester,
  ) async {
    await _pump(tester, products: products);

    await tester.tap(find.byKey(const ValueKey('pvc-group-mode-area-1')));
    await tester.pump();
    await tester.enterText(_field('pvc-group-area-1'), '15');
    await tester.tap(find.byKey(const ValueKey('pvc-add-product-pvc_k_3000')));
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(find.byKey(const ValueKey('pvc-zone-settings-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pvc-advanced-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coverage per piece').last);
    await tester.pump();
    await tester.enterText(_field('pvc-advanced-coverage'), '0.75');
    await tester.tap(find.byKey(const ValueKey('pvc-advanced-apply')));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    expect(_resultQuantity(tester, 'pvc_k_3000'), '20');
    expect(find.textContaining('Coverage per piece'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom under and over allocations remain calculable', (
    tester,
  ) async {
    await _pump(tester, products: products);

    await tester.tap(find.byKey(const ValueKey('pvc-group-mode-area-1')));
    await tester.pump();
    await tester.enterText(_field('pvc-group-area-1'), '26');
    await tester.tap(find.byKey(const ValueKey('pvc-add-product-pvc_k_3000')));
    await tester.pump();
    await tester.enterText(_field('pvc-zone-area-1'), '20');
    await tester.pump();
    expect(find.textContaining('Remaining: 6 m²'), findsOneWidget);

    await tester.enterText(_field('pvc-zone-area-1'), '28');
    await tester.pump(const Duration(milliseconds: 220));
    await tester.pumpAndSettle();
    expect(find.textContaining('Over allocated: 2 m²'), findsOneWidget);
    expect(_resultQuantity(tester, 'pvc_k_3000'), '24');
    expect(tester.takeException(), isNull);
  });

  testWidgets('smaller Windows size keeps horizontal workspace navigation', (
    tester,
  ) async {
    await _pump(tester, products: products, size: const Size(1100, 720));

    final scroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('pvc-workspace-horizontal-scroll')),
    );
    expect(scroll.scrollDirection, Axis.horizontal);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openAdvancedInput(
  WidgetTester tester, {
  required int zoneId,
  required String label,
}) async {
  await tester.tap(find.byKey(ValueKey('pvc-zone-settings-$zoneId')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('pvc-advanced-input-mode')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pump();
}

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

String _resultQuantity(WidgetTester tester, String productId) => tester
    .widget<Text>(find.byKey(ValueKey('pvc-result-quantity-$productId')))
    .data!;

String _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
    .join('\n');

Future<void> _pump(
  WidgetTester tester, {
  required List products,
  Size size = const Size(1600, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true, fontFamily: 'NotoSansKhmer'),
      home: Scaffold(
        body: PvcQuantityCalculatorScreen(
          products: products.cast(),
          optimizer: _WidgetOptimizer(),
        ),
      ),
    ),
  );
  await tester.pump();
}

class _WidgetOptimizer implements MeasurementOptimizer {
  @override
  Future<MeasurementOptimizationResult> optimize(
    MeasurementOptimizationRequest request,
  ) async {
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
          requiredAreaM2: 0,
          purchasedAreaM2: 0,
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
