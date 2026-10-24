import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../core/constants/business_ids.dart';
import '../../../core/utils/money_formatter.dart';
import '../data/models/material_category.dart';
import '../data/models/material_item.dart';
import '../data/models/material_price.dart';
import '../data/models/packaging_rule.dart';
import '../data/models/product_type_template.dart';
import '../data/models/unit_of_measure.dart';
import '../domain/live_calculation_models.dart';

enum AppDestination {
  ceiling,
  insulation,
  led,
  wire,
  decoration,
  custom,
  products,
  prices,
  packaging,
  productKinds,
  formulas,
  unitsCategories,
  appSettings,
}

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  AppDestination _destination = AppDestination.ceiling;

  @override
  Widget build(BuildContext context) {
    final meta = _meta(_destination);
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F14),
      body: Row(
        children: [
          _Sidebar(
            destination: _destination,
            onSelected: (value) => setState(() => _destination = value),
          ),
          Expanded(
            child: Column(
              children: [
                _TopHeader(title: meta.title, subtitle: meta.subtitle),
                Expanded(child: _body(_destination)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(AppDestination destination) {
    return switch (destination) {
      AppDestination.ceiling => const ProductKindCalculatorScreen(
        templateId: 'ceiling_full_set',
        title: 'Ceiling Calculator / គណនាពិដាន',
        subtitle: 'Calculate ceiling materials from Area (m² / ការ៉េ).',
        requiresArea: true,
      ),
      AppDestination.insulation => const ProductKindCalculatorScreen(
        templateId: 'insulation_only',
        title: 'Insulation Calculator / គណនាអ៊ីសូឡង់',
        subtitle:
            'Manual roll/box quantity. Insulation is not area-based by default.',
      ),
      AppDestination.led => const ProductKindCalculatorScreen(
        templateId: 'led_only',
        title: 'LED Calculator / គណនាអំពូល LED',
        subtitle: 'Manual LED quantity with unit, box, or box + loose selling.',
      ),
      AppDestination.wire => const ProductKindCalculatorScreen(
        templateId: 'wire_only',
        title: 'Wire Calculator / គណនាលួស',
        subtitle: 'Manual roll/package quantity for wire.',
      ),
      AppDestination.decoration => const ProductKindCalculatorScreen(
        templateId: 'decoration_only',
        title: 'Decoration Calculator / គណនាលម្អ',
        subtitle: 'Manual piece quantity for decoration products.',
      ),
      AppDestination.custom => const ProductKindCalculatorScreen(
        templateId: 'custom',
        title: 'Custom Calculator / គណនាផលិតផលផ្សេងៗ',
        subtitle: 'Select any product, quantity, and sell method.',
        customMode: true,
      ),
      AppDestination.products => const ProductsScreen(),
      AppDestination.prices => const PricesScreen(),
      AppDestination.packaging => const PackagingScreen(),
      AppDestination.productKinds => const ProductKindsScreen(),
      AppDestination.formulas => const FormulaRulesScreen(),
      AppDestination.unitsCategories => const UnitsCategoriesScreen(),
      AppDestination.appSettings => const AppSettingsScreen(),
    };
  }
}

class _DestinationMeta {
  const _DestinationMeta(this.title, this.subtitle);

  final String title;
  final String subtitle;
}

_DestinationMeta _meta(AppDestination destination) {
  return switch (destination) {
    AppDestination.ceiling => const _DestinationMeta(
      'Ceiling Calculator / គណនាពិដាន',
      'Area-based ceiling material calculation',
    ),
    AppDestination.insulation => const _DestinationMeta(
      'Insulation Calculator / គណនាអ៊ីសូឡង់',
      'Manual roll quantity calculator',
    ),
    AppDestination.led => const _DestinationMeta(
      'LED Calculator / គណនាអំពូល LED',
      'Manual LED piece or box calculator',
    ),
    AppDestination.wire => const _DestinationMeta(
      'Wire Calculator / គណនាលួស',
      'Manual wire roll/package calculator',
    ),
    AppDestination.decoration => const _DestinationMeta(
      'Decoration Calculator / គណនាលម្អ',
      'Manual decoration product calculator',
    ),
    AppDestination.custom => const _DestinationMeta(
      'Custom Calculator / គណនាផលិតផលផ្សេងៗ',
      'Any product with manual quantity and sell method',
    ),
    AppDestination.products => const _DestinationMeta(
      'Products',
      'Manage material/product master data',
    ),
    AppDestination.prices => const _DestinationMeta(
      'Prices',
      'Manage editable unit, box, wholesale, service, and manual prices',
    ),
    AppDestination.packaging => const _DestinationMeta(
      'Packaging',
      'Manage items per box and packaging notes',
    ),
    AppDestination.productKinds => const _DestinationMeta(
      'Product Kinds',
      'Configure calculator types and assigned products',
    ),
    AppDestination.formulas => const _DestinationMeta(
      'Formula Rules',
      'Available calculation formula rules',
    ),
    AppDestination.unitsCategories => const _DestinationMeta(
      'Units / Categories',
      'Manage units and product categories',
    ),
    AppDestination.appSettings => const _DestinationMeta(
      'App Settings',
      'Local calculator settings',
    ),
  };
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.destination, required this.onSelected});

  final AppDestination destination;
  final ValueChanged<AppDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF11141B),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Row(
                children: [
                  Icon(
                    Icons.construction_rounded,
                    color: Color(0xFF7C8CFF),
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Material Quote Pro',
                      style: TextStyle(
                        color: Color(0xFFF4F6FA),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _group('Calculator'),
                  _item(
                    Icons.grid_view_rounded,
                    'Ceiling',
                    AppDestination.ceiling,
                  ),
                  _item(
                    Icons.layers_rounded,
                    'Insulation',
                    AppDestination.insulation,
                  ),
                  _item(
                    Icons.lightbulb_outline_rounded,
                    'LED',
                    AppDestination.led,
                  ),
                  _item(Icons.cable_rounded, 'Wire', AppDestination.wire),
                  _item(
                    Icons.dashboard_customize_outlined,
                    'Decoration',
                    AppDestination.decoration,
                  ),
                  _item(Icons.tune_rounded, 'Custom', AppDestination.custom),
                  const SizedBox(height: 14),
                  _group('Data'),
                  _item(
                    Icons.inventory_2_outlined,
                    'Products',
                    AppDestination.products,
                  ),
                  _item(Icons.sell_outlined, 'Prices', AppDestination.prices),
                  _item(
                    Icons.all_inbox_outlined,
                    'Packaging',
                    AppDestination.packaging,
                  ),
                  _item(
                    Icons.category_outlined,
                    'Product Kinds',
                    AppDestination.productKinds,
                  ),
                  _item(
                    Icons.functions_rounded,
                    'Formula Rules',
                    AppDestination.formulas,
                  ),
                  _item(
                    Icons.straighten_rounded,
                    'Units / Categories',
                    AppDestination.unitsCategories,
                  ),
                  const SizedBox(height: 14),
                  _group('Settings'),
                  _item(
                    Icons.settings_outlined,
                    'App Settings',
                    AppDestination.appSettings,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, AppDestination value) {
    final active = destination == value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelected(value),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1D2440) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? const Color(0xFF2E3A67) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: active
                    ? const Color(0xFF7C8CFF)
                    : const Color(0xFFA8AFBF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFFF4F6FA)
                        : const Color(0xFFA8AFBF),
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2F3D))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFF4F6FA),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                Text(
                  subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA8AFBF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const _HeaderPill(icon: Icons.attach_money_rounded, label: 'USD'),
          const SizedBox(width: 8),
          const _HeaderPill(
            icon: Icons.inventory_2_outlined,
            label: 'Box + Loose Ready',
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181B24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFA8AFBF), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ProductKindCalculatorScreen extends StatefulWidget {
  const ProductKindCalculatorScreen({
    super.key,
    required this.templateId,
    required this.title,
    required this.subtitle,
    this.requiresArea = false,
    this.customMode = false,
  });

  final String templateId;
  final String title;
  final String subtitle;
  final bool requiresArea;
  final bool customMode;

  @override
  State<ProductKindCalculatorScreen> createState() =>
      _ProductKindCalculatorScreenState();
}

class _ProductKindCalculatorScreenState
    extends State<ProductKindCalculatorScreen> {
  final _areaController = TextEditingController(text: '100');
  final _discountAmountController = TextEditingController(text: '0');
  final _discountPercentController = TextEditingController(text: '0');
  final Map<String, TextEditingController> _quantityControllers = {};
  final Set<String> _selectedMaterialIds = {};
  final Map<String, String> _sellModeOverrides = {};
  late String _defaultSellModeId;
  String? _lastSignature;

  String get _initialSellModeId =>
      widget.requiresArea ? SellModeIds.boxPlusLoose : SellModeIds.unitOnly;

  @override
  void initState() {
    super.initState();
    _defaultSellModeId = _initialSellModeId;
    for (final controller in [
      _areaController,
      _discountAmountController,
      _discountPercentController,
    ]) {
      controller.addListener(_calculateSoon);
    }
  }

  @override
  void didUpdateWidget(covariant ProductKindCalculatorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.templateId != widget.templateId) {
      _selectedMaterialIds.clear();
      _sellModeOverrides.clear();
      _defaultSellModeId = _initialSellModeId;
      _lastSignature = null;
      _calculateSoon();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<AppState>();
    for (final material in state.materials) {
      _quantityControllers.putIfAbsent(material.id, () {
        final controller = TextEditingController();
        controller.addListener(_calculateSoon);
        return controller;
      });
    }
    final signature =
        '${widget.templateId}:${state.materials.length}:${state.prices.length}:${state.packagingRules.length}:${state.productTemplates.length}';
    if (_lastSignature != signature) {
      _lastSignature = signature;
      _calculateSoon();
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _discountAmountController.dispose();
    _discountPercentController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final template = _template(state);
    final result = state.liveResult;
    final selectable = _selectableMaterials(state, template);
    final manualMaterials = _manualMaterials(state, template);

    return _Page(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoCard(
            title: widget.title,
            subtitle: widget.subtitle,
            icon: widget.requiresArea
                ? Icons.square_foot_rounded
                : Icons.edit_note_rounded,
          ),
          const SizedBox(height: 14),
          _Card(
            title: 'Input Form',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.requiresArea)
                  SizedBox(
                    width: 230,
                    child: TextField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Area (m² / ការ៉េ)',
                      ),
                    ),
                  ),
                SizedBox(
                  width: 230,
                  child: DropdownButtonFormField<String>(
                    initialValue: _defaultSellModeId,
                    decoration: const InputDecoration(labelText: 'Sell Method'),
                    items: const [
                      DropdownMenuItem(
                        value: SellModeIds.unitOnly,
                        child: Text('Unit only'),
                      ),
                      DropdownMenuItem(
                        value: SellModeIds.boxOnlyRoundUp,
                        child: Text('Box only round up'),
                      ),
                      DropdownMenuItem(
                        value: SellModeIds.boxPlusLoose,
                        child: Text('Box + loose'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _defaultSellModeId = value;
                        _sellModeOverrides
                          ..clear()
                          ..addEntries(
                            _activeMaterialIds(
                              template,
                              state,
                            ).map((id) => MapEntry(id, value)),
                          );
                      });
                      _calculateSoon();
                    },
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: TextField(
                    controller: _discountAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Discount \$'),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: TextField(
                    controller: _discountPercentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Discount %'),
                  ),
                ),
                if (widget.requiresArea)
                  SizedBox(
                    width: 220,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: false,
                      onChanged: null,
                      title: const Text('Include Service / Labor'),
                      subtitle: const Text('Configure service item later'),
                    ),
                  ),
                FilledButton.icon(
                  onPressed: _calculateNow,
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: const Text('Calculate'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            title: widget.customMode
                ? 'Product Selector'
                : 'Product Selection / Optional Add-ons',
            child: selectable.isEmpty
                ? const Text('No selectable products configured.')
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: selectable.map((material) {
                      final selected = _selectedMaterialIds.contains(
                        material.id,
                      );
                      return FilterChip(
                        selected: selected,
                        label: Text(
                          '${material.khmerName} / ${material.englishName} ${material.spec}',
                        ),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _selectedMaterialIds.add(material.id);
                            } else {
                              _selectedMaterialIds.remove(material.id);
                              _sellModeOverrides.remove(material.id);
                            }
                          });
                          _calculateSoon();
                        },
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 14),
          _Card(
            title: 'Manual Quantity Inputs',
            child: manualMaterials.isEmpty
                ? const Text('No manual quantities required.')
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: manualMaterials.map((material) {
                      return SizedBox(
                        width: 260,
                        child: TextField(
                          controller: _quantityControllers[material.id],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                '${material.englishName} ${material.spec}',
                            suffixText: material.unitEnglish,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 14),
          _Card(
            title: 'Result Table',
            child: _ResultTable(
              result: result,
              onSellModeChanged: (materialId, sellModeId) {
                setState(() => _sellModeOverrides[materialId] = sellModeId);
                _calculateSoon();
              },
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 980;
              final pickList = _Card(
                title: 'Warehouse Pick-list',
                child: _PickListTable(result: result),
              );
              final totals = _Card(
                title: 'Totals / Copy Summary',
                child: _TotalsPanel(result: result),
              );
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: pickList),
                    const SizedBox(width: 14),
                    Expanded(child: totals),
                  ],
                );
              }
              return Column(
                children: [pickList, const SizedBox(height: 14), totals],
              );
            },
          ),
        ],
      ),
    );
  }

  ProductTypeTemplate? _template(AppState state) {
    return state.productTemplates
        .where((template) => template.id == widget.templateId)
        .firstOrNull;
  }

  List<String> _activeMaterialIds(
    ProductTypeTemplate? template,
    AppState state,
  ) {
    if (widget.customMode) {
      return _selectedMaterialIds.toList();
    }
    if (template == null) return const [];
    return [
      for (final rule in template.defaultMaterialRules)
        if (rule.includedByDefault ||
            _selectedMaterialIds.contains(rule.materialId))
          rule.materialId,
      ..._selectedMaterialIds.where(
        (id) =>
            !template.defaultMaterialRules.any((rule) => rule.materialId == id),
      ),
    ];
  }

  List<MaterialItem> _selectableMaterials(
    AppState state,
    ProductTypeTemplate? template,
  ) {
    if (widget.customMode) {
      return state.materials.where((material) => material.active).toList();
    }
    final ids = <String>{};
    for (final rule in template?.defaultMaterialRules ?? const []) {
      if (!rule.includedByDefault) ids.add(rule.materialId);
    }
    ids.addAll(state.optionalMaterials.map((material) => material.id));
    return state.materials
        .where((material) => material.active && ids.contains(material.id))
        .toList();
  }

  List<MaterialItem> _manualMaterials(
    AppState state,
    ProductTypeTemplate? template,
  ) {
    final ids = _activeMaterialIds(template, state).toSet();
    return state.materials.where((material) {
      if (!ids.contains(material.id)) return false;
      final rule = template?.defaultMaterialRules
          .where((rule) => rule.materialId == material.id)
          .firstOrNull;
      final formulaType = rule?.formulaTypeOverrideId ?? material.formulaTypeId;
      return formulaType == FormulaTypeIds.manualQuantity ||
          template?.inputModeId == InputModeIds.manualQuantity ||
          template?.inputModeId == InputModeIds.boxQuantity ||
          widget.customMode;
    }).toList();
  }

  void _calculateSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _calculateNow();
    });
  }

  void _calculateNow() {
    final state = context.read<AppState>();
    final template = _template(state);
    if (template == null) return;
    final manualQuantities = <String, double>{};
    for (final entry in _quantityControllers.entries) {
      final value = _parseDouble(entry.value.text);
      if (value != null) manualQuantities[entry.key] = value;
    }
    final selected = _selectedMaterialIds.toList();
    final sellOverrides = <String, String>{..._sellModeOverrides};
    for (final id in _activeMaterialIds(template, state)) {
      sellOverrides.putIfAbsent(id, () => _defaultSellModeId);
    }
    state.calculateLive(
      LiveCalculationInput(
        productTypeTemplateId: widget.templateId,
        areaM2: _parseDouble(_areaController.text),
        selectedOptionalMaterialIds: selected,
        manualQuantities: manualQuantities,
        sellModeOverrides: sellOverrides,
        discountAmount: _parseDouble(_discountAmountController.text) ?? 0,
        discountPercent: _parseDouble(_discountPercentController.text) ?? 0,
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0F14),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1380),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF4F6FA),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151821),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF202849),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF7C8CFF), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF4F6FA),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFA8AFBF),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({required this.result, required this.onSellModeChanged});

  final LiveCalculationResult? result;
  final void Function(String materialId, String sellModeId) onSellModeChanged;

  @override
  Widget build(BuildContext context) {
    if (result == null) return const Text('Calculation will appear here.');
    if (result!.validationErrors.isNotEmpty) {
      return _ErrorList(errors: result!.validationErrors);
    }
    if (result!.lines.isEmpty) return const Text('No result lines.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('No.')),
          DataColumn(label: Text('Material')),
          DataColumn(label: Text('Spec')),
          DataColumn(label: Text('Formula')),
          DataColumn(label: Text('Raw Qty')),
          DataColumn(label: Text('Sell Qty')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Per Box')),
          DataColumn(label: Text('Boxes')),
          DataColumn(label: Text('Loose')),
          DataColumn(label: Text('Sell Method')),
          DataColumn(label: Text('Unit Price')),
          DataColumn(label: Text('Box Price')),
          DataColumn(label: Text('Total')),
        ],
        rows: [
          for (var i = 0; i < result!.lines.length; i++)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(
                  Text(
                    '${result!.lines[i].khmerName} / ${result!.lines[i].englishName}',
                  ),
                ),
                DataCell(Text(result!.lines[i].spec)),
                DataCell(Text(result!.lines[i].formulaText)),
                DataCell(
                  Text(MoneyFormatter.decimal(result!.lines[i].rawQuantity)),
                ),
                DataCell(Text('${result!.lines[i].roundedQuantity}')),
                DataCell(Text(result!.lines[i].unitKhmer)),
                DataCell(Text(result!.lines[i].itemsPerBox?.toString() ?? '-')),
                DataCell(Text('${result!.lines[i].packagingFullBoxes}')),
                DataCell(Text('${result!.lines[i].packagingLooseItems}')),
                DataCell(
                  DropdownButton<String>(
                    value: result!.lines[i].sellModeId,
                    items: const [
                      DropdownMenuItem(
                        value: SellModeIds.unitOnly,
                        child: Text('Unit only'),
                      ),
                      DropdownMenuItem(
                        value: SellModeIds.boxOnlyRoundUp,
                        child: Text('Box round up'),
                      ),
                      DropdownMenuItem(
                        value: SellModeIds.boxPlusLoose,
                        child: Text('Box + loose'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        onSellModeChanged(result!.lines[i].materialId, value);
                      }
                    },
                  ),
                ),
                DataCell(Text(_moneyOrDash(result!.lines[i].unitPrice))),
                DataCell(Text(_moneyOrDash(result!.lines[i].boxPrice))),
                DataCell(
                  Text(MoneyFormatter.money(result!.lines[i].lineTotal)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PickListTable extends StatelessWidget {
  const _PickListTable({required this.result});

  final LiveCalculationResult? result;

  @override
  Widget build(BuildContext context) {
    if (result == null || result!.validationErrors.isNotEmpty) {
      return const Text('Pick-list appears after a valid calculation.');
    }
    final lines = result!.lines.where((line) => line.showInPickList).toList();
    if (lines.isEmpty) return const Text('No warehouse items.');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Material')),
          DataColumn(label: Text('Total Qty')),
          DataColumn(label: Text('Boxes')),
          DataColumn(label: Text('Loose')),
          DataColumn(label: Text('Unit')),
        ],
        rows: lines.map((line) {
          return DataRow(
            cells: [
              DataCell(Text('${line.khmerName} / ${line.englishName}')),
              DataCell(Text('${line.roundedQuantity}')),
              DataCell(Text('${line.packagingFullBoxes}')),
              DataCell(Text('${line.packagingLooseItems}')),
              DataCell(Text(line.unitKhmer)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({required this.result});

  final LiveCalculationResult? result;

  @override
  Widget build(BuildContext context) {
    final valid = result != null && result!.validationErrors.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _totalRow('Product Type Total', result?.subtotal ?? 0),
        _totalRow('Discount', -(result?.discountTotal ?? 0)),
        const Divider(color: Color(0xFF2A2F3D)),
        _totalRow('Grand Total', result?.grandTotal ?? 0, strong: true),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: valid
              ? () {
                  Clipboard.setData(ClipboardData(text: _summary(result!)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Summary copied.')),
                  );
                }
              : null,
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy Summary'),
        ),
      ],
    );
  }

  Widget _totalRow(String label, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFFA8AFBF),
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            MoneyFormatter.money(value),
            style: TextStyle(
              color: strong ? const Color(0xFFF4F6FA) : const Color(0xFFA8AFBF),
              fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _summary(LiveCalculationResult result) {
    final buffer = StringBuffer()
      ..writeln('${result.productTypeNameEnglish} Calculation')
      ..writeln()
      ..writeln('Materials:');
    for (var i = 0; i < result.lines.length; i++) {
      final line = result.lines[i];
      buffer.writeln(
        '${i + 1}. ${line.khmerName} ${line.spec}: ${line.roundedQuantity} ${line.unitKhmer} = ${line.packagingFullBoxes} កេស + ${line.packagingLooseItems} ${line.unitKhmer}',
      );
    }
    buffer.writeln();
    buffer.writeln('Total: ${MoneyFormatter.money(result.grandTotal)}');
    return buffer.toString();
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: errors
          .map(
            (error) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '• $error',
                style: const TextStyle(color: Color(0xFFFCA5A5)),
              ),
            ),
          )
          .toList(),
    );
  }
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _Page(
      child: _Card(
        title: 'Products',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openProductDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Product'),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Spec')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Unit')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Optional')),
                  DataColumn(label: Text('Service')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: state.materials.map((material) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text('${material.khmerName} / ${material.englishName}'),
                      ),
                      DataCell(Text(material.spec)),
                      DataCell(Text(material.categoryEnglish)),
                      DataCell(Text(material.unitEnglish)),
                      DataCell(Text(material.active ? 'Yes' : 'No')),
                      DataCell(Text(material.isOptionalAddon ? 'Yes' : 'No')),
                      DataCell(Text(material.isServiceOnly ? 'Yes' : 'No')),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openProductDialog(
                                context,
                                material: material,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Deactivate',
                              icon: const Icon(Icons.visibility_off_outlined),
                              onPressed: material.active
                                  ? () => context
                                        .read<AppState>()
                                        .deactivateMaterial(material.id)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PricesScreen extends StatelessWidget {
  const PricesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final materialById = {for (final item in state.materials) item.id: item};
    return _Page(
      child: _Card(
        title: 'Prices',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openPriceDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Price'),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Price Type')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Currency')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Effective From')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: state.prices.map((price) {
                  final material = materialById[price.materialId];
                  return DataRow(
                    cells: [
                      DataCell(Text(material?.englishName ?? price.materialId)),
                      DataCell(Text(price.priceTypeId)),
                      DataCell(Text(MoneyFormatter.money(price.price))),
                      DataCell(Text(price.currencyCode)),
                      DataCell(Text(price.active ? 'Yes' : 'No')),
                      DataCell(Text(_date(price.effectiveFrom))),
                      DataCell(
                        IconButton(
                          tooltip: 'Edit price',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _openPriceDialog(context, price: price),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackagingScreen extends StatelessWidget {
  const PackagingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final materialById = {for (final item in state.materials) item.id: item};
    return _Page(
      child: _Card(
        title: 'Packaging',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openPackagingDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Packaging'),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Items per Box')),
                  DataColumn(label: Text('Size')),
                  DataColumn(label: Text('Length')),
                  DataColumn(label: Text('Note')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: state.packagingRules.map((rule) {
                  final material = materialById[rule.materialId];
                  return DataRow(
                    cells: [
                      DataCell(Text(material?.englishName ?? rule.materialId)),
                      DataCell(Text('${rule.itemsPerBox}')),
                      DataCell(Text(rule.size)),
                      DataCell(Text(rule.length)),
                      DataCell(Text(rule.note)),
                      DataCell(
                        IconButton(
                          tooltip: 'Edit packaging',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _openPackagingDialog(context, rule: rule),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductKindsScreen extends StatelessWidget {
  const ProductKindsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _Page(
      child: _Card(
        title: 'Product Kinds',
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Input Mode')),
              DataColumn(label: Text('Active')),
              DataColumn(label: Text('Default')),
              DataColumn(label: Text('Products')),
              DataColumn(label: Text('Actions')),
            ],
            rows: state.productTemplates.map((template) {
              return DataRow(
                cells: [
                  DataCell(Text(template.label)),
                  DataCell(Text(template.inputModeId)),
                  DataCell(Text(template.active ? 'Yes' : 'No')),
                  DataCell(Text(template.isDefault ? 'Yes' : 'No')),
                  DataCell(Text('${template.defaultMaterialRules.length}')),
                  DataCell(
                    IconButton(
                      tooltip: 'Edit product kind',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          _openProductKindDialog(context, template),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class FormulaRulesScreen extends StatelessWidget {
  const FormulaRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _Page(
      child: _Card(
        title: 'Formula Rules',
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Formula ID')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Active')),
            ],
            rows: state.formulaRules.map((rule) {
              return DataRow(
                cells: [
                  DataCell(Text(rule.formulaTypeId)),
                  DataCell(Text(rule.label)),
                  DataCell(Text(rule.description)),
                  DataCell(Text(rule.active ? 'Yes' : 'No')),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class UnitsCategoriesScreen extends StatelessWidget {
  const UnitsCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _Page(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 900;
          final units = _Card(
            title: 'Units',
            child: _SimpleCatalogList(
              rows: state.units
                  .map((unit) => _CatalogRow(unit.id, unit.label, unit.active))
                  .toList(),
              onAdd: () => _openUnitDialog(context),
            ),
          );
          final categories = _Card(
            title: 'Categories',
            child: _SimpleCatalogList(
              rows: state.categories
                  .map(
                    (category) => _CatalogRow(
                      category.id,
                      category.label,
                      category.active,
                    ),
                  )
                  .toList(),
              onAdd: () => _openCategoryDialog(context),
            ),
          );
          if (!wide) {
            return Column(
              children: [units, const SizedBox(height: 14), categories],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: units),
              const SizedBox(width: 14),
              Expanded(child: categories),
            ],
          );
        },
      ),
    );
  }
}

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Page(
      child: _Card(
        title: 'App Settings',
        child: Text(
          'Local-only calculator MVP. Invoice saving, PDF export, customers, and cloud sync are intentionally not included yet.',
        ),
      ),
    );
  }
}

class _CatalogRow {
  const _CatalogRow(this.id, this.label, this.active);

  final String id;
  final String label;
  final bool active;
}

class _SimpleCatalogList extends StatelessWidget {
  const _SimpleCatalogList({required this.rows, required this.onAdd});

  final List<_CatalogRow> rows;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add'),
        ),
        const SizedBox(height: 10),
        ...rows.map(
          (row) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(row.label),
            subtitle: Text(row.id),
            trailing: Text(row.active ? 'Active' : 'Inactive'),
          ),
        ),
      ],
    );
  }
}

Future<void> _openProductDialog(
  BuildContext context, {
  MaterialItem? material,
}) async {
  final state = context.read<AppState>();
  final saved = await showDialog<MaterialItem>(
    context: context,
    builder: (_) => _ProductDialog(
      material: material,
      units: state.units,
      categories: state.categories,
      nextSortOrder: state.materials.length + 1,
    ),
  );
  if (saved != null && context.mounted) {
    await context.read<AppState>().saveMaterial(saved);
  }
}

Future<void> _openPriceDialog(
  BuildContext context, {
  MaterialPrice? price,
}) async {
  final state = context.read<AppState>();
  final saved = await showDialog<MaterialPrice>(
    context: context,
    builder: (_) => _PriceDialog(price: price, materials: state.materials),
  );
  if (saved != null && context.mounted) {
    await context.read<AppState>().savePrice(saved);
  }
}

Future<void> _openPackagingDialog(
  BuildContext context, {
  PackagingRule? rule,
}) async {
  final state = context.read<AppState>();
  final saved = await showDialog<PackagingRule>(
    context: context,
    builder: (_) => _PackagingDialog(rule: rule, materials: state.materials),
  );
  if (saved != null && context.mounted) {
    await context.read<AppState>().savePackagingRule(saved);
  }
}

Future<void> _openProductKindDialog(
  BuildContext context,
  ProductTypeTemplate template,
) async {
  final state = context.read<AppState>();
  final saved = await showDialog<ProductTypeTemplate>(
    context: context,
    builder: (_) =>
        _ProductKindDialog(template: template, materials: state.materials),
  );
  if (saved != null && context.mounted) {
    await context.read<AppState>().saveProductTemplate(saved);
  }
}

Future<void> _openUnitDialog(BuildContext context) async {
  final state = context.read<AppState>();
  final saved = await showDialog<UnitOfMeasure>(
    context: context,
    builder: (_) => _UnitDialog(nextSortOrder: state.units.length + 1),
  );
  if (saved != null && context.mounted) {
    await context.read<AppState>().saveUnit(saved);
  }
}

Future<void> _openCategoryDialog(BuildContext context) async {
  final state = context.read<AppState>();
  final saved = await showDialog<MaterialCategory>(
    context: context,
    builder: (_) => _CategoryDialog(nextSortOrder: state.categories.length + 1),
  );
  if (saved != null && context.mounted) {
    await context.read<AppState>().saveCategory(saved);
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({
    required this.units,
    required this.categories,
    required this.nextSortOrder,
    this.material,
  });

  final MaterialItem? material;
  final List<UnitOfMeasure> units;
  final List<MaterialCategory> categories;
  final int nextSortOrder;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _khmer;
  late final TextEditingController _english;
  late final TextEditingController _spec;
  late final TextEditingController _sort;
  late String _unitId;
  late String _categoryId;
  bool _active = true;
  bool _optional = false;
  bool _service = false;
  bool _showCalculator = true;
  bool _showPickList = true;

  @override
  void initState() {
    super.initState();
    final material = widget.material;
    _khmer = TextEditingController(text: material?.khmerName ?? '');
    _english = TextEditingController(text: material?.englishName ?? '');
    _spec = TextEditingController(text: material?.spec ?? '');
    _sort = TextEditingController(
      text: '${material?.sortOrder ?? widget.nextSortOrder}',
    );
    _unitId = material?.unitId ?? widget.units.first.id;
    _categoryId = material?.categoryId ?? widget.categories.first.id;
    _active = material?.active ?? true;
    _optional = material?.isOptionalAddon ?? false;
    _service = material?.isServiceOnly ?? false;
    _showCalculator = material?.showInCustomerQuote ?? true;
    _showPickList = material?.showInPickList ?? true;
  }

  @override
  void dispose() {
    _khmer.dispose();
    _english.dispose();
    _spec.dispose();
    _sort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.material == null ? 'Add Product' : 'Edit Product'),
      content: SizedBox(
        width: 680,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _dialogField(_khmer, 'Khmer Name'),
              _dialogField(_english, 'English Name'),
              _dialogField(_spec, 'Spec'),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  initialValue: _unitId,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: widget.units
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit.id,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _unitId = value ?? _unitId),
                ),
              ),
              SizedBox(
                width: 230,
                child: DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _categoryId = value ?? _categoryId),
                ),
              ),
              _dialogField(_sort, 'Sort Order', number: true),
              _dialogSwitch(
                'Active',
                _active,
                (v) => setState(() => _active = v),
              ),
              _dialogSwitch(
                'Optional Add-on',
                _optional,
                (v) => setState(() => _optional = v),
              ),
              _dialogSwitch(
                'Service Only',
                _service,
                (v) => setState(() => _service = v),
              ),
              _dialogSwitch(
                'Show in Calculator',
                _showCalculator,
                (v) => setState(() => _showCalculator = v),
              ),
              _dialogSwitch(
                'Show in Pick-list',
                _showPickList,
                (v) => setState(() => _showPickList = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    final now = DateTime.now();
    final unit = widget.units.firstWhere((unit) => unit.id == _unitId);
    final category = widget.categories.firstWhere(
      (cat) => cat.id == _categoryId,
    );
    final original = widget.material;
    Navigator.pop(
      context,
      MaterialItem(
        id: original?.id ?? _slug(_english.text, 'product'),
        khmerName: _khmer.text.trim(),
        englishName: _english.text.trim(),
        spec: _spec.text.trim(),
        unitId: unit.id,
        unitKhmer: unit.nameKhmer,
        unitEnglish: unit.nameEnglish,
        categoryId: category.id,
        categoryKhmer: category.nameKhmer,
        categoryEnglish: category.nameEnglish,
        formulaTypeId: original?.formulaTypeId ?? FormulaTypeIds.manualQuantity,
        coverageValue: original?.coverageValue,
        multiplierValue: original?.multiplierValue,
        fixedQuantity: original?.fixedQuantity,
        itemsPerBox: original?.itemsPerBox,
        active: _active,
        includedByDefault: original?.includedByDefault ?? false,
        showInCustomerQuote: _showCalculator,
        showInPickList: _showPickList,
        isOptionalAddon: _optional,
        isServiceOnly: _service,
        sortOrder: int.tryParse(_sort.text) ?? widget.nextSortOrder,
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }
}

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({required this.materials, this.price});

  final MaterialPrice? price;
  final List<MaterialItem> materials;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late String _materialId;
  late String _priceTypeId;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _materialId = widget.price?.materialId ?? widget.materials.first.id;
    _priceTypeId = widget.price?.priceTypeId ?? PriceTypeIds.unitPrice;
    _price = TextEditingController(
      text: widget.price?.price.toStringAsFixed(2) ?? '0.00',
    );
    _currency = TextEditingController(
      text: widget.price?.currencyCode ?? 'USD',
    );
    _active = widget.price?.active ?? true;
  }

  @override
  void dispose() {
    _price.dispose();
    _currency.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.price == null ? 'Add Price' : 'Edit Price'),
      content: SizedBox(
        width: 520,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 250,
              child: DropdownButtonFormField<String>(
                initialValue: _materialId,
                decoration: const InputDecoration(labelText: 'Product'),
                items: widget.materials
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.englishName),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _materialId = v ?? _materialId),
              ),
            ),
            SizedBox(
              width: 230,
              child: DropdownButtonFormField<String>(
                initialValue: _priceTypeId,
                decoration: const InputDecoration(labelText: 'Price Type'),
                items: PriceTypeIds.editableDefaults
                    .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _priceTypeId = v ?? _priceTypeId),
              ),
            ),
            _dialogField(_price, 'Price', number: true),
            _dialogField(_currency, 'Currency'),
            _dialogSwitch(
              'Active',
              _active,
              (v) => setState(() => _active = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    final now = DateTime.now();
    final original = widget.price;
    Navigator.pop(
      context,
      MaterialPrice(
        id:
            original?.id ??
            '${_materialId}_${_priceTypeId}_${now.microsecondsSinceEpoch}',
        materialId: _materialId,
        priceTypeId: _priceTypeId,
        price: _parseDouble(_price.text) ?? 0,
        currencyCode: _currency.text.trim().isEmpty
            ? 'USD'
            : _currency.text.trim(),
        effectiveFrom: original?.effectiveFrom ?? now,
        effectiveTo: original?.effectiveTo,
        active: _active,
        createdAt: original?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }
}

class _PackagingDialog extends StatefulWidget {
  const _PackagingDialog({required this.materials, this.rule});

  final PackagingRule? rule;
  final List<MaterialItem> materials;

  @override
  State<_PackagingDialog> createState() => _PackagingDialogState();
}

class _PackagingDialogState extends State<_PackagingDialog> {
  late String _materialId;
  late final TextEditingController _items;
  late final TextEditingController _size;
  late final TextEditingController _length;
  late final TextEditingController _note;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _materialId = widget.rule?.materialId ?? widget.materials.first.id;
    _items = TextEditingController(text: '${widget.rule?.itemsPerBox ?? 1}');
    _size = TextEditingController(text: widget.rule?.size ?? '');
    _length = TextEditingController(text: widget.rule?.length ?? '');
    _note = TextEditingController(text: widget.rule?.note ?? '');
    _active = widget.rule?.active ?? true;
  }

  @override
  void dispose() {
    _items.dispose();
    _size.dispose();
    _length.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule == null ? 'Add Packaging' : 'Edit Packaging'),
      content: SizedBox(
        width: 560,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: _materialId,
                decoration: const InputDecoration(labelText: 'Product'),
                items: widget.materials
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text(m.englishName),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _materialId = v ?? _materialId),
              ),
            ),
            _dialogField(_items, 'Items per Box', number: true),
            _dialogField(_size, 'Size'),
            _dialogField(_length, 'Length'),
            _dialogField(_note, 'Note'),
            _dialogSwitch(
              'Active',
              _active,
              (v) => setState(() => _active = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _save() {
    final now = DateTime.now();
    Navigator.pop(
      context,
      PackagingRule(
        id: widget.rule?.id ?? 'packaging_$_materialId',
        materialId: _materialId,
        itemsPerBox: int.tryParse(_items.text) ?? 1,
        boxUnitNameKhmer: widget.rule?.boxUnitNameKhmer ?? 'កេស',
        boxUnitNameEnglish: widget.rule?.boxUnitNameEnglish ?? 'Box',
        size: _size.text.trim(),
        length: _length.text.trim(),
        note: _note.text.trim(),
        active: _active,
        updatedAt: now,
      ),
    );
  }
}

class _ProductKindDialog extends StatefulWidget {
  const _ProductKindDialog({required this.template, required this.materials});

  final ProductTypeTemplate template;
  final List<MaterialItem> materials;

  @override
  State<_ProductKindDialog> createState() => _ProductKindDialogState();
}

class _ProductKindDialogState extends State<_ProductKindDialog> {
  late final TextEditingController _khmer;
  late final TextEditingController _english;
  late final TextEditingController _sort;
  late String _inputModeId;
  late bool _active;
  late bool _default;
  late List<ProductTemplateMaterialRule> _rules;

  @override
  void initState() {
    super.initState();
    _khmer = TextEditingController(text: widget.template.nameKhmer);
    _english = TextEditingController(text: widget.template.nameEnglish);
    _sort = TextEditingController(text: '${widget.template.sortOrder}');
    _inputModeId = widget.template.inputModeId;
    _active = widget.template.active;
    _default = widget.template.isDefault;
    _rules = [...widget.template.defaultMaterialRules];
  }

  @override
  void dispose() {
    _khmer.dispose();
    _english.dispose();
    _sort.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Product Kind'),
      content: SizedBox(
        width: 780,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _dialogField(_khmer, 'Name Khmer'),
                  _dialogField(_english, 'Name English'),
                  SizedBox(
                    width: 230,
                    child: DropdownButtonFormField<String>(
                      initialValue: _inputModeId,
                      decoration: const InputDecoration(
                        labelText: 'Input Mode',
                      ),
                      items: InputModeIds.supportedNow
                          .map(
                            (id) =>
                                DropdownMenuItem(value: id, child: Text(id)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _inputModeId = v ?? _inputModeId),
                    ),
                  ),
                  _dialogField(_sort, 'Sort Order', number: true),
                  _dialogSwitch(
                    'Active',
                    _active,
                    (v) => setState(() => _active = v),
                  ),
                  _dialogSwitch(
                    'Default',
                    _default,
                    (v) => setState(() => _default = v),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Assigned Products',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...widget.materials.map((material) {
                final rule = _rules
                    .where((r) => r.materialId == material.id)
                    .firstOrNull;
                final selected = rule != null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2A2F3D)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: selected,
                        title: Text(
                          '${material.khmerName} / ${material.englishName} ${material.spec}',
                        ),
                        subtitle: selected
                            ? Text(
                                '${rule.defaultSellModeId} • ${rule.formulaTypeOverrideId ?? material.formulaTypeId}',
                              )
                            : null,
                        onChanged: (value) {
                          setState(() {
                            if (value == true && rule == null) {
                              _rules.add(
                                ProductTemplateMaterialRule(
                                  materialId: material.id,
                                  includedByDefault: false,
                                  allowManualOverride: true,
                                  formulaTypeOverrideId: material.formulaTypeId,
                                  coverageValueOverride: material.coverageValue,
                                  multiplierValueOverride:
                                      material.multiplierValue,
                                  fixedQuantityOverride: material.fixedQuantity,
                                  defaultSellModeId: SellModeIds.unitOnly,
                                ),
                              );
                            } else if (value == false) {
                              _rules.removeWhere(
                                (r) => r.materialId == material.id,
                              );
                            }
                          });
                        },
                      ),
                      if (rule != null)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            SizedBox(
                              width: 190,
                              child: DropdownButtonFormField<String>(
                                initialValue:
                                    rule.formulaTypeOverrideId ??
                                    material.formulaTypeId,
                                decoration: const InputDecoration(
                                  labelText: 'Formula Type',
                                ),
                                items: FormulaTypeIds.supportedNow
                                    .map(
                                      (id) => DropdownMenuItem(
                                        value: id,
                                        child: Text(id),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => _updateRule(
                                  material.id,
                                  rule.copyWith(formulaTypeOverrideId: value),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                initialValue: rule.defaultSellModeId,
                                decoration: const InputDecoration(
                                  labelText: 'Default Sell Method',
                                ),
                                items: SellModeIds.supportedNow
                                    .map(
                                      (id) => DropdownMenuItem(
                                        value: id,
                                        child: Text(id),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => _updateRule(
                                  material.id,
                                  rule.copyWith(defaultSellModeId: value),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 190,
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: rule.includedByDefault,
                                title: const Text('Included by default'),
                                onChanged: (value) => _updateRule(
                                  material.id,
                                  rule.copyWith(includedByDefault: value),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _updateRule(String materialId, ProductTemplateMaterialRule next) {
    setState(() {
      final index = _rules.indexWhere((rule) => rule.materialId == materialId);
      if (index >= 0) _rules[index] = next;
    });
  }

  void _save() {
    Navigator.pop(
      context,
      widget.template.copyWith(
        nameKhmer: _khmer.text.trim(),
        nameEnglish: _english.text.trim(),
        inputModeId: _inputModeId,
        active: _active,
        isDefault: _default,
        defaultMaterialRules: _rules,
        sortOrder: int.tryParse(_sort.text) ?? widget.template.sortOrder,
      ),
    );
  }
}

class _UnitDialog extends StatefulWidget {
  const _UnitDialog({required this.nextSortOrder});

  final int nextSortOrder;

  @override
  State<_UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<_UnitDialog> {
  final _id = TextEditingController();
  final _khmer = TextEditingController();
  final _english = TextEditingController();
  final _abbrKhmer = TextEditingController();
  final _abbrEnglish = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _khmer.dispose();
    _english.dispose();
    _abbrKhmer.dispose();
    _abbrEnglish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Unit'),
      content: SizedBox(
        width: 480,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _dialogField(_id, 'ID'),
            _dialogField(_khmer, 'Name Khmer'),
            _dialogField(_english, 'Name English'),
            _dialogField(_abbrKhmer, 'Abbr Khmer'),
            _dialogField(_abbrEnglish, 'Abbr English'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              UnitOfMeasure(
                id: _id.text.trim().isEmpty
                    ? _slug(_english.text, 'unit')
                    : _id.text.trim(),
                nameKhmer: _khmer.text.trim(),
                nameEnglish: _english.text.trim(),
                abbreviationKhmer: _abbrKhmer.text.trim(),
                abbreviationEnglish: _abbrEnglish.text.trim(),
                active: true,
                sortOrder: widget.nextSortOrder,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.nextSortOrder});

  final int nextSortOrder;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _id = TextEditingController();
  final _khmer = TextEditingController();
  final _english = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _khmer.dispose();
    _english.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Category'),
      content: SizedBox(
        width: 480,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _dialogField(_id, 'ID'),
            _dialogField(_khmer, 'Name Khmer'),
            _dialogField(_english, 'Name English'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              MaterialCategory(
                id: _id.text.trim().isEmpty
                    ? _slug(_english.text, 'category')
                    : _id.text.trim(),
                nameKhmer: _khmer.text.trim(),
                nameEnglish: _english.text.trim(),
                active: true,
                sortOrder: widget.nextSortOrder,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Widget _dialogField(
  TextEditingController controller,
  String label, {
  bool number = false,
}) {
  return SizedBox(
    width: 210,
    child: TextField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

Widget _dialogSwitch(String label, bool value, ValueChanged<bool> onChanged) {
  return SizedBox(
    width: 210,
    child: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(label),
      onChanged: onChanged,
    ),
  );
}

double? _parseDouble(String value) {
  final trimmed = value.replaceAll(',', '').trim();
  if (trimmed.isEmpty) return null;
  return double.tryParse(trimmed);
}

String _moneyOrDash(double? value) {
  return value == null ? '-' : MoneyFormatter.money(value);
}

String _date(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _slug(String value, String prefix) {
  final cleaned = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return cleaned.isEmpty
      ? '${prefix}_${DateTime.now().microsecondsSinceEpoch}'
      : cleaned;
}
