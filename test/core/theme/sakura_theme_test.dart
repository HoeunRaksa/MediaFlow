import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/app_state.dart';
import 'package:material_quote_pro/core/theme/sakura_theme.dart';
import 'package:material_quote_pro/features/materials/presentation/selling_desktop_shell.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('app theme exposes professional navy and neutral controls', (
    tester,
  ) async {
    late ThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(fontFamily: 'NotoSansKhmer'),
        home: Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const Scaffold(body: TextField());
          },
        ),
      ),
    );

    expect(theme.colorScheme.primary, AppColors.primary);
    expect(theme.colorScheme.surface, AppColors.surfaceGlassStrong);
    expect(theme.inputDecorationTheme.fillColor, AppColors.inputBackground);
    expect(theme.dialogTheme.backgroundColor, AppColors.surfaceGlassStrong);
    expect(theme.cardTheme.surfaceTintColor, Colors.transparent);
    expect(
      theme.switchTheme.trackColor?.resolve({WidgetState.selected}),
      AppColors.primary,
    );
    expect(
      theme.switchTheme.trackColor?.resolve(const {}),
      AppColors.surfaceSelected,
    );
  });

  testWidgets('professional workspace uses a clean bordered surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppWorkspaceBackground(
          child: Center(
            child: AppGlassSurface(
              key: ValueKey('glass-under-test'),
              child: SizedBox(width: 180, height: 120),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('app-professional-workspace')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('glass-under-test')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('glass-under-test')),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
  });

  testWidgets('desktop shell keeps its workflow inside the glass backdrop', (
    tester,
  ) async {
    final state = AppState()..isLoading = false;
    addTearDown(state.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 900);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light(fontFamily: 'NotoSansKhmer'),
          home: const SellingDesktopShell(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.byKey(const ValueKey('app-professional-workspace')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ceiling-root')), findsOneWidget);
    expect(find.byKey(const ValueKey('ceiling-room-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('ceiling-result-panel')), findsOneWidget);
    expect(find.byType(AppGlassSurface), findsAtLeastNWidgets(5));
  });
}
