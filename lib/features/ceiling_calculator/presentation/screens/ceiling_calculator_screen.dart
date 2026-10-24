import '../../../../core/ios/iphone_controls.dart';
import '../../../../core/ios/iphone_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_quote_pro/features/ceiling_calculator/domain/ceiling_wire.dart';
import 'package:material_quote_pro/app_state.dart';
import 'package:material_quote_pro/core/theme/sakura_theme.dart';
import 'package:material_quote_pro/core/utils/money_formatter.dart';
import 'package:material_quote_pro/core/utils/quantity_rounding.dart';
import 'package:material_quote_pro/core/widgets/product_image_thumbnail.dart';
import 'package:material_quote_pro/features/ceiling_calculator/domain/ceiling_v_extra_calculator.dart';
import 'package:material_quote_pro/features/materials/data/models/material_item.dart';
import 'package:material_quote_pro/features/materials/domain/product_sale_engine.dart';
import 'package:material_quote_pro/features/materials/domain/product_sale_models.dart';
import 'package:material_quote_pro/features/measurement_calculator/domain/models/measurement_models.dart';
import 'package:provider/provider.dart';
import '../../domain/ceiling_khmer_replies.dart';
import '../widgets/ceiling_reply_generator.dart';

class CeilingCalculatorEngine {
  static ProductSaleResult? calculateSingleProduct({
    required AppState state,
    required MaterialItem material,
    required double areaM2,
    required String templateId,
  }) {
    if (areaM2 <= 0) return null;
    final engine = const ProductSaleEngine();
    return engine.calculate(
      input: ProductSaleInput(
        productKindId: templateId,
        materialId: material.id,
        inputMethodId: InputMethodIds.areaM2,
        areaM2: areaM2,
        buyModeId: InputMethodIds.areaM2,
      ),
      productKinds: state.productTemplates,
      materials: state.materials,
      prices: state.prices,
      packagingRules: state.packagingRules,
      automaticQuantityRounder: roundCeilingQuantity,
    );
  }
}

const _surface = AppColors.surface;
const _card = AppColors.card;
const _border = AppColors.border;
const _primary = AppColors.primary;
const _text = AppColors.textMain;
const _textSecondary = AppColors.textSecondary;
const _textMuted = AppColors.textMuted;

enum CeilingCategoryTab {
  all('ទាំងអស់'),
  ceilingTile('ពិដាន'),
  tBar('ជ្រី'),
  vIron('ដែក V'),
  accessories('សម្ភារ:');

  const CeilingCategoryTab(this.label);
  final String label;
}

class CeilingCalculatorScreen extends StatefulWidget {
  const CeilingCalculatorScreen({super.key});

  @override
  State<CeilingCalculatorScreen> createState() =>
      _CeilingCalculatorScreenState();
}

class _CeilingCalculatorScreenState extends State<CeilingCalculatorScreen> {
  final List<_RoomGroupFields> _roomGroups = [];
  int _activeGroupIndex = 0;
  int _nextGroupId = 1;

  final Set<String> _selectedMaterialIds = {
    'ceiling_6mm',
    'long_t_3m',
    'short_t_06m',
    'v_iron_295m',
  };

  CeilingCategoryTab _selectedTab = CeilingCategoryTab.all;
  final TextEditingController _temporarySellPriceController =
      TextEditingController(text: '8.50');
  final TextEditingController _search = TextEditingController();
  final TextEditingController _contactPhones = TextEditingController();
  final TextEditingController _contactTelegram = TextEditingController();
  final ScrollController _groupsScroll = ScrollController();
  final ScrollController _categoriesScroll = ScrollController();
  final ScrollController _productsScroll = ScrollController();
  final ScrollController _selectedScroll = ScrollController();
  final ScrollController _workspaceScroll = ScrollController();

  double get _temporarySellPricePerM2 {
    final text = _temporarySellPriceController.text.trim();
    return double.tryParse(text) ?? 0.0;
  }

  double get _totalSellingAmount {
    return _grandTotalAreaM2 * _temporarySellPricePerM2;
  }

