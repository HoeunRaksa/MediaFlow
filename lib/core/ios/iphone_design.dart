import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

bool isIPhoneLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 1000 &&
    (kIsWeb || defaultTargetPlatform != TargetPlatform.windows);

/// Resolve legacy semantic colors only for the phone's dark appearance.
/// Desktop keeps the exact existing palette.
Color iPhoneColor(BuildContext context, Color color) {
  if (!isIPhoneLayout(context) ||
      MediaQuery.platformBrightnessOf(context) != Brightness.dark) {
    return color;
  }
  return _phoneDarkColors.putIfAbsent(color, () => _darkColor(color));
}

final _phoneDarkColors = <Color, Color>{};

Color _darkColor(Color color) {
  final hsl = HSLColor.fromColor(color);
  final luminance = color.computeLuminance();
  if (luminance > .65) {
    return const Color(0xFF24262F).withValues(alpha: color.a);
  }
  if (luminance > .42) {
    return const Color(0xFF363945).withValues(alpha: color.a);
  }
  if (hsl.saturation < .4 && luminance < .18) {
    return const Color(0xFFE7E9F0).withValues(alpha: color.a);
  }
  if (luminance < .32) {
    return hsl
        .withLightness(.74)
        .withSaturation(hsl.saturation.clamp(.25, .7))
        .toColor();
  }
  return color;
}

Future<T?> showAdaptiveEditor<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  if (!isIPhoneLayout(context)) {
    return showDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
    );
  }
  return showCupertinoSheet<T>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => InheritedTheme.captureAll(
      context,
      Material(
        color: CupertinoColors.systemGroupedBackground.resolveFrom(
          sheetContext,
        ),
        child: SafeArea(child: builder(sheetContext)),
      ),
    ),
  );
}

/// Phone presentation only. Business state continues to live in AppState and
/// each calculator's existing controllers.
class IPhoneShell extends StatefulWidget {
  const IPhoneShell({super.key, required this.pages, this.initialIndex = 0});
  final List<Widget> pages;
  final int initialIndex;

  @override
  State<IPhoneShell> createState() => _IPhoneShellState();
}

