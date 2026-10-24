import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/data/pvc_physical_catalog.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/domain/pvc_khmer_replies.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/presentation/screens/pvc_quantity_calculator_screen.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/presentation/widgets/pvc_reply_generator.dart';

void main() {
  test('preserves price text while changing Khmer wording and emoji', () {
    final replies = PvcKhmerReplies(random: Random(42))..next();
    final first = replies.reply(r'$20.5');
    replies.next();
    final second = replies.reply(r'  $20.5  ');

    expect(PvcKhmerReplies.templates.length, greaterThanOrEqualTo(25));
    expect(first, contains(r'$20.5'));
    expect(second, contains(r'$20.5'));
    expect(second, isNot(first));
    expect(replies.reply('   '), isEmpty);
  });

  testWidgets('copy and randomize work at all requested phone widths', (
    tester,
  ) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
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

    for (final width in [320.0, 375.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PvcReplyGenerator(compactMobile: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final input = find.byKey(const ValueKey('pvc-reply-price'));
      await tester.enterText(input, r'$25.8');
      await tester.pumpAndSettle();
      final preview = tester.widget<SelectableText>(
        find.byKey(const ValueKey('pvc-reply-preview')),
      );
      final beforeRandomize = preview.data!;

      await tester.tap(find.text('Randomize'));
      await tester.pumpAndSettle();
      final afterRandomize = tester.widget<SelectableText>(
        find.byKey(const ValueKey('pvc-reply-preview')),
      );
      expect(afterRandomize.data, isNot(beforeRandomize));

      await tester.tap(find.text('Copy & Generate Next'));
      await tester.pumpAndSettle();
      expect(copied.last, afterRandomize.data);
      expect(find.text('Copied! Next reply is ready.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('PVC compact page keeps the generator in the vertical flow', (
    tester,
  ) async {
    final products = const PvcPhysicalCatalog().build(
      DefaultMaterialSeed.materials(DateTime.utc(2026, 8, 8)),
    );
    for (final width in [320.0, 375.0, 390.0, 430.0]) {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PvcQuantityCalculatorScreen(
                compactMobile: true,
                simpleAreaEstimates: true,
                products: products,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pvc-reply-price')), findsOneWidget);
      expect(find.byKey(const ValueKey('pvc-reply-preview')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
