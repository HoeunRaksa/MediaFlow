import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:material_quote_pro/core/ios/iphone_design.dart';
import 'package:material_quote_pro/features/materials/presentation/selling_desktop_shell.dart';
import 'package:material_quote_pro/features/materials/presentation/mobile_quick_quote_screen.dart';
import 'package:material_quote_pro/app_state.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'selling_desktop_shell_layout_test.dart' show seededAppState;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final khmer = FontLoader('NotoSansKhmer')
      ..addFont(rootBundle.load('assets/fonts/NotoSansKhmer-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NotoSansKhmer-Bold.ttf'));
    await khmer.load();
    final latin = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await latin.load();
    final cupertino = FontLoader('packages/cupertino_icons/CupertinoIcons')
      ..addFont(
        rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
      );
    await cupertino.load();
    final material = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await material.load();
  });
  testWidgets(
    'phone catalog editor fits with keyboard and every secondary screen opens',
    (tester) async {
      final state = seededAppState();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(375, 812);
      addTearDown(() {
        state.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            home: SellingDesktopShell(
              initialDestination: SaleDestination.products,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('កែ').first);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      final editorContext = tester.element(find.byType(AlertDialog));
      Navigator.of(editorContext).pop();
      await tester.pumpAndSettle();
      tester.widget<CupertinoTabBar>(find.byType(CupertinoTabBar)).onTap!(2);
      await tester.pumpAndSettle();
      for (var index = 8; index < SaleDestination.values.length; index++) {
        final tile = find.byType(CupertinoListTile).at(index);
        await Scrollable.ensureVisible(tester.element(tile), alignment: .5);
        await tester.pumpAndSettle();
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'secondary screen $index',
        );
        final nav = Navigator.of(tester.element(find.byType(IPhonePage).last));
        nav.pop();
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets('capture iPhone light and dark renderings', (tester) async {
    final state = seededAppState();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      state.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SellingDesktopShell(),
          ),
        ),
      ),
    );
    for (final brightness in Brightness.values) {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      await tester.pump(const Duration(milliseconds: 600));
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.png,
        ))!.buffer.asUint8List();
        await File(
          'D:/ProMax/.tool-state/web-setup/iphone-${brightness.name}.png',
        ).writeAsBytes(bytes);
        image.dispose();
      });
    }
  });
  for (final size in [
    const Size(375, 667),
    const Size(393, 852),
    const Size(430, 932),
    const Size(932, 430),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('iPhone tabs and calculators at $size in $brightness', (
        tester,
      ) async {
        final state = seededAppState();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = size;
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(() {
          state.dispose();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearPlatformBrightnessTestValue();
        });
        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>.value(
            value: state,
            child: const MaterialApp(
              debugShowCheckedModeBanner: false,
              home: SellingDesktopShell(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(CupertinoTabBar), findsOneWidget);
        expect(
          find.byKey(const ValueKey('mobile-workspace-scroll')),
          findsNothing,
        );
        final scaffold = tester.state(find.byType(CupertinoTabScaffold));
        // Each calculator is a complete page; switching tabs must remain error-free.
        for (var tab = 0; tab < 2; tab++) {
          final tabBar = tester.widget<CupertinoTabBar>(
            find.byType(CupertinoTabBar),
          );
          tabBar.onTap!(tab);
          await tester.pump(const Duration(milliseconds: 300));
          expect(scaffold.mounted, isTrue);
          expect(tester.takeException(), isNull);
        }
        tester.widget<CupertinoTabBar>(find.byType(CupertinoTabBar)).onTap!(2);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byType(CupertinoListTile), findsWidgets);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'secondary navigation pushes and supports back and editor dismissal',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: IPhoneShell(
            pages: [
              for (var i = 0; i < 2; i++) const SizedBox(),
              IPhoneMenu(
                entries: [
                  IPhoneMenuEntry(
                    title: 'Settings detail',
                    icon: CupertinoIcons.settings,
                    builder: (_) => const Center(child: Text('Detail page')),
                  ),
                ],
              ),
            ],
            initialIndex: 2,
          ),
        ),
      );
      await tester.tap(find.text('Settings detail'));
      await tester.pumpAndSettle();
      expect(find.text('Detail page'), findsOneWidget);
      await tester.dragFrom(const Offset(1, 300), const Offset(350, 0));
      await tester.pumpAndSettle();
      expect(find.text('Settings detail'), findsOneWidget);
      expect(find.text('Detail page'), findsNothing);
    },
  );

  testWidgets(
    'quick quote switches products while keeping compact calculators',
    (tester) async {
      final state = seededAppState();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(() {
        state.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: const MaterialApp(home: MobileQuickQuoteScreen()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.byKey(const ValueKey('mobile-ceiling-quotation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mobile-ceiling-quick-quote-copy')),
        findsOneWidget,
      );
      expect(find.text('25.2 m²'), findsWidgets);

      await tester.tap(find.text('ក្ដារ PVC'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.byKey(const ValueKey('mobile-pvc-quotation')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('mobile-pvc-quick-quote-copy')),
        findsOneWidget,
      );
      expect(find.text('ទំហំ PVC'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
