import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Semantic colors for the professional navy, gold, and neutral design system.
class AppColors {
  const AppColors._();

  // Application and ambient backgrounds.
  static const Color background = Color(0xFFF3F5F7);
  static const Color backgroundSecondary = Color(0xFFF8FAFC);
  static const Color backgroundRosy = Color(0xFFEEF2F6);
  static const Color sidebar = Color(0xFFF7F9FC);
  static const Color topBar = Color(0xFFFFFFFF);

  // Frosted surfaces. Legacy aliases below keep existing screens semantic.
  static const Color surfaceGlass = Color(0xFFFCFDFE);
  static const Color surfaceGlassStrong = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF6F8FA);
  static const Color surface = surfaceGlassStrong;
  static const Color surfaceSecondary = surfaceSoft;
  static const Color surfaceSelected = Color(0xFFE6EDF6);
  static const Color card = surfaceGlass;
  static const Color cardHover = Color(0xFFF1F5F9);

  // Brand accents sampled from the supplied logo.
  static const Color primary = Color(0xFF0B2A57);
  static const Color primarySoft = Color(0xFFD5E0ED);
  static const Color primaryHover = Color(0xFF123D73);
  static const Color primaryPressed = Color(0xFF071E40);
  static const Color primaryText = Color(0xFF0B2A57);
  static const Color primaryDeep = Color(0xFF071E40);
  static const Color primaryGlow = Color(0x240B2A57);

  // Secondary brand and status accents.
  static const Color secondary = Color(0xFFB88419);
  static const Color accentLavender = Color(0xFFE6EDF6);
  static const Color accentGreen = Color(0xFF2E7A52);
  static const Color accentPeach = Color(0xFFF2E6C8);
  static const Color accentPinkLavender = Color(0xFFD5E0ED);
  static const Color lilacHighlight = Color(0xFFEAF0F7);

  // Sidebar-specific tokens.
  static const Color sidebarText = Color(0xFF475569);
  static const Color sidebarSelectedBg = Color(0xFFE3EBF5);
  static const Color sidebarSelectedIconText = Color(0xFF0B2A57);
  static const Color sidebarHoverBg = Color(0xFFEDF2F7);

  // Typography. Keep contrast high enough for dense Khmer desktop content.
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textMain = textPrimary;
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Glass edges and highlights.
  static const Color borderSoft = Color(0xFFDCE3EA);
  static const Color border = borderSoft;
  static const Color borderStrong = Color(0xFFC5D0DC);
  static const Color borderLight = Color(0xFFE8EDF2);
  static const Color glassHighlight = Color(0xFFE2E8F0);
  static const Color glassWhiteBorder = glassHighlight;
  static const Color shadowSoft = Color(0x1A0F2742);

  // Input fields.
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = borderSoft;
  static const Color inputFocusBorder = primary;

  // Secondary buttons.
  static const Color buttonSecondaryBg = Color(0xFFF1F5F9);
  static const Color buttonSecondaryText = Color(0xFF0B2A57);
  static const Color buttonSecondaryBorder = borderStrong;

  // Mint Green Summary Cards (Matching Reference Image Bottom Cards)
  static const Color success = Color(0xFF2E7A52);
  static const Color successText = Color(0xFF2E7A52);
  static const Color successSoft = Color(0xD9E8F3EA);
  static const Color successBg = successSoft;
  static const Color successBorder = Color(0xFFC8EAD6);
  static const Color successGlow = Color(0x152E7A52);

  static const Color warning = Color(0xFFB7791F);
  static const Color warningText = Color(0xFF8A5A13);
  static const Color warningSoft = Color(0xE6F7EBDD);
  static const Color warningBg = warningSoft;
  static const Color warningBorder = Color(0xFFEAD5BE);

  static const Color error = Color(0xFFD45B6B);
  static const Color errorText = Color(0xFFC63A4B);
  static const Color errorSoft = Color(0xE6F6DFE3);
  static const Color errorBg = errorSoft;
  static const Color errorBorder = Color(0xFFE8BAC1);
  static const Color errorGlow = Color(0x20D45B6B);

  // Calculation & Total Highlights
  static const Color totalAreaBg = successSoft;
  static const Color totalAreaText = Color(0xFF2E7A52);

  // Category Accent Surfaces
  static const Color categoryPvcBg = Color(0xFFEAF0F7);
  static const Color categoryPvcText = Color(0xFF0B2A57);
  static const Color categoryAccBg = Color(0xFFFBF4E3);
  static const Color categoryAccText = Color(0xFF8A5A13);
  static const Color categoryClineBg = Color(0xFFEBF7F0);
  static const Color categoryClineText = Color(0xFF2E7A52);
  static const Color categoryDbBg = Color(0xFFEDF2F7);
  static const Color categoryDbText = Color(0xFF334155);
  static const Color categoryGdBg = Color(0xFFEEF3FC);
  static const Color categoryGdText = Color(0xFF4A68B8);
}

