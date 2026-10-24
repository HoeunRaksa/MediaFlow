import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/app_state.dart';
import 'package:material_quote_pro/features/ceiling_calculator/presentation/screens/ceiling_calculator_screen.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'copies customer quantities and total estimate without unit prices',
    (tester) async {
      await _pump(tester, state: _seededState());
      final copyButton = find.byKey(
        const ValueKey('ceiling-copy-customer-text'),
      );
      await tester.scrollUntilVisible(
        copyButton,
        250,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('ceiling-result-list')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('ceiling-edit-contacts')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('ceiling-dialog-phones')),
        '012 345 678\n098 765 432',
      );
      await tester.enterText(
        find.byKey(const ValueKey('ceiling-dialog-telegram')),
        '@ceiling_shop',
      );
      await tester.tap(find.text('រួចរាល់'));
      await tester.pumpAndSettle();
      final text = tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('ceiling-customer-text')),
          )
          .data!;
      expect(text, contains('• លួស៖ 500m'));
      expect(text, contains('ទំហំ៖ 6m × 4.2m'));
      expect(text, contains('• ពិដាន៖ 70 សន្លឹក\n• T វែង 3m៖'));
      expect(text, startsWith('បាទបង 🙏\nតម្លៃសរុបប្រហែល\n'));
      expect(text, contains('📐 ផ្ទៃពិដាន៖ 25.2m²\n'));
      expect(text, contains('📞 012 345 678\n📞 098 765 432'));
      expect(text, contains('Telegram៖ @ceiling_shop'));
      expect(text, contains(r'$224.20 – $236.00'));
      expect(text, isNot(contains(r'$8.50')));
      expect(text, isNot(contains(r'$10.00')));
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.ensureVisible(copyButton);
      await tester.pumpAndSettle();
      await tester.tap(copyButton);
      await tester.pump();
      expect(copied, text);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'ceiling calculator shows material quantities and temporary per-m² selling section',
    (tester) async {
      final state = _seededState();
      await _pump(tester, state: state);

      expect(find.byKey(const ValueKey('ceiling-root')), findsOneWidget);
      expect(find.byKey(const ValueKey('ceiling-room-panel')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ceiling-products-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ceiling-result-panel')),
        findsOneWidget,
      );

      _expectResultQuantity(tester, 'ceiling_6mm', '70 សន្លឹក');
      _expectResultQuantity(tester, 'long_t_3m', '14 ដើម');
      _expectResultQuantity(tester, 'short_t_06m', '68 ដើម');
      _expectResultQuantity(tester, 'v_iron_295m', '5 ដើម');
      expect(find.text('5 ប្រអប់ + 10 សន្លឹក'), findsOneWidget);
      expect(find.text('សម្ភារៈសរុប: 5 មុខ'), findsOneWidget);

      // Verify compact selling section exists directly in the result panel
      expect(
        find.byKey(const ValueKey('ceiling-selling-section')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ceiling-temporary-price-per-m2')),
        findsOneWidget,
      );
      expect(find.text('តម្លៃលក់ / m²'), findsOneWidget);
      expect(find.text('ផ្ទៃសរុប'), findsOneWidget);
      expect(find.text('សរុបតម្លៃលក់'), findsOneWidget);

      // Default room is 6 x 4.2 x 1 = 25.2 m² @ $8.50 / m² = $214.20
      expect(
        find.byKey(const ValueKey('ceiling-selling-total-area')),
        findsOneWidget,
      );
      expect(find.text('25.2 m²'), findsWidgets);
      expect(
        find.byKey(const ValueKey('ceiling-selling-total-amount')),
        findsOneWidget,
      );
      expect(find.text(r'$214.20'), findsOneWidget);

      // Verify no individual item unit price fields exist for ceiling materials
      expect(find.text('តម្លៃ / ឯកតា'), findsNothing);
      expect(find.byKey(const ValueKey('ceiling-grand-total')), findsNothing);
      expect(find.byKey(const ValueKey('ceiling-add-to-cart')), findsNothing);

      // PVC products remain outside the Ceiling calculator.
      expect(find.text('K 3m'), findsNothing);
      expect(find.text('K 4m'), findsNothing);
    },
  );

  testWidgets(
    r'calculates ceiling selling amount for 5x4x5 rooms ($8.50/m² => $850.00, $9.00/m² => $900.00)',
    (tester) async {
      final state = _seededState();
      await _pump(tester, state: state);

      // 5m x 4m x 5 rooms = 100m²
      await tester.enterText(_field('ceiling-group-length-1'), '5');
      await tester.enterText(_field('ceiling-group-width-1'), '4');
      await tester.enterText(
        find.byKey(const ValueKey('ceiling-group-count-1')),
        '5',
      );
      await tester.pump();

      // Material quantities check remain unchanged
      _expectResultQuantity(tester, 'ceiling_6mm', '278 សន្លឹក');
      _expectResultQuantity(tester, 'long_t_3m', '54 ដើម');
      _expectResultQuantity(tester, 'short_t_06m', '270 ដើម');
      _expectResultQuantity(tester, 'v_iron_295m', '20 ដើម');
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ceiling-extra-v-result')),
          matching: find.text('11 ដើម'),
        ),
        findsOneWidget,
      );

      // Selling amount check at $8.50 / m² => $850.00
      expect(find.text('100 m²'), findsWidgets);
      expect(find.text(r'$850.00'), findsOneWidget);

      // Change temporary sell price to $9.00 / m² => $900.00 immediately
      final priceField = find.byKey(
        const ValueKey('ceiling-temporary-price-per-m2'),
      );
      await tester.enterText(priceField, '9.00');
      await tester.pump();

      expect(find.text(r'$900.00'), findsOneWidget);

      // Verify material quantities remain unchanged when price changes
      _expectResultQuantity(tester, 'ceiling_6mm', '278 សន្លឹក');
      _expectResultQuantity(tester, 'long_t_3m', '54 ដើម');
      _expectResultQuantity(tester, 'short_t_06m', '270 ដើម');
      _expectResultQuantity(tester, 'v_iron_295m', '20 ដើម');
    },
  );

  testWidgets(
    r'calculates ceiling selling amount for 6x4.2x1 room ($8.50/m² => $214.20)',
    (tester) async {
      final state = _seededState();
      await _pump(tester, state: state);

      // Default setup is 6 x 4.2 x 1 = 25.2m²
      expect(find.text('25.2 m²'), findsWidgets);
      expect(find.text(r'$214.20'), findsOneWidget);
    },
  );

  testWidgets('updates selling amount in real-time when adding a room group', (
    tester,
  ) async {
    final state = _seededState();
    await _pump(tester, state: state);

    // Room 1: 6 x 4.2 x 1 = 25.2m²
    // Add Room 2: 5 x 4 x 1 = 20m² -> total 45.2m² @ $8.50 => $384.20
    await tester.tap(find.byKey(const ValueKey('ceiling-add-room-group')));
    await tester.pump();
    await tester.enterText(_field('ceiling-group-length-2'), '5');
    await tester.enterText(_field('ceiling-group-width-2'), '4');
    await tester.enterText(
      find.byKey(const ValueKey('ceiling-group-count-2')),
      '1',
    );
    await tester.pump();

    expect(find.text('45.2 m²'), findsWidgets);
    expect(find.text(r'$384.20'), findsOneWidget);
  });

  testWidgets(
    'missing prices in AppState do not affect Ceiling m² selling price or quantities',
    (tester) async {
      final state = _seededState()..prices = [];
      await _pump(tester, state: state);

      _expectResultQuantity(tester, 'ceiling_6mm', '70 សន្លឹក');
      _expectResultQuantity(tester, 'long_t_3m', '14 ដើម');
      _expectResultQuantity(tester, 'short_t_06m', '68 ដើម');
      _expectResultQuantity(tester, 'v_iron_295m', '5 ដើម');

      expect(find.text(r'$214.20'), findsOneWidget);
    },
  );

  testWidgets('room count shows total customer quantities for all rooms', (
    tester,
  ) async {
    final state = _seededState();
    await _pump(tester, state: state);

    final countField = find.byKey(const ValueKey('ceiling-group-count-1'));
    await tester.enterText(countField, '20');
    await tester.pump();

    expect(find.text('504 m²'), findsWidgets);
    expect(find.text('20 បន្ទប់'), findsWidgets);
    _expectResultQuantity(tester, 'ceiling_6mm', '1400 សន្លឹក');
    expect(find.text('116 ប្រអប់ + 8 សន្លឹក'), findsOneWidget);

    // Selling amount: 504m² * $8.50 = $4,284.00
    expect(find.text(r'$4,284.00'), findsOneWidget);
  });

  testWidgets(
    'calculates exact extra V case: 5x4m room count 5 yields 11 extra V',
    (tester) async {
      final state = _seededState();
      await _pump(tester, state: state);

      await tester.enterText(_field('ceiling-group-length-1'), '5');
      await tester.enterText(_field('ceiling-group-width-1'), '4');
      await tester.enterText(
        find.byKey(const ValueKey('ceiling-group-count-1')),
        '5',
      );
      await tester.pump();

      _expectResultQuantity(tester, 'v_iron_295m', '20 ដើម');
      expect(
        find.byKey(const ValueKey('ceiling-extra-v-result')),
        findsOneWidget,
      );
      expect(find.text('V ទិញថែម'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('ceiling-extra-v-result')),
          matching: find.text('11 ដើម'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('shows extra V directly under the unchanged original V row', (
    tester,
  ) async {
    final state = _seededState();
    await _pump(tester, state: state);

    await tester.enterText(
      find.byKey(const ValueKey('ceiling-group-count-1')),
      '3',
    );
    await tester.pump();

    _expectResultQuantity(tester, 'v_iron_295m', '15 ដើម');
    expect(
      find.byKey(const ValueKey('ceiling-extra-v-result')),
      findsOneWidget,
    );
    expect(find.text('V ទិញថែម'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ceiling-extra-v-result')),
        matching: find.text('6 ដើម'),
      ),
      findsOneWidget,
    );

    final originalBottom = tester
        .getBottomLeft(find.byKey(const ValueKey('ceiling-result-v_iron_295m')))
        .dy;
    final extraTop = tester
        .getTopLeft(find.byKey(const ValueKey('ceiling-extra-v-result')))
        .dy;
    expect(extraTop, greaterThan(originalBottom));
  });

  testWidgets('extra V updates for multiple room-size groups', (tester) async {
    final state = _seededState();
    await _pump(tester, state: state);

    await tester.enterText(
      find.byKey(const ValueKey('ceiling-group-count-1')),
      '3',
    );
    await tester.tap(find.byKey(const ValueKey('ceiling-add-room-group')));
    await tester.pump();
    await tester.enterText(_field('ceiling-group-length-2'), '5');
    await tester.enterText(_field('ceiling-group-width-2'), '4');
    await tester.enterText(
      find.byKey(const ValueKey('ceiling-group-count-2')),
      '2',
    );
    await tester.pump();

    _expectResultQuantity(tester, 'v_iron_295m', '23 ដើម');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ceiling-extra-v-result')),
        matching: find.text('11 ដើម'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('ceiling quantities update across the half-up boundary', (
    tester,
  ) async {
    final state = _seededState();
    await _pump(tester, state: state);

    await tester.tap(find.byKey(const ValueKey('ceiling-group-mode-area-1')));
    await tester.pump();

    final areaField = find.descendant(
      of: find.byKey(const ValueKey('ceiling-group-area-1')),
      matching: find.byType(TextField),
    );

    // 1.224 m² / 0.36 m² per sheet = 3.4 sheets.
    await tester.enterText(areaField, '1.224');
    await tester.pump();
    _expectResultQuantity(tester, 'ceiling_6mm', '3 សន្លឹក');

    // 1.26 m² / 0.36 m² per sheet = 3.5 sheets.
    await tester.enterText(areaField, '1.26');
    await tester.pump();
    _expectResultQuantity(tester, 'ceiling_6mm', '4 សន្លឹក');
  });
}

Finder _field(String key) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byType(TextField),
);

void _expectResultQuantity(
  WidgetTester tester,
  String materialId,
  String quantity,
) {
  expect(
    find.descendant(
      of: find.byKey(ValueKey('ceiling-result-$materialId')),
      matching: find.text(quantity),
    ),
    findsOneWidget,
  );
}

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
        theme: ThemeData.light(useMaterial3: true),
        home: const Scaffold(body: CeilingCalculatorScreen()),
      ),
    ),
  );
  await tester.pump();
}