class _IPhoneShellState extends State<IPhoneShell> {
  late final _tabs = CupertinoTabController(initialIndex: widget.initialIndex);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final dark = brightness == Brightness.dark;
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: brightness,
        primaryColor: dark ? const Color(0xFF80B8FF) : const Color(0xFF1763B2),
        scaffoldBackgroundColor: dark
            ? const Color(0xFF111217)
            : const Color(0xFFF2F3F7),
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            inherit: false,
            fontFamily: 'NotoSansKhmer',
            fontFamilyFallback: const ['Roboto'],
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: dark ? Colors.white : const Color(0xFF172A48),
          ),
          navLargeTitleTextStyle: TextStyle(
            inherit: false,
            fontFamily: 'NotoSansKhmer',
            fontFamilyFallback: const ['Roboto'],
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: dark ? Colors.white : const Color(0xFF172A48),
          ),
          tabLabelTextStyle: TextStyle(
            fontFamily: 'NotoSansKhmer',
            fontFamilyFallback: const ['Roboto'],
            fontSize: 10,
            color: dark ? Colors.white70 : Colors.black54,
          ),
          textStyle: TextStyle(
            fontFamily: 'NotoSansKhmer',
            fontFamilyFallback: const ['Roboto'],
            fontSize: 16,
            color: dark ? const Color(0xFFE7E9F0) : const Color(0xFF172A48),
          ),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          brightness: brightness,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1763B2),
            brightness: brightness,
          ),
          textTheme: Theme.of(context).textTheme.apply(
            fontFamily: 'NotoSansKhmer',
            fontFamilyFallback: const ['Roboto'],
            bodyColor: dark ? const Color(0xFFE7E9F0) : const Color(0xFF172A48),
            displayColor: dark
                ? const Color(0xFFE7E9F0)
                : const Color(0xFF172A48),
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: dark ? const Color(0xFF24262F) : Colors.white,
            insetPadding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          platform: TargetPlatform.iOS,
          splashFactory: NoSplash.splashFactory,
          visualDensity: VisualDensity.standard,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(minimumSize: const Size(44, 44)),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44)),
          ),
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: dark ? const Color(0xFF363945) : const Color(0xFFF1F2F6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        child: ScrollConfiguration(
          behavior: const CupertinoScrollBehavior(),
          child: CupertinoTabScaffold(
            controller: _tabs,
            tabBar: CupertinoTabBar(
              backgroundColor: dark
                  ? const Color(0xE822242C)
                  : const Color(0xE8FAFBFF),
              height: 58,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.bubble_left_bubble_right),
                  label: 'ពិដាន',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.layers),
                  label: 'PVC',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.cube_box),
                  label: 'ផលិតផល',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.ellipsis_circle),
                  label: 'បន្ថែម',
                ),
              ],
            ),
            tabBuilder: (context, index) => CupertinoTabView(
              builder: (context) => index == 3
                  ? Material(
                      type: MaterialType.transparency,
                      child: widget.pages[index],
                    )
                  : IPhonePage(
                      title: [
                        'គណនាពិដាន',
                        'គណនា PVC',
                        'ផលិតផល',
                        'បន្ថែម',
                      ][index],
                      child: widget.pages[index],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class IPhonePage extends StatelessWidget {
  const IPhonePage({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      backgroundColor: CupertinoColors.systemBackground
          .resolveFrom(context)
          .withValues(alpha: .88),
      enableBackgroundFilterBlur: !MediaQuery.disableAnimationsOf(context),
    ),
    child: SafeArea(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    ),
  );
}

/// One full-width workspace step at a time; no desktop canvas or horizontal pan.
class IPhoneWorkspace extends StatefulWidget {
  const IPhoneWorkspace({
    super.key,
    required this.panels,
    this.footer,
    this.tabLabels,
    this.continuous = false,
    this.mobilePanelHeights,
  });
  final List<Widget> panels;
  final Widget? footer;
  final List<String>? tabLabels;
  final bool continuous;

  /// Fixed heights are only used to bound the nested lists inside each panel.
  /// Callers can tune them per workspace while keeping the desktop layout
  /// completely unchanged.
  final List<double>? mobilePanelHeights;
  @override
  State<IPhoneWorkspace> createState() => _IPhoneWorkspaceState();
}

class _IPhoneWorkspaceState extends State<IPhoneWorkspace> {
  int _step = 0;
  @override
  Widget build(BuildContext context) => widget.continuous
      ? SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              for (var index = 0; index < widget.panels.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    height:
                        widget.mobilePanelHeights != null &&
                            index < widget.mobilePanelHeights!.length
                        ? widget.mobilePanelHeights![index]
                        : 620,
                    child: widget.panels[index],
                  ),
                ),
              if (widget.footer != null) widget.footer!,
            ],
          ),
        )
      : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _step,
                  onValueChanged: (value) {
                    if (value == null) return;
                    FocusManager.instance.primaryFocus?.unfocus();
                    setState(() => _step = value);
                  },
                  children: {
                    0: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        widget.tabLabels?[0] ?? 'ទំហំ',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'NotoSansKhmer',
                          fontFamilyFallback: const ['Roboto'],
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        widget.tabLabels?[1] ?? 'ផលិតផល',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'NotoSansKhmer',
                          fontFamilyFallback: const ['Roboto'],
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                    2: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        widget.tabLabels?[2] ?? 'លទ្ធផល',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'NotoSansKhmer',
                          fontFamilyFallback: const ['Roboto'],
                          color: CupertinoColors.label.resolveFrom(context),
                        ),
                      ),
                    ),
                  },
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: constraints.maxHeight < 640
                              ? 640
                              : constraints.maxHeight - 20,
                          child: IndexedStack(
                            index: _step,
                            children: widget.panels,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Row(
                            children: [
                              if (_step > 0)
                                Expanded(
                                  child: CupertinoButton.tinted(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    onPressed: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      setState(() => _step--);
                                    },
                                    child: const Text('ត្រឡប់'),
                                  ),
                                ),
                              if (_step > 0 && _step < widget.panels.length - 1)
                                const SizedBox(width: 10),
                              if (_step < widget.panels.length - 1)
                                Expanded(
                                  child: CupertinoButton.filled(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    onPressed: () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      setState(() => _step++);
                                    },
                                    child: const Text('បន្ទាប់'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_step == 2 && widget.footer != null) widget.footer!,
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
}

class IPhoneMenuEntry {
  const IPhoneMenuEntry({
    required this.title,
    required this.icon,
    required this.builder,
  });
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
}

class IPhoneMenu extends StatelessWidget {
  const IPhoneMenu({super.key, required this.entries});
  final List<IPhoneMenuEntry> entries;
  @override
  Widget build(BuildContext context) => CustomScrollView(
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    slivers: [
      const CupertinoSliverNavigationBar(
        largeTitle: Text('បន្ថែម'),
        automaticallyImplyLeading: false,
      ),
      SliverToBoxAdapter(
        child: CupertinoListSection.insetGrouped(
          children: [
            for (final entry in entries)
              CupertinoListTile.notched(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                leading: Icon(
                  entry.icon,
                  size: 23,
                  color: CupertinoTheme.of(context).primaryColor,
                ),
                title: Text(entry.title),
                trailing: const CupertinoListTileChevron(),
                onTap: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (context) => IPhonePage(
                      title: entry.title,
                      child: entry.builder(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ],
  );
}

class IPhoneGlass extends StatelessWidget {
  const IPhoneGlass({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground
              .resolveFrom(context)
              .withValues(alpha: .86),
          border: Border.all(
            color: CupertinoColors.separator
                .resolveFrom(context)
                .withValues(alpha: .18),
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      ),
    ),
  );
}
