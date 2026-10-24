import '../../../../core/ios/iphone_controls.dart';
import '../../../../core/ios/iphone_design.dart';
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app_state.dart';
import '../../../../core/theme/sakura_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../invoice/domain/invoice_document.dart';
import '../../../invoice/presentation/customer_document_dialog.dart';
import '../../data/measurement_quotation_adapter.dart';
import '../../data/measurement_workspace_catalog.dart';
import '../../domain/models/measurement_models.dart';
import '../../domain/workspace_calculation_service.dart';
import '../../domain/workspace_models.dart';
import '../../native/measurement_native_api.dart';

const _surface = AppColors.surface;
const _card = AppColors.surfaceSecondary;
const _border = AppColors.border;
const _primary = AppColors.primary;
const _secondary = AppColors.primaryDeep;
const _success = AppColors.successText;
const _warning = AppColors.warningText;
const _danger = AppColors.errorText;
const _text = AppColors.textMain;
const _textSecondary = AppColors.textSecondary;
const _textMuted = AppColors.textMuted;

class MeasurementCalculatorScreen extends StatefulWidget {
  const MeasurementCalculatorScreen({super.key, this.optimizer});

  final MeasurementOptimizer? optimizer;

  @override
  State<MeasurementCalculatorScreen> createState() =>
      _MeasurementCalculatorScreenState();
}

