import 'package:material_quote_pro/core/ios/iphone_controls.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/domain/pvc_khmer_replies.dart';
import 'package:material_quote_pro/features/pvc_quantity_calculator/presentation/widgets/pvc_reply_generator.dart';

void main() {
  test(
    'text prices remain exact and repeated generations change wording and emoji',
    () {
      final replies = PvcKhmerReplies(random: Random(42))..next();
      expect(
        PvcKhmerReplies.templates.toSet().length,
        greaterThanOrEqualTo(25),
      );
      for (final price in [r'$20.5', r'$25.8', r'$6.7', r'$20.X', r'$25.X']) {
        var previous = replies.reply(price);
        for (var i = 0; i < 100; i++) {
          replies.next();
          final next = replies.reply('  $price  ');
          expect(next, contains(price));
          expect(r'$'.allMatches(next).length, 1);
          expect(next, isNot(previous));
          final oldEmoji = PvcKhmerReplies.emojis.firstWhere(previous.contains);
          expect(next, isNot(contains(oldEmoji)));
          previous = next;
        }
      }
      expect(replies.reply('  '), isEmpty);
      expect(replies.reply('20.X'), contains(r'$20.X'));
    },
  );

  testWidgets(
    'price edits, repeated copies, randomization, validation and copy failure',
    (tester) async {
      final copied = <String>[];
      var fail = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            if (fail) throw PlatformException(code: 'clipboard-unavailable');
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
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PvcReplyGenerator()),
          ),
        ),
      );
      String preview() => tester
          .widget<SelectableText>(
            find.byKey(const ValueKey('pvc-reply-preview')),
          )
          .data!;
      await tester.tap(find.text('Copy & Generate Next'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a price to generate a reply.'), findsOneWidget);
      expect(copied, isEmpty);
      final input = find.byKey(const ValueKey('pvc-reply-price'));
      await tester.enterText(input, r'$20.X');
      await tester.pumpAndSettle();
      expect(preview(), contains(r'$20.X'));
      await tester.enterText(input, r'$25.8');
      await tester.pumpAndSettle();
      expect(preview(), contains(r'$25.8'));
      expect(preview(), isNot(contains(r'$20.X')));
      for (var i = 0; i < 15; i++) {
        final before = preview();
        await tester.tap(find.text('Copy & Generate Next'));
        await tester.pumpAndSettle();
        expect(copied.last, before);
        expect(preview(), isNot(before));
        expect(find.text('Copied! Next reply is ready.'), findsOneWidget);
      }
      final beforeRandom = preview();
      await tester.tap(find.text('Randomize'));
      await tester.pumpAndSettle();
      expect(preview(), isNot(beforeRandom));
      expect(copied.length, 15);
      expect(
        tester.widget<AdaptiveTextField>(input).controller!.text,
        r'$25.8',
      );
      fail = true;
      final beforeFailure = preview();
      await tester.tap(find.text('Copy & Generate Next'));
      await tester.pumpAndSettle();
      expect(preview(), beforeFailure);
      expect(find.text('Could not copy. Please try again.'), findsOneWidget);
      await tester.enterText(input, '   ');
      await tester.pumpAndSettle();
      expect(preview(), isNot(contains(r'$25.8')));
    },
  );

  testWidgets('generator fits a narrow screen with large text', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const SingleChildScrollView(child: PvcReplyGenerator()),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(AdaptiveTextField), r'$20.5');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
