import '../../../../core/ios/iphone_controls.dart';
import '../../../../core/ios/iphone_design.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app_state.dart';
import '../../../../core/constants/business_ids.dart';
import '../../../../core/theme/sakura_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/widgets/product_image_thumbnail.dart';
import '../../../measurement_calculator/domain/models/measurement_models.dart';
import '../../../measurement_calculator/native/measurement_native_api.dart';
import '../../data/pvc_physical_catalog.dart';
import '../../domain/pvc_quantity_calculation_service.dart';
import '../../domain/pvc_quantity_models.dart';
import '../widgets/pvc_reply_generator.dart';

class PvcQuantityCalculatorScreen extends StatefulWidget {
  const PvcQuantityCalculatorScreen({
    super.key,
    this.optimizer,
    this.products,
    this.compactMobile = false,
    this.simpleAreaEstimates = kIsWeb,
  });

  final MeasurementOptimizer? optimizer;
  final List<PvcPhysicalProduct>? products;
  final bool compactMobile;
  final bool simpleAreaEstimates;

  @override
  State<PvcQuantityCalculatorScreen> createState() =>
      _PvcQuantityCalculatorScreenState();
}

class _PvcQuantityCalculatorScreenState
    extends State<PvcQuantityCalculatorScreen> {
  final _search = TextEditingController();
  final _horizontalScroll = ScrollController();
  final _groups = <_EditableGroup>[];
  final Map<String, TextEditingController> _priceControllers = {};
  Timer? _debounce;
  late List<PvcPhysicalProduct> _products;
  late PvcQuantityCalculationService _service;
  PvcProductCategory? _category;
  PvcQuantityWorkspaceResult? _result;
  MeasurementOptimizationOptions _options =
      const MeasurementOptimizationOptions();
  int _activeGroupIndex = 0;
  int _nextGroupId = 1;
  int _nextZoneId = 1;
  int _calculationGeneration = 0;
  bool _initialized = false;
  bool _isCalculating = false;

  _EditableGroup get _activeGroup => _groups[_activeGroupIndex];

  TextEditingController _priceControllerFor(String productId) {
    return _priceControllers.putIfAbsent(productId, () {
      final controller = TextEditingController(
        text: _defaultPriceFor(productId)?.toStringAsFixed(2),
      );
      controller.addListener(() => setState(() {}));
      return controller;
    });
  }

  double? _defaultPriceFor(String productId) {
    final product = _products.firstWhere(
      (item) => item.id == productId,
      orElse: () => throw StateError('Unknown PVC product: $productId'),
    );
    final priceType = product.isPackagePriced
        ? PriceTypeIds.saleBoxPrice
        : PriceTypeIds.saleUnitPrice;
    AppState? state;
    try {
      state = context.read<AppState>();
    } catch (_) {
      // Some catalog/unit tests intentionally render this widget without the
      // application provider. In that case prices stay editable and blank.
      return null;
    }
    return state.prices
        .where(
          (price) =>
              price.materialId == productId && price.priceTypeId == priceType,
        )
        .where((price) => price.active)
        .map((price) => price.price)
        .firstOrNull;
  }

  double _calculateGrandTotal(List<PvcProductQuantityResult> products) {
    var sum = 0.0;
    for (final res in products) {
      final controller = _priceControllers[res.product.id];
      final price = double.tryParse(controller?.text.trim() ?? '') ?? 0.0;
      sum += res.billableQuantity * price;
    }
    return sum;
  }

  @override
  void initState() {
    super.initState();
    _search.addListener(_searchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (widget.products != null) {
      _products = widget.products!;
    } else {
      final state = context.read<AppState>();
      _products = const PvcPhysicalCatalog().build(state.materials);
      _options = state.measurementOptions;
    }
    _service = PvcQuantityCalculationService(
      optimizer: widget.optimizer,
      simpleAreaEstimates: widget.simpleAreaEstimates,
    );
    _groups.add(_EditableGroup(id: _nextGroupId++, length: '6', width: '4.2'));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search
      ..removeListener(_searchChanged)
      ..dispose();
    _horizontalScroll.dispose();
    for (final group in _groups) {
      group.dispose();
    }
    for (final controller in _priceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return SizedBox.shrink();
    if (isIPhoneLayout(context) && widget.compactMobile) {
      return _buildCompactMobileQuote();
    }
    if (isIPhoneLayout(context)) {
      return IPhoneWorkspace(
        continuous: true,
        mobilePanelHeights: const [600, 520, 600],
        panels: [_measurementPanel(), _productsPanel(), _resultsPanel()],
        footer: const PvcReplyGenerator(compactMobile: true),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: ValueKey('pvc-page-scroll'),
        child: Column(
          children: [
            SizedBox(
              height: constraints.maxHeight < 660 ? 660 : constraints.maxHeight,
              child: _buildWorkspace(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: PvcReplyGenerator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMobileQuote() {
    final result = _result;
    final products = [
      for (final item in result?.products ?? const <PvcProductQuantityResult>[])
        if (item.quantity > 0) item,
    ];
    final notices = [
      for (final item in result?.products ?? const <PvcProductQuantityResult>[])
        ...item.notices,
    ];
    final hasAreaEstimate =
        result?.products.any((item) => item.isAreaEstimate) ?? false;
    final grandTotal = _calculateGrandTotal(products);
    final quotation = _pvcQuotationText(products, grandTotal);
    final group = _activeGroup;
    final model = group.toModel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _compactPvcCard(
          title: 'ទំហំ PVC',
          child: _GroupEditorCard(
            group: group,
            groupNumber: _activeGroupIndex + 1,
            compact: true,
            canDelete: _groups.length > 1,
            onChanged: _workspaceChanged,
            onModeChanged: (mode) {
              setState(() {
                group.mode = mode;
                _syncAutoAccessoryLengths(group);
              });
              _scheduleCalculation();
            },
            onDelete: () => _removeGroup(_activeGroupIndex),
          ),
        ),
        SizedBox(height: 8),
        _compactPvcCard(
          title: hasAreaEstimate
              ? 'សរុប និងតម្លៃ · ប៉ាន់ស្មាន'
              : 'សរុប និងតម្លៃ',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _WorkspaceTotals(
                totalArea: model.totalAreaM2,
                allocatedArea: model.allocatedAreaM2,
              ),
              SizedBox(height: 8),
              if (notices.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(bottom: 7),
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  decoration: BoxDecoration(
                    color: iPhoneColor(context, AppColors.warningBg),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    notices.join(' • '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.warningText),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (products.isEmpty)
                Text(
                  notices.isEmpty
                      ? 'សូមបន្ថែមសម្ភារៈក្នុងការកំណត់បន្ថែម'
                      : 'មិនទាន់មានសម្ភារៈដែលអាចគណនា',
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.textMuted),
                    fontSize: 12,
                  ),
                )
              else
                for (final item in products) ...[
                  _compactPvcPriceRow(item),
                  SizedBox(height: 6),
                ],
              _compactPvcTotal(grandTotal),
            ],
          ),
        ),
        SizedBox(height: 8),
        _compactPvcCard(
          title: 'សម្រង់តម្លៃ',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                quotation,
                key: ValueKey('mobile-pvc-quotation'),
                style: TextStyle(
                  color: iPhoneColor(context, AppColors.textMain),
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              SizedBox(height: 10),
              FilledButton.icon(
                key: ValueKey('mobile-pvc-quick-quote-copy'),
                onPressed: () => _copyQuotation(quotation),
                icon: Icon(Icons.copy_rounded, size: 18),
                label: Text('ចម្លងសម្រង់តម្លៃ'),
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 4),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            'ការកំណត់បន្ថែម',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          children: [
            SizedBox(height: 520, child: _productsPanel()),
            SizedBox(height: 600, child: _resultsPanel()),
          ],
        ),
        SizedBox(height: 8),
        const PvcReplyGenerator(compactMobile: true),
      ],
    );
  }

  Widget _compactPvcCard({required String title, required Widget child}) {
    return AppGlassSurface(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 11),
      borderRadius: BorderRadius.circular(16),
      tint: iPhoneColor(context, AppColors.surfaceGlass),
      borderColor: iPhoneColor(context, AppColors.glassHighlight),
      blur: AppEffects.glassBlur,
      shadows: AppShadows.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: iPhoneColor(context, AppColors.primaryText),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 7),
          child,
        ],
      ),
    );
  }

  Widget _compactPvcPriceRow(PvcProductQuantityResult item) {
    final controller = _priceControllerFor(item.product.id);
    final price = double.tryParse(controller.text.trim()) ?? 0.0;
    return Row(
      children: [
        Expanded(
          child: Text(
            '${item.product.nameKhmer} · ${item.quantitySummary}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        SizedBox(width: 7),
        SizedBox(
          width: 92,
          height: 44,
          child: AdaptiveTextField(
            key: ValueKey('mobile-pvc-price-${item.product.id}'),
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: r'$ ',
              hintText: item.priceUnitLabel,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 7),
            ),
          ),
        ),
        SizedBox(width: 7),
        SizedBox(
          width: 70,
          child: Text(
            MoneyFormatter.money(item.billableQuantity * price),
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _compactPvcTotal(double total) {
    return Container(
      key: ValueKey('mobile-pvc-total'),
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.successBg),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: iPhoneColor(context, AppColors.successBorder),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'សរុបអតិថិជនបង់',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            MoneyFormatter.money(total),
            style: TextStyle(
              color: iPhoneColor(context, AppColors.successText),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _pvcQuotationText(
    List<PvcProductQuantityResult> products,
    double total,
  ) {
    final area = _groups.fold<double>(
      0,
      (sum, group) => sum + group.toModel().totalAreaM2,
    );
    final lines = <String>[
      'បាទបង 🙏',
      'សម្រង់ក្ដារ PVC',
      '📐 ផ្ទៃសរុប៖ ${_number(area)}m²',
      if (products.any((item) => item.isAreaEstimate))
        'ℹ️ បរិមាណសន្លឹក៖ ប៉ាន់ស្មានតាមផ្ទៃ អាចមានសំណល់បន្ថែម',
      for (final item in products)
        if (item.quantity > 0)
          '• ${item.product.nameKhmer}៖ ${item.quantitySummary} · ${MoneyFormatter.money(item.billableQuantity * (double.tryParse(_priceControllers[item.product.id]?.text.trim() ?? '') ?? 0.0))}',
      'សរុបតម្លៃ៖ ${MoneyFormatter.money(total)}',
    ];
    return lines.join('\n');
  }

  Future<void> _copyQuotation(String quotation) async {
    try {
      await Clipboard.setData(ClipboardData(text: quotation));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('បានចម្លងសម្រង់តម្លៃ')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('មិនអាចចម្លងបាន សូមព្យាយាមម្ដងទៀត')),
      );
    }
  }

  Widget _buildWorkspace() {
    return Padding(
      padding: EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final workspace = _workspaceRow();
          if (constraints.maxWidth >= 1180) return workspace;
          return Scrollbar(
            controller: _horizontalScroll,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              key: ValueKey('pvc-workspace-horizontal-scroll'),
              controller: _horizontalScroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1160,
                height: constraints.maxHeight,
                child: workspace,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _workspaceRow() {
    return Row(
      key: ValueKey('pvc-quantity-workspace'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 36, child: _measurementPanel()),
        SizedBox(width: 8),
        Expanded(flex: 34, child: _productsPanel()),
        SizedBox(width: 8),
        Expanded(flex: 30, child: _resultsPanel()),
      ],
    );
  }

  Widget _measurementPanel() {
    final group = _activeGroup;
    final model = group.toModel();
    return _Panel(
      key: ValueKey('pvc-measurement-panel'),
      title: 'ROOM / AREA',
      subtitle: 'Create an area, then split it into material zones.',
      trailing: IconButton.filledTonal(
        key: ValueKey('pvc-add-group'),
        tooltip: 'Add room / area group',
        onPressed: _addGroup,
        icon: Icon(Icons.add_rounded, size: 19),
      ),
      child: Column(
        children: [
          SizedBox(
            height: isIPhoneLayout(context) ? 44 : 38,
            child: ListView.separated(
              key: ValueKey('pvc-group-tabs'),
              scrollDirection: Axis.horizontal,
              itemCount: _groups.length,
              separatorBuilder: (_, _) => SizedBox(width: 6),
              itemBuilder: (context, index) {
                final item = _groups[index];
                return ChoiceChip(
                  key: ValueKey('pvc-group-${item.id}'),
                  label: Text('Area ${index + 1}'),
                  selected: index == _activeGroupIndex,
                  onSelected: (_) => setState(() => _activeGroupIndex = index),
                  avatar: index == _activeGroupIndex
                      ? Icon(Icons.crop_square_rounded, size: 15)
                      : null,
                );
              },
            ),
          ),
          SizedBox(height: 10),
          _GroupEditorCard(
            group: group,
            groupNumber: _activeGroupIndex + 1,
            canDelete: _groups.length > 1,
            onChanged: _workspaceChanged,
            onModeChanged: (mode) {
              setState(() {
                group.mode = mode;
                _syncAutoAccessoryLengths(group);
              });
              _scheduleCalculation();
            },
            onDelete: () => _removeGroup(_activeGroupIndex),
          ),
          SizedBox(height: 10),
          _AllocationCard(group: model),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'MATERIAL ZONES',
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.textMuted),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Text(
                '${group.zones.length}',
                style: TextStyle(
                  color: iPhoneColor(context, AppColors.primaryText),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: group.zones.isEmpty
                ? _EmptyZones()
                : ListView.separated(
                    key: ValueKey('pvc-zone-list-${group.id}'),
                    padding: EdgeInsets.only(bottom: 8),
                    itemCount: group.zones.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final zone = group.zones[index];
                      final derived = model.derivedZones[index];
                      return _ZoneCard(
                        key: ValueKey('pvc-zone-${zone.id}'),
                        zone: zone,
                        zoneNumber: index + 1,
                        products: _products,
                        derived: derived,
                        roomCount: model.roomCount,
                        onChanged: _workspaceChanged,
                        onAccessoryLengthChanged: () =>
                            _overrideAccessoryLength(zone),
                        onRestoreAutoLength: () =>
                            _restoreAutoAccessoryLength(group, zone),
                        onModeChanged: (mode) => _setZoneMode(zone, mode),
                        onProductChanged: (product) =>
                            _changeZoneProduct(zone, product),
                        onAdvanced: () => _editAdvanced(zone),
                        onDelete: () => _removeZone(zone),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _productsPanel() {
    final products = _visibleProducts;
    return _Panel(
      key: ValueKey('pvc-products-panel'),
      title: 'PRODUCTS',
      subtitle:
          'Physical types only. Colors and designs do not duplicate rows.',
      child: Column(
        children: [
          isIPhoneLayout(context)
              ? IPhoneSearchField(
                  controller: _search,
                  placeholder: 'ស្វែងរកផលិតផល',
                )
              : AdaptiveTextField(
                  key: ValueKey('pvc-product-search'),
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search PVC material…',
                    prefixIcon: Icon(Icons.search_rounded, size: 19),
                    isDense: true,
                  ),
                ),
          SizedBox(height: 9),
          SizedBox(
            height: isIPhoneLayout(context) ? 44 : 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _category == null,
                  onTap: () => setState(() => _category = null),
                ),
                for (final category in PvcProductCategory.values)
                  Padding(
                    padding: EdgeInsets.only(left: 5),
                    child: _CategoryChip(
                      key: ValueKey('pvc-category-${category.name}'),
                      label: _categoryLabel(category),
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 9),
          Expanded(
            child: products.isEmpty
                ? Center(child: Text('No matching PVC materials.'))
                : ListView.separated(
                    key: ValueKey('pvc-product-list'),
                    padding: EdgeInsets.only(bottom: 8),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductRow(
                        key: ValueKey('pvc-product-${product.id}'),
                        product: product,
                        onAdd: () => _addProduct(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _resultsPanel() {
    final result = _result;
    final products = result?.products ?? [];
    final grandTotal = _calculateGrandTotal(products);

    return _Panel(
      key: ValueKey('pvc-results-panel'),
      title: 'QUANTITY NEEDED',
      subtitle: 'Pieces, sheets, and lengths only.',
      trailing: _isCalculating
          ? SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : Icon(
              Icons.inventory_2_outlined,
              color: iPhoneColor(context, AppColors.primaryText),
              size: 21,
            ),
      child: Column(
        children: [
          _WorkspaceTotals(
            totalArea: _groups.fold(
              0,
              (total, group) => total + group.toModel().totalAreaM2,
            ),
            allocatedArea: _groups.fold(
              0,
              (total, group) => total + group.toModel().allocatedAreaM2,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: products.isEmpty
                ? _EmptyResults()
                : ListView.separated(
                    key: ValueKey('pvc-result-list'),
                    padding: EdgeInsets.only(bottom: 8),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = products[index];
                      return _ProductResultCard(
                        result: item,
                        priceController: _priceControllerFor(item.product.id),
                      );
                    },
                  ),
          ),
          if (products.isNotEmpty) ...[
            SizedBox(height: 8),
            _PvcSellingGrandTotalSection(grandTotal: grandTotal),
          ],
        ],
      ),
    );
  }

  List<PvcPhysicalProduct> get _visibleProducts {
    final query = _search.text.trim().toLowerCase();
    return _products
        .where((product) {
          if (_category != null && product.category != _category) return false;
          if (query.isEmpty) return true;
          return '${product.nameKhmer} ${product.family} ${product.spec}'
              .toLowerCase()
              .contains(query);
        })
        .toList(growable: false);
  }

  void _searchChanged() => setState(() {});

  void _addGroup() {
    setState(() {
      _groups.add(
        _EditableGroup(id: _nextGroupId++, length: '6', width: '4.2'),
      );
      _activeGroupIndex = _groups.length - 1;
    });
    _scheduleCalculation();
  }

  void _removeGroup(int index) {
    final removed = _groups.removeAt(index);
    removed.dispose();
    setState(() {
      if (_activeGroupIndex >= _groups.length) {
        _activeGroupIndex = _groups.length - 1;
      }
    });
    _scheduleCalculation(immediate: true);
  }

  void _addProduct(PvcPhysicalProduct product) {
    final group = _activeGroup;
    final hasAreaZone = group.zones.any(
      (zone) => zone.product.consumesRoomArea,
    );
    final useRoomDefaults = product.isLinearAccessory || !hasAreaZone;
    final autoAccessory = product.usesEditablePerimeterLength;
    final zone = _EditableZone(
      id: _nextZoneId++,
      product: product,
      inputMode: autoAccessory
          ? PvcZoneInputMode.perimeterStrip
          : group.mode == PvcGroupInputMode.dimensions
          ? PvcZoneInputMode.dimensions
          : PvcZoneInputMode.area,
      length: useRoomDefaults ? group.length.text : '',
      width: useRoomDefaults ? group.width.text : '',
      area: useRoomDefaults && group.mode == PvcGroupInputMode.area
          ? group.area.text
          : '',
      customRun: autoAccessory ? _automaticPerimeterText(group) : '',
      calculationMode:
          product.calculationUnit == PvcProductCalculationUnit.manual
          ? PvcZoneCalculationMode.manualQuantity
          : PvcZoneCalculationMode.auto,
    );
    setState(() {
      final remainingIndex = group.zones.indexWhere(
        (item) => item.useRemainingArea,
      );
      if (remainingIndex >= 0) {
        group.zones.insert(remainingIndex, zone);
      } else {
        group.zones.add(zone);
      }
      _reconcileAutomaticFill(group);
    });
    _scheduleCalculation(immediate: true);
  }

  void _removeZone(_EditableZone zone) {
    setState(() {
      _activeGroup.zones.remove(zone);
      _reconcileAutomaticFill(_activeGroup);
    });
    zone.dispose();
    _scheduleCalculation(immediate: true);
  }

  void _setZoneMode(_EditableZone zone, PvcZoneInputMode mode) {
    setState(() {
      zone.useRemainingArea = false;
      zone.inputMode = mode;
      _reconcileAutomaticFill(_activeGroup);
    });
    _scheduleCalculation();
  }

  void _changeZoneProduct(_EditableZone zone, PvcPhysicalProduct product) {
    setState(() {
      final wasEditableAccessory = zone.product.usesEditablePerimeterLength;
      final previousUnit = zone.product.calculationUnit;
      zone.product = product;
      if (!product.supportsManualSheetQuantity &&
          zone.inputMode == PvcZoneInputMode.sheetQuantity) {
        _restoreRoomInput(_activeGroup, zone);
      }
      if (product.calculationUnit == PvcProductCalculationUnit.manual) {
        zone.calculationMode = PvcZoneCalculationMode.manualQuantity;
      } else if (previousUnit == PvcProductCalculationUnit.manual &&
          zone.calculationMode == PvcZoneCalculationMode.manualQuantity) {
        zone.calculationMode = PvcZoneCalculationMode.auto;
      }
      if (product.usesEditablePerimeterLength) {
        zone
          ..calculationMode = PvcZoneCalculationMode.auto
          ..inputMode = PvcZoneInputMode.perimeterStrip
          ..perimeterRunMode = PvcPerimeterRunMode.autoPerimeter
          ..useRemainingArea = false;
        zone.customRun.text = _automaticPerimeterText(_activeGroup);
      } else if (product.isLinearAccessory) {
        zone.useRemainingArea = false;
        if (_activeGroup.mode == PvcGroupInputMode.dimensions) {
          zone.inputMode = PvcZoneInputMode.dimensions;
          if (zone.length.text.trim().isEmpty) {
            zone.length.text = _activeGroup.length.text;
          }
          if (zone.width.text.trim().isEmpty) {
            zone.width.text = _activeGroup.width.text;
          }
        }
      } else if (wasEditableAccessory) {
        _restoreRoomInput(_activeGroup, zone);
      }
      _reconcileAutomaticFill(_activeGroup);
    });
    _scheduleCalculation(immediate: true);
  }

  Future<void> _editAdvanced(_EditableZone zone) async {
    if (zone.product.usesEditablePerimeterLength) return;
    final values = await showAdaptiveEditor<_AdvancedValues>(
      context: context,
      builder: (context) => _AdvancedCalculationDialog(zone: zone),
    );
    if (values == null || !mounted) return;
    setState(() {
      zone.calculationMode = values.calculationMode;
      zone.orientation = values.orientation;
      zone.inputMode = values.inputMode;
      zone.perimeterRunMode = values.perimeterRunMode;
      zone.useRemainingArea = values.useRemainingArea;
      zone.linear.text = values.linear;
      zone.stripWidth.text = values.stripWidth;
      zone.customRun.text = values.customRun;
      zone.coverage.text = values.coverage;
      zone.manualQuantity.text = values.manualQuantity;
      if (values.calculationMode == PvcZoneCalculationMode.coveragePerPiece &&
          zone.inputMode == PvcZoneInputMode.linear) {
        zone.inputMode = PvcZoneInputMode.area;
      }
      _reconcileAutomaticFill(_activeGroup);
    });
    _scheduleCalculation(immediate: true);
  }

  void _workspaceChanged() {
    setState(() => _syncAutoAccessoryLengths(_activeGroup));
    _scheduleCalculation();
  }

  void _overrideAccessoryLength(_EditableZone zone) {
    setState(() {
      zone.perimeterRunMode = PvcPerimeterRunMode.custom;
    });
    _scheduleCalculation();
  }

  void _restoreAutoAccessoryLength(_EditableGroup group, _EditableZone zone) {
    setState(() {
      zone.perimeterRunMode = PvcPerimeterRunMode.autoPerimeter;
      zone.customRun.text = _automaticPerimeterText(group);
    });
    _scheduleCalculation(immediate: true);
  }

  void _syncAutoAccessoryLengths(_EditableGroup group) {
    final value = _automaticPerimeterText(group);
    for (final zone in group.zones) {
      if (zone.product.usesEditablePerimeterLength &&
          zone.perimeterRunMode == PvcPerimeterRunMode.autoPerimeter) {
        zone.customRun.text = value;
      }
    }
  }

  String _automaticPerimeterText(_EditableGroup group) {
    if (group.mode != PvcGroupInputMode.dimensions) return '';
    final length = _positiveDouble(group.length.text) ?? 0;
    final width = _positiveDouble(group.width.text) ?? 0;
    if (length <= 0 || width <= 0) return '';
    return _number(2 * (length + width));
  }

  void _reconcileAutomaticFill(_EditableGroup group) {
    final hasFixedArea = group.zones.any(
      (zone) =>
          zone.inputMode != PvcZoneInputMode.sheetQuantity &&
          zone.product.areaAllocationRole == PvcAreaAllocationRole.fixed,
    );
    final fill = hasFixedArea
        ? group.zones.cast<_EditableZone?>().firstWhere(
            (zone) =>
                zone?.product.areaAllocationRole ==
                    PvcAreaAllocationRole.fillCapable &&
                zone?.inputMode != PvcZoneInputMode.sheetQuantity,
            orElse: () => null,
          )
        : null;

    for (final zone in group.zones) {
      if (identical(zone, fill)) {
        zone
          ..useRemainingArea = true
          ..inputMode = PvcZoneInputMode.area;
      } else if (zone.product.areaAllocationRole ==
              PvcAreaAllocationRole.fillCapable &&
          zone.useRemainingArea) {
        zone.useRemainingArea = false;
        _restoreRoomInput(group, zone);
      } else if (fill != null && zone.useRemainingArea) {
        zone.useRemainingArea = false;
        _restoreRoomInput(group, zone);
      }
    }

    if (fill == null) return;
    final fillIndex = group.zones.indexOf(fill);
    if (fillIndex >= 0 && fillIndex != group.zones.length - 1) {
      group.zones
        ..removeAt(fillIndex)
        ..add(fill);
    }
  }

  void _restoreRoomInput(_EditableGroup group, _EditableZone zone) {
    if (group.mode == PvcGroupInputMode.dimensions) {
      zone.inputMode = PvcZoneInputMode.dimensions;
      if (zone.length.text.trim().isEmpty) zone.length.text = group.length.text;
      if (zone.width.text.trim().isEmpty) zone.width.text = group.width.text;
      return;
    }
    zone.inputMode = PvcZoneInputMode.area;
    if (zone.area.text.trim().isEmpty) zone.area.text = group.area.text;
  }

  void _scheduleCalculation({bool immediate = false}) {
    _debounce?.cancel();
    if (immediate) {
      unawaited(_calculate());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 100), _calculate);
  }

  Future<void> _calculate() async {
    final generation = ++_calculationGeneration;
    final groups = [for (final group in _groups) group.toModel()];
    if (mounted) setState(() => _isCalculating = true);
    final result = await _service.calculate(groups: groups, options: _options);
    if (!mounted || generation != _calculationGeneration) return;
    setState(() {
      _result = result;
      _isCalculating = false;
    });
  }

  String _categoryLabel(PvcProductCategory category) => switch (category) {
    PvcProductCategory.panels => 'Panels',
    PvcProductCategory.trims => 'Trims',
    PvcProductCategory.cLine => 'C-Line',
    PvcProductCategory.gdDb => 'GD / DB',
    PvcProductCategory.other => 'Other',
  };
}

class _EditableGroup {
  _EditableGroup({
    required this.id,
    String length = '',
    String width = '',
    String area = '',
    String count = '1',
  }) : length = TextEditingController(text: length),
       width = TextEditingController(text: width),
       area = TextEditingController(text: area),
       count = TextEditingController(text: count);

  final int id;
  PvcGroupInputMode mode = PvcGroupInputMode.dimensions;
  final TextEditingController length;
  final TextEditingController width;
  final TextEditingController area;
  final TextEditingController count;
  final List<_EditableZone> zones = [];

  PvcMeasurementGroup toModel() {
    return PvcMeasurementGroup(
      id: id,
      name: 'Area $id',
      inputMode: mode,
      lengthM: _positiveDouble(length.text),
      widthM: _positiveDouble(width.text),
      directAreaM2: _positiveDouble(area.text),
      roomCount: _positiveInt(count.text) ?? 1,
      zones: [
        for (var index = 0; index < zones.length; index++)
          zones[index].toModel(index + 1),
      ],
    );
  }

  void dispose() {
    length.dispose();
    width.dispose();
    area.dispose();
    count.dispose();
    for (final zone in zones) {
      zone.dispose();
    }
  }
}

class _EditableZone {
  _EditableZone({
    required this.id,
    required this.product,
    required this.inputMode,
    required String length,
    required String width,
    required String area,
    String customRun = '',
    required this.calculationMode,
  }) : length = TextEditingController(text: length),
       width = TextEditingController(text: width),
       area = TextEditingController(text: area),
       linear = TextEditingController(),
       stripWidth = TextEditingController(),
       customRun = TextEditingController(text: customRun),
       coverage = TextEditingController(),
       manualQuantity = TextEditingController();

  final int id;
  PvcPhysicalProduct product;
  PvcZoneInputMode inputMode;
  PvcZoneCalculationMode calculationMode;
  PvcPerimeterRunMode perimeterRunMode = PvcPerimeterRunMode.autoPerimeter;
  bool useRemainingArea = false;
  MeasurementOrientation? orientation;
  final TextEditingController length;
  final TextEditingController width;
  final TextEditingController area;
  final TextEditingController linear;
  final TextEditingController stripWidth;
  final TextEditingController customRun;
  final TextEditingController coverage;
  final TextEditingController manualQuantity;

  bool get usesManualSheetQuantity =>
      inputMode == PvcZoneInputMode.sheetQuantity &&
      product.supportsManualSheetQuantity;

  PvcQuantityZone toModel(int zoneNumber) {
    return PvcQuantityZone(
      id: id,
      name: 'Zone $zoneNumber',
      product: product,
      inputMode: inputMode,
      lengthM: _positiveDouble(length.text),
      widthM: _positiveDouble(width.text),
      areaM2: _positiveDouble(area.text),
      requiredLinearM: _positiveDouble(linear.text),
      stripWidthM: _positiveDouble(stripWidth.text),
      perimeterRunMode: perimeterRunMode,
      customRunM: _positiveDouble(customRun.text),
      useRemainingArea: useRemainingArea,
      calculationMode: calculationMode,
      coveragePerPieceM2: _positiveDouble(coverage.text),
      manualQuantity: _positiveInt(manualQuantity.text),
      orientation: orientation,
    );
  }

  void dispose() {
    length.dispose();
    width.dispose();
    area.dispose();
    linear.dispose();
    stripWidth.dispose();
    customRun.dispose();
    coverage.dispose();
    manualQuantity.dispose();
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      padding: EdgeInsets.fromLTRB(14, 13, 14, 12),
      borderRadius: BorderRadius.circular(AppEffects.panelRadius),
      tint: iPhoneColor(context, AppColors.surfaceGlass),
      borderColor: iPhoneColor(context, AppColors.glassHighlight),
      blur: AppEffects.glassBlur,
      shadows: AppShadows.glassCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.textMain),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.textMuted),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[SizedBox(width: 8), trailing!],
            ],
          ),
          SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _GroupEditorCard extends StatelessWidget {
  const _GroupEditorCard({
    required this.group,
    required this.groupNumber,
    this.compact = false,
    required this.canDelete,
    required this.onChanged,
    required this.onModeChanged,
    required this.onDelete,
  });

  final _EditableGroup group;
  final int groupNumber;
  final bool compact;
  final bool canDelete;
  final VoidCallback onChanged;
  final ValueChanged<PvcGroupInputMode> onModeChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final model = group.toModel();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.card),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: iPhoneColor(context, AppColors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.all(11),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Area group $groupNumber',
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.textMain),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (canDelete)
                  IconButton(
                    tooltip: 'Delete group',
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: iPhoneColor(context, AppColors.errorText),
                      size: 19,
                    ),
                  ),
              ],
            ),
            _ModeToggle<PvcGroupInputMode>(
              values: [PvcGroupInputMode.dimensions, PvcGroupInputMode.area],
              selected: group.mode,
              label: (mode) => switch (mode) {
                PvcGroupInputMode.dimensions => 'Length × Width',
                PvcGroupInputMode.area => 'Direct m²',
              },
              keyFor: (mode) => 'pvc-group-mode-${mode.name}-${group.id}',
              onSelected: onModeChanged,
            ),
            SizedBox(height: 10),
            if (group.mode == PvcGroupInputMode.dimensions)
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      key: ValueKey('pvc-group-length-${group.id}'),
                      controller: group.length,
                      label: compact ? 'L' : 'Length',
                      suffix: 'm',
                      onChanged: onChanged,
                    ),
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: _NumberField(
                      key: ValueKey('pvc-group-width-${group.id}'),
                      controller: group.width,
                      label: compact ? 'W' : 'Width',
                      suffix: 'm',
                      onChanged: onChanged,
                    ),
                  ),
                ],
              )
            else
              _NumberField(
                key: ValueKey('pvc-group-area-${group.id}'),
                controller: group.area,
                label: compact ? 'Area' : 'Area per room',
                suffix: 'm²',
                onChanged: onChanged,
              ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _NumberField(
                    key: ValueKey('pvc-group-count-${group.id}'),
                    controller: group.count,
                    label: compact ? 'Rooms' : 'Identical rooms',
                    suffix: compact ? '' : 'rooms',
                    integer: true,
                    onChanged: onChanged,
                  ),
                ),
                SizedBox(width: 9),
                Expanded(
                  child: _Metric(
                    label: 'TOTAL AREA',
                    value: '${_number(model.totalAreaM2)} m²',
                    key: ValueKey('pvc-group-total-${group.id}'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  const _AllocationCard({required this.group});

  final PvcMeasurementGroup group;

  @override
  Widget build(BuildContext context) {
    final delta = group.allocationDeltaM2;
    final over = delta < -0.0001;
    final complete = delta.abs() <= 0.0001;
    final color = over
        ? iPhoneColor(context, AppColors.errorText)
        : complete
        ? iPhoneColor(context, AppColors.successText)
        : iPhoneColor(context, AppColors.warningText);
    final background = over
        ? iPhoneColor(context, AppColors.errorBg)
        : complete
        ? iPhoneColor(context, AppColors.successBg)
        : iPhoneColor(context, AppColors.warningBg);
    final status = over
        ? 'Over allocated: ${_number(-delta)} m²'
        : 'Remaining: ${_number(delta.clamp(0, double.infinity))} m²';
    return Container(
      key: ValueKey('pvc-allocation-${group.id}'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            over
                ? Icons.warning_amber_rounded
                : complete
                ? Icons.check_circle_outline_rounded
                : Icons.pie_chart_outline_rounded,
            color: color,
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Allocated ${_number(group.allocatedAreaM2)} / ${_number(group.totalAreaM2)} m²\n$status',
              style: TextStyle(
                color: color,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  const _ZoneCard({
    super.key,
    required this.zone,
    required this.zoneNumber,
    required this.products,
    required this.derived,
    required this.roomCount,
    required this.onChanged,
    required this.onAccessoryLengthChanged,
    required this.onRestoreAutoLength,
    required this.onModeChanged,
    required this.onProductChanged,
    required this.onAdvanced,
    required this.onDelete,
  });

  final _EditableZone zone;
  final int zoneNumber;
  final List<PvcPhysicalProduct> products;
  final PvcZoneDerivedMeasurement derived;
  final int roomCount;
  final VoidCallback onChanged;
  final VoidCallback onAccessoryLengthChanged;
  final VoidCallback onRestoreAutoLength;
  final ValueChanged<PvcZoneInputMode> onModeChanged;
  final ValueChanged<PvcPhysicalProduct> onProductChanged;
  final VoidCallback onAdvanced;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final packaging = zone.product.perMeterPackaging;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.card),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: iPhoneColor(context, AppColors.border)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(11, 9, 8, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: iPhoneColor(context, AppColors.surfaceSelected),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$zoneNumber',
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.primaryText),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: PopupMenuButton<PvcPhysicalProduct>(
                    key: ValueKey('pvc-zone-product-${zone.id}'),
                    tooltip: 'Change product',
                    onSelected: onProductChanged,
                    itemBuilder: (context) => [
                      for (final product in products)
                        PopupMenuItem(
                          value: product,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.nameKhmer,
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                product.spec,
                                style: TextStyle(
                                  color: iPhoneColor(
                                    context,
                                    AppColors.textMuted,
                                  ),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zone.product.nameKhmer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: iPhoneColor(
                                    context,
                                    AppColors.textMain,
                                  ),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                zone.product.spec,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: iPhoneColor(
                                    context,
                                    AppColors.textMuted,
                                  ),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.unfold_more_rounded,
                          color: iPhoneColor(context, AppColors.textMuted),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                if (packaging == null)
                  IconButton(
                    key: ValueKey('pvc-zone-settings-${zone.id}'),
                    tooltip: 'Advanced calculation',
                    onPressed: onAdvanced,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.more_horiz_rounded, size: 20),
                  ),
                IconButton(
                  tooltip: 'Remove zone',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    color: iPhoneColor(context, AppColors.errorText),
                    size: 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (packaging != null)
              _perMeterAccessoryEditor(packaging)
            else ...[
              _ModeToggle<PvcZoneInputMode>(
                values: [
                  PvcZoneInputMode.dimensions,
                  PvcZoneInputMode.area,
                  if (zone.product.supportsManualSheetQuantity)
                    PvcZoneInputMode.sheetQuantity,
                ],
                selected: zone.inputMode,
                label: (mode) => switch (mode) {
                  PvcZoneInputMode.dimensions => 'បណ្ដោយ × ទទឹង',
                  PvcZoneInputMode.area => 'm²',
                  PvcZoneInputMode.sheetQuantity => 'ចំនួនសន្លឹក',
                  PvcZoneInputMode.perimeterStrip => '',
                  PvcZoneInputMode.linear => '',
                },
                keyFor: (mode) => 'pvc-zone-mode-${mode.name}-${zone.id}',
                onSelected: onModeChanged,
              ),
              if (!zone.useRemainingArea &&
                  (zone.inputMode == PvcZoneInputMode.dimensions ||
                      zone.inputMode == PvcZoneInputMode.area ||
                      zone.inputMode == PvcZoneInputMode.sheetQuantity)) ...[
                SizedBox(height: 8),
                _inputEditor(),
              ],
              SizedBox(height: 7),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  zone.usesManualSheetQuantity
                      ? '= ${_positiveInt(zone.manualQuantity.text) ?? 0} សន្លឹក'
                      : zone.product.isLinearAccessory
                      ? '= ${_number(derived.runLengthPerRoomM)} m'
                      : '= ${_number(derived.assignedAreaPerRoomM2)} m²',
                  key: ValueKey('pvc-zone-assigned-summary-${zone.id}'),
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.primaryText),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _perMeterAccessoryEditor(PvcPerMeterPackaging packaging) {
    final pieces =
        packaging.piecesForLength(derived.runLengthPerRoomM) * roomCount;
    final packages = packaging.packagesForPieces(pieces);
    final manual = zone.perimeterRunMode == PvcPerimeterRunMode.custom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _NumberField(
                key: ValueKey('pvc-zone-required-length-${zone.id}'),
                controller: zone.customRun,
                label: 'ត្រូវប្រើប្រវែង',
                suffix: 'm',
                onChanged: onAccessoryLengthChanged,
              ),
            ),
            if (manual) ...[
              SizedBox(width: 6),
              AdaptiveActionButton.textIcon(
                key: ValueKey('pvc-zone-auto-length-${zone.id}'),
                onPressed: onRestoreAutoLength,
                icon: Icon(Icons.refresh_rounded, size: 16),
                label: Text('Auto'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 7),
        Text(
          '${_number(packaging.piecesPerMeter)} គ្រាប់ / 1m',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '= $pieces គ្រាប់',
                key: ValueKey('pvc-zone-pieces-${zone.id}'),
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '= $packages កញ្ចប់',
                key: ValueKey('pvc-zone-packages-${zone.id}'),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inputEditor() {
    return switch (zone.inputMode) {
      PvcZoneInputMode.dimensions => Row(
        children: [
          Expanded(
            child: _NumberField(
              key: ValueKey('pvc-zone-length-${zone.id}'),
              controller: zone.length,
              label: 'Length',
              suffix: 'm',
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: _NumberField(
              key: ValueKey('pvc-zone-width-${zone.id}'),
              controller: zone.width,
              label: 'Width',
              suffix: 'm',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
      PvcZoneInputMode.area => _NumberField(
        key: ValueKey('pvc-zone-area-${zone.id}'),
        controller: zone.area,
        label: 'Assigned per room',
        suffix: 'm²',
        onChanged: onChanged,
      ),
      PvcZoneInputMode.sheetQuantity => _NumberField(
        key: ValueKey('pvc-zone-manual-sheets-${zone.id}'),
        controller: zone.manualQuantity,
        label: 'ចំនួនសន្លឹក',
        suffix: 'សន្លឹក',
        integer: true,
        onChanged: onChanged,
      ),
      PvcZoneInputMode.perimeterStrip => SizedBox.shrink(),
      PvcZoneInputMode.linear => SizedBox.shrink(),
    };
  }
}

class _AdvancedCalculationDialog extends StatefulWidget {
  const _AdvancedCalculationDialog({required this.zone});

  final _EditableZone zone;

  @override
  State<_AdvancedCalculationDialog> createState() =>
      _AdvancedCalculationDialogState();
}

class _AdvancedCalculationDialogState
    extends State<_AdvancedCalculationDialog> {
  late PvcZoneInputMode _inputMode;
  late PvcZoneCalculationMode _mode;
  late PvcPerimeterRunMode _perimeterRunMode;
  late bool _useRemainingArea;
  late MeasurementOrientation? _orientation;
  late final TextEditingController _linear;
  late final TextEditingController _stripWidth;
  late final TextEditingController _customRun;
  late final TextEditingController _coverage;
  late final TextEditingController _manual;

  @override
  void initState() {
    super.initState();
    _inputMode = widget.zone.inputMode;
    _mode = widget.zone.calculationMode;
    _perimeterRunMode = widget.zone.perimeterRunMode;
    _useRemainingArea = widget.zone.useRemainingArea;
    _orientation = widget.zone.orientation;
    _linear = TextEditingController(text: widget.zone.linear.text);
    _stripWidth = TextEditingController(text: widget.zone.stripWidth.text);
    _customRun = TextEditingController(text: widget.zone.customRun.text);
    _coverage = TextEditingController(text: widget.zone.coverage.text);
    _manual = TextEditingController(text: widget.zone.manualQuantity.text);
  }

  @override
  void dispose() {
    _linear.dispose();
    _stripWidth.dispose();
    _customRun.dispose();
    _coverage.dispose();
    _manual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.zone.product.nameKhmer} · Calculation'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use automatic physical dimensions, a shop-tested coverage, or a manual quantity.',
              style: TextStyle(
                color: iPhoneColor(context, AppColors.textSecondary),
                fontSize: 12,
              ),
            ),
            SizedBox(height: 16),
            AdaptiveChoiceField<PvcZoneInputMode>(
              key: ValueKey('pvc-advanced-input-mode'),
              initialValue: _inputMode,
              decoration: InputDecoration(labelText: 'Zone input'),
              items: [
                DropdownMenuItem(
                  value: PvcZoneInputMode.dimensions,
                  child: Text('Length × Width'),
                ),
                DropdownMenuItem(
                  value: PvcZoneInputMode.area,
                  child: Text('m²'),
                ),
                if (widget.zone.product.supportsManualSheetQuantity)
                  DropdownMenuItem(
                    value: PvcZoneInputMode.sheetQuantity,
                    child: Text('Sheet quantity'),
                  ),
                DropdownMenuItem(
                  value: PvcZoneInputMode.perimeterStrip,
                  child: Text('Perimeter / run'),
                ),
                DropdownMenuItem(
                  value: PvcZoneInputMode.linear,
                  child: Text('Linear meters'),
                ),
              ],
              onChanged: (value) => setState(() {
                _inputMode = value!;
                _useRemainingArea = false;
              }),
            ),
            if (widget.zone.product.calculationUnit ==
                PvcProductCalculationUnit.area) ...[
              SizedBox(height: 8),
              CheckboxListTile(
                key: ValueKey('pvc-advanced-use-remaining'),
                value: _useRemainingArea,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  'Automatically use remaining room area',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (value) => setState(() {
                  _useRemainingArea = value ?? false;
                  if (_useRemainingArea) _inputMode = PvcZoneInputMode.area;
                }),
              ),
            ],
            if (_inputMode == PvcZoneInputMode.perimeterStrip &&
                !_useRemainingArea) ...[
              SizedBox(height: 8),
              _ModeToggle<PvcPerimeterRunMode>(
                values: [
                  PvcPerimeterRunMode.autoPerimeter,
                  PvcPerimeterRunMode.custom,
                ],
                selected: _perimeterRunMode,
                label: (mode) => switch (mode) {
                  PvcPerimeterRunMode.autoPerimeter => 'Room perimeter',
                  PvcPerimeterRunMode.custom => 'Custom run',
                },
                keyFor: (mode) => 'pvc-advanced-run-${mode.name}',
                onSelected: (mode) => setState(() => _perimeterRunMode = mode),
              ),
              SizedBox(height: 8),
              _NumberField(
                key: ValueKey('pvc-advanced-strip-width'),
                controller: _stripWidth,
                label: 'Strip width',
                suffix: 'm',
                onChanged: () {},
              ),
              if (_perimeterRunMode == PvcPerimeterRunMode.custom) ...[
                SizedBox(height: 8),
                _NumberField(
                  key: ValueKey('pvc-advanced-custom-run'),
                  controller: _customRun,
                  label: 'Custom run',
                  suffix: 'm',
                  onChanged: () {},
                ),
              ],
            ],
            if (_inputMode == PvcZoneInputMode.linear &&
                !_useRemainingArea) ...[
              SizedBox(height: 8),
              _NumberField(
                key: ValueKey('pvc-advanced-linear'),
                controller: _linear,
                label: 'Required linear meters',
                suffix: 'm',
                onChanged: () {},
              ),
            ],
            SizedBox(height: 14),
            AdaptiveChoiceField<PvcZoneCalculationMode>(
              key: ValueKey('pvc-advanced-mode'),
              initialValue: _mode,
              decoration: InputDecoration(labelText: 'Calculation'),
              items: [
                DropdownMenuItem(
                  value: PvcZoneCalculationMode.auto,
                  child: Text('Auto'),
                ),
                DropdownMenuItem(
                  value: PvcZoneCalculationMode.coveragePerPiece,
                  child: Text('Coverage per piece'),
                ),
                DropdownMenuItem(
                  value: PvcZoneCalculationMode.manualQuantity,
                  child: Text('Manual quantity'),
                ),
              ],
              onChanged: (value) => setState(() => _mode = value!),
            ),
            if (_mode == PvcZoneCalculationMode.coveragePerPiece) ...[
              SizedBox(height: 12),
              _NumberField(
                key: ValueKey('pvc-advanced-coverage'),
                controller: _coverage,
                label: '1 piece covers',
                suffix: 'm²',
                onChanged: () {},
              ),
            ],
            if (_inputMode == PvcZoneInputMode.sheetQuantity ||
                _mode == PvcZoneCalculationMode.manualQuantity) ...[
              SizedBox(height: 12),
              _NumberField(
                key: ValueKey('pvc-advanced-manual'),
                controller: _manual,
                label: _inputMode == PvcZoneInputMode.sheetQuantity
                    ? 'Sheet quantity'
                    : 'Quantity per room',
                suffix: _inputMode == PvcZoneInputMode.sheetQuantity
                    ? 'sheets'
                    : 'pieces',
                integer: true,
                onChanged: () {},
              ),
            ],
            if (_mode == PvcZoneCalculationMode.auto &&
                _inputMode != PvcZoneInputMode.sheetQuantity &&
                widget.zone.product.calculationUnit ==
                    PvcProductCalculationUnit.area) ...[
              SizedBox(height: 12),
              AdaptiveChoiceField<MeasurementOrientation?>(
                initialValue: _orientation,
                decoration: InputDecoration(labelText: 'Orientation'),
                items: [
                  DropdownMenuItem(value: null, child: Text('Auto')),
                  DropdownMenuItem(
                    value: MeasurementOrientation.alongLength,
                    child: Text('Along length'),
                  ),
                  DropdownMenuItem(
                    value: MeasurementOrientation.alongWidth,
                    child: Text('Along width'),
                  ),
                ],
                onChanged: (value) => setState(() => _orientation = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        AdaptiveActionButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        AdaptiveActionButton.filled(
          key: ValueKey('pvc-advanced-apply'),
          onPressed: () => Navigator.pop(
            context,
            _AdvancedValues(
              inputMode: _inputMode,
              calculationMode: _mode,
              perimeterRunMode: _perimeterRunMode,
              useRemainingArea: _useRemainingArea,
              linear: _linear.text,
              stripWidth: _stripWidth.text,
              customRun: _customRun.text,
              coverage: _coverage.text,
              manualQuantity: _manual.text,
              orientation: _orientation,
            ),
          ),
          child: Text('Apply'),
        ),
      ],
    );
  }
}

class _AdvancedValues {
  const _AdvancedValues({
    required this.inputMode,
    required this.calculationMode,
    required this.perimeterRunMode,
    required this.useRemainingArea,
    required this.linear,
    required this.stripWidth,
    required this.customRun,
    required this.coverage,
    required this.manualQuantity,
    required this.orientation,
  });

  final PvcZoneInputMode inputMode;
  final PvcZoneCalculationMode calculationMode;
  final PvcPerimeterRunMode perimeterRunMode;
  final bool useRemainingArea;
  final String linear;
  final String stripWidth;
  final String customRun;
  final String coverage;
  final String manualQuantity;
  final MeasurementOrientation? orientation;
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({super.key, required this.product, required this.onAdd});

  final PvcPhysicalProduct product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: iPhoneColor(context, AppColors.card),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.fromLTRB(11, 9, 7, 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iPhoneColor(context, AppColors.border)),
          ),
          child: Row(
            children: [
              ProductImageThumbnail(
                imagePath: product.imagePath,
                productName: product.nameKhmer,
                width: 36,
                height: isIPhoneLayout(context) ? 44 : 36,
                borderRadius: 9,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nameKhmer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.textMain),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      product.spec,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.textSecondary),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: ValueKey('pvc-add-product-${product.id}'),
                tooltip: 'Add material zone',
                onPressed: onAdd,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductResultCard extends StatelessWidget {
  const _ProductResultCard({
    required this.result,
    required this.priceController,
  });

  final PvcProductQuantityResult result;
  final TextEditingController priceController;

  @override
  Widget build(BuildContext context) {
    final priceVal = double.tryParse(priceController.text.trim()) ?? 0.0;
    final lineTotal = result.billableQuantity * priceVal;

    return Container(
      key: ValueKey('pvc-result-${result.product.id}'),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.card),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iPhoneColor(context, AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: ProductImageThumbnail(
                  imagePath: result.product.imagePath,
                  productName: result.product.nameKhmer,
                  width: 36,
                  height: isIPhoneLayout(context) ? 44 : 36,
                  borderRadius: 9,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.product.nameKhmer,
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.textMain),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      result.product.spec,
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.textMuted),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${result.quantity}',
                    key: ValueKey('pvc-result-quantity-${result.product.id}'),
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.primaryText),
                      fontSize: 29,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    result.unitLabel,
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.textSecondary),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (result.requiredPackages case final packages?)
                    Text(
                      '$packages បាច់',
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.textMuted),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          if (result.assignedAreaM2 > 0)
            _ResultMetric(
              icon: Icons.square_foot_rounded,
              text: 'Assigned: ${_number(result.assignedAreaM2)} m²',
            ),
          if (result.isAreaEstimate)
            _ResultMetric(
              icon: Icons.info_outline_rounded,
              text: 'ប៉ាន់ស្មានតាមផ្ទៃសន្លឹក (អាចត្រូវការសំណល់បន្ថែម)',
            ),
          if (result.product.calculationUnit ==
                  PvcProductCalculationUnit.linear &&
              result.requiredLinearM > 0)
            _ResultMetric(
              icon: Icons.straighten_rounded,
              text: 'Required: ${_number(result.requiredLinearM)} m',
            ),
          if (result.requiredPackages case final packages?)
            _ResultMetric(
              icon: Icons.inventory_2_outlined,
              text: '$packages កញ្ចប់',
            ),
          if (result.loosePieces case final loose?
              when result.requiredPackages != null)
            _ResultMetric(
              icon: Icons.view_list_outlined,
              text: '$loose ដើមក្នុងតម្រូវការ',
            ),
          for (final notice in result.notices)
            _ResultMetric(icon: Icons.info_outline_rounded, text: notice),
          SizedBox(height: 10),
          Divider(height: 1, color: iPhoneColor(context, AppColors.border)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'តម្លៃលក់ / ${result.priceUnitLabel}',
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.textMuted),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    SizedBox(
                      width: 100,
                      height: isIPhoneLayout(context) ? 44 : 34,
                      child: AdaptiveTextField(
                        key: ValueKey('pvc-price-input-${result.product.id}'),
                        controller: priceController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(
                          color: iPhoneColor(context, AppColors.textMain),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        decoration: InputDecoration(
                          prefixText: r'$ ',
                          prefixStyle: TextStyle(
                            color: iPhoneColor(
                              context,
                              AppColors.textSecondary,
                            ),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          fillColor: iPhoneColor(
                            context,
                            AppColors.inputBackground,
                          ),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: iPhoneColor(context, AppColors.border),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: iPhoneColor(context, AppColors.border),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: iPhoneColor(context, AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'សរុប',
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.textMuted),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      MoneyFormatter.money(lineTotal),
                      key: ValueKey('pvc-line-total-${result.product.id}'),
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.primaryText),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PvcSellingGrandTotalSection extends StatelessWidget {
  const _PvcSellingGrandTotalSection({required this.grandTotal});

  final double grandTotal;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('pvc-selling-summary'),
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.card),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iPhoneColor(context, AppColors.border)),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'សរុបតម្លៃលក់',
              style: TextStyle(
                color: iPhoneColor(context, AppColors.textMain),
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              MoneyFormatter.money(grandTotal),
              key: ValueKey('pvc-selling-grand-total'),
              style: TextStyle(
                color: iPhoneColor(context, AppColors.successText),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: iPhoneColor(context, AppColors.textSecondary),
          ),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: iPhoneColor(context, AppColors.textSecondary),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceTotals extends StatelessWidget {
  const _WorkspaceTotals({
    required this.totalArea,
    required this.allocatedArea,
  });

  final double totalArea;
  final double allocatedArea;

  @override
  Widget build(BuildContext context) {
    final delta = totalArea - allocatedArea;
    final over = delta < -0.0001;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.surfaceSecondary),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iPhoneColor(context, AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              label: 'JOB AREA',
              value: '${_number(totalArea)} m²',
            ),
          ),
          Container(
            width: 1,
            height: isIPhoneLayout(context) ? 44 : 34,
            color: iPhoneColor(context, AppColors.borderStrong),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _Metric(
              label: over ? 'OVER' : 'REMAINING',
              value:
                  '${_number(over ? -delta : delta.clamp(0, double.infinity))} m²',
              valueColor: over
                  ? iPhoneColor(context, AppColors.errorText)
                  : iPhoneColor(context, AppColors.successText),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: iPhoneColor(context, AppColors.textMuted),
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? iPhoneColor(context, AppColors.textMain),
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _ModeToggle<T> extends StatelessWidget {
  const _ModeToggle({
    required this.values,
    required this.selected,
    required this.label,
    required this.keyFor,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final String Function(T) keyFor;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.surfaceSecondary),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: iPhoneColor(context, AppColors.border)),
      ),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: Material(
                key: ValueKey(keyFor(value)),
                color: value == selected
                    ? iPhoneColor(context, AppColors.surface)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                child: InkWell(
                  onTap: () => onSelected(value),
                  borderRadius: BorderRadius.circular(7),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      label(value),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: value == selected
                            ? iPhoneColor(context, AppColors.primaryText)
                            : iPhoneColor(context, AppColors.textMuted),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.onChanged,
    this.integer = false,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final VoidCallback onChanged;
  final bool integer;

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: true,
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
    );
  }
}

class _EmptyZones extends StatelessWidget {
  const _EmptyZones();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.hasBoundedHeight && constraints.maxHeight < 120;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(compact ? 8 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_box_outlined,
                    color: iPhoneColor(context, AppColors.primary),
                    size: compact ? 24 : 34,
                  ),
                  SizedBox(height: compact ? 4 : 9),
                  Text(
                    'Choose “+” on a product to create the first material zone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.textMuted),
                      fontSize: compact ? 10 : 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.hasBoundedHeight && constraints.maxHeight < 120;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(compact ? 8 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: iPhoneColor(context, AppColors.primary),
                    size: compact ? 26 : 36,
                  ),
                  SizedBox(height: compact ? 4 : 9),
                  Text(
                    'Quantity results appear here for every selected physical material.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.textMuted),
                      fontSize: compact ? 10 : 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

double? _positiveDouble(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value.isFinite && value > 0 ? value : null;
}

int? _positiveInt(String text) {
  final value = int.tryParse(text.trim());
  return value != null && value > 0 ? value : null;
}

String _number(double value) {
  if (!value.isFinite) return '0';
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
