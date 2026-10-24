import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../core/constants/business_ids.dart';
import '../../../core/utils/money_formatter.dart';
import '../data/models/material_item.dart';
import '../data/models/material_price.dart';
import '../data/models/product_type_template.dart';
import '../domain/live_calculation_models.dart';

class LiveCalculatorScreen extends StatefulWidget {
  const LiveCalculatorScreen({super.key});

  @override
  State<LiveCalculatorScreen> createState() => _LiveCalculatorScreenState();
}

class _LiveCalculatorScreenState extends State<LiveCalculatorScreen> {
  final _areaController = TextEditingController(text: '100');
  final _discountAmountController = TextEditingController(text: '0');
  final _discountPercentController = TextEditingController(text: '0');
  final Map<String, TextEditingController> _manualControllers = {};
  final Set<String> _selectedMaterialIds = {};
  final Map<String, String> _sellModeOverrides = {};
  String? _productTypeId;
  String? _lastDataSignature;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _areaController,
      _discountAmountController,
      _discountPercentController,
    ]) {
      controller.addListener(_scheduleCalculate);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<AppState>();
    _productTypeId ??= state.defaultProductTemplate?.id;
    _syncManualControllers(state);
    final signature =
        '${state.materials.length}:${state.prices.length}:${state.productTemplates.length}:${state.sellModes.length}:$_productTypeId';
    if (signature != _lastDataSignature) {
      _lastDataSignature = signature;
      _scheduleCalculate();
    }
  }

  @override
  void dispose() {
    _areaController.dispose();
    _discountAmountController.dispose();
    _discountPercentController.dispose();
    for (final controller in _manualControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final selectedTemplate = _selectedTemplate(state);
    final selectableMaterials = _selectableMaterials(state, selectedTemplate);
    final result = state.liveResult;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Material Calculator'),
        actions: [
          IconButton(
            tooltip: 'Reload saved settings',
            onPressed: state.reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: '1. Calculator Controls',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: DropdownButtonFormField<String>(
                    initialValue: _productTypeId,
                    decoration: const InputDecoration(
                      labelText: 'Product Type / ប្រភេទផលិតផល',
                    ),
                    items: state.productTemplates
                        .where((template) => template.active)
                        .map(
                          (template) => DropdownMenuItem(
                            value: template.id,
                            child: Text(template.label),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _productTypeId = value;
                        _selectedMaterialIds.clear();
                        _sellModeOverrides.clear();
                      });
                      _scheduleCalculate();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
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
                  width: 190,
                  child: TextField(
                    controller: _discountAmountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Discount \$'),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: TextField(
                    controller: _discountPercentController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Discount %'),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _calculateNow,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calculate'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '2. Product Type Selector',
            child: selectedTemplate == null
                ? const Text('No active product template is configured.')
                : Text(
                    '${selectedTemplate.label}\nInput mode: ${selectedTemplate.inputModeId}',
                  ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '3. Optional Add-ons / Selectable Products',
            child: selectableMaterials.isEmpty
                ? const Text('No optional products for this selection.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectableMaterials.map((material) {
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
                            }
                          });
                          _scheduleCalculate();
                        },
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '4. Manual Quantity Inputs',
            child: _manualInputMaterials(state, selectedTemplate).isEmpty
                ? const Text(
                    'No manual quantities required for current selection.',
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _manualInputMaterials(state, selectedTemplate)
                        .map(
                          (material) => SizedBox(
                            width: 260,
                            child: TextField(
                              controller: _manualControllers[material.id],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText:
                                    '${material.englishName} ${material.spec}',
                                suffixText: material.unitEnglish,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '5. Customer Price Result',
            child: _ResultTable(
              result: result,
              sellModes: state.sellModes.map((mode) => mode.id).toList(),
              sellModeOverrides: _sellModeOverrides,
              onSellModeChanged: (materialId, sellModeId) {
                setState(() => _sellModeOverrides[materialId] = sellModeId);
                _scheduleCalculate();
              },
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '6. Warehouse / Pick-list Summary',
            child: _PickListTable(result: result),
          ),
          const SizedBox(height: 12),
          _Section(
            title: '7. Totals / Copy Summary',
            child: _TotalsAndCopy(result: result),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Settings: Product Defaults / Templates',
            child: _ProductTemplateEditor(
              materials: state.materials,
              templates: state.productTemplates,
              onSave: state.saveProductTemplate,
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Settings: Material Prices',
            child: _PriceEditor(
              materials: state.materials,
              prices: state.prices,
              onSave: state.savePrice,
            ),
          ),
        ],
      ),
    );
  }

  ProductTypeTemplate? _selectedTemplate(AppState state) {
    return state.productTemplates
        .where((template) => template.id == _productTypeId)
        .firstOrNull;
  }

  List<MaterialItem> _selectableMaterials(
    AppState state,
    ProductTypeTemplate? template,
  ) {
    final ids = <String>{};
    if (template != null) {
      for (final rule in template.defaultMaterialRules) {
        if (!rule.includedByDefault) {
          ids.add(rule.materialId);
        }
      }
    }
    ids.addAll(state.optionalMaterials.map((material) => material.id));
    return state.materials
        .where((material) => material.active && ids.contains(material.id))
        .toList();
  }

  List<MaterialItem> _manualInputMaterials(
    AppState state,
    ProductTypeTemplate? template,
  ) {
    if (template == null) {
      return const [];
    }
    final ruleById = {
      for (final rule in template.defaultMaterialRules) rule.materialId: rule,
    };
    final includedIds = <String>{
      for (final rule in template.defaultMaterialRules)
        if (rule.includedByDefault ||
            _selectedMaterialIds.contains(rule.materialId))
          rule.materialId,
      ..._selectedMaterialIds,
    };
    return state.materials.where((material) {
      if (!includedIds.contains(material.id)) {
        return false;
      }
      final rule = ruleById[material.id];
      final formulaType = rule?.formulaTypeOverrideId ?? material.formulaTypeId;
      return formulaType == FormulaTypeIds.manualQuantity ||
          template.inputModeId == InputModeIds.manualQuantity ||
          template.inputModeId == InputModeIds.boxQuantity;
    }).toList();
  }

  void _syncManualControllers(AppState state) {
    for (final material in state.materials) {
      _manualControllers.putIfAbsent(material.id, () {
        final controller = TextEditingController();
        controller.addListener(_scheduleCalculate);
        return controller;
      });
    }
  }

  void _scheduleCalculate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _calculateNow();
      }
    });
  }

  void _calculateNow() {
    final state = context.read<AppState>();
    final manualQuantities = <String, double>{};
    for (final entry in _manualControllers.entries) {
      final value = _parseDouble(entry.value.text);
      if (value != null) {
        manualQuantities[entry.key] = value;
      }
    }
    state.calculateLive(
      LiveCalculationInput(
        productTypeTemplateId: _productTypeId ?? '',
        areaM2: _parseDouble(_areaController.text),
        selectedOptionalMaterialIds: _selectedMaterialIds.toList(),
        manualQuantities: manualQuantities,
        sellModeOverrides: Map<String, String>.from(_sellModeOverrides),
        discountAmount: _parseDouble(_discountAmountController.text) ?? 0,
        discountPercent: _parseDouble(_discountPercentController.text) ?? 0,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResultTable extends StatelessWidget {
  const _ResultTable({
    required this.result,
    required this.sellModes,
    required this.sellModeOverrides,
    required this.onSellModeChanged,
  });

  final LiveCalculationResult? result;
  final List<String> sellModes;
  final Map<String, String> sellModeOverrides;
  final void Function(String materialId, String sellModeId) onSellModeChanged;

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const Text('Waiting for calculator settings.');
    }
    if (result!.validationErrors.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: result!.validationErrors
            .map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            )
            .toList(),
      );
    }
    if (result!.lines.isEmpty) {
      return const Text('No calculated lines.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('No.')),
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Spec')),
          DataColumn(label: Text('Formula')),
          DataColumn(label: Text('Raw Qty')),
          DataColumn(label: Text('Rounded Qty')),
          DataColumn(label: Text('Unit')),
          DataColumn(label: Text('Per Box')),
          DataColumn(label: Text('Full Boxes')),
          DataColumn(label: Text('Loose Items')),
          DataColumn(label: Text('Sell Mode')),
          DataColumn(label: Text('Unit Price')),
          DataColumn(label: Text('Box Price')),
          DataColumn(label: Text('Charged Qty')),
          DataColumn(label: Text('Line Total')),
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
                    value:
                        sellModeOverrides[result!.lines[i].materialId] ??
                        result!.lines[i].sellModeId,
                    items: sellModes
                        .map(
                          (mode) =>
                              DropdownMenuItem(value: mode, child: Text(mode)),
                        )
                        .toList(),
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
                  Text(result!.lines[i].chargedBoxes?.toString() ?? '-'),
                ),
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
    final lines =
        result?.lines.where((line) => line.showInPickList).toList() ?? const [];
    if (result == null || result!.validationErrors.isNotEmpty) {
      return const Text('Pick-list appears after a valid calculation.');
    }
    if (lines.isEmpty) {
      return const Text('No warehouse items for this calculation.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Product')),
          DataColumn(label: Text('Total Qty')),
          DataColumn(label: Text('Full Boxes')),
          DataColumn(label: Text('Loose Items')),
          DataColumn(label: Text('Unit')),
        ],
        rows: lines.map((line) {
          return DataRow(
            cells: [
              DataCell(Text('${line.khmerName} / ${line.englishName}')),
              DataCell(Text('${line.roundedQuantity} ${line.unitKhmer}')),
              DataCell(Text('${line.packagingFullBoxes} កេស')),
              DataCell(Text('${line.packagingLooseItems} ${line.unitKhmer}')),
              DataCell(Text(line.unitEnglish)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _TotalsAndCopy extends StatelessWidget {
  const _TotalsAndCopy({required this.result});

  final LiveCalculationResult? result;

  @override
  Widget build(BuildContext context) {
    final hasResult = result != null && !result!.hasErrors;
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: Column(
            children: [
              _totalRow('Product Type Total', result?.subtotal ?? 0),
              _totalRow('Discount', -(result?.discountTotal ?? 0)),
              const Divider(),
              _totalRow('Grand Total', result?.grandTotal ?? 0, strong: true),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: hasResult
              ? () {
                  Clipboard.setData(ClipboardData(text: _summary(result!)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Summary copied.')),
                  );
                }
              : null,
          icon: const Icon(Icons.copy),
          label: const Text('Copy Summary'),
        ),
      ],
    );
  }

  Widget _totalRow(String label, double value, {bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: strong ? FontWeight.w800 : null),
            ),
          ),
          Text(
            MoneyFormatter.money(value),
            style: TextStyle(fontWeight: strong ? FontWeight.w800 : null),
          ),
        ],
      ),
    );
  }

  String _summary(LiveCalculationResult result) {
    final buffer = StringBuffer()
      ..writeln(
        '${result.productTypeNameEnglish} / ${result.productTypeNameKhmer}',
      )
      ..writeln('Total: ${MoneyFormatter.money(result.grandTotal)}')
      ..writeln()
      ..writeln('Needed materials:');
    for (final line in result.lines) {
      buffer.writeln(
        '${line.khmerName}: ${line.roundedQuantity} ${line.unitKhmer} = ${line.packagingFullBoxes} កេស + ${line.packagingLooseItems} ${line.unitKhmer}',
      );
    }
    return buffer.toString();
  }
}

class _ProductTemplateEditor extends StatelessWidget {
  const _ProductTemplateEditor({
    required this.materials,
    required this.templates,
    required this.onSave,
  });

  final List<MaterialItem> materials;
  final List<ProductTypeTemplate> templates;
  final Future<void> Function(ProductTypeTemplate template) onSave;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Edit product defaults'),
      children: templates.map((template) {
        return ListTile(
          title: Text(template.label),
          subtitle: Text(
            '${template.inputModeId} • ${template.defaultMaterialRules.length} materials',
          ),
          trailing: IconButton(
            tooltip: 'Edit template',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final saved = await showDialog<ProductTypeTemplate>(
                context: context,
                builder: (_) =>
                    _TemplateDialog(template: template, materials: materials),
              );
              if (saved != null) {
                await onSave(saved);
              }
            },
          ),
        );
      }).toList(),
    );
  }
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({required this.template, required this.materials});

  final ProductTypeTemplate template;
  final List<MaterialItem> materials;

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  late final TextEditingController _khmer;
  late final TextEditingController _english;
  late final TextEditingController _sortOrder;
  late String _inputModeId;
  late bool _active;
  late bool _isDefault;
  late List<ProductTemplateMaterialRule> _rules;

  @override
  void initState() {
    super.initState();
    _khmer = TextEditingController(text: widget.template.nameKhmer);
    _english = TextEditingController(text: widget.template.nameEnglish);
    _sortOrder = TextEditingController(text: '${widget.template.sortOrder}');
    _inputModeId = widget.template.inputModeId;
    _active = widget.template.active;
    _isDefault = widget.template.isDefault;
    _rules = [...widget.template.defaultMaterialRules];
  }

  @override
  void dispose() {
    _khmer.dispose();
    _english.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Product Template'),
      content: SizedBox(
        width: 820,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _field(_khmer, 'Khmer name'),
                  _field(_english, 'English name'),
                  SizedBox(
                    width: 240,
                    child: DropdownButtonFormField<String>(
                      initialValue: _inputModeId,
                      decoration: const InputDecoration(
                        labelText: 'Input mode',
                      ),
                      items: InputModeIds.supportedNow
                          .map(
                            (id) =>
                                DropdownMenuItem(value: id, child: Text(id)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _inputModeId = value ?? _inputModeId),
                    ),
                  ),
                  _field(_sortOrder, 'Sort order', number: true),
                  SizedBox(
                    width: 180,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _active,
                      title: const Text('Active'),
                      onChanged: (value) => setState(() => _active = value),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isDefault,
                      title: const Text('Default'),
                      onChanged: (value) => setState(() => _isDefault = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...widget.materials.map((material) {
                final existing = _rules
                    .where((rule) => rule.materialId == material.id)
                    .firstOrNull;
                final inTemplate = existing != null;
                return CheckboxListTile(
                  value: inTemplate,
                  title: Text(
                    '${material.khmerName} / ${material.englishName} ${material.spec}',
                  ),
                  subtitle: inTemplate
                      ? Text(
                          '${existing.defaultSellModeId} • ${existing.formulaTypeOverrideId ?? material.formulaTypeId}',
                        )
                      : null,
                  onChanged: (value) {
                    setState(() {
                      if (value == true && existing == null) {
                        _rules.add(
                          ProductTemplateMaterialRule(
                            materialId: material.id,
                            includedByDefault: false,
                            allowManualOverride: true,
                            formulaTypeOverrideId: material.formulaTypeId,
                            coverageValueOverride: material.coverageValue,
                            multiplierValueOverride: material.multiplierValue,
                            fixedQuantityOverride: material.fixedQuantity,
                            defaultSellModeId: material.isServiceOnly
                                ? SellModeIds.areaService
                                : SellModeIds.unitOnly,
                          ),
                        );
                      } else if (value == false) {
                        _rules.removeWhere(
                          (rule) => rule.materialId == material.id,
                        );
                      }
                    });
                  },
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

  Widget _field(
    TextEditingController controller,
    String label, {
    bool number = false,
  }) {
    return SizedBox(
      width: 240,
      child: TextField(
        controller: controller,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  void _save() {
    Navigator.pop(
      context,
      widget.template.copyWith(
        nameKhmer: _khmer.text.trim(),
        nameEnglish: _english.text.trim(),
        inputModeId: _inputModeId,
        active: _active,
        isDefault: _isDefault,
        defaultMaterialRules: _rules,
        sortOrder: int.tryParse(_sortOrder.text) ?? widget.template.sortOrder,
      ),
    );
  }
}

class _PriceEditor extends StatelessWidget {
  const _PriceEditor({
    required this.materials,
    required this.prices,
    required this.onSave,
  });

  final List<MaterialItem> materials;
  final List<MaterialPrice> prices;
  final Future<void> Function(MaterialPrice price) onSave;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Edit unit and box prices'),
      children: materials.map((material) {
        final unit = _price(material.id, PriceTypeIds.unitPrice);
        final box = _price(material.id, PriceTypeIds.boxPrice);
        return ListTile(
          title: Text(
            '${material.khmerName} / ${material.englishName} ${material.spec}',
          ),
          subtitle: Text(
            'Unit: ${_moneyOrDash(unit?.price)} • Box: ${_moneyOrDash(box?.price)}',
          ),
          trailing: IconButton(
            tooltip: 'Edit prices',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final saved = await showDialog<List<MaterialPrice>>(
                context: context,
                builder: (_) =>
                    _PriceDialog(material: material, prices: prices),
              );
              if (saved != null) {
                for (final price in saved) {
                  await onSave(price);
                }
              }
            },
          ),
        );
      }).toList(),
    );
  }

  MaterialPrice? _price(String materialId, String priceTypeId) {
    final now = DateTime.now();
    final matches =
        prices
            .where(
              (price) =>
                  price.materialId == materialId &&
                  price.priceTypeId == priceTypeId &&
                  price.isEffectiveAt(now),
            )
            .toList()
          ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    return matches.firstOrNull;
  }
}

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({required this.material, required this.prices});

  final MaterialItem material;
  final List<MaterialPrice> prices;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  final _unit = TextEditingController();
  final _box = TextEditingController();

  @override
  void initState() {
    super.initState();
    _unit.text =
        _find(PriceTypeIds.unitPrice)?.price.toStringAsFixed(2) ?? '0.00';
    _box.text =
        _find(PriceTypeIds.boxPrice)?.price.toStringAsFixed(2) ?? '0.00';
  }

  @override
  void dispose() {
    _unit.dispose();
    _box.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Prices: ${widget.material.englishName}'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _unit,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Unit Price'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _box,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Box Price'),
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

  MaterialPrice? _find(String priceTypeId) {
    final now = DateTime.now();
    final matches =
        widget.prices
            .where(
              (price) =>
                  price.materialId == widget.material.id &&
                  price.priceTypeId == priceTypeId &&
                  price.isEffectiveAt(now),
            )
            .toList()
          ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    return matches.firstOrNull;
  }

  void _save() {
    final now = DateTime.now();
    MaterialPrice price(String priceTypeId, TextEditingController controller) {
      final existing = _find(priceTypeId);
      return MaterialPrice(
        id:
            existing?.id ??
            '${widget.material.id}_${priceTypeId}_${now.microsecondsSinceEpoch}',
        materialId: widget.material.id,
        priceTypeId: priceTypeId,
        price: _parseDouble(controller.text) ?? 0,
        currencyCode: existing?.currencyCode ?? 'USD',
        effectiveFrom: existing?.effectiveFrom ?? now,
        effectiveTo: existing?.effectiveTo,
        active: true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
    }

    Navigator.pop(context, [
      price(PriceTypeIds.unitPrice, _unit),
      price(PriceTypeIds.boxPrice, _box),
    ]);
  }
}

double? _parseDouble(String value) {
  final trimmed = value.replaceAll(',', '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return double.tryParse(trimmed);
}

String _moneyOrDash(double? value) {
  return value == null ? '-' : MoneyFormatter.money(value);
}
