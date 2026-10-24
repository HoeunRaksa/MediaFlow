import 'package:material_quote_pro/core/ios/iphone_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/app_state.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/models/measurement_models.dart';
import 'package:material_quote_pro/features/measurement_calculator/native/measurement_native_api.dart';
import 'package:material_quote_pro/features/measurement_calculator/presentation/screens/measurement_calculator_screen.dart';
import 'package:provider/provider.dart';

const _k3ProductId = 'pvc_k_3000';
const _k4ProductId = 'pvc_k_4000';
const _cLine023ProductId = 'pvc_c_line_023_4000';

String _productKey(String productId, int variantId) =>
    'workspace-product-$productId-$variantId';

void main() {
  testWidgets('desktop workspace uses three fixed horizontal panels', (
    tester,
  ) async {
    final state = _seededState();
    await _pump(tester, state: state, optimizer: _WorkspaceOptimizer());

    expect(find.byKey(const ValueKey('workspace-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('workspace-room-panel')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('workspace-products-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-result-panel')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-product-list')),
      findsOneWidget,
    );
    final productList = tester.widget<ListView>(
      find.byKey(const ValueKey('workspace-product-list')),
    );
    expect(productList.scrollDirection, Axis.vertical);
    expect(find.text('K 3m'), findsOneWidget);
    expect(find.text('K 4m'), findsOneWidget);
    expect(find.text('P 3m'), findsOneWidget);
    expect(find.text('P 4m'), findsOneWidget);
    expect(find.text('K-01'), findsNothing);
    expect(find.text('K-05'), findsNothing);
    expect(find.byKey(const ValueKey('workspace-room-tabs')), findsNothing);
    expect(
      find.byKey(const ValueKey('workspace-measurement-tabs')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('workspace-room-group-tabs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-group-mode-dimensions-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-group-mode-area-1')),
      findsOneWidget,
    );
    expect(_textValue(tester, 'workspace-group-area-per-room-1'), '25.2 m²');
    expect(_textValue(tester, 'workspace-group-total-area-1'), '25.2 m²');
    final k3Row = find.byKey(ValueKey(_productKey(_k3ProductId, 3000)));
    expect(k3Row, findsOneWidget);
    final productsPanel = find.byKey(
      const ValueKey('workspace-products-panel'),
    );
    final productTable = find.byKey(const ValueKey('workspace-product-table'));
    final panelSize = tester.getSize(productsPanel);
    final tableSize = tester.getSize(productTable);
    final rowSize = tester.getSize(k3Row);
    expect(tableSize.width, greaterThan(panelSize.width - 30));
    expect(rowSize.width, closeTo(tableSize.width, 0.1));
    expect(rowSize.height, 42);
    expect(
      tester.getTopLeft(k3Row).dy,
      closeTo(tester.getTopLeft(productTable).dy + 32, 0.1),
    );
    for (final scrollView in tester.widgetList<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    )) {
      expect(scrollView.scrollDirection, Axis.horizontal);
    }
    expect(find.text('គណនា'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selecting products updates the pinned result automatically', (
    tester,
  ) async {
    final optimizer = _WorkspaceOptimizer();
    final state = _seededState();
    await _pump(tester, state: state, optimizer: optimizer);

    await tester.tap(find.byKey(ValueKey(_productKey(_k3ProductId, 3000))));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(optimizer.lastRequest, isNotNull);
    expect(optimizer.lastRequest!.variants, hasLength(1));
    expect(
      optimizer.lastRequest!.variants.map((variant) => variant.unitPrice),
      [6.70],
    );
    expect(find.text(r'$107.20'), findsWidgets);
    expect(
      find.byKey(const ValueKey('workspace-selected-$_k3ProductId')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(ValueKey(_productKey(_k4ProductId, 4000))));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(optimizer.lastRequest!.variants, hasLength(1));
    expect(optimizer.lastRequest!.variants.single.unitPrice, 8.60);
    expect(find.text(r'$244.80'), findsWidgets);
    expect(
      find.byKey(const ValueKey('workspace-selected-$_k4ProductId')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('workspace-category-cLine')));
    await tester.pump();
    await tester.tap(
      find.byKey(ValueKey(_productKey(_cLine023ProductId, 4000))),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('workspace-selected-$_cLine023ProductId')),
      findsOneWidget,
    );
    expect(find.text(r'$261.04'), findsWidgets);
    expect(find.textContaining('C.Line 0.23 x 4m'), findsWidgets);

    expect(find.byKey(const ValueKey('workspace-add-quotation')), findsNothing);
    expect(find.byKey(const ValueKey('workspace-get-invoice')), findsOneWidget);
    expect(find.text('Optional color/design'), findsNothing);
    expect(state.currentSaleItems, isEmpty);

    await tester.tap(find.byKey(const ValueKey('workspace-get-invoice')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('customer-document-preview')),
      findsOneWidget,
    );
    expect(find.textContaining(r'$261.04'), findsWidgets);
    expect(find.textContaining('Owner cost'), findsNothing);
    expect(find.textContaining('Profit'), findsNothing);
    expect(state.currentSaleItems, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('categories render unique compact rows in a full-width table', (
    tester,
  ) async {
    final state = _seededState();
    await _pump(
      tester,
      state: state,
      optimizer: _WorkspaceOptimizer(),
      size: const Size(1100, 720),
    );

    for (final category in const ['pvc', 'accessories', 'cLine', 'db', 'gd']) {
      await tester.tap(find.byKey(ValueKey('workspace-category-$category')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('workspace-product-table')),
        findsOneWidget,
      );
      final productRowKeys = tester
          .widgetList(
            find.descendant(
              of: find.byKey(const ValueKey('workspace-product-list')),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget.key is ValueKey<String> &&
                    (widget.key! as ValueKey<String>).value.startsWith(
                      'workspace-product-',
                    ),
              ),
            ),
          )
          .map((widget) => widget.key)
          .toList();
      expect(productRowKeys, isNotEmpty);
      expect(productRowKeys.toSet(), hasLength(productRowKeys.length));
      expect(tester.takeException(), isNull);
    }

    await tester.tap(
      find.byKey(const ValueKey('workspace-category-accessories')),
    );
    await tester.pump();
    for (final id in const [
      'pvc_image1_row07',
      'pvc_image1_row08',
      'pvc_image1_row09',
    ]) {
      expect(find.byKey(ValueKey(_productKey(id, 3000))), findsOneWidget);
    }
    final productListFinder = find.byKey(
      const ValueKey('workspace-product-list'),
    );
    final productList = tester.widget<ListView>(productListFinder);
    expect(productList.scrollDirection, Axis.vertical);
    expect(
      find.descendant(
        of: productListFinder,
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    await tester.drag(productListFinder, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(productList.controller!.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('room-size groups keep counts and dimensions independent', (
    tester,
  ) async {
    final state = _seededState();
    await _pump(tester, state: state, optimizer: _WorkspaceOptimizer());

    final firstCount = find.byKey(const ValueKey('workspace-group-count-1'));
    await tester.enterText(firstCount, '20');
    await tester.pump();
    expect(_textValue(tester, 'workspace-group-total-area-1'), '504 m²');
    expect(_textValue(tester, 'workspace-grand-room-area'), '504 m²');
    expect(find.text('6×4.2 · ×20'), findsOneWidget);

    await tester.enterText(firstCount, '0');
    await tester.pump();
    expect(tester.widget<AdaptiveTextField>(firstCount).controller!.text, '20');

    await tester.tap(find.byKey(const ValueKey('workspace-add-room-group')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('workspace-room-group-2')),
      findsOneWidget,
    );
    await tester.enterText(_groupField('workspace-group-length-2'), '5');
    await tester.enterText(_groupField('workspace-group-width-2'), '3');
    await tester.enterText(
      find.byKey(const ValueKey('workspace-group-count-2')),
      '4',
    );
    await tester.pump();
    expect(_textValue(tester, 'workspace-group-total-area-2'), '60 m²');
    expect(_textValue(tester, 'workspace-grand-room-area'), '564 m²');

    await tester.tap(find.byKey(const ValueKey('workspace-add-room-group')));
    await tester.pump();
    await tester.enterText(_groupField('workspace-group-length-3'), '8');
    await tester.enterText(_groupField('workspace-group-width-3'), '5');
    await tester.pump();
    expect(_textValue(tester, 'workspace-group-total-area-3'), '40 m²');
    expect(_textValue(tester, 'workspace-grand-room-area'), '604 m²');

    await tester.tap(find.byKey(const ValueKey('workspace-room-group-1')));
    await tester.pump();
    expect(_fieldText(tester, 'workspace-group-length-1'), '6');
    expect(_fieldText(tester, 'workspace-group-width-1'), '4.2');
    expect(
      tester
          .widget<AdaptiveTextField>(
            find.byKey(const ValueKey('workspace-group-count-1')),
          )
          .controller!
          .text,
      '20',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing room count recalculates selected materials', (
    tester,
  ) async {
    final optimizer = _WorkspaceOptimizer();
    final state = _seededState();
    await _pump(tester, state: state, optimizer: optimizer);

    await tester.tap(find.byKey(ValueKey(_productKey(_k3ProductId, 3000))));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(optimizer.lastRequest!.rooms, hasLength(1));

    await tester.enterText(
      find.byKey(const ValueKey('workspace-group-count-1')),
      '20',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(optimizer.lastRequest!.rooms, hasLength(20));
    expect(
      optimizer.lastRequest!.rooms.every(
        (room) => room.lengthM == 6 && room.widthM == 4.2,
      ),
      isTrue,
    );
    expect(_textValue(tester, 'workspace-grand-room-area'), '504 m²');
    expect(find.text(r'$2,144.00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'direct area mode updates totals and skips geometry optimization',
    (tester) async {
      final optimizer = _WorkspaceOptimizer();
      final state = _seededState();
      await _pump(tester, state: state, optimizer: optimizer);

      await tester.tap(
        find.byKey(const ValueKey('workspace-group-mode-area-1')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('workspace-group-length-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('workspace-group-width-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('workspace-group-area-1')),
        findsOneWidget,
      );

      await tester.enterText(_groupField('workspace-group-area-1'), '25.2');
      await tester.enterText(
        find.byKey(const ValueKey('workspace-group-count-1')),
        '20',
      );
      await tester.pump();

      expect(_textValue(tester, 'workspace-group-area-per-room-1'), '25.2 m²');
      expect(_textValue(tester, 'workspace-group-total-area-1'), '504 m²');
      expect(_textValue(tester, 'workspace-grand-room-area'), '504 m²');
      expect(find.text('25.2m² · ×20'), findsOneWidget);

      await tester.tap(find.byKey(ValueKey(_productKey(_k3ProductId, 3000))));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(optimizer.callCount, 0);
      expect(optimizer.lastRequest, isNull);
      expect(_textValue(tester, 'workspace-grand-total'), r'$2,814.00');
      expect(
        find.byKey(const ValueKey('workspace-material-notice-$_k3ProductId')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dimension and direct area groups produce a mixed grand total', (
    tester,
  ) async {
    final state = _seededState();
    await _pump(tester, state: state, optimizer: _WorkspaceOptimizer());

    await tester.enterText(
      find.byKey(const ValueKey('workspace-group-count-1')),
      '20',
    );
    await tester.tap(find.byKey(const ValueKey('workspace-add-room-group')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('workspace-group-mode-area-2')));
    await tester.pump();
    await tester.enterText(_groupField('workspace-group-area-2'), '100');
    await tester.pump();

    expect(_textValue(tester, 'workspace-group-total-area-2'), '100 m²');
    expect(_textValue(tester, 'workspace-grand-room-area'), '604 m²');
    expect(find.text('6×4.2 · ×20'), findsOneWidget);
    expect(find.text('100m² · ×1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected material opens compact contextual overrides', (
    tester,
  ) async {
    final state = _seededState();
    await _pump(tester, state: state, optimizer: _WorkspaceOptimizer());
    await tester.tap(find.byKey(ValueKey(_productKey(_k3ProductId, 3000))));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('workspace-selected-$_k3ProductId')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('workspace-override-length')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-override-quantity')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-override-price')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-override-waste')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('workspace-override-orientation')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('smaller desktop window keeps horizontal workspace navigation', (
    tester,
  ) async {
    final state = _seededState();
    final previousOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previousOnError);
    await _pump(
      tester,
      state: state,
      optimizer: _WorkspaceOptimizer(),
      size: const Size(1100, 720),
    );

    final workspaceScroll = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('workspace-horizontal-scroll')),
    );
    expect(workspaceScroll.scrollDirection, Axis.horizontal);
    FlutterError.onError = previousOnError;
    expect(
      errors,
      isEmpty,
      reason: errors.map((error) => error.toString()).join('\n\n'),
    );
  });
}

Finder _groupField(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

String _fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(_groupField(key)).controller!.text;

String _textValue(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

AppState _seededState() {
  final now = DateTime.utc(2026, 8, 8);
  return AppState()
    ..isLoading = false
    ..materials = DefaultMaterialSeed.materials(now)
    ..prices = DefaultMaterialSeed.prices(now)
    ..packagingRules = DefaultMaterialSeed.packagingRules(now)
    ..productTemplates = DefaultMaterialSeed.productTypeTemplates();
}

Future<void> _pump(
  WidgetTester tester, {
  required AppState state,
  required MeasurementOptimizer optimizer,
  Size size = const Size(1920, 1080),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(state.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: MeasurementCalculatorScreen(optimizer: optimizer)),
      ),
    ),
  );
  await tester.pump();
}

class _WorkspaceOptimizer implements MeasurementOptimizer {
  MeasurementOptimizationRequest? lastRequest;
  int callCount = 0;

  @override
  Future<MeasurementOptimizationResult> optimize(
    MeasurementOptimizationRequest request,
  ) async {
    callCount++;
    lastRequest = request;
    final roomMultiplier = request.rooms.length;
    final quantities = request.variants.length == 2
        ? [
            MeasurementVariantQuantity(
              variantId: 3000,
              baseQuantity: 11 * roomMultiplier,
              reserveQuantity: 0,
              purchaseQuantity: 11 * roomMultiplier,
            ),
            MeasurementVariantQuantity(
              variantId: 4000,
              baseQuantity: 11 * roomMultiplier,
              reserveQuantity: 0,
              purchaseQuantity: 11 * roomMultiplier,
            ),
          ]
        : [
            MeasurementVariantQuantity(
              variantId: request.variants.first.variantId,
              baseQuantity: 16 * roomMultiplier,
              reserveQuantity: 0,
              purchaseQuantity: 16 * roomMultiplier,
            ),
          ];
    final totalCost = quantities.fold<double>(0, (total, quantity) {
      final variant = request.variants.singleWhere(
        (item) => item.variantId == quantity.variantId,
      );
      return total + variant.unitPrice * quantity.purchaseQuantity;
    });
    final area = request.rooms.fold<double>(
      0,
      (total, room) => total + room.areaM2,
    );
    return MeasurementOptimizationResult(
      status: MeasurementStatus.ok,
      selectedCandidateIndex: 0,
      candidates: [
        MeasurementCandidate(
          candidateId: 3,
          valid: true,
          stockMode: request.variants.length == 2
              ? MeasurementStockMode.mixed
              : MeasurementStockMode.single,
          singleVariantId: request.variants.length == 1
              ? request.variants.first.variantId
              : null,
          quantities: quantities,
          cuts: const [],
          roomLayouts: const [],
          basePieceCount: quantities.fold(
            0,
            (total, quantity) => total + quantity.baseQuantity,
          ),
          reservePieceCount: 0,
          purchasePieceCount: quantities.fold(
            0,
            (total, quantity) => total + quantity.purchaseQuantity,
          ),
          jointCount: 0,
          requiredAreaM2: area,
          purchasedAreaM2: area + 5.6,
          wasteAreaM2: 5.6,
          wastePercent: 18.182,
          totalCost: totalCost,
          score: 5.6,
        ),
      ],
      diagnostics: const MeasurementDiagnostics(
        candidatesConsidered: 3,
        candidatesPruned: 0,
        executionTimeUs: 10,
        cuts: 22,
        offcutsCreated: 0,
        offcutsReused: 0,
      ),
    );
  }
}
