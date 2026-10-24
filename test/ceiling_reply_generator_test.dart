import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/ceiling_calculator/domain/ceiling_khmer_replies.dart';
import 'package:material_quote_pro/features/ceiling_calculator/presentation/widgets/ceiling_reply_generator.dart';

void main() {
  final data = CeilingReplyData(
    priceRange: r'$227.80 – $240.00',
    details: [
      '📐 ផ្ទៃពិដាន៖ 56m²',
      'ទំហំ៖ 7m × 8m',
      '• ពិដាន៖ 156 សន្លឹក',
      '• T វែង 3m៖ 30 ដើម',
      '• T ខ្លី 0.6m៖ 151 ដើម',
      '• V 2.95m៖ 11 ដើម',
      '• លួស៖ 1000m',
    ],
  );
  test('20 distinct templates preserve every data line and avoid repeats', () {
    expect(
      CeilingKhmerReplies.templates.toSet().length,
      greaterThanOrEqualTo(20),
    );
    final replies = CeilingKhmerReplies(random: Random(42));
    var previous = replies.render(data);
    for (var i = 0; i < 500; i++) {
      replies.next();
      final text = replies.render(data);
      expect(text, isNot(previous));
      expect(text, contains(data.priceRange));
      expect(text, contains(data.details.join('\n')));
      final emoji = CeilingKhmerReplies.emojis.firstWhere(previous.contains);
      expect(text, isNot(contains(emoji)));
      previous = text;
    }
  });

  testWidgets(
    'copy next, randomize, live updates and copy failure at narrow width',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final copied = <String>[];
      var fail = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            if (fail) throw PlatformException(code: 'unavailable');
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
      Future<void> pump(CeilingReplyData value) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CeilingReplyGenerator(data: value),
            ),
          ),
        ),
      );
      String preview() => tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('ceiling-random-reply-preview')),
          )
          .data!;
      await pump(data);
      for (var i = 0; i < 12; i++) {
        final before = preview();
        await tester.tap(find.text('Copy & Generate Next'));
        await tester.pumpAndSettle();
        expect(copied.last, before);
        expect(preview(), isNot(before));
        expect(preview(), contains(data.details.join('\n')));
      }
      final before = preview();
      await tester.tap(find.text('Randomize'));
      await tester.pumpAndSettle();
      expect(preview(), isNot(before));
      expect(copied.length, 12);
      final updated = CeilingReplyData(
        priceRange: r'$500.00 – $525.00',
        details: ['📐 ផ្ទៃពិដាន៖ 100m²'],
      );
      await pump(updated);
      await tester.pumpAndSettle();
      expect(preview(), contains(updated.priceRange));
      expect(preview(), contains('100m²'));
      expect(preview(), isNot(contains('56m²')));
      fail = true;
      final beforeFailure = preview();
      await tester.tap(find.text('Copy & Generate Next'));
      await tester.pumpAndSettle();
      expect(preview(), beforeFailure);
      expect(find.text('Could not copy. Please try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