class _MeasurementCalculatorScreenState
    extends State<MeasurementCalculatorScreen> {
  final _search = TextEditingController();
  final _workspaceScroll = ScrollController();
  final _groupsScroll = ScrollController();
  final _categoriesScroll = ScrollController();
  final _productsScroll = ScrollController();
  final _selectedScroll = ScrollController();
  _MeasurementWorkspaceFields? _workspaceFields;
  List<WorkspaceProduct> _products = const [];
  WorkspaceProductCategory _category = WorkspaceProductCategory.pvc;
  WorkspaceCalculationService? _calculationService;
  MeasurementOptimizationOptions _options =
      const MeasurementOptimizationOptions();
  Timer? _calculationDebounce;
  bool _initialized = false;

  _MeasurementWorkspaceFields get _workspace => _workspaceFields!;

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
    final state = context.read<AppState>();
    _options = state.measurementOptions;
    _products = const MeasurementWorkspaceCatalog().build(
      materials: state.materials,
      prices: state.prices,
    );
    _calculationService = WorkspaceCalculationService(
      optimizer: widget.optimizer,
    );
    _workspaceFields = _createWorkspace(length: '6', width: '4.2');
  }

  @override
  void dispose() {
    _calculationDebounce?.cancel();
    _search
      ..removeListener(_searchChanged)
      ..dispose();
    for (final controller in [
      _workspaceScroll,
      _groupsScroll,
      _categoriesScroll,
      _productsScroll,
      _selectedScroll,
    ]) {
      controller.dispose();
    }
    _workspaceFields?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_workspaceFields == null) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.all(10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isIPhoneLayout(context)) {
            return IPhoneWorkspace(
              panels: [_measurementPanel(), _productsPanel(), _resultPanel()],
              tabLabels: [
                'បន្ទប់',
                'សម្ភារៈ (${_workspace.selections.length})',
                'លទ្ធផល',
              ],
            );
          }
          if (constraints.maxWidth >= 1240) {
            return Row(
              key: ValueKey('workspace-root'),
              children: [
                Expanded(flex: 20, child: _measurementPanel()),
                _WorkspaceDivider(),
                Expanded(flex: 50, child: _productsPanel()),
                _WorkspaceDivider(),
                Expanded(flex: 30, child: _resultPanel()),
              ],
            );
          }
          return Scrollbar(
            controller: _workspaceScroll,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              key: ValueKey('workspace-horizontal-scroll'),
              controller: _workspaceScroll,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 1220,
                height: constraints.maxHeight,
                child: Row(
                  key: ValueKey('workspace-root'),
                  children: [
                    SizedBox(width: 270, child: _measurementPanel()),
                    _WorkspaceDivider(),
                    SizedBox(width: 590, child: _productsPanel()),
                    _WorkspaceDivider(),
                    SizedBox(width: 340, child: _resultPanel()),
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
    final workspace = _workspace;
    final group = workspace.activeGroup;
    return _WorkspacePanel(
      key: ValueKey('workspace-room-panel'),
      title: 'ទំហំបន្ទប់',
      icon: Icons.straighten_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: isIPhoneLayout(context) ? 44 : 42,
            child: _HorizontalStrip(
              key: ValueKey('workspace-room-group-tabs'),
              controller: _groupsScroll,
              compact: true,
              children: [
                for (var index = 0; index < workspace.groups.length; index++)
                  _WorkspaceTab(
                    key: ValueKey(
                      'workspace-room-group-${workspace.groups[index].id}',
                    ),
                    label: workspace.groups[index].tabLabel,
                    selected: index == workspace.activeGroupIndex,
                    onTap: () => _selectGroup(index),
                    onClose: workspace.groups.length > 1
                        ? () => _removeGroup(index)
                        : null,
                  ),
                _AddTab(
                  key: ValueKey('workspace-add-room-group-tab'),
                  label: '+',
                  onTap: _addGroup,
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Container(
            key: ValueKey('workspace-room-group-editor-${group.id}'),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iPhoneColor(context, _surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iPhoneColor(context, _border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ទំហំ ${workspace.activeGroupIndex + 1}',
                        style: TextStyle(
                          color: iPhoneColor(context, _text),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${group.countValue} បន្ទប់',
                      key: ValueKey('workspace-group-room-count-${group.id}'),
                      style: TextStyle(
                        color: iPhoneColor(context, _secondary),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                _RoomModeToggle(
                  groupId: group.id,
                  mode: group.mode,
                  onChanged: (mode) => _setGroupMode(group, mode),
                ),
                SizedBox(height: 10),
                if (group.mode == MeasurementRoomMode.dimensions)
                  Row(
                    children: [
                      Expanded(
                        child: _RoomDimensionField(
                          key: ValueKey('workspace-group-length-${group.id}'),
                          label: 'បណ្ដោយ',
                          controller: group.length,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _RoomDimensionField(
                          key: ValueKey('workspace-group-width-${group.id}'),
                          label: 'ទទឹង',
                          controller: group.width,
                        ),
                      ),
                    ],
                  )
                else
                  _RoomDimensionField(
                    key: ValueKey('workspace-group-area-${group.id}'),
                    label: 'ទំហំក្នុង 1 បន្ទប់',
                    controller: group.area,
                    suffix: 'm²',
                  ),
                SizedBox(height: 10),
                _CompactLabel('ចំនួនបន្ទប់'),
                SizedBox(height: 6),
                _RoomCountControl(
                  key: ValueKey('workspace-group-count-control-${group.id}'),
                  groupId: group.id,
                  controller: group.count,
                  value: group.countValue,
                  onDecrement: group.countValue > 1
                      ? () => _setGroupCount(group, group.countValue - 1)
                      : null,
                  onIncrement: () =>
                      _setGroupCount(group, group.countValue + 1),
                  onNormalize: group.normalizeCount,
                ),
                SizedBox(height: 12),
                Divider(height: 1, color: iPhoneColor(context, _border)),
                SizedBox(height: 10),
                _RoomMetricRow(
                  label: 'ក្នុង 1 បន្ទប់',
                  value: '${_format(group.areaPerRoomM2)} m²',
                  valueKey: ValueKey(
                    'workspace-group-area-per-room-${group.id}',
                  ),
                ),
                SizedBox(height: 7),
                _RoomMetricRow(
                  label: 'សរុបក្រុម',
                  value: '${_format(group.totalAreaM2)} m²',
                  valueKey: ValueKey('workspace-group-total-area-${group.id}'),
                  emphasized: true,
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: iPhoneColor(context, AppColors.totalAreaBg),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iPhoneColor(context, AppColors.successBorder),
              ),
            ),
            child: _RoomMetricRow(
              label: 'សរុបទាំងអស់',
              value: '${_format(workspace.totalAreaM2)} m²',
              valueKey: ValueKey('workspace-grand-room-area'),
              emphasized: true,
            ),
          ),
          Spacer(),
          AdaptiveActionButton.outlinedIcon(
            key: ValueKey('workspace-add-room-group'),
            onPressed: _addGroup,
            icon: Icon(Icons.add_rounded, size: 18),
            label: Text('បន្ថែមទំហំផ្សេង'),
          ),
        ],
      ),
    );
  }

  Widget _productsPanel() {
    final products = _visibleProducts;
    final selected = _workspace.selections;
    return _WorkspacePanel(
      key: ValueKey('workspace-products-panel'),
      title: 'ផលិតផល / សម្ភារៈ',
      icon: Icons.inventory_2_outlined,
      trailing: Text(
        '${selected.length} បានជ្រើស',
        style: TextStyle(
          color: iPhoneColor(context, _textSecondary),
          fontSize: 12,
        ),
      ),
      child: Column(
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
                    key: ValueKey('workspace-product-search'),
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'ស្វែងរកផលិតផល…',
                      prefixIcon: Icon(Icons.search_rounded, size: 19),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                    ),
                  ),
          ),
          SizedBox(height: 9),
          SizedBox(
            height: isIPhoneLayout(context) ? 44 : 38,
            child: _HorizontalStrip(
              key: ValueKey('workspace-category-tabs'),
              controller: _categoriesScroll,
              compact: true,
              children: [
                for (final category in WorkspaceProductCategory.values)
                  _WorkspaceTab(
                    key: ValueKey('workspace-category-${category.name}'),
                    label: _categoryLabel(category),
                    selected: category == _category,
                    onTap: () => _selectCategory(category),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: SizedBox(
              key: ValueKey('workspace-product-table'),
              width: double.infinity,
              height: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProductTableHeader(),
                  Expanded(
                    child: products.isEmpty
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: Text(
                                'មិនមានផលិតផលត្រូវនឹងការស្វែងរក',
                                style: TextStyle(
                                  color: iPhoneColor(context, _textSecondary),
                                ),
                              ),
                            ),
                          )
                        : Scrollbar(
                            controller: _productsScroll,
                            child: ListView.separated(
                              key: ValueKey('workspace-product-list'),
                              controller: _productsScroll,
                              padding: EdgeInsets.zero,
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                final product = products[index];
                                return _CompactProductRow(
                                  key: ValueKey(
                                    'workspace-product-${product.id}-${product.variants.first.variantId}',
                                  ),
                                  product: product,
                                  selected: selected.containsKey(product.id),
                                  onTap: () => _selectProduct(product),
                                  onEdit: () => _editSelection(product.id),
                                );
                              },
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: iPhoneColor(context, _border),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _CompactLabel('បានជ្រើស'),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: isIPhoneLayout(context) ? 44 : 42,
                  child: selected.isEmpty
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
                          key: ValueKey('workspace-selected-strip'),
                          controller: _selectedScroll,
                          compact: true,
                          children: [
                            for (final selection in selected.values)
                              InputChip(
                                key: ValueKey(
                                  'workspace-selected-${selection.product.id}',
                                ),
                                label: Text(selection.product.code),
                                avatar: Icon(Icons.tune_rounded, size: 15),
                                onPressed: () =>
                                    _editSelection(selection.product.id),
                                onDeleted: () =>
                                    _removeProduct(selection.product.id),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultPanel() {
    final workspace = _workspace;
    final result = workspace.result;
    return _WorkspacePanel(
      key: ValueKey('workspace-result-panel'),
      title: 'លទ្ធផលផ្ទាល់',
      icon: Icons.receipt_long_outlined,
      trailing: workspace.isCalculating
          ? SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iPhoneColor(context, _surface),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${workspace.totalRoomCount} បន្ទប់',
                  style: TextStyle(
                    color: iPhoneColor(context, _text),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  workspace.summary,
                  style: TextStyle(
                    color: iPhoneColor(context, _textSecondary),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          if (workspace.error != null)
            _InlineError(workspace.error!)
          else if (workspace.selections.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'ជ្រើសផលិតផលដើម្បីមើលលទ្ធផល',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: iPhoneColor(context, _textSecondary)),
                ),
              ),
            )
          else if (result == null)
            Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            _ResultTableHeader(),
            SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                key: ValueKey('workspace-result-list'),
                padding: EdgeInsets.zero,
                itemCount: result.materials.length,
                itemBuilder: (context, index) {
                  return _MaterialResultGroup(
                    material: result.materials[index],
                    onEdit: () => _editSelection(
                      result.materials[index].selection.product.id,
                    ),
                  );
                },
              ),
            ),
            Divider(height: 14, color: iPhoneColor(context, _border)),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'សរុប',
                    style: TextStyle(
                      color: iPhoneColor(context, _text),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  MoneyFormatter.money(result.totalPrice),
                  key: ValueKey('workspace-grand-total'),
                  style: TextStyle(
                    color: iPhoneColor(context, _success),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            SakuraDecisionBadge(
              canSell: result.totalPrice >= 0,
              customText: result.totalPrice >= 0
                  ? '✓ អាចលក់បាន'
                  : '✕ មិនគួរលក់',
            ),
            SizedBox(height: 10),
            AdaptiveActionButton.filledIcon(
              key: ValueKey('workspace-get-invoice'),
              onPressed: result.materials.isEmpty
                  ? null
                  : () => _openCustomerDocument(result),
              icon: Icon(Icons.receipt_long_rounded, size: 19),
              label: Text('Get Invoice'),
            ),
          ],
        ],
      ),
    );
  }

  void _openCustomerDocument(WorkspaceCalculationResult result) {
    final state = context.read<AppState>();
    final lines = const MeasurementQuotationAdapter().createWorkspaceLines(
      state: state,
      result: result,
    );
    if (lines.isEmpty) {
      _showInvoiceUnavailable('សូមជ្រើសសម្ភារៈដែលមានបរិមាណជាមុនសិន។');
      return;
    }
    if (lines.any((line) => !line.canAddToTemporarySale)) {
      _showInvoiceUnavailable(
        'សូមកំណត់តម្លៃលក់ឱ្យគ្រប់សម្ភារៈ មុនពេលយកវិក្កយបត្រ។',
      );
      return;
    }
    showAdaptiveEditor<void>(
      context: context,
      builder: (context) => CustomerDocumentDialog(
        initialDocument: InvoiceDocument.fromSaleItems(lines),
      ),
    );
  }

  void _showInvoiceUnavailable(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<WorkspaceProduct> get _visibleProducts {
    final query = _search.text.trim().toLowerCase();
    return _products
        .where(
          (product) =>
              product.category == _category &&
              (query.isEmpty ||
                  product.code.toLowerCase().contains(query) ||
                  product.name.toLowerCase().contains(query) ||
                  product.designOptions.any(
                    (option) => option.code.toLowerCase().contains(query),
                  )),
        )
        .toList(growable: false);
  }

  _MeasurementWorkspaceFields _createWorkspace({
    String length = '4',
    String width = '3',
  }) {
    final workspace = _MeasurementWorkspaceFields();
    workspace.groups.add(
      _RoomSizeGroupFields(
        id: workspace.nextGroupId++,
        length: length,
        width: width,
        area: '25.2',
        count: '1',
        onChanged: _workspaceChanged,
      ),
    );
    return workspace;
  }

  void _searchChanged() {
    if (mounted) setState(() {});
  }

  void _selectCategory(WorkspaceProductCategory category) {
    if (_category == category) return;
    setState(() => _category = category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _productsScroll.hasClients) {
        _productsScroll.jumpTo(0);
      }
    });
  }

  void _workspaceChanged() {
    if (!mounted) return;
    setState(() {});
    _scheduleCalculation();
  }

  void _selectGroup(int index) {
    if (index == _workspace.activeGroupIndex) return;
    setState(() => _workspace.activeGroupIndex = index);
  }

  void _addGroup() {
    final workspace = _workspace;
    setState(() {
      workspace.groups.add(
        _RoomSizeGroupFields(
          id: workspace.nextGroupId++,
          length: '2',
          width: '2',
          area: '4',
          count: '1',
          onChanged: _workspaceChanged,
        ),
      );
      workspace.activeGroupIndex = workspace.groups.length - 1;
    });
    _scheduleCalculation();
  }

  void _removeGroup(int index) {
    final workspace = _workspace;
    workspace.groups.removeAt(index).dispose();
    if (workspace.activeGroupIndex >= workspace.groups.length) {
      workspace.activeGroupIndex = workspace.groups.length - 1;
    } else if (index < workspace.activeGroupIndex) {
      workspace.activeGroupIndex--;
    }
    setState(() {});
    _scheduleCalculation();
  }

  void _setGroupCount(_RoomSizeGroupFields group, int value) {
    group.count.text = value.clamp(1, 999999).toString();
    group.count.selection = TextSelection.collapsed(
      offset: group.count.text.length,
    );
  }

  void _setGroupMode(_RoomSizeGroupFields group, MeasurementRoomMode mode) {
    if (group.mode == mode) return;
    setState(() => group.mode = mode);
    _scheduleCalculation(immediate: true);
  }

  void _selectProduct(WorkspaceProduct product) {
    final existing = _workspace.selections[product.id];
    if (existing != null) {
      _editSelection(product.id);
      return;
    }
    setState(() {
      _workspace.selections[product.id] = WorkspaceProductSelection(
        product: product,
      );
    });
    _scheduleCalculation(immediate: true);
  }

  void _removeProduct(String productId) {
    setState(() {
      _workspace.selections.remove(productId);
      if (_workspace.selections.isEmpty) _workspace.result = null;
    });
    _scheduleCalculation(immediate: true);
  }

  Future<void> _editSelection(String productId) async {
    final selection = _workspace.selections[productId];
    if (selection == null) return;
    final overrides = await showAdaptiveEditor<WorkspaceMaterialOverride>(
      context: context,
      builder: (context) => _MaterialOverrideDialog(selection: selection),
    );
    if (overrides == null || !mounted) return;
    setState(() {
      _workspace.selections[productId] = selection.copyWith(
        overrides: overrides,
      );
    });
    _scheduleCalculation(immediate: true);
  }

  void _scheduleCalculation({bool immediate = false}) {
    _calculationDebounce?.cancel();
    final workspace = _workspace;
    final generation = ++workspace.calculationGeneration;
    if (workspace.selections.isEmpty) {
      workspace.result = null;
      workspace.error = null;
      workspace.isCalculating = false;
      if (mounted) setState(() {});
      return;
    }
    _calculationDebounce = Timer(
      immediate ? Duration.zero : const Duration(milliseconds: 260),
      () => _calculateWorkspace(workspace, generation),
    );
  }

  Future<void> _calculateWorkspace(
    _MeasurementWorkspaceFields workspace,
    int generation,
  ) async {
    if (generation != workspace.calculationGeneration) return;
    final groups = workspace.roomGroups;
    if (groups.any(
      (item) =>
          item.count < 1 ||
          !item.areaPerRoomM2.isFinite ||
          item.areaPerRoomM2 <= 0 ||
          (item.mode == MeasurementRoomMode.dimensions &&
              (item.lengthM == null ||
                  item.widthM == null ||
                  item.lengthM! <= 0 ||
                  item.widthM! <= 0)),
    )) {
      if (!mounted) return;
      setState(() {
        workspace.error = 'ទំហំត្រូវធំជាង 0 ហើយចំនួនយ៉ាងតិច 1។';
        workspace.isCalculating = false;
      });
      return;
    }
    if (mounted) {
      setState(() {
        workspace.isCalculating = true;
        workspace.error = null;
      });
    }
    try {
      final result = await _calculationService!.calculate(
        rooms: groups,
        selections: workspace.selections.values.toList(growable: false),
        options: _options,
      );
      if (!mounted || generation != workspace.calculationGeneration) return;
      setState(() => workspace.result = result);
    } on Object catch (error) {
      if (!mounted || generation != workspace.calculationGeneration) return;
      setState(() => workspace.error = 'ការគណនាមិនបានសម្រេច៖ $error');
    } finally {
      if (mounted && generation == workspace.calculationGeneration) {
        setState(() => workspace.isCalculating = false);
      }
    }
  }

  String _categoryLabel(WorkspaceProductCategory category) =>
      switch (category) {
        WorkspaceProductCategory.pvc => 'PVC',
        WorkspaceProductCategory.accessories => 'ជ្រី / សម្ភារៈ',
        WorkspaceProductCategory.cLine => 'C-Line',
        WorkspaceProductCategory.db => 'DB',
        WorkspaceProductCategory.gd => 'GD',
      };

  String _format(double value) => MoneyFormatter.decimal(value);
}

class _MaterialOverrideDialog extends StatefulWidget {
  const _MaterialOverrideDialog({required this.selection});

  final WorkspaceProductSelection selection;

  @override
  State<_MaterialOverrideDialog> createState() =>
      _MaterialOverrideDialogState();
}

class _MaterialOverrideDialogState extends State<_MaterialOverrideDialog> {
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  late final TextEditingController _customLength;
  late final TextEditingController _customWaste;
  late int _lengthChoice;
  late double _wasteChoice;
  late int _orientationChoice;

  WorkspaceMaterialOverride? get existing => widget.selection.overrides;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(
      text: existing?.quantity?.toString() ?? '',
    );
    _price = TextEditingController(
      text: existing?.unitPrice?.toStringAsFixed(2) ?? '',
    );
    _customLength = TextEditingController(
      text: existing?.customLengthMm?.toStringAsFixed(0) ?? '',
    );
    _customWaste = TextEditingController();
    _lengthChoice = existing?.customLengthMm != null
        ? -2
        : existing?.variantId ?? -1;
    final savedWaste = existing?.sparePercent;
    _wasteChoice = savedWaste == null
        ? -1
        : const [0.0, 3.0, 5.0].contains(savedWaste)
        ? savedWaste
        : -2;
    if (_wasteChoice == -2) {
      _customWaste.text = savedWaste!.toStringAsFixed(0);
    }
    _orientationChoice = existing?.orientation == null
        ? 0
        : existing!.orientation!.index + 1;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    _customLength.dispose();
    _customWaste.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.selection.product;
    return AlertDialog(
      title: Row(
        children: [
          Expanded(child: Text('${product.code} • កែតម្រូវ')),
          Text(
            product.priceLabel,
            style: TextStyle(
              color: iPhoneColor(context, _success),
              fontSize: 13,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ទុកទទេ ឬ Auto ដើម្បីប្រើទិន្នន័យផលិតផល និងការគណនាស្វ័យប្រវត្តិ។',
                style: TextStyle(
                  color: iPhoneColor(context, _textSecondary),
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fields = [
                    AdaptiveChoiceField<int>(
                      key: ValueKey('workspace-override-length'),
                      initialValue: _lengthChoice,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: 'បណ្ដោយ'),
                      items: [
                        DropdownMenuItem(value: -1, child: Text('Auto')),
                        for (final variant in product.variants)
                          DropdownMenuItem(
                            value: variant.variantId,
                            child: Text(_variantLength(variant)),
                          ),
                        DropdownMenuItem(value: -2, child: Text('Custom')),
                      ],
                      onChanged: (value) =>
                          setState(() => _lengthChoice = value ?? -1),
                    ),
                    AdaptiveTextField(
                      key: ValueKey('workspace-override-quantity'),
                      controller: _quantity,
                      inputFormatters: [_integerFormatter],
                      decoration: InputDecoration(
                        labelText: 'ចំនួន',
                        hintText: 'Auto',
                      ),
                    ),
                    AdaptiveTextField(
                      key: ValueKey('workspace-override-price'),
                      controller: _price,
                      inputFormatters: [_decimalFormatter],
                      decoration: InputDecoration(
                        labelText: 'តម្លៃ',
                        prefixText: r'$',
                        hintText: 'Database',
                      ),
                    ),
                    AdaptiveChoiceField<double>(
                      key: ValueKey('workspace-override-waste'),
                      initialValue: _wasteChoice,
                      decoration: InputDecoration(labelText: 'បម្រុង'),
                      items: [
                        DropdownMenuItem(value: -1, child: Text('Auto')),
                        DropdownMenuItem(value: 0, child: Text('0%')),
                        DropdownMenuItem(value: 3, child: Text('3%')),
                        DropdownMenuItem(value: 5, child: Text('5%')),
                        DropdownMenuItem(value: -2, child: Text('Custom')),
                      ],
                      onChanged: (value) =>
                          setState(() => _wasteChoice = value ?? -1),
                    ),
                  ];
                  return GridView.count(
                    crossAxisCount: constraints.maxWidth >= 440 ? 2 : 1,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    childAspectRatio: constraints.maxWidth >= 440 ? 3.2 : 5,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: fields,
                  );
                },
              ),
              if (_lengthChoice == -2) ...[
                SizedBox(height: 10),
                AdaptiveTextField(
                  controller: _customLength,
                  inputFormatters: [_decimalFormatter],
                  decoration: InputDecoration(
                    labelText: 'បណ្ដោយផ្ទាល់ខ្លួន',
                    suffixText: 'mm',
                  ),
                ),
              ],
              if (_wasteChoice == -2) ...[
                SizedBox(height: 10),
                AdaptiveTextField(
                  controller: _customWaste,
                  inputFormatters: [_decimalFormatter],
                  decoration: InputDecoration(
                    labelText: 'បម្រុងផ្ទាល់ខ្លួន',
                    suffixText: '%',
                  ),
                ),
              ],
              if (product.calculationKind ==
                  WorkspaceCalculationKind.coverage) ...[
                SizedBox(height: 10),
                AdaptiveChoiceField<int>(
                  key: ValueKey('workspace-override-orientation'),
                  initialValue: _orientationChoice,
                  decoration: InputDecoration(labelText: 'ទិសដាក់'),
                  items: [
                    DropdownMenuItem(value: 0, child: Text('Auto')),
                    DropdownMenuItem(value: 1, child: Text('តាមបណ្ដោយ')),
                    DropdownMenuItem(value: 2, child: Text('តាមទទឹង')),
                  ],
                  onChanged: (value) =>
                      setState(() => _orientationChoice = value ?? 0),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        AdaptiveActionButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text('បោះបង់'),
        ),
        AdaptiveActionButton.filled(
          key: ValueKey('workspace-override-apply'),
          onPressed: _apply,
          child: Text('អនុវត្ត'),
        ),
      ],
    );
  }

  void _apply() {
    final quantity = int.tryParse(_quantity.text.trim());
    final price = double.tryParse(_price.text.trim().replaceAll(',', '.'));
    final customLength = double.tryParse(
      _customLength.text.trim().replaceAll(',', '.'),
    );
    final customWaste = double.tryParse(
      _customWaste.text.trim().replaceAll(',', '.'),
    );
    Navigator.pop(
      context,
      WorkspaceMaterialOverride(
        variantId: _lengthChoice >= 0 ? _lengthChoice : null,
        customLengthMm: _lengthChoice == -2 && (customLength ?? 0) > 0
            ? customLength
            : null,
        quantity: (quantity ?? 0) > 0 ? quantity : null,
        unitPrice: (price ?? -1) >= 0 ? price : null,
        sparePercent: _wasteChoice == -1
            ? null
            : _wasteChoice == -2
            ? customWaste?.clamp(0, 100)
            : _wasteChoice,
        orientation: _orientationChoice == 0
            ? null
            : MeasurementOrientation.values[_orientationChoice - 1],
      ),
    );
  }

  String _variantLength(WorkspaceProductVariant variant) {
    if (variant.lengthMm == null) return variant.label;
    final meters = variant.lengthMm! / 1000;
    final value = meters == meters.roundToDouble()
        ? meters.toInt().toString()
        : meters.toStringAsFixed(1);
    return '${value}m • \$${variant.unitPrice.toStringAsFixed(2)}';
  }
}

class _MeasurementWorkspaceFields {
  final List<_RoomSizeGroupFields> groups = [];
  final Map<String, WorkspaceProductSelection> selections = {};
  int activeGroupIndex = 0;
  int nextGroupId = 1;
  int calculationGeneration = 0;
  bool isCalculating = false;
  String? error;
  WorkspaceCalculationResult? result;

  _RoomSizeGroupFields get activeGroup => groups[activeGroupIndex];

  List<MeasurementRoom> get roomGroups => [
    for (var index = 0; index < groups.length; index++)
      switch (groups[index].mode) {
        MeasurementRoomMode.dimensions => MeasurementRoom(
          id: groups[index].id,
          name: 'ទំហំ ${index + 1}',
          lengthM: groups[index].lengthValue,
          widthM: groups[index].widthValue,
          count: groups[index].countValue,
        ),
        MeasurementRoomMode.area => MeasurementRoom.area(
          id: groups[index].id,
          name: 'ទំហំ ${index + 1}',
          directAreaM2: groups[index].areaValue,
          count: groups[index].countValue,
        ),
      },
  ];

  int get totalRoomCount =>
      groups.fold(0, (total, group) => total + group.countValue);

  double get totalAreaM2 =>
      groups.fold(0, (total, group) => total + group.totalAreaM2);

  String get summary => '${groups.length} ទំហំ • ${_number(totalAreaM2)} m²';

  void dispose() {
    for (final group in groups) {
      group.dispose();
    }
  }
}

class _RoomSizeGroupFields {
  _RoomSizeGroupFields({
    required this.id,
    required String length,
    required String width,
    required String area,
    required String count,
    required this.onChanged,
  }) : length = TextEditingController(text: length),
       width = TextEditingController(text: width),
       area = TextEditingController(text: area),
       count = TextEditingController(text: count) {
    this.length.addListener(onChanged);
    this.width.addListener(onChanged);
    this.area.addListener(onChanged);
    this.count.addListener(onChanged);
  }

  final int id;
  MeasurementRoomMode mode = MeasurementRoomMode.dimensions;
  final TextEditingController length;
  final TextEditingController width;
  final TextEditingController area;
  final TextEditingController count;
  final VoidCallback onChanged;

  double get lengthValue => _parse(length.text);
  double get widthValue => _parse(width.text);
  double get areaValue => _parse(area.text);
  int get countValue {
    final value = int.tryParse(count.text.trim()) ?? 1;
    return value < 1 ? 1 : value;
  }

  double get areaPerRoomM2 => switch (mode) {
    MeasurementRoomMode.dimensions => lengthValue * widthValue,
    MeasurementRoomMode.area => areaValue,
  };
  double get totalAreaM2 => areaPerRoomM2 * countValue;

  String get tabLabel => switch (mode) {
    MeasurementRoomMode.dimensions =>
      '${_number(lengthValue)}×${_number(widthValue)} · ×$countValue',
    MeasurementRoomMode.area => '${_number(areaValue)}m² · ×$countValue',
  };

  void normalizeCount() {
    final normalized = countValue.toString();
    if (count.text != normalized) count.text = normalized;
  }

  void dispose() {
    length
      ..removeListener(onChanged)
      ..dispose();
    width
      ..removeListener(onChanged)
      ..dispose();
    area
      ..removeListener(onChanged)
      ..dispose();
    count
      ..removeListener(onChanged)
      ..dispose();
  }

  static double _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
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
      borderRadius: BorderRadius.circular(AppEffects.panelRadius),
      tint: iPhoneColor(context, _card),
      borderColor: iPhoneColor(context, AppColors.glassHighlight),
      blur: AppEffects.glassBlur,
      shadows: AppShadows.glassCard,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, color: iPhoneColor(context, _secondary), size: 19),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: iPhoneColor(context, _text),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
          Divider(height: 1, color: iPhoneColor(context, _border)),
          Expanded(
            child: Padding(padding: EdgeInsets.all(12), child: child),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceDivider extends StatelessWidget {
  const _WorkspaceDivider();

  @override
  Widget build(BuildContext context) => const SizedBox(width: 8);
}

class _HorizontalStrip extends StatefulWidget {
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
  State<_HorizontalStrip> createState() => _HorizontalStripState();
}

class _HorizontalStripState extends State<_HorizontalStrip> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _scroll(-180);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _scroll(180);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Row(
        children: [
          _StripArrow(
            icon: Icons.chevron_left_rounded,
            compact: widget.compact,
            onPressed: () => _scroll(-220),
          ),
          Expanded(
            child: Listener(
              onPointerSignal: (signal) {
                if (signal is! PointerScrollEvent) return;
                final horizontal = signal.scrollDelta.dx;
                final shifted = HardwareKeyboard.instance.isShiftPressed
                    ? signal.scrollDelta.dy
                    : 0.0;
                final delta = horizontal.abs() > 0.01 ? horizontal : shifted;
                if (delta.abs() > 0.01) _scroll(delta);
              },
              child: GestureDetector(
                onTap: _focusNode.requestFocus,
                child: SingleChildScrollView(
                  controller: widget.controller,
                  scrollDirection: Axis.horizontal,
                  physics: BouncingScrollPhysics(),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < widget.children.length;
                          index++
                        ) ...[
                          widget.children[index],
                          if (index != widget.children.length - 1)
                            SizedBox(width: widget.compact ? 6 : 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _StripArrow(
            icon: Icons.chevron_right_rounded,
            compact: widget.compact,
            onPressed: () => _scroll(220),
          ),
        ],
      ),
    );
  }

  void _scroll(double delta) {
    _focusNode.requestFocus();
    if (!widget.controller.hasClients) return;
    final target = (widget.controller.offset + delta).clamp(
      widget.controller.position.minScrollExtent,
      widget.controller.position.maxScrollExtent,
    );
    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }
}

class _StripArrow extends StatelessWidget {
  const _StripArrow({
    required this.icon,
    required this.onPressed,
    required this.compact,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 25 : 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, size: compact ? 18 : 22),
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
    return Material(
      color: selected
          ? iPhoneColor(context, _primary).withValues(alpha: 0.18)
          : iPhoneColor(context, _surface),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          height: isIPhoneLayout(context) ? 44 : 32,
          padding: EdgeInsets.only(left: 10, right: onClose == null ? 10 : 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected
                  ? iPhoneColor(context, _primary)
                  : iPhoneColor(context, _border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? iPhoneColor(context, _text)
                      : iPhoneColor(context, _textSecondary),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
              if (onClose != null) ...[
                SizedBox(width: 2),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: EdgeInsets.all(3),
                    child: Icon(Icons.close_rounded, size: 13),
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
    return AdaptiveActionButton.text(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: Size(0, 32),
        padding: EdgeInsets.symmetric(horizontal: 9),
      ),
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }
}

class _ProductTableHeader extends StatelessWidget {
  const _ProductTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isIPhoneLayout(context) ? 44 : 32,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: iPhoneColor(context, _surface),
        border: Border(
          top: BorderSide(color: iPhoneColor(context, _border)),
          bottom: BorderSide(color: iPhoneColor(context, _border)),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _ProductColumnLabel('PRODUCT')),
          SizedBox(width: 8),
          Expanded(flex: 3, child: _ProductColumnLabel('SIZE')),
          Expanded(
            flex: 2,
            child: _ProductColumnLabel('PRICE', textAlign: TextAlign.right),
          ),
          SizedBox(width: 8),
          SizedBox(
            width: 46,
            child: _ProductColumnLabel('ACTION', textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _ProductColumnLabel extends StatelessWidget {
  const _ProductColumnLabel(this.label, {this.textAlign = TextAlign.left});

  final String label;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: TextStyle(
        color: iPhoneColor(context, _textMuted),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CompactProductRow extends StatelessWidget {
  const _CompactProductRow({
    super.key,
    required this.product,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });

  final WorkspaceProduct product;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isIPhoneLayout(context) ? 44 : 42,
      width: double.infinity,
      child: Material(
        color: selected
            ? iPhoneColor(context, _primary).withValues(alpha: 0.13)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Tooltip(
                    message: product.code,
                    child: Text(
                      product.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: iPhoneColor(context, _text),
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w900
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    _compactSpec(product),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: iPhoneColor(context, _textSecondary),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    product.priceLabel,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: iPhoneColor(context, _success),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 46,
                  child: IconButton(
                    tooltip: selected ? 'កែតម្រូវ' : 'បន្ថែម',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(width: 30, height: 30),
                    onPressed: selected ? onEdit : onTap,
                    icon: Icon(
                      selected ? Icons.tune_rounded : Icons.add_rounded,
                      size: 17,
                      color: selected
                          ? iPhoneColor(context, _success)
                          : iPhoneColor(context, _primary),
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

  static String _compactSpec(WorkspaceProduct product) {
    final variant = product.variants.first;
    if (variant.widthMm != null &&
        variant.thicknessMm != null &&
        variant.lengthMm != null) {
      return '${_number(variant.widthMm!)}×${_number(variant.thicknessMm!)}×${_number(variant.lengthMm!)}';
    }
    if (variant.lengthMm != null) {
      final meters = variant.lengthMm! / 1000;
      return '${_number(meters)}m';
    }
    if (variant.itemsPerBundle > 1) return variant.label;
    return variant.label == product.code ? '' : variant.label;
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
      height: isIPhoneLayout(context) ? 44 : 32,
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: iPhoneColor(context, _card),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: iPhoneColor(context, _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoomModeButton(
              key: ValueKey('workspace-group-mode-dimensions-$groupId'),
              label: 'បណ្ដោយ × ទទឹង',
              selected: mode == MeasurementRoomMode.dimensions,
              onTap: () => onChanged(MeasurementRoomMode.dimensions),
            ),
          ),
          SizedBox(width: 2),
          Expanded(
            child: _RoomModeButton(
              key: ValueKey('workspace-group-mode-area-$groupId'),
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
      color: selected
          ? iPhoneColor(context, _primary).withValues(alpha: 0.22)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected
                  ? iPhoneColor(context, _text)
                  : iPhoneColor(context, _textSecondary),
              fontSize: 11,
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: iPhoneColor(context, _textSecondary),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5),
        SizedBox(
          height: isIPhoneLayout(context) ? 44 : 42,
          child: AdaptiveTextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalFormatter],
            decoration: InputDecoration(
              suffixText: suffix,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
    required this.onDecrement,
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
      height: isIPhoneLayout(context) ? 44 : 42,
      decoration: BoxDecoration(
        color: iPhoneColor(context, _card),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: iPhoneColor(context, _border)),
      ),
      child: Row(
        children: [
          IconButton(
            key: ValueKey('workspace-group-count-decrement-$groupId'),
            tooltip: 'បន្ថយ',
            onPressed: onDecrement,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.remove_rounded, size: 18),
          ),
          VerticalDivider(width: 1, color: iPhoneColor(context, _border)),
          Expanded(
            child: AdaptiveTextField(
              key: ValueKey('workspace-group-count-$groupId'),
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [_positiveIntegerFormatter],
              onSubmitted: (_) => onNormalize(),
              onTapOutside: (_) {
                onNormalize();
                FocusScope.of(context).unfocus();
              },
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 9),
              ),
              style: TextStyle(
                color: iPhoneColor(context, _text),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          VerticalDivider(width: 1, color: iPhoneColor(context, _border)),
          IconButton(
            key: ValueKey('workspace-group-count-increment-$groupId'),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasized
                  ? iPhoneColor(context, _text)
                  : iPhoneColor(context, _textSecondary),
              fontSize: 12,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          value,
          key: valueKey,
          style: TextStyle(
            color: emphasized
                ? iPhoneColor(context, _secondary)
                : iPhoneColor(context, _text),
            fontSize: emphasized ? 15 : 13,
            fontWeight: FontWeight.w900,
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
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: _textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _ResultTableHeader extends StatelessWidget {
  const _ResultTableHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            'សម្ភារៈ',
            style: TextStyle(
              color: iPhoneColor(context, _textMuted),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            'ចំនួន',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: iPhoneColor(context, _textMuted),
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'តម្លៃ',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: iPhoneColor(context, _textMuted),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialResultGroup extends StatelessWidget {
  const _MaterialResultGroup({required this.material, required this.onEdit});

  final WorkspaceMaterialResult material;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: iPhoneColor(context, _surface),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        children: [
          for (var index = 0; index < material.lines.length; index++)
            InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(9),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.selection.product.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: iPhoneColor(context, _text),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (material.lines[index].detail.isNotEmpty)
                            Text(
                              material.lines[index].detail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: iPhoneColor(context, _textMuted),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${material.lines[index].quantity}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: iPhoneColor(context, _text),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        MoneyFormatter.money(material.lines[index].totalPrice),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: iPhoneColor(context, _text),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (material.notice case final notice?)
            Padding(
              padding: EdgeInsets.fromLTRB(9, 0, 9, 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: iPhoneColor(context, _warning),
                    ),
                  ),
                  SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      notice,
                      key: ValueKey(
                        'workspace-material-notice-${material.selection.product.id}',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: iPhoneColor(context, _warning),
                        fontSize: 10,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (material.wasteAreaM2 > 0.005 || material.wasteLinearM > 0.005)
            Padding(
              padding: EdgeInsets.fromLTRB(9, 0, 9, 7),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  material.wasteAreaM2 > 0.005
                      ? 'សល់ ${MoneyFormatter.decimal(material.wasteAreaM2)} m²'
                      : 'សល់ ${MoneyFormatter.decimal(material.wasteLinearM)} m',
                  style: TextStyle(
                    color: iPhoneColor(context, _textMuted),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: iPhoneColor(context, _danger).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        message,
        style: TextStyle(color: iPhoneColor(context, _danger), fontSize: 12),
      ),
    );
  }
}

final _decimalFormatter = FilteringTextInputFormatter.allow(
  RegExp(r'[-0-9.,]'),
);
final _integerFormatter = FilteringTextInputFormatter.digitsOnly;
final _positiveIntegerFormatter = TextInputFormatter.withFunction((
  oldValue,
  newValue,
) {
  if (newValue.text.isEmpty) return newValue;
  final parsed = int.tryParse(newValue.text);
  return parsed != null && parsed >= 1 ? newValue : oldValue;
});

String _number(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
