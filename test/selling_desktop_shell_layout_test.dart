import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_quote_pro/app_state.dart';
import 'package:material_quote_pro/features/materials/data/models/formula_rule.dart';
import 'package:material_quote_pro/features/materials/data/models/material_category.dart';
import 'package:material_quote_pro/features/materials/data/models/material_item.dart';
import 'package:material_quote_pro/features/materials/data/models/material_price.dart';
import 'package:material_quote_pro/features/materials/data/models/packaging_rule.dart';
import 'package:material_quote_pro/features/materials/data/models/pricing_tier.dart';
import 'package:material_quote_pro/features/materials/data/models/product_type_template.dart';
import 'package:material_quote_pro/features/materials/data/models/sell_mode.dart';
import 'package:material_quote_pro/features/materials/data/models/unit_of_measure.dart';
import 'package:material_quote_pro/features/materials/data/seed/default_material_seed.dart';
import 'package:material_quote_pro/features/materials/presentation/selling_desktop_shell.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('desktop selling shell does not overflow on supported sizes', (
    tester,
  ) async {
    final state = seededAppState();
    final previousOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    void captureFlutterErrors() {
      FlutterError.onError = errors.add;
    }

    void restoreFlutterErrors() {
      FlutterError.onError = previousOnError;
    }

    captureFlutterErrors();

    addTearDown(() async {
      restoreFlutterErrors();
      state.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const sizes = [
      Size(1366, 768),
      Size(1600, 900),
      Size(1920, 1080),
      Size(393, 852),
      Size(852, 393),
    ];
    for (final size in sizes) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;

      for (final destination in SaleDestination.values) {
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: state,
            child: MaterialApp(
              home: SellingDesktopShell(
                key: ValueKey('shell-${destination.name}-$size'),
                initialDestination: destination,
              ),
            ),
          ),
        );
        await _pumpLayoutFrames(tester);
        restoreFlutterErrors();
        _expectNoFlutterErrors(errors, '${destination.name} at $size');
        errors.clear();
        captureFlutterErrors();
      }
    }
  });
}

AppState seededAppState() {
  final seed = DefaultMaterialSeed.json(DateTime(2026, 1, 1));
  final state = AppState();
  state.isLoading = false;
  state.materials = _decodeSeed(seed, 'materials', MaterialItem.fromJson);
  state.prices = _decodeSeed(seed, 'prices', MaterialPrice.fromJson);
  state.pricingTiers = _decodeSeed(seed, 'pricingTiers', PricingTier.fromJson);
  state.formulaRules = _decodeSeed(seed, 'formulaRules', FormulaRule.fromJson);
  state.categories = _decodeSeed(seed, 'categories', MaterialCategory.fromJson);
  state.units = _decodeSeed(seed, 'units', UnitOfMeasure.fromJson);
  state.productTemplates = _decodeSeed(
    seed,
    'productTypeTemplates',
    ProductTypeTemplate.fromJson,
  );
  state.sellModes = _decodeSeed(seed, 'sellModes', SellMode.fromJson);
  state.packagingRules = _decodeSeed(
    seed,
    'packagingRules',
    PackagingRule.fromJson,
  );
  final settings = seed['settings'] as Map<String, dynamic>? ?? const {};
  state.useSavedPriceAsDefault =
      settings['useSavedPriceAsDefault'] as bool? ?? true;
  state.allowSaleBelowCost = settings['allowSaleBelowCost'] as bool? ?? false;
  return state;
}

List<T> _decodeSeed<T>(
  Map<String, dynamic> seed,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  return (seed[key] as List<dynamic>)
      .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
      .toList(growable: false);
}

Future<void> _pumpLayoutFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void _expectNoFlutterErrors(List<FlutterErrorDetails> errors, String context) {
  expect(
    errors,
    isEmpty,
    reason: [
      'Unexpected Flutter layout/runtime error during $context.',
      for (final error in errors) error.toString(),
    ].join('\n\n'),
  );
}