  @override
  void initState() {
    super.initState();
    _addGroup(length: '6', width: '4.2', count: '1');
    _search.addListener(() => setState(() {}));
    _temporarySellPriceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final group in _roomGroups) {
      group.dispose();
    }
    _temporarySellPriceController.dispose();
    _search.dispose();
    _contactPhones.dispose();
    _contactTelegram.dispose();
    _groupsScroll.dispose();
    _categoriesScroll.dispose();
    _productsScroll.dispose();
    _selectedScroll.dispose();
    _workspaceScroll.dispose();
    super.dispose();
  }

  List<MaterialItem> _filteredProducts(AppState state) {
    return state.materials.where((product) {
      final cat = product.categoryId.toLowerCase();
      final isCeiling =
          cat == 'ceiling' ||
          cat == 't_bar' ||
          cat == 'v_iron' ||
          product.id.contains('ceiling') ||
          product.id.contains('t_3m') ||
          product.id.contains('t_06m') ||
          product.id.contains('v_iron');

      if (!isCeiling) return false;

      if (_selectedTab == CeilingCategoryTab.ceilingTile &&
          !cat.contains('ceiling') &&
          !product.id.contains('ceiling')) {
        return false;
      }
      if (_selectedTab == CeilingCategoryTab.tBar &&
          !cat.contains('t_bar') &&
          !product.id.contains('t_3m') &&
          !product.id.contains('t_06m')) {
        return false;
      }
      if (_selectedTab == CeilingCategoryTab.vIron &&
          !cat.contains('v_iron') &&
          !product.id.contains('v_iron')) {
        return false;
      }
      if (_selectedTab == CeilingCategoryTab.accessories &&
          (cat == 'ceiling' || cat == 't_bar' || cat == 'v_iron')) {
        return false;
      }

      final q = _search.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final name = product.khmerName.toLowerCase();
        final eng = product.englishName.toLowerCase();
        final spec = product.spec.toLowerCase();
        if (!name.contains(q) && !eng.contains(q) && !spec.contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  List<ProductSaleResult> _calculateResults(AppState state) {
    final area = _grandTotalAreaM2;
    if (area <= 0) return const [];

    final results = <ProductSaleResult>[];
    final activeTemplate =
        state.productTemplates
            .where((t) => t.id == 'ceiling_full_set')
            .firstOrNull ??
        state.defaultProductTemplate;
    final templateId = activeTemplate?.id ?? 'ceiling_full_set';

    for (final productId in _selectedMaterialIds) {
      final material = state.materials
          .where((m) => m.id == productId)
          .firstOrNull;
      if (material == null) continue;

      final res = CeilingCalculatorEngine.calculateSingleProduct(
        state: state,
        material: material,
        areaM2: area,
        templateId: templateId,
      );
      if (res != null) results.add(res);
    }
    return results;
  }

  CeilingVExtraResult? _calculateExtraV(List<ProductSaleResult> results) {
    if (!_selectedMaterialIds.contains('v_iron_295m')) return null;
    final vResult = results
        .where((r) => r.materialId == 'v_iron_295m')
        .firstOrNull;
    if (vResult == null) return null;

    final groups = _roomGroups
        .where((g) => g.mode == MeasurementRoomMode.dimensions)
        .map(
          (g) => CeilingVRoomGroup(
            lengthM: g.lengthM ?? 0,
            widthM: g.widthM ?? 0,
            roomCount: g.countValue,
          ),
        );

    final calc = const CeilingVExtraCalculator();
    final res = calc.calculate(
      roomGroups: groups,
      existingVQuantity: vResult.sellQuantity,
    );
    if (res.extraVToBuy <= 0) return null;
    return res;
  }

  double get _grandTotalAreaM2 {
    return _roomGroups.fold(0.0, (sum, group) => sum + group.totalAreaM2);
  }

  int get _totalRoomCount {
    return _roomGroups.fold(0, (sum, group) => sum + group.countValue);
  }

  void _addGroup({
    String length = '6',
    String width = '4.2',
    String count = '1',
  }) {
    setState(() {
      final group = _RoomGroupFields(
        id: _nextGroupId++,
        length: length,
        width: width,
        area: '25.2',
        count: count,
        onChanged: () => setState(() {}),
      );
      _roomGroups.add(group);
      _activeGroupIndex = _roomGroups.length - 1;
    });
  }

  void _removeGroup(int index) {
    if (_roomGroups.length <= 1) return;
    setState(() {
      _roomGroups.removeAt(index).dispose();
      if (_activeGroupIndex >= _roomGroups.length) {
        _activeGroupIndex = _roomGroups.length - 1;
      } else if (index < _activeGroupIndex) {
        _activeGroupIndex--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = _filteredProducts(state);
    final results = _calculateResults(state);
    final extraVResult = _calculateExtraV(results);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isIPhoneLayout(context)) {
            return IPhoneWorkspace(
              continuous: true,
              panels: [
                _measurementPanel(),
                _productsPanel(state, products),
                _resultPanel(results, extraVResult),
              ],
            );
          }
          if (constraints.maxWidth >= 1240) {
            return Row(
              key: ValueKey('ceiling-root'),
              children: [
                Expanded(flex: 20, child: _measurementPanel()),
                _WorkspaceDivider(),
                Expanded(flex: 50, child: _productsPanel(state, products)),
                _WorkspaceDivider(),
                Expanded(flex: 30, child: _resultPanel(results, extraVResult)),
              ],
            );
          }
          return Scrollbar(
            controller: _workspaceScroll,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              key: ValueKey('ceiling-horizontal-scroll'),
              controller: _workspaceScroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1220,
                height: constraints.maxHeight,
                child: Row(
                  key: ValueKey('ceiling-root'),
                  children: [
                    SizedBox(width: 270, child: _measurementPanel()),
                    _WorkspaceDivider(),
                    SizedBox(
                      width: 590,
                      child: _productsPanel(state, products),
                    ),
                    _WorkspaceDivider(),
                    SizedBox(
                      width: 340,
                      child: _resultPanel(results, extraVResult),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _measurementPanel() {
    if (_roomGroups.isEmpty) return SizedBox.shrink();
    final activeGroup =
        _roomGroups[_activeGroupIndex.clamp(0, _roomGroups.length - 1)];

    return _WorkspacePanel(
      key: ValueKey('ceiling-room-panel'),
      title: 'ទំហំបន្ទប់ពិដាន',
      icon: Icons.grid_view_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isIPhoneLayout(context) ? 44 : 42,
            child: _HorizontalStrip(
              key: ValueKey('ceiling-room-group-tabs'),
              controller: _groupsScroll,
              compact: true,
              children: [
                for (var index = 0; index < _roomGroups.length; index++)
                  _WorkspaceTab(
                    key: ValueKey(
                      'ceiling-room-group-${_roomGroups[index].id}',
                    ),
                    label: _roomGroups[index].tabLabel,
                    selected: index == _activeGroupIndex,
                    onTap: () => setState(() => _activeGroupIndex = index),
                    onClose: _roomGroups.length > 1
                        ? () => _removeGroup(index)
                        : null,
                  ),
                _AddTab(
                  key: ValueKey('ceiling-add-room-group-tab'),
                  label: '+',
                  onTap: () => _addGroup(),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Container(
            key: ValueKey('ceiling-room-group-editor-${activeGroup.id}'),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iPhoneColor(context, _surface),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: iPhoneColor(context, _border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'បន្ទប់ ${_activeGroupIndex + 1}',
                        style: TextStyle(
                          color: iPhoneColor(context, _text),
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Text(
                      'បន្ទប់',
                      key: ValueKey(
                        'ceiling-group-room-count-${activeGroup.id}',
                      ),
                      style: TextStyle(
                        color: iPhoneColor(context, _primary),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _RoomModeToggle(
                  groupId: activeGroup.id,
                  mode: activeGroup.mode,
                  onChanged: (mode) => setState(() => activeGroup.mode = mode),
                ),
                SizedBox(height: 10),
                if (activeGroup.mode == MeasurementRoomMode.dimensions)
                  Row(
                    children: [
                      Expanded(
                        child: _RoomDimensionField(
                          key: ValueKey(
                            'ceiling-group-length-${activeGroup.id}',
                          ),
                          label: 'ប្រវែង',
                          controller: activeGroup.length,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _RoomDimensionField(
                          key: ValueKey(
                            'ceiling-group-width-${activeGroup.id}',
                          ),
                          label: 'ទទឹង',
                          controller: activeGroup.width,
                        ),
                      ),
                    ],
                  )
                else
                  _RoomDimensionField(
                    key: ValueKey('ceiling-group-area-${activeGroup.id}'),
                    label: 'ទំហំក្នុង 1 បន្ទប់',
                    controller: activeGroup.area,
                    suffix: 'm²',
                  ),
                SizedBox(height: 10),
                _CompactLabel('ចំនួនបន្ទប់'),
                SizedBox(height: 6),
                _RoomCountControl(
                  key: ValueKey(
                    'ceiling-group-count-control-${activeGroup.id}',
                  ),
                  groupId: activeGroup.id,
                  controller: activeGroup.count,
                  value: activeGroup.countValue,
                  onDecrement: activeGroup.countValue > 1
                      ? () {
                          activeGroup.count.text = (activeGroup.countValue - 1)
                              .toString();
                          setState(() {});
                        }
                      : null,
                  onIncrement: () {
                    activeGroup.count.text = (activeGroup.countValue + 1)
                        .toString();
                    setState(() {});
                  },
                  onNormalize: activeGroup.normalizeCount,
                ),
                SizedBox(height: 12),
                Divider(height: 1, color: iPhoneColor(context, _border)),
                SizedBox(height: 10),
                _RoomMetricRow(
                  label: 'ក្នុង 1បន្ទប់',
                  value: '${_format(activeGroup.areaPerRoomM2)} m²',
                  valueKey: ValueKey(
                    'ceiling-group-area-per-room-${activeGroup.id}',
                  ),
                ),
                SizedBox(height: 7),
                _RoomMetricRow(
                  label: 'សរុបរួម',
                  value: '${_format(activeGroup.totalAreaM2)} m²',
                  valueKey: ValueKey(
                    'ceiling-group-total-area-${activeGroup.id}',
                  ),
                  emphasized: true,
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: iPhoneColor(context, AppColors.successBg),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: iPhoneColor(context, AppColors.successBorder),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'សរុបមើលអស់',
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.successText),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  '${_format(_grandTotalAreaM2)} m²',
                  key: ValueKey('ceiling-grand-room-area'),
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.successText),
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          SizedBox(
            height: isIPhoneLayout(context) ? 44 : 42,
            child: AdaptiveActionButton.filledIcon(
              key: ValueKey('ceiling-add-room-group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: iPhoneColor(
                  context,
                  AppColors.buttonSecondaryBg,
                ),
                foregroundColor: iPhoneColor(
                  context,
                  AppColors.buttonSecondaryText,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: iPhoneColor(
                      context,
                      AppColors.buttonSecondaryBorder,
                    ),
                  ),
                ),
              ),
              onPressed: () => _addGroup(),
              icon: Icon(Icons.add_rounded, size: 18),
              label: Text(
                '+ បន្ថែមបន្ទប់ផ្សេង',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productsPanel(AppState state, List<MaterialItem> products) {
    return _WorkspacePanel(
      key: ValueKey('ceiling-products-panel'),
      title: 'ផលិតផលពិដាន / សម្ភារ:',
      icon: Icons.inventory_2_outlined,
      trailing: Text(
        '${_selectedMaterialIds.length} បានជ្រើស',
        style: TextStyle(
          color: iPhoneColor(context, _textSecondary),
          fontSize: 12,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: isIPhoneLayout(context) ? 44 : 42,
                child: isIPhoneLayout(context)
                    ? IPhoneSearchField(
                        controller: _search,
                        placeholder: 'ស្វែងរកផលិតផល',
                      )
                    : AdaptiveTextField(
                        key: ValueKey('ceiling-product-search'),
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកផលិតផលពិដាន...',
                          hintStyle: TextStyle(
                            color: iPhoneColor(context, _textMuted),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 19,
                            color: iPhoneColor(context, _textMuted),
                          ),
                          fillColor: iPhoneColor(
                            context,
                            AppColors.surfaceSecondary,
                          ),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: iPhoneColor(context, _border),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: iPhoneColor(context, _border),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: iPhoneColor(context, _primary),
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: isIPhoneLayout(context) ? 44 : 36,
                child: _HorizontalStrip(
                  key: ValueKey('ceiling-category-tabs'),
                  controller: _categoriesScroll,
                  compact: true,
                  children: [
                    for (final tab in CeilingCategoryTab.values)
                      _WorkspaceTab(
                        key: ValueKey('ceiling-category-${tab.name}'),
                        label: tab.label,
                        selected: tab == _selectedTab,
                        onTap: () => setState(() => _selectedTab = tab),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'ជ្រើសរើសផលិតផល',
                  style: TextStyle(
                    color: iPhoneColor(context, _textMuted),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Text(
                          'មិនមានផលិតផលត្រូវនឹងការស្វែងរក',
                          style: TextStyle(
                            color: iPhoneColor(context, _textSecondary),
                          ),
                        ),
                      )
                    : ListView.separated(
                        key: ValueKey('ceiling-product-list'),
                        controller: _productsScroll,
                        padding: EdgeInsets.zero,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final selected = _selectedMaterialIds.contains(
                            product.id,
                          );
                          return _CeilingProductRow(
                            key: ValueKey('ceiling-product-${product.id}'),
                            product: product,
                            selected: selected,
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selectedMaterialIds.remove(product.id);
                                } else {
                                  _selectedMaterialIds.add(product.id);
                                }
                              });
                            },
                          );
                        },
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 6),
                      ),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: isIPhoneLayout(context) ? 44 : 38,
                child: _selectedMaterialIds.isEmpty
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ចុចលើផលិតផលដើម្បីបន្ថែម',
                          style: TextStyle(
                            color: iPhoneColor(context, _textMuted),
                            fontSize: 12,
                          ),
                        ),
                      )
                    : _HorizontalStrip(
                        key: ValueKey('ceiling-selected-strip'),
                        controller: _selectedScroll,
                        compact: true,
                        children: [
                          for (final productId in _selectedMaterialIds)
                            _SelectedProductChip(
                              key: ValueKey('ceiling-selected-$productId'),
                              label: _productLabel(state, productId),
                              onDeleted: () {
                                setState(() {
                                  _selectedMaterialIds.remove(productId);
                                });
                              },
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultPanel(
    List<ProductSaleResult> results,
    CeilingVExtraResult? extraVResult,
  ) {
    final wire = CeilingWire.forArea(_grandTotalAreaM2);
    final customerTotal = _totalSellingAmount + wire.price;
    final materialLines = [
      for (final result in results)
        switch (result.materialId) {
          'ceiling_6mm' =>
            '• ពិដាន៖ ${result.sellQuantity} ${result.unitKhmer}',
          'long_t_3m' =>
            '• T វែង 3m៖ ${result.sellQuantity} ${result.unitKhmer}',
          'short_t_06m' =>
            '• T ខ្លី 0.6m៖ ${result.sellQuantity} ${result.unitKhmer}',
          'v_iron_295m' =>
            '• V 2.95m៖ ${result.sellQuantity} ${result.unitKhmer}',
          _ =>
            '• ${result.materialNameKhmer} ${result.spec}៖ ${result.sellQuantity} ${result.unitKhmer}',
        },
      if (extraVResult != null) '• V បន្ថែម៖ ${extraVResult.extraVToBuy} ដើម',
      if (wire.lengthM > 0) '• លួស៖ ${wire.lengthM}m',
    ];
    final phoneLines = _contactPhones.text
        .split(RegExp(r'[\n,;]+'))
        .map((phone) => phone.trim())
        .where((phone) => phone.isNotEmpty)
        .map((phone) => '📞 $phone');
    final priceRange =
        '${MoneyFormatter.money(customerTotal)} – ${MoneyFormatter.money((customerTotal * 1.05).ceilToDouble())}';
    final customerDetails = [
      '📐 ផ្ទៃពិដាន៖ ${_format(_grandTotalAreaM2)}m²',
      for (var index = 0; index < _roomGroups.length; index++)
        if (_roomGroups[index].mode == MeasurementRoomMode.dimensions)
          '${_roomGroups.length > 1 ? 'ទំហំបន្ទប់ ${index + 1}' : 'ទំហំ'}៖ ${_roomGroups[index].lengthText}m × ${_roomGroups[index].widthText}m${_roomGroups[index].countValue > 1 ? ' × ${_roomGroups[index].countValue} បន្ទប់' : ''}'
        else
          '${_roomGroups.length > 1 ? 'ទំហំបន្ទប់ ${index + 1}' : 'ទំហំ'}៖ ${_format(_roomGroups[index].areaPerRoomM2)}m²${_roomGroups[index].countValue > 1 ? ' × ${_roomGroups[index].countValue} បន្ទប់' : ''}',
      ...materialLines,
      ...phoneLines,
      if (_contactTelegram.text.trim().isNotEmpty)
        'Telegram៖ ${_contactTelegram.text.trim()}',
    ];
    final customerText = [
      'បាទបង 🙏',
      'តម្លៃសរុបប្រហែល',
      priceRange,
      ...customerDetails,
    ].join('\n');
    final activeGroup =
        _roomGroups[_activeGroupIndex.clamp(0, _roomGroups.length - 1)];
    final roomDimensionsText =
        '${activeGroup.lengthText}m × ${activeGroup.widthText}m';

    return _WorkspacePanel(
      key: ValueKey('ceiling-result-panel'),
      title: 'បរិមាណសរុប: ពិដាន',
      icon: Icons.receipt_long_outlined,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iPhoneColor(context, AppColors.surfaceSecondary),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: iPhoneColor(context, _border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'បន្ទប់ / ផ្ទៃក្រឡា',
                            style: TextStyle(
                              color: iPhoneColor(context, _textSecondary),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '$_totalRoomCount បន្ទប់',
                            style: TextStyle(
                              color: iPhoneColor(context, _text),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            roomDimensionsText,
                            style: TextStyle(
                              color: iPhoneColor(context, _textSecondary),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _IsometricRoomWidget(),
                    SizedBox(width: 10),
                    Text(
                      '${_format(_grandTotalAreaM2)} m²',
                      style: TextStyle(
                        color: iPhoneColor(context, _primary),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              _CeilingCompactSellingSection(
                priceController: _temporarySellPriceController,
                totalAreaM2: _grandTotalAreaM2,
                totalSellingAmount: _totalSellingAmount,
              ),
              SizedBox(height: 8),
              AdaptiveActionButton.outlinedIcon(
                key: ValueKey('ceiling-edit-contacts'),
                icon: Icon(Icons.contact_phone_outlined, size: 18),
                label: Text('លេខទូរស័ព្ទ / Telegram'),
                onPressed: () => showAdaptiveEditor<void>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text('លេខទូរស័ព្ទ / Telegram'),
                    content: SizedBox(
                      width: 400,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AdaptiveTextField(
                              key: ValueKey('ceiling-dialog-phones'),
                              controller: _contactPhones,
                              minLines: 2,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              decoration: InputDecoration(
                                labelText: 'លេខទូរស័ព្ទ',
                                helperText:
                                    'លេខមួយក្នុងមួយបន្ទាត់ ឬបំបែកដោយសញ្ញា ,',
                                helperMaxLines: 2,
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            SizedBox(height: 20),
                            AdaptiveTextField(
                              key: ValueKey('ceiling-dialog-telegram'),
                              controller: _contactTelegram,
                              decoration: InputDecoration(
                                labelText: 'Telegram',
                                hintText: '@username / https://t.me/username',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      AdaptiveActionButton.text(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text('រួចរាល់'),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              if (results.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'ជ្រើសផលិតផលដើម្បីមើលលទ្ធផល',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: iPhoneColor(context, _textSecondary),
                      ),
                    ),
                  ),
                )
              else ...[
                Expanded(
                  child: ListView.separated(
                    key: ValueKey('ceiling-result-list'),
                    padding: EdgeInsets.zero,
                    itemCount: results.length + 3,
                    itemBuilder: (context, index) {
                      if (index == results.length + 2) {
                        return CeilingReplyGenerator(
                          key: ValueKey('ceiling-reply-generator'),
                          data: CeilingReplyData(
                            priceRange: priceRange,
                            details: customerDetails,
                          ),
                        );
                      }
                      if (index == results.length) {
                        return Container(
                          key: ValueKey('ceiling-wire-result'),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: iPhoneColor(context, _surface),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: iPhoneColor(context, _border),
                            ),
                          ),
                          child: Text(
                            'លួស\n${wire.lengthM} m • ${MoneyFormatter.money(wire.price)}',
                            style: TextStyle(
                              color: iPhoneColor(context, _text),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }
                      if (index == results.length + 1) {
                        return Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: iPhoneColor(context, _border),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SelectableText(
                                customerText,
                                key: ValueKey('ceiling-customer-text'),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  height: 1.7,
                                ),
                              ),
                              SizedBox(height: 8),
                              AdaptiveActionButton.outlinedIcon(
                                key: ValueKey('ceiling-copy-customer-text'),
                                onPressed: () async {
                                  try {
                                    await Clipboard.setData(
                                      ClipboardData(text: customerText),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('បានចម្លងព័ត៌មាន'),
                                      ),
                                    );
                                  } catch (_) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'មិនអាចចម្លងបាន សូមព្យាយាមម្ដងទៀត',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: Icon(Icons.copy_rounded, size: 16),
                                label: Text('ចម្លងព័ត៌មានជូនអតិថិជន'),
                              ),
                            ],
                          ),
                        );
                      }
                      final result = results[index];
                      final resultCard = _CeilingResultGroup(
                        key: ValueKey('ceiling-result-${result.materialId}'),
                        result: result,
                        onRemove: () {
                          setState(() {
                            _selectedMaterialIds.remove(result.materialId);
                          });
                        },
                      );
                      if (result.materialId != 'v_iron_295m' ||
                          extraVResult == null) {
                        return resultCard;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          resultCard,
                          SizedBox(height: 8),
                          _CeilingExtraVResult(
                            extraQuantity: extraVResult.extraVToBuy,
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 8),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  key: ValueKey('ceiling-material-summary'),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: iPhoneColor(context, AppColors.successBg),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: iPhoneColor(context, AppColors.successBorder),
                    ),
                  ),
                  child: Text(
                    'សម្ភារៈសរុប: ${results.length + (wire.lengthM > 0 ? 1 : 0)} មុខ',
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.successText),
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _productLabel(AppState state, String id) {
    final item = state.materials.where((m) => m.id == id).firstOrNull;
    if (item == null) return id;
    final spec = item.spec.isEmpty ? '' : ' ${item.spec}';
    return '${item.khmerName}$spec';
  }

  String _format(double value) => MoneyFormatter.decimal(value);
}

class _IsometricRoomWidget extends StatelessWidget {
  const _IsometricRoomWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(48, 36), painter: _IsometricRoomPainter());
  }
}

class _IsometricRoomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final backWall = Paint()
      ..color = AppColors.surfaceSelected
      ..style = PaintingStyle.fill;
    final leftWall = Paint()
      ..color = AppColors.primarySoft
      ..style = PaintingStyle.fill;
    final floor = Paint()
      ..color = AppColors.lilacHighlight
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = AppColors.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final w = size.width;
    final h = size.height;

    final floorPath = Path()
      ..moveTo(0, h * 0.75)
      ..lineTo(w * 0.5, h * 0.95)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h * 0.55)
      ..close();
    canvas.drawPath(floorPath, floor);

    final leftPath = Path()
      ..moveTo(0, h * 0.75)
      ..lineTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.5, h * 0.10)
      ..lineTo(0, h * 0.30)
      ..close();
    canvas.drawPath(leftPath, leftWall);

    final backPath = Path()
      ..moveTo(w * 0.5, h * 0.55)
      ..lineTo(w, h * 0.75)
      ..lineTo(w, h * 0.30)
      ..lineTo(w * 0.5, h * 0.10)
      ..close();
    canvas.drawPath(backPath, backWall);

    canvas.drawPath(floorPath, linePaint);
    canvas.drawPath(leftPath, linePaint);
    canvas.drawPath(backPath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SelectedProductChip extends StatelessWidget {
  const _SelectedProductChip({
    super.key,
    required this.label,
    required this.onDeleted,
  });

  final String label;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.surfaceSelected),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iPhoneColor(context, _border)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: iPhoneColor(context, _primary),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(width: 4),
          InkWell(
            onTap: onDeleted,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: iPhoneColor(context, _primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomGroupFields {
  _RoomGroupFields({
    required this.id,
    required String length,
    required String width,
    required String area,
    required String count,
    required this.onChanged,
  }) {
    this.length = TextEditingController(text: length)..addListener(onChanged);
    this.width = TextEditingController(text: width)..addListener(onChanged);
    this.area = TextEditingController(text: area)..addListener(onChanged);
    this.count = TextEditingController(text: count)..addListener(onChanged);
  }

  final int id;
  final VoidCallback onChanged;
  late final TextEditingController length;
  late final TextEditingController width;
  late final TextEditingController area;
  late final TextEditingController count;
  MeasurementRoomMode mode = MeasurementRoomMode.dimensions;

  String get tabLabel {
    final countSuffix = countValue > 1 ? ' · ×$countValue' : '';
    if (mode == MeasurementRoomMode.dimensions) {
      return '$lengthText×$widthText$countSuffix';
    }
    return '${areaText}m²$countSuffix';
  }

  String get lengthText => length.text.trim();
  String get widthText => width.text.trim();
  String get areaText => area.text.trim();

  double? get lengthM => double.tryParse(lengthText);
  double? get widthM => double.tryParse(widthText);
  double? get directAreaM2 => double.tryParse(areaText);

  int get countValue {
    final parsed = int.tryParse(count.text.trim());
    return (parsed == null || parsed < 1) ? 1 : parsed;
  }

  double get areaPerRoomM2 {
    if (mode == MeasurementRoomMode.dimensions) {
      final l = lengthM ?? 0;
      final w = widthM ?? 0;
      return (l > 0 && w > 0) ? (l * w * 10000).round() / 10000 : 0;
    }
    final a = directAreaM2 ?? 0;
    return a > 0 ? (a * 10000).round() / 10000 : 0;
  }

  double get totalAreaM2 => areaPerRoomM2 * countValue;

  void normalizeCount() {
    final val = countValue;
    if (count.text != val.toString()) {
      count.text = val.toString();
    }
  }

  void dispose() {
    length.dispose();
    width.dispose();
    area.dispose();
    count.dispose();
  }
}

class _CeilingProductRow extends StatelessWidget {
  const _CeilingProductRow({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final MaterialItem product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final specLabel = product.spec.isNotEmpty ? ' ${product.spec}' : '';

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? iPhoneColor(context, AppColors.surfaceSecondary)
            : iPhoneColor(context, _surface),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? iPhoneColor(context, AppColors.borderStrong)
              : iPhoneColor(context, _border),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  color: selected
                      ? iPhoneColor(context, _primary)
                      : iPhoneColor(context, _textMuted),
                  size: 20,
                ),
                SizedBox(width: 8),
                ProductImageThumbnail(
                  imagePath: product.imagePath,
                  productName: '${product.khmerName}$specLabel',
                  width: 32,
                  height: isIPhoneLayout(context) ? 44 : 32,
                  borderRadius: 6,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${product.khmerName}$specLabel',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? iPhoneColor(context, _primary)
                          : iPhoneColor(context, _text),
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CeilingResultGroup extends StatelessWidget {
  const _CeilingResultGroup({
    super.key,
    required this.result,
    required this.onRemove,
  });

  final ProductSaleResult result;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final item = state.materials
        .where((m) => m.id == result.materialId)
        .firstOrNull;
    final packageBreakdown = _packageBreakdown(result);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iPhoneColor(context, _border)),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ProductImageThumbnail(
              imagePath: item?.imagePath,
              productName: result.materialNameKhmer,
              width: 42,
              height: isIPhoneLayout(context) ? 44 : 42,
              borderRadius: 12,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.materialNameKhmer} ${result.spec}'.trim(),
                  style: TextStyle(
                    color: iPhoneColor(context, _text),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${result.sellQuantity} ${result.unitKhmer}',
                  key: ValueKey('ceiling-result-quantity-${result.materialId}'),
                  style: TextStyle(
                    color: iPhoneColor(context, _primary),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                if (packageBreakdown != null) ...[
                  SizedBox(height: 3),
                  Text(
                    packageBreakdown,
                    style: TextStyle(
                      color: iPhoneColor(context, _textMuted),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: iPhoneColor(context, _textMuted),
            ),
            onPressed: onRemove,
            tooltip: 'លុប',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String? _packageBreakdown(ProductSaleResult result) {
    if (result.itemsPerBox <= 1 || result.packagingFullBoxes <= 0) {
      return null;
    }

    final parts = <String>['${result.packagingFullBoxes} ប្រអប់'];
    if (result.packagingLooseItems > 0) {
      parts.add('${result.packagingLooseItems} ${result.unitKhmer}');
    }
    return parts.join(' + ');
  }
}

class _CeilingExtraVResult extends StatelessWidget {
  const _CeilingExtraVResult({required this.extraQuantity});

  final int extraQuantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('ceiling-extra-v-result'),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.lilacHighlight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iPhoneColor(context, _border)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_circle_outline_rounded,
            color: iPhoneColor(context, _primary),
            size: 20,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'V ទិញថែម',
              style: TextStyle(
                color: iPhoneColor(context, _primary),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$extraQuantity ដើម',
            key: ValueKey('ceiling-extra-v-quantity'),
            style: TextStyle(
              color: iPhoneColor(context, _primary),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspacePanel extends StatelessWidget {
  const _WorkspacePanel({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      padding: EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(AppEffects.panelRadius),
      tint: iPhoneColor(context, _card),
      borderColor: iPhoneColor(context, AppColors.glassHighlight),
      blur: AppEffects.glassBlur,
      shadows: AppShadows.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: iPhoneColor(context, _primary)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: iPhoneColor(context, _primary),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _WorkspaceDivider extends StatelessWidget {
  const _WorkspaceDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 10);
  }
}

class _HorizontalStrip extends StatelessWidget {
  const _HorizontalStrip({
    super.key,
    required this.controller,
    required this.children,
    this.compact = false,
  });

  final ScrollController controller;
  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: controller,
      thumbVisibility: false,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: compact ? 6 : 8),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkspaceTab extends StatelessWidget {
  const _WorkspaceTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onClose,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isIPhoneLayout(context) ? 44 : 34,
      decoration: BoxDecoration(
        color: selected
            ? iPhoneColor(context, AppColors.surfaceSelected)
            : iPhoneColor(context, _surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? iPhoneColor(context, _primary)
              : iPhoneColor(context, _border),
          width: selected ? 1.2 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? iPhoneColor(context, _primary)
                      : iPhoneColor(context, _textSecondary),
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              if (onClose != null) ...[
                SizedBox(width: 4),
                InkWell(
                  onTap: onClose,
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: iPhoneColor(context, _textMuted),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddTab extends StatelessWidget {
  const _AddTab({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: isIPhoneLayout(context) ? 44 : 34,
      decoration: BoxDecoration(
        color: iPhoneColor(context, _surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iPhoneColor(context, _border)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Text(
          label,
          style: TextStyle(
            color: iPhoneColor(context, _primary),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _RoomModeToggle extends StatelessWidget {
  const _RoomModeToggle({
    required this.groupId,
    required this.mode,
    required this.onChanged,
  });

  final int groupId;
  final MeasurementRoomMode mode;
  final ValueChanged<MeasurementRoomMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isIPhoneLayout(context) ? 44 : 34,
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.surfaceSecondary),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iPhoneColor(context, _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoomModeButton(
              key: ValueKey('ceiling-group-mode-dimensions-$groupId'),
              label: 'បណ្ដោយ × ទទឹង',
              selected: mode == MeasurementRoomMode.dimensions,
              onTap: () => onChanged(MeasurementRoomMode.dimensions),
            ),
          ),
          SizedBox(width: 2),
          Expanded(
            child: _RoomModeButton(
              key: ValueKey('ceiling-group-mode-area-$groupId'),
              label: 'm²',
              selected: mode == MeasurementRoomMode.area,
              onTap: () => onChanged(MeasurementRoomMode.area),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomModeButton extends StatelessWidget {
  const _RoomModeButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? iPhoneColor(context, AppColors.surfaceSelected)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? iPhoneColor(context, _primary)
                  : iPhoneColor(context, _textSecondary),
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoomDimensionField extends StatelessWidget {
  const _RoomDimensionField({
    super.key,
    required this.label,
    required this.controller,
    this.suffix = 'm',
  });

  final String label;
  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompactLabel(label),
        SizedBox(height: 5),
        SizedBox(
          height: isIPhoneLayout(context) ? 44 : 38,
          child: AdaptiveTextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: iPhoneColor(context, _text),
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              suffixText: suffix,
              suffixStyle: TextStyle(
                color: iPhoneColor(context, _textMuted),
                fontSize: 12,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              fillColor: iPhoneColor(context, AppColors.inputBackground),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: iPhoneColor(context, _border)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: iPhoneColor(context, _border)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: iPhoneColor(context, _primary)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomCountControl extends StatelessWidget {
  const _RoomCountControl({
    super.key,
    required this.groupId,
    required this.controller,
    required this.value,
    this.onDecrement,
    required this.onIncrement,
    required this.onNormalize,
  });

  final int groupId;
  final TextEditingController controller;
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onNormalize;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isIPhoneLayout(context) ? 44 : 38,
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.inputBackground),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iPhoneColor(context, _border)),
      ),
      child: Row(
        children: [
          IconButton(
            key: ValueKey('ceiling-group-count-decrement-$groupId'),
            tooltip: 'បន្ថយ',
            onPressed: onDecrement,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.remove_rounded,
              size: 18,
              color: iPhoneColor(context, _primary),
            ),
          ),
          VerticalDivider(width: 1, color: iPhoneColor(context, _border)),
          Expanded(
            child: AdaptiveTextField(
              key: ValueKey('ceiling-group-count-$groupId'),
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onSubmitted: (_) => onNormalize(),
              onTapOutside: (_) {
                onNormalize();
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: TextStyle(
                color: iPhoneColor(context, _text),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          VerticalDivider(width: 1, color: iPhoneColor(context, _border)),
          IconButton(
            key: ValueKey('ceiling-group-count-increment-$groupId'),
            tooltip: 'បន្ថែម',
            onPressed: onIncrement,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.add_rounded,
              size: 18,
              color: iPhoneColor(context, _primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomMetricRow extends StatelessWidget {
  const _RoomMetricRow({
    required this.label,
    required this.value,
    required this.valueKey,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Key valueKey;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: emphasized
                  ? iPhoneColor(context, _text)
                  : iPhoneColor(context, _textSecondary),
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          key: valueKey,
          style: TextStyle(
            color: emphasized
                ? iPhoneColor(context, _primary)
                : iPhoneColor(context, _text),
            fontSize: emphasized ? 13.5 : 12.5,
            fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CompactLabel extends StatelessWidget {
  const _CompactLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: iPhoneColor(context, _textSecondary),
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _CeilingCompactSellingSection extends StatelessWidget {
  const _CeilingCompactSellingSection({
    required this.priceController,
    required this.totalAreaM2,
    required this.totalSellingAmount,
  });

  final TextEditingController priceController;
  final double totalAreaM2;
  final double totalSellingAmount;

  @override
  Widget build(BuildContext context) {
    final areaText = MoneyFormatter.decimal(totalAreaM2);
    final sellingTotalText = MoneyFormatter.money(totalSellingAmount);

    return Container(
      key: ValueKey('ceiling-selling-section'),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iPhoneColor(context, _surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iPhoneColor(context, _border)),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'តម្លៃលក់ / m²',
                  style: TextStyle(
                    color: iPhoneColor(context, _textSecondary),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 95,
                height: isIPhoneLayout(context) ? 44 : 36,
                child: AdaptiveTextField(
                  key: ValueKey('ceiling-temporary-price-per-m2'),
                  controller: priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: iPhoneColor(context, _primary),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    prefixText: r'$ ',
                    prefixStyle: TextStyle(
                      color: iPhoneColor(context, _primary),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    fillColor: iPhoneColor(context, AppColors.inputBackground),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: iPhoneColor(context, _border),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: iPhoneColor(context, _border),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: iPhoneColor(context, _primary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'ផ្ទៃសរុប',
                  style: TextStyle(
                    color: iPhoneColor(context, _textSecondary),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$areaText m²',
                key: ValueKey('ceiling-selling-total-area'),
                style: TextStyle(
                  color: iPhoneColor(context, _text),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Divider(height: 1, color: iPhoneColor(context, _border)),
          SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  'សរុបតម្លៃលក់',
                  style: TextStyle(
                    color: iPhoneColor(context, _text),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  sellingTotalText,
                  key: ValueKey('ceiling-selling-total-amount'),
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.successText),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