/// Shared geometry and motion tokens for the desktop system.
class AppEffects {
  const AppEffects._();

  static const double glassBlur = 0;
  static const double glassBlurSubtle = 0;
  static const double panelRadius = 18;
  static const double cardRadius = 14;
  static const double controlRadius = 11;
  static const double pillRadius = 999;
  static const Duration motionFast = Duration(milliseconds: 150);
  static const Duration motionNormal = Duration(milliseconds: 220);
  static const Curve motionCurve = Curves.easeOutCubic;
}

/// Quiet neutral shadows that preserve hierarchy without a decorative glow.
class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> cardSoft = [
    BoxShadow(
      color: Color(0x120F2742),
      blurRadius: 16,
      spreadRadius: -5,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> glassCard = [
    BoxShadow(
      color: Color(0x160F2742),
      blurRadius: 20,
      spreadRadius: -6,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> cardHover = [
    BoxShadow(
      color: Color(0x240B2A57),
      blurRadius: 18,
      spreadRadius: -5,
      offset: Offset(0, 7),
    ),
  ];
}

/// Central Material configuration. Screens should consume this instead of
/// repeating component colors and interaction states.
class AppTheme {
  const AppTheme._();

  static ThemeData light({required String fontFamily}) {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.textPrimary,
      surface: AppColors.surfaceGlassStrong,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surfaceGlassStrong,
      colorScheme: colorScheme,
      dividerColor: AppColors.borderSoft,
      focusColor: AppColors.primaryGlow,
      hoverColor: AppColors.primarySoft.withValues(alpha: 0.18),
      highlightColor: AppColors.primarySoft.withValues(alpha: 0.16),
      splashColor: AppColors.primarySoft.withValues(alpha: 0.22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIconColor: AppColors.textSecondary,
        suffixIconColor: AppColors.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppEffects.controlRadius),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppEffects.controlRadius),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppEffects.controlRadius),
          borderSide: const BorderSide(
            color: AppColors.inputFocusBorder,
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppEffects.controlRadius),
          borderSide: const BorderSide(color: AppColors.errorBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceGlassStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEffects.cardRadius),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
      ),
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(AppColors.surfaceSoft),
        headingTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        dataTextStyle: TextStyle(color: AppColors.textPrimary),
        dataRowMinHeight: 46,
        dataRowMaxHeight: 54,
        dividerThickness: 0.5,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceGlassStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.shadowSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEffects.panelRadius),
          side: const BorderSide(color: AppColors.glassHighlight, width: 1.2),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      dropdownMenuTheme: const DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surfaceGlassStrong),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          shadowColor: WidgetStatePropertyAll(AppColors.shadowSoft),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surfaceGlassStrong,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.shadowSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEffects.cardRadius),
          side: const BorderSide(color: AppColors.glassHighlight),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.textPrimary.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.cardSoft,
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primarySoft.withValues(alpha: 0.45);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryPressed;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryHover;
            }
            return AppColors.primary;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.10),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppEffects.controlRadius),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(
            AppColors.buttonSecondaryBg,
          ),
          foregroundColor: const WidgetStatePropertyAll(
            AppColors.buttonSecondaryText,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.buttonSecondaryBorder),
          ),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primarySoft.withValues(alpha: 0.16),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppEffects.controlRadius),
            ),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppEffects.controlRadius),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: const WidgetStatePropertyAll(AppColors.primaryText),
          overlayColor: WidgetStatePropertyAll(
            AppColors.primarySoft.withValues(alpha: 0.20),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.textMuted.withValues(alpha: 0.45);
          }
          return AppColors.surfaceGlassStrong;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceSoft.withValues(alpha: 0.55);
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surfaceSelected;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primarySoft;
          }
          return AppColors.borderStrong;
        }),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.surfaceGlassStrong;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: AppColors.borderStrong, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textMuted;
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceGlass,
        selectedColor: AppColors.surfaceSelected,
        disabledColor: AppColors.surfaceSoft.withValues(alpha: 0.55),
        side: const BorderSide(color: AppColors.borderSoft),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEffects.pillRadius),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        secondaryLabelStyle: const TextStyle(
          color: AppColors.primaryText,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSoft,
        thickness: 0.7,
        space: 1,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          AppColors.primarySoft.withValues(alpha: 0.72),
        ),
        trackColor: const WidgetStatePropertyAll(Colors.transparent),
        radius: const Radius.circular(20),
        thickness: const WidgetStatePropertyAll(6),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary.withValues(alpha: 0.95),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppEffects.cardRadius),
        ),
      ),
    );
  }
}

/// SakuraTheme alias compatibility class
class SakuraTheme {
  const SakuraTheme._();

  static const Color bg = AppColors.background;
  static const Color sidebar = AppColors.sidebar;
  static const Color surface = AppColors.surface;
  static const Color card = AppColors.card;
  static const Color cardHover = AppColors.cardHover;
  static const Color border = AppColors.border;
  static const Color borderLight = AppColors.borderLight;

  static const Color sakuraPink = AppColors.primary;
  static const Color sakuraRose = AppColors.primaryHover;
  static const Color sakuraDeep = AppColors.primaryDeep;
  static const Color sakuraGlow = AppColors.primaryGlow;
  static const Color sakuraBorder = AppColors.borderStrong;

  static const Color secondary = AppColors.secondary;
  static const Color success = AppColors.success;
  static const Color successGlow = AppColors.successGlow;
  static const Color danger = AppColors.error;
  static const Color dangerGlow = AppColors.errorGlow;
  static const Color warning = AppColors.warning;

  static const Color textMain = AppColors.textMain;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textMuted = AppColors.textMuted;

  // Spacing & Border Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = AppEffects.controlRadius;
  static const double radiusLg = AppEffects.cardRadius;
  static const double radiusXl = AppEffects.panelRadius;

  // Animation Specs
  static const Duration animFast = AppEffects.motionFast;
  static const Duration animNormal = AppEffects.motionNormal;
  static const Curve animCurve = AppEffects.motionCurve;
}

/// A clean bordered surface. The legacy blur argument is retained so existing
/// screens do not need calculation or layout changes during the visual refresh.
class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AppEffects.panelRadius),
    ),
    this.tint = AppColors.surfaceGlass,
    this.borderColor = AppColors.glassHighlight,
    this.blur = AppEffects.glassBlur,
    this.shadows = AppShadows.glassCard,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Color tint;
  final Color borderColor;
  final double blur;
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
      ),
      child: Padding(padding: padding, child: child),
    );

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: ClipRRect(borderRadius: borderRadius, child: surface),
    );
  }
}

/// A neutral workspace shared by every desktop destination.
class AppWorkspaceBackground extends StatelessWidget {
  const AppWorkspaceBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRect(
        child: Stack(
          key: const ValueKey('app-professional-workspace'),
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.backgroundSecondary,
                    AppColors.background,
                    AppColors.backgroundRosy,
                  ],
                  stops: [0, 0.60, 1],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: SizedBox(
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Backward-compatible compact glass card.
class SakuraGlassContainer extends StatelessWidget {
  const SakuraGlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.width,
    this.height,
    this.borderRadius = 20.0,
    this.color,
    this.borderColor,
    this.shadows,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      borderRadius: BorderRadius.circular(borderRadius),
      tint: color ?? AppColors.card,
      borderColor: borderColor ?? AppColors.border,
      blur: AppEffects.glassBlurSubtle,
      shadows: shadows ?? AppShadows.cardSoft,
      child: child,
    );
  }
}

/// The supplied business logo, shown without decorative replacements.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({super.key, this.size = 32.0, this.width, this.height});

  final double size;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final w = width ?? size;
    final h = height ?? size;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        AppConstants.brandLogoAsset,
        width: w,
        height: h,
        fit: BoxFit.cover,
        cacheWidth: (w * 3).round(),
        cacheHeight: (h * 3).round(),
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.business_rounded,
          size: w * 0.54,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Soft Pastel Decision Status Badge Widget (✓ អាចលក់បាន / ✕ មិនគួរលក់)
class SakuraDecisionBadge extends StatelessWidget {
  const SakuraDecisionBadge({
    super.key,
    required this.canSell,
    this.customText,
  });

  final bool canSell;
  final String? customText;

  @override
  Widget build(BuildContext context) {
    final bgColor = canSell ? AppColors.successBg : AppColors.errorBg;
    final borderColor = canSell
        ? AppColors.successBorder
        : AppColors.errorBorder;
    final textColor = canSell ? AppColors.successText : AppColors.errorText;
    final label = customText ?? (canSell ? '✓ អាចលក់បាន' : '✕ មិនគួរលក់');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(SakuraTheme.radiusLg),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            canSell ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
