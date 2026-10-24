import '../../../core/ios/iphone_controls.dart';
import '../../../core/ios/iphone_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/business_ids.dart';
import '../../../core/services/product_image_service.dart';
import '../../../core/theme/sakura_theme.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../core/widgets/product_image_thumbnail.dart';
import '../../ceiling_calculator/presentation/screens/ceiling_calculator_screen.dart';
import '../../invoice/domain/invoice_document.dart';
import '../../invoice/presentation/customer_document_dialog.dart';
import '../../measurement_calculator/presentation/screens/measurement_calculator_screen.dart';
import '../../pvc_quantity_calculator/presentation/screens/pvc_quantity_calculator_screen.dart';
import '../data/models/material_category.dart';
import '../data/models/material_item.dart';
import '../data/models/material_price.dart';
import '../data/models/packaging_rule.dart';
import '../data/models/product_type_template.dart';
import '../data/models/unit_of_measure.dart';
import '../domain/product_sale_models.dart';
import 'facebook_comment_reply_page.dart';

const _sidebar = AppColors.sidebar;
const _surface = AppColors.surface;
const _card = AppColors.surfaceSecondary;
const _border = AppColors.border;
const _primary = AppColors.primary;
const _secondary = AppColors.primaryDeep;
const _success = AppColors.successText;
const _danger = AppColors.errorText;
const _text = AppColors.textMain;
const _textSecondary = AppColors.textSecondary;
const _textMuted = AppColors.textMuted;

enum SaleDestination {
  facebookReply,
  ceiling,
  pvc,
  workspace,
  insulation,
  led,
  wire,
  decoration,
  custom,
  currentSale,
  products,
  prices,
  packaging,
  productKinds,
  formulas,
  unitsCategories,
  appSettings,
}

class SellingDesktopShell extends StatefulWidget {
  const SellingDesktopShell({
    super.key,
    this.initialDestination = SaleDestination.ceiling,
  });

  final SaleDestination initialDestination;

  @override
  State<SellingDesktopShell> createState() => _SellingDesktopShellState();
}

class _SellingDesktopShellState extends State<SellingDesktopShell> {
  late SaleDestination _destination;

  @override
  void initState() {
    super.initState();
    _destination = widget.initialDestination;
  }

  @override
  Widget build(BuildContext context) {
    final meta = _destinationMeta(_destination);
    if (isIPhoneLayout(context)) {
      return IPhoneShell(
        initialIndex: switch (widget.initialDestination) {
          SaleDestination.pvc => 1,
          SaleDestination.workspace => 4,
          SaleDestination.products => 3,
          SaleDestination.appSettings => 4,
          SaleDestination.facebookReply => 2,
          _ => 0,
        },
        pages: [
          _body(SaleDestination.ceiling),
          _body(SaleDestination.pvc),
          const FacebookCommentReplyPage(),
          _body(SaleDestination.products),
          IPhoneMenu(
            entries: [
              for (final destination in SaleDestination.values)
                IPhoneMenuEntry(
                  title: _destinationMeta(destination).title,
                  icon: _destinationMeta(destination).icon,
                  builder: (_) => _body(destination),
                ),
            ],
          ),
        ],
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppWorkspaceBackground(
        child: Row(
          children: [
            _Sidebar(
              destination: _destination,
              onSelected: (value) => setState(() => _destination = value),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopHeader(
                    meta: meta,
                    onSelectDestination: (value) =>
                        setState(() => _destination = value),
                  ),
                  Expanded(child: _body(_destination)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(SaleDestination destination) {
    return switch (destination) {
      SaleDestination.facebookReply => const FacebookCommentReplyPage(),
      SaleDestination.ceiling => CeilingCalculatorScreen(
        key: ValueKey('ceiling_calculator'),
      ),
      SaleDestination.pvc => PvcQuantityCalculatorScreen(
        key: ValueKey('pvc_quantity_calculator'),
      ),
      SaleDestination.workspace => MeasurementCalculatorScreen(
        key: ValueKey('measurement_calculator'),
      ),
      SaleDestination.insulation ||
      SaleDestination.led ||
      SaleDestination.wire ||
      SaleDestination.decoration ||
      SaleDestination.custom => MeasurementCalculatorScreen(
        key: ValueKey('measurement_calculator'),
      ),
      SaleDestination.currentSale => _TemporarySaleScreen(),
      SaleDestination.products => _ProductsDataScreen(),
      SaleDestination.prices => _PricesDataScreen(),
      SaleDestination.packaging => _PackagingDataScreen(),
      SaleDestination.productKinds => _ProductKindsDataScreen(),
      SaleDestination.formulas => _FormulaRulesDataScreen(),
      SaleDestination.unitsCategories => _UnitsCategoriesDataScreen(),
      SaleDestination.appSettings => _AppSettingsDataScreen(),
    };
  }
}

class _DestinationMeta {
  const _DestinationMeta(this.title, this.subtitle, this.icon);

  final String title;
  final String subtitle;
  final IconData icon;
}

_DestinationMeta _destinationMeta(SaleDestination destination) {
  return switch (destination) {
    SaleDestination.facebookReply => const _DestinationMeta(
      'Facebook Reply',
      'ចម្លើយខ្លីសម្រាប់ comment អតិថិជន',
      Icons.facebook_rounded,
    ),
    SaleDestination.ceiling => const _DestinationMeta(
      'គណនាពិដាន',
      'គណនា / លក់ សម្ភារៈពិដាន',
      Icons.grid_view_rounded,
    ),
    SaleDestination.pvc => const _DestinationMeta(
      'គណនា PVC',
      'គណនាចំនួនសម្ភារៈ PVC ដែលត្រូវការ',
      Icons.layers_rounded,
    ),
    SaleDestination.workspace => const _DestinationMeta(
      'គណនា / លក់',
      'គណនា បរិមាណ និងទទួលវិក្កយបត្រ',
      Icons.receipt_long_outlined,
    ),
    SaleDestination.insulation => const _DestinationMeta(
      'អ៊ីសូឡង់',
      'គណនា / លក់',
      Icons.layers_rounded,
    ),
    SaleDestination.led => const _DestinationMeta(
      'អំពូល LED',
      'គណនា / លក់',
      Icons.lightbulb_outline_rounded,
    ),
    SaleDestination.wire => const _DestinationMeta(
      'លួស',
      'គណនា / លក់',
      Icons.cable_rounded,
    ),
    SaleDestination.decoration => const _DestinationMeta(
      'លម្អ',
      'គណនា / លក់',
      Icons.dashboard_customize_outlined,
    ),
    SaleDestination.custom => const _DestinationMeta(
      'ផលិតផលផ្សេងៗ',
      'គណនា / លក់',
      Icons.tune_rounded,
    ),
    SaleDestination.currentSale => const _DestinationMeta(
      'បញ្ជីលក់បច្ចុប្បន្ន',
      'សង្ខេបបណ្ដោះអាសន្ន',
      Icons.receipt_long_rounded,
    ),
    SaleDestination.products => const _DestinationMeta(
      'ផលិតផល',
      'ទិន្នន័យ',
      Icons.inventory_2_outlined,
    ),
    SaleDestination.prices => const _DestinationMeta(
      'តម្លៃ',
      'ទិន្នន័យ',
      Icons.sell_outlined,
    ),
    SaleDestination.packaging => const _DestinationMeta(
      'ការវេចខ្ចប់',
      'ទិន្នន័យ',
      Icons.all_inbox_outlined,
    ),
    SaleDestination.productKinds => const _DestinationMeta(
      'ប្រភេទផលិតផល',
      'ទិន្នន័យ',
      Icons.category_outlined,
    ),
    SaleDestination.formulas => const _DestinationMeta(
      'រូបមន្តគណនា',
      'ទិន្នន័យ',
      Icons.functions_rounded,
    ),
    SaleDestination.unitsCategories => const _DestinationMeta(
      'ឯកតា / ប្រភេទ',
      'ទិន្នន័យ',
      Icons.straighten_rounded,
    ),
    SaleDestination.appSettings => const _DestinationMeta(
      'ការកំណត់កម្មវិធី',
      'ការកំណត់',
      Icons.settings_outlined,
    ),
  };
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.destination, required this.onSelected});

  final SaleDestination destination;
  final ValueChanged<SaleDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      width: 248,
      borderRadius: BorderRadius.zero,
      tint: _sidebar,
      borderColor: iPhoneColor(
        context,
        AppColors.glassHighlight,
      ).withValues(alpha: 0.72),
      blur: AppEffects.glassBlur,
      shadows: AppShadows.glassCard,
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Row(
                    children: [
                      AppBrandLogo(size: 48),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppConstants.appName,
                              style: TextStyle(
                                color: iPhoneColor(context, _primary),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'គណនា និងលក់សម្ភារៈសំណង់',
                              style: TextStyle(
                                color: iPhoneColor(context, _textMuted),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _group(context, 'គណនាលក់'),
                      _item(
                        context,
                        Icons.grid_view_rounded,
                        'គណនាពិដាន',
                        SaleDestination.ceiling,
                      ),
                      _item(
                        context,
                        Icons.layers_rounded,
                        'គណនា PVC',
                        SaleDestination.pvc,
                      ),
                      _item(
                        context,
                        Icons.receipt_long_outlined,
                        'គណនា / លក់',
                        SaleDestination.workspace,
                      ),
                      SizedBox(height: 12),
                      _group(context, 'ទិន្នន័យ'),
                      _item(
                        context,
                        Icons.inventory_2_outlined,
                        'ផលិតផល',
                        SaleDestination.products,
                      ),
                      SizedBox(height: 12),
                      _group(context, 'ការកំណត់'),
                      _item(
                        context,
                        Icons.settings_outlined,
                        'ការកំណត់',
                        SaleDestination.appSettings,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 12, 10, 6),
      child: Text(
        label,
        style: TextStyle(
          color: iPhoneColor(context, _textMuted),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    SaleDestination value,
  ) {
    final active = destination == value;
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('nav-${value.name}'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => onSelected(value),
          hoverColor: iPhoneColor(context, AppColors.sidebarHoverBg),
          child: AnimatedContainer(
            duration: SakuraTheme.animFast,
            curve: SakuraTheme.animCurve,
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: active
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        iPhoneColor(context, AppColors.surfaceGlassStrong),
                        iPhoneColor(context, AppColors.sidebarSelectedBg),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? iPhoneColor(context, AppColors.glassHighlight)
                    : Colors.transparent,
              ),
              boxShadow: active ? AppShadows.cardSoft : [],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: active
                      ? iPhoneColor(context, AppColors.sidebarSelectedIconText)
                      : iPhoneColor(context, AppColors.sidebarText),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active
                          ? iPhoneColor(
                              context,
                              AppColors.sidebarSelectedIconText,
                            )
                          : iPhoneColor(context, AppColors.sidebarText),
                      fontSize: 13.5,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.1,
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

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.meta, this.onSelectDestination});

  final _DestinationMeta meta;
  final ValueChanged<SaleDestination>? onSelectDestination;

  @override
  Widget build(BuildContext context) {
    final count = context.select<AppState, int>(
      (state) => state.currentSaleItems.length,
    );
    return AppGlassSurface(
      height: 68,
      padding: EdgeInsets.symmetric(horizontal: 22),
      borderRadius: BorderRadius.zero,
      tint: iPhoneColor(context, AppColors.topBar),
      borderColor: iPhoneColor(context, AppColors.glassHighlight),
      blur: AppEffects.glassBlurSubtle,
      shadows: AppShadows.cardSoft,
      child: Row(
        children: [
          AppBrandLogo(size: 34),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meta.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: iPhoneColor(context, _primary),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  meta.subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: iPhoneColor(context, _textSecondary),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _HeaderPill(icon: Icons.attach_money_rounded, label: 'USD'),
          SizedBox(width: 10),
          _HeaderPill(
            icon: Icons.receipt_long_outlined,
            label: 'Get Invoice • $count',
            onTap: onSelectDestination != null
                ? () => onSelectDestination!(
                    count > 0
                        ? SaleDestination.currentSale
                        : SaleDestination.workspace,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AppGlassSurface(
          height: isIPhoneLayout(context) ? 44 : 38,
          padding: EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(AppEffects.pillRadius),
          tint: iPhoneColor(context, AppColors.surfaceGlassStrong),
          borderColor: iPhoneColor(context, AppColors.glassHighlight),
          blur: AppEffects.glassBlurSubtle,
          shadows: AppShadows.cardSoft,
          child: Row(
            children: [
              Icon(icon, color: iPhoneColor(context, _primary), size: 18),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: iPhoneColor(context, _primary),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemporarySaleScreen extends StatelessWidget {
  const _TemporarySaleScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final summary = state.temporarySaleSummary;
    return _Page(
      child: _Panel(
        title: 'បញ្ជីលក់បច្ចុប្បន្ន',
        icon: Icons.receipt_long_rounded,
        scrollBody: true,
        trailing: Wrap(
          spacing: 8,
          children: [
            AdaptiveActionButton.filledIcon(
              key: ValueKey('get-invoice-action'),
              onPressed: summary.items.isEmpty
                  ? null
                  : () => _openCustomerDocument(context, summary.items),
              icon: Icon(Icons.receipt_long_rounded, size: 18),
              label: Text('Get Invoice'),
            ),
            AdaptiveActionButton.filledIcon(
              onPressed: summary.items.isEmpty
                  ? null
                  : () => _copyCartSummary(context, summary.items),
              icon: Icon(Icons.copy_rounded, size: 18),
              label: Text('ចម្លងសង្ខេប'),
            ),
            AdaptiveActionButton.outlinedIcon(
              onPressed: summary.items.isEmpty
                  ? null
                  : () => context.read<AppState>().clearTemporarySale(),
              icon: Icon(Icons.delete_sweep_rounded, size: 18),
              label: Text('សម្អាតទាំងអស់'),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile('ចំនួនផលិតផលសរុប', '${summary.totalQuantity}'),
                _MetricTile(
                  'អតិថិជនបង់សរុប',
                  MoneyFormatter.money(summary.customerPayTotal),
                ),
                _MetricTile(
                  'ថ្លៃដើមសរុប',
                  MoneyFormatter.money(summary.ownerCostTotal),
                ),
                _MetricTile(
                  'ចំណេញសរុប',
                  MoneyFormatter.money(summary.ownerProfit),
                  accent: summary.ownerProfit < 0
                      ? iPhoneColor(context, _danger)
                      : iPhoneColor(context, _success),
                ),
              ],
            ),
            SizedBox(height: 14),
            _TemporarySaleTable(items: summary.items),
          ],
        ),
      ),
    );
  }

  void _copyCartSummary(BuildContext context, List<ProductSaleResult> items) {
    Clipboard.setData(ClipboardData(text: _summaryText(items)));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('បានចម្លងសង្ខេប។')));
  }

  Future<void> _openCustomerDocument(
    BuildContext context,
    List<ProductSaleResult> items,
  ) {
    return showAdaptiveEditor<void>(
      context: context,
      builder: (context) => CustomerDocumentDialog(
        initialDocument: InvoiceDocument.fromSaleItems(items),
      ),
    );
  }
}

class _TemporarySaleTable extends StatelessWidget {
  const _TemporarySaleTable({required this.items});

  final List<ProductSaleResult> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'មិនទាន់មានផលិតផលក្នុងបញ្ជី',
        style: TextStyle(color: iPhoneColor(context, _textSecondary)),
      );
    }
    if (isIPhoneLayout(context)) {
      return Column(
        children: [
          for (var i = 0; i < items.length; i++)
            IPhoneCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _productResultLabel(items[i]),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${items[i].productKindNameKhmer} • ${items[i].inputMethodNameKhmer} • ${items[i].chargeMethodNameKhmer}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${items[i].sellQuantity} • ${items[i].packagingFullBoxes} កេស • ${items[i].packagingLooseItems} រាយ',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'អតិថិជនបង់: ${MoneyFormatter.money(items[i].customerPayTotal)}',
                  ),
                  Text(
                    'ថ្លៃដើម: ${MoneyFormatter.money(items[i].ownerCostTotal)}',
                  ),
                  Text('ចំណេញ: ${MoneyFormatter.money(items[i].ownerProfit)}'),
                  Text(items[i].canSellStatusNameKhmer),
                  AdaptiveActionButton.textIcon(
                    onPressed: () async {
                      final state = context.read<AppState>();
                      if (await confirmIPhoneAction(
                        context,
                        title: _productResultLabel(items[i]),
                        action: 'លុបមួយមុខ',
                      )) {
                        state.removeTemporarySaleItem(i);
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('លុបមួយមុខ'),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('ល.រ')),
          DataColumn(label: Text('ប្រភេទ')),
          DataColumn(label: Text('ផលិតផល')),
          DataColumn(label: Text('របៀបបញ្ចូល')),
          DataColumn(label: Text('របៀបគិតលុយ')),
          DataColumn(label: Text('ចំនួន')),
          DataColumn(label: Text('កេស')),
          DataColumn(label: Text('រាយ')),
          DataColumn(label: Text('អតិថិជនបង់')),
          DataColumn(label: Text('ថ្លៃដើម')),
          DataColumn(label: Text('ចំណេញ')),
          DataColumn(label: Text('ស្ថានភាព')),
          DataColumn(label: Text('')),
        ],
        rows: [
          for (var i = 0; i < items.length; i++)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(items[i].productKindNameKhmer)),
                DataCell(Text(_productResultLabel(items[i]))),
                DataCell(Text(items[i].inputMethodNameKhmer)),
                DataCell(Text(items[i].chargeMethodNameKhmer)),
                DataCell(Text('${items[i].sellQuantity}')),
                DataCell(Text('${items[i].packagingFullBoxes}')),
                DataCell(Text('${items[i].packagingLooseItems}')),
                DataCell(Text(MoneyFormatter.money(items[i].customerPayTotal))),
                DataCell(Text(MoneyFormatter.money(items[i].ownerCostTotal))),
                DataCell(Text(MoneyFormatter.money(items[i].ownerProfit))),
                DataCell(Text(items[i].canSellStatusNameKhmer)),
                DataCell(
                  IconButton(
                    tooltip: 'លុបមួយមុខ',
                    onPressed: () =>
                        context.read<AppState>().removeTemporarySaleItem(i),
                    icon: Icon(Icons.delete_outline_rounded, size: 19),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

enum ProductFilterGroup {
  all('All', 'ទាំងអស់'),
  pvc('PVC', 'PVC'),
  accessories('Accessories', 'សម្ភារៈ'),
  cLine('C-Line', 'C-Line'),
  db('DB', 'DB'),
  gd('GD', 'GD');

  const ProductFilterGroup(this.englishLabel, this.khmerLabel);
  final String englishLabel;
  final String khmerLabel;
}

class _ProductsDataScreen extends StatefulWidget {
  const _ProductsDataScreen();

  @override
  State<_ProductsDataScreen> createState() => _ProductsDataScreenState();
}

class _ProductsDataScreenState extends State<_ProductsDataScreen> {
  final TextEditingController _searchController = TextEditingController();
  ProductFilterGroup _selectedFilter = ProductFilterGroup.all;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesFilterGroup(MaterialItem material) {
    final code = (material.code ?? '').toUpperCase();
    final family = (material.productFamilyId ?? '').toUpperCase();
    final name = material.khmerName.toUpperCase();
    final english = material.englishName.toUpperCase();

    switch (_selectedFilter) {
      case ProductFilterGroup.all:
        return true;
      case ProductFilterGroup.pvc:
        return material.categoryId == 'pvc';
      case ProductFilterGroup.accessories:
        return material.categoryId != 'pvc' ||
            name.contains('ជ្រី') ||
            name.contains('ឃ្មៀប') ||
            name.contains('វីស') ||
            name.contains('កាវ') ||
            name.contains('ញូម') ||
            english.contains('ACCESSORY') ||
            family.contains('ACCESSORY');
      case ProductFilterGroup.cLine:
        return code.contains('C.LINE') ||
            family.contains('C_LINE') ||
            name.contains('C.LINE');
      case ProductFilterGroup.db:
        return code.startsWith('DB') ||
            family.contains('DB') ||
            name.startsWith('DB');
      case ProductFilterGroup.gd:
        return code.startsWith('GD') ||
            family.contains('GD') ||
            name.startsWith('GD');
    }
  }

  bool _matchesSearchQuery(MaterialItem material) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return true;

    final khmer = material.khmerName.toLowerCase();
    final english = material.englishName.toLowerCase();
    final code = (material.code ?? '').toLowerCase();
    final spec = material.spec.toLowerCase();
    final family = (material.productFamilyId ?? '').toLowerCase();
    final notes = (material.notes ?? '').toLowerCase();
    final lengthLabel = material.lengthMm != null
        ? '${(material.lengthMm! / 1000).toStringAsFixed(0)}m'
        : '';

    if (khmer.contains(query) ||
        english.contains(query) ||
        code.contains(query) ||
        spec.contains(query) ||
        family.contains(query) ||
        notes.contains(query) ||
        (lengthLabel.isNotEmpty && lengthLabel == query)) {
      return true;
    }

    final compactQuery = query.replaceAll('-', '').replaceAll(' ', '');
    for (final designCode in material.designCodes) {
      final codeLower = designCode.toLowerCase();
      final compactCode = codeLower.replaceAll('-', '').replaceAll(' ', '');
      if (codeLower.contains(query) || compactCode.contains(compactQuery)) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final allProducts = [...state.materials]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final filteredProducts = allProducts.where((product) {
      return _matchesFilterGroup(product) && _matchesSearchQuery(product);
    }).toList();

    return _Page(
      child: _Panel(
        title: 'ផលិតផល',
        icon: Icons.inventory_2_outlined,
        fillHeight: true,
        child: Column(
          children: [
            // Search Input Field
            isIPhoneLayout(context)
                ? IPhoneSearchField(
                    controller: _searchController,
                    placeholder: 'ស្វែងរកផលិតផល',
                  )
                : AdaptiveTextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search product...',
                      prefixIcon: Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
            SizedBox(height: 10),
            // Compact Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final group in ProductFilterGroup.values) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedFilter = group),
                      child: Container(
                        height: isIPhoneLayout(context) ? 44 : 34,
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _selectedFilter == group
                              ? iPhoneColor(context, AppColors.surfaceSelected)
                              : iPhoneColor(context, _surface),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedFilter == group
                                ? iPhoneColor(context, _primary)
                                : iPhoneColor(context, _border),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            group.englishLabel,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: _selectedFilter == group
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _selectedFilter == group
                                  ? iPhoneColor(context, _text)
                                  : iPhoneColor(context, _textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),
            // Product List
            if (filteredProducts.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'មិនរកឃើញផលិតផលទេ (No products found)',
                    style: TextStyle(
                      color: iPhoneColor(context, _textSecondary),
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: _PanelList(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    final subtitleParts = <String>[
                      product.categoryKhmer,
                      if (product.spec.isNotEmpty) product.spec,
                      if (product.designCodes.isNotEmpty)
                        'Codes: ${product.designCodes.join(', ')}'
                      else
                        product.unitKhmer,
                    ];

                    return _ListRow(
                      leading: ProductImageThumbnail(
                        imagePath: product.imagePath,
                        productName: _productLabel(product),
                        width: 42,
                        height: isIPhoneLayout(context) ? 44 : 42,
                      ),
                      title: _productLabel(product),
                      subtitle: subtitleParts.join(' • '),
                      trailing: Switch.adaptive(
                        value: product.active,
                        onChanged: (value) =>
                            state.saveMaterial(product.copyWith(active: value)),
                      ),
                      onEdit: () async {
                        final saved = await showAdaptiveEditor<MaterialItem>(
                          context: context,
                          builder: (_) => _ProductDialog(
                            product: product,
                            categories: state.categories,
                            units: state.units,
                          ),
                        );
                        if (saved != null) await state.saveMaterial(saved);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PricesDataScreen extends StatelessWidget {
  const _PricesDataScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final products = [...state.materials]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return _Page(
      child: _Panel(
        title: 'តម្លៃ',
        icon: Icons.sell_outlined,
        fillHeight: true,
        child: _PanelList(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ListRow(
              title: _productLabel(product),
              subtitle:
                  'លក់រាយ ${_moneyOrDash(_price(state.prices, product.id, PriceTypeIds.saleUnitPrice, fallback: PriceTypeIds.unitPrice))} • លក់កេស ${_moneyOrDash(_price(state.prices, product.id, PriceTypeIds.saleBoxPrice, fallback: PriceTypeIds.boxPrice))} • ដើមរាយ ${_moneyOrDash(_price(state.prices, product.id, PriceTypeIds.costUnitPrice))}',
              onEdit: () async {
                final saved = await showAdaptiveEditor<List<MaterialPrice>>(
                  context: context,
                  builder: (_) =>
                      _PriceDialog(product: product, prices: state.prices),
                );
                if (saved != null) {
                  for (final price in saved) {
                    await state.savePrice(price);
                  }
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _PackagingDataScreen extends StatelessWidget {
  const _PackagingDataScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rulesByMaterial = {
      for (final rule in state.packagingRules) rule.materialId: rule,
    };
    final products = [...state.materials]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return _Page(
      child: _Panel(
        title: 'ការវេចខ្ចប់',
        icon: Icons.all_inbox_outlined,
        fillHeight: true,
        child: _PanelList(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _ListRow(
              title: _productLabel(product),
              subtitle:
                  '${rulesByMaterial[product.id]?.itemsPerBox ?? product.itemsPerBox ?? 1} ក្នុងកេស',
              onEdit: () async {
                final saved = await showAdaptiveEditor<PackagingRule>(
                  context: context,
                  builder: (_) => _PackagingDialog(
                    product: product,
                    rule: rulesByMaterial[product.id],
                  ),
                );
                if (saved != null) await state.savePackagingRule(saved);
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProductKindsDataScreen extends StatelessWidget {
  const _ProductKindsDataScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final templates = [...state.productTemplates]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return _Page(
      child: _Panel(
        title: 'ប្រភេទផលិតផល',
        icon: Icons.category_outlined,
        fillHeight: true,
        child: _PanelList(
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return _ListRow(
              title: template.nameKhmer,
              subtitle: '${template.defaultMaterialRules.length} ផលិតផល',
              trailing: Switch.adaptive(
                value: template.active,
                onChanged: (value) =>
                    state.saveProductTemplate(template.copyWith(active: value)),
              ),
              onEdit: () async {
                final saved = await showAdaptiveEditor<ProductTypeTemplate>(
                  context: context,
                  builder: (_) => _ProductKindDialog(template: template),
                );
                if (saved != null) await state.saveProductTemplate(saved);
              },
            );
          },
        ),
      ),
    );
  }
}

class _FormulaRulesDataScreen extends StatelessWidget {
  const _FormulaRulesDataScreen();

  @override
  Widget build(BuildContext context) {
    final rules = context.watch<AppState>().formulaRules;
    return _Page(
      child: _Panel(
        title: 'រូបមន្តគណនា',
        icon: Icons.functions_rounded,
        fillHeight: true,
        child: _PanelList(
          itemCount: rules.length,
          itemBuilder: (context, index) {
            final rule = rules[index];
            return _ListRow(
              title: rule.nameKhmer,
              subtitle: rule.formulaTypeId,
            );
          },
        ),
      ),
    );
  }
}

class _UnitsCategoriesDataScreen extends StatelessWidget {
  const _UnitsCategoriesDataScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _Page(
      child: Flex(
        direction: isIPhoneLayout(context) ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Panel(
              title: 'ឯកតា',
              icon: Icons.straighten_rounded,
              fillHeight: true,
              child: _PanelList(
                itemCount: state.units.length,
                itemBuilder: (context, index) {
                  final unit = state.units[index];
                  return _ListRow(
                    title: unit.nameKhmer,
                    subtitle: unit.abbreviationKhmer,
                    onEdit: () async {
                      final saved = await showAdaptiveEditor<UnitOfMeasure>(
                        context: context,
                        builder: (_) => _UnitDialog(unit: unit),
                      );
                      if (saved != null) await state.saveUnit(saved);
                    },
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 14, height: 14),
          Expanded(
            child: _Panel(
              title: 'ប្រភេទ',
              icon: Icons.category_outlined,
              fillHeight: true,
              child: _PanelList(
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  final category = state.categories[index];
                  return _ListRow(
                    title: category.nameKhmer,
                    subtitle: category.id,
                    onEdit: () async {
                      final saved = await showAdaptiveEditor<MaterialCategory>(
                        context: context,
                        builder: (_) => _CategoryDialog(category: category),
                      );
                      if (saved != null) await state.saveCategory(saved);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppSettingsDataScreen extends StatelessWidget {
  const _AppSettingsDataScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _Page(
      child: _Panel(
        title: 'ការកំណត់កម្មវិធី',
        icon: Icons.settings_outlined,
        scrollBody: true,
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: state.useSavedPriceAsDefault,
              title: Text('ប្រើតម្លៃរក្សាទុកជាតម្លៃដើម'),
              subtitle: Text(
                'បិទ = ការគណនាចាប់ផ្តើមតម្លៃ 0 ហើយវាយតម្លៃថ្មីពេលលក់',
              ),
              onChanged: state.setUseSavedPriceAsDefault,
            ),
            Divider(),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: state.allowSaleBelowCost,
              title: Text('អនុញ្ញាតលក់ទាបជាងថ្លៃដើម'),
              subtitle: Text('បិទ = មិនអាចបន្ថែមទៅបញ្ជីបណ្ដោះអាសន្នបើខាត'),
              onChanged: state.setAllowSaleBelowCost,
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile('ផលិតផល', '${state.materials.length}'),
                _MetricTile('តម្លៃ', '${state.prices.length}'),
                _MetricTile(
                  'បញ្ជីបណ្ដោះអាសន្ន',
                  '${state.currentSaleItems.length}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({
    required this.product,
    required this.categories,
    required this.units,
  });

  final MaterialItem product;
  final List<MaterialCategory> categories;
  final List<UnitOfMeasure> units;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  late final TextEditingController _khmer;
  late final TextEditingController _english;
  late final TextEditingController _spec;
  late final TextEditingController _coverage;
  late final TextEditingController _multiplier;
  late final TextEditingController _itemsPerBox;
  late String _categoryId;
  late String _unitId;
  late String _formulaTypeId;
  late bool _active;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _khmer = TextEditingController(text: widget.product.khmerName);
    _english = TextEditingController(text: widget.product.englishName);
    _spec = TextEditingController(text: widget.product.spec);
    _coverage = TextEditingController(
      text: widget.product.coverageValue?.toString() ?? '',
    );
    _multiplier = TextEditingController(
      text: widget.product.multiplierValue?.toString() ?? '',
    );
    _itemsPerBox = TextEditingController(
      text: (widget.product.itemsPerBox ?? 1).toString(),
    );
    _categoryId = widget.product.categoryId;
    _unitId = widget.product.unitId;
    _formulaTypeId = widget.product.formulaTypeId;
    _active = widget.product.active;
    _imagePath = widget.product.imagePath;
  }

  @override
  void dispose() {
    _khmer.dispose();
    _english.dispose();
    _spec.dispose();
    _coverage.dispose();
    _multiplier.dispose();
    _itemsPerBox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('កែផលិតផល'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _dialogField(_khmer, 'ឈ្មោះផលិតផល'),
              _dialogField(_english, 'កូដ / ឈ្មោះបច្ចេកទេស'),
              _dialogField(_spec, 'លក្ខណៈ'),
              _dropdown(
                label: 'ប្រភេទផលិតផល',
                value: _categoryId,
                items: widget.categories
                    .map((item) => MapEntry(item.id, item.nameKhmer))
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
              _dropdown(
                label: 'ឯកតា',
                value: _unitId,
                items: widget.units
                    .map((item) => MapEntry(item.id, item.nameKhmer))
                    .toList(),
                onChanged: (value) => setState(() => _unitId = value),
              ),
              _dropdown(
                label: 'រូបមន្តគណនា',
                value: _formulaTypeId,
                items: FormulaTypeIds.supportedNow
                    .map((id) => MapEntry(id, id))
                    .toList(),
                onChanged: (value) => setState(() => _formulaTypeId = value),
              ),
              _dialogField(_coverage, 'តម្លៃគ្របដណ្ដប់', number: true),
              _dialogField(_multiplier, 'មេគុណ', number: true),
              _dialogField(_itemsPerBox, 'ចំនួនក្នុងកេស', number: true),
              Container(
                width: 696,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iPhoneColor(context, AppColors.surfaceSecondary),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iPhoneColor(context, _border)),
                ),
                child: Flex(
                  mainAxisSize: MainAxisSize.min,
                  direction: isIPhoneLayout(context)
                      ? Axis.vertical
                      : Axis.horizontal,
                  children: [
                    ProductImageThumbnail(
                      imagePath: _imagePath,
                      width: 56,
                      height: 56,
                      borderRadius: 10,
                      enablePreview: true,
                    ),
                    SizedBox(width: 14),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'រូបភាពផលិតផល (Product Image)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: iPhoneColor(context, _text),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            _imagePath == null
                                ? 'មិនទាន់មានរូបភាព (គ្មាន)'
                                : 'រូបភាពត្រូវបានភ្ជាប់',
                            style: TextStyle(
                              fontSize: 12,
                              color: iPhoneColor(context, _textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AdaptiveActionButton.outlinedIcon(
                      onPressed: () async {
                        final picked =
                            await ProductImageService.pickImageFile();
                        if (picked != null) {
                          final newPath =
                              await ProductImageService.replaceImage(
                                oldImagePath: _imagePath,
                                newSourceFilePath: picked,
                                productId: widget.product.id,
                              );
                          if (newPath != null) {
                            setState(() => _imagePath = newPath);
                          }
                        }
                      },
                      icon: Icon(
                        _imagePath == null
                            ? Icons.add_a_photo_outlined
                            : Icons.edit_outlined,
                        size: 16,
                      ),
                      label: Text(
                        _imagePath == null ? 'ជ្រើសរូបភាព' : 'ប្ដូររូបភាព',
                      ),
                    ),
                    if (_imagePath != null) ...[
                      SizedBox(width: 8),
                      IconButton(
                        tooltip: 'លុបរូបភាព',
                        onPressed: () {
                          setState(() => _imagePath = null);
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        AdaptiveActionButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text('បោះបង់'),
        ),
        AdaptiveActionButton.filled(onPressed: _save, child: Text('រក្សាទុក')),
      ],
    );
  }

  void _save() {
    final category = widget.categories.firstWhere(
      (item) => item.id == _categoryId,
      orElse: () => widget.categories.first,
    );
    final unit = widget.units.firstWhere(
      (item) => item.id == _unitId,
      orElse: () => widget.units.first,
    );
    Navigator.pop(
      context,
      widget.product.copyWith(
        khmerName: _khmer.text.trim(),
        englishName: _english.text.trim(),
        spec: _spec.text.trim(),
        categoryId: category.id,
        categoryKhmer: category.nameKhmer,
        categoryEnglish: category.nameEnglish,
        unitId: unit.id,
        unitKhmer: unit.abbreviationKhmer,
        unitEnglish: unit.abbreviationEnglish,
        formulaTypeId: _formulaTypeId,
        coverageValue: _parseDouble(_coverage.text),
        clearCoverageValue: _coverage.text.trim().isEmpty,
        multiplierValue: _parseDouble(_multiplier.text),
        clearMultiplierValue: _multiplier.text.trim().isEmpty,
        itemsPerBox: _parseInt(_itemsPerBox.text) ?? 1,
        active: _active,
        imagePath: _imagePath,
        clearImagePath: _imagePath == null,
      ),
    );
  }
}

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({required this.product, required this.prices});

  final MaterialItem product;
  final List<MaterialPrice> prices;

  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  late final TextEditingController _saleUnit;
  late final TextEditingController _saleBox;
  late final TextEditingController _costUnit;
  late final TextEditingController _costBox;

  @override
  void initState() {
    super.initState();
    _saleUnit = TextEditingController(
      text:
          '${_price(widget.prices, widget.product.id, PriceTypeIds.saleUnitPrice, fallback: PriceTypeIds.unitPrice) ?? 0}',
    );
    _saleBox = TextEditingController(
      text:
          '${_price(widget.prices, widget.product.id, PriceTypeIds.saleBoxPrice, fallback: PriceTypeIds.boxPrice) ?? 0}',
    );
    _costUnit = TextEditingController(
      text:
          '${_price(widget.prices, widget.product.id, PriceTypeIds.costUnitPrice) ?? 0}',
    );
    _costBox = TextEditingController(
      text:
          '${_price(widget.prices, widget.product.id, PriceTypeIds.costBoxPrice) ?? 0}',
    );
  }

  @override
  void dispose() {
    _saleUnit.dispose();
    _saleBox.dispose();
    _costUnit.dispose();
    _costBox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('តម្លៃ ${widget.product.khmerName}'),
      content: SizedBox(
        width: 470,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _dialogField(_saleUnit, 'តម្លៃលក់រាយ', number: true),
            _dialogField(_saleBox, 'តម្លៃលក់កេស', number: true),
            _dialogField(_costUnit, 'ថ្លៃដើមរាយ', number: true),
            _dialogField(_costBox, 'ថ្លៃដើមកេស', number: true),
          ],
        ),
      ),
      actions: [
        AdaptiveActionButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text('បោះបង់'),
        ),
        AdaptiveActionButton.filled(onPressed: _save, child: Text('រក្សាទុក')),
      ],
    );
  }

  void _save() {
    final now = DateTime.now();
    MaterialPrice build(String typeId, TextEditingController controller) {
      return MaterialPrice(
        id: '${widget.product.id}_$typeId',
        materialId: widget.product.id,
        priceTypeId: typeId,
        price: _parseDouble(controller.text) ?? 0,
        currencyCode: 'USD',
        effectiveFrom: DateTime(2020),
        effectiveTo: null,
        active: true,
        createdAt: now,
        updatedAt: now,
      );
    }

    Navigator.pop(context, [
      build(PriceTypeIds.saleUnitPrice, _saleUnit),
      build(PriceTypeIds.saleBoxPrice, _saleBox),
      build(PriceTypeIds.costUnitPrice, _costUnit),
      build(PriceTypeIds.costBoxPrice, _costBox),
    ]);
  }
}

class _PackagingDialog extends StatefulWidget {
  const _PackagingDialog({required this.product, this.rule});

  final MaterialItem product;
  final PackagingRule? rule;

  @override
  State<_PackagingDialog> createState() => _PackagingDialogState();
}

class _PackagingDialogState extends State<_PackagingDialog> {
  late final TextEditingController _items;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _items = TextEditingController(
      text: '${widget.rule?.itemsPerBox ?? widget.product.itemsPerBox ?? 1}',
    );
    _active = widget.rule?.active ?? true;
  }

  @override
  void dispose() {
    _items.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('ការវេចខ្ចប់ ${widget.product.khmerName}'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(_items, 'ចំនួនក្នុងកេស', number: true),
            SwitchListTile.adaptive(
              value: _active,
              title: Text('សកម្ម'),
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
        ),
      ),
      actions: [
        AdaptiveActionButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text('បោះបង់'),
        ),
        AdaptiveActionButton.filled(onPressed: _save, child: Text('រក្សាទុក')),
      ],
    );
  }

  void _save() {
    Navigator.pop(
      context,
      PackagingRule(
        id: widget.rule?.id ?? 'packaging_${widget.product.id}',
        materialId: widget.product.id,
        itemsPerBox: _parseInt(_items.text) ?? 1,
        boxUnitNameKhmer: 'កេស',
        boxUnitNameEnglish: 'Box',
        size: widget.rule?.size ?? '',
        length: widget.rule?.length ?? '',
        note: widget.rule?.note ?? '',
        active: _active,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class _ProductKindDialog extends StatefulWidget {
  const _ProductKindDialog({required this.template});

  final ProductTypeTemplate template;

  @override
  State<_ProductKindDialog> createState() => _ProductKindDialogState();
}

class _ProductKindDialogState extends State<_ProductKindDialog> {
  late final TextEditingController _khmer;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _khmer = TextEditingController(text: widget.template.nameKhmer);
    _active = widget.template.active;
  }

  @override
  void dispose() {
    _khmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('កែប្រភេទផលិតផល'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(_khmer, 'ឈ្មោះ'),
            SwitchListTile.adaptive(
              value: _active,
              title: Text('សកម្ម'),
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
        ),
      ),
      actions: [
        AdaptiveActionButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text('បោះបង់'),
        ),
        AdaptiveActionButton.filled(
          onPressed: () => Navigator.pop(
            context,
            widget.template.copyWith(nameKhmer: _khmer.text, active: _active),
          ),
          child: Text('រក្សាទុក'),
        ),
      ],
    );
  }
}

class _UnitDialog extends StatefulWidget {
  const _UnitDialog({required this.unit});

  final UnitOfMeasure unit;

  @override
  State<_UnitDialog> createState() => _UnitDialogState();
}

class _UnitDialogState extends State<_UnitDialog> {
  late final TextEditingController _name;
  late final TextEditingController _abbr;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.unit.nameKhmer);
    _abbr = TextEditingController(text: widget.unit.abbreviationKhmer);
  }

  @override
  void dispose() {
    _name.dispose();
    _abbr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('កែឯកតា'),
      content: SizedBox(
        width: 320,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _dialogField(_name, 'ឈ្មោះ'),
            _dialogField(_abbr, 'អក្សរកាត់'),
          ],
        ),
      ),
      actions: [
        AdaptiveActionButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text('បោះបង់'),
        ),
        AdaptiveActionButton.filled(
          onPressed: () => Navigator.pop(
            context,
            widget.unit.copyWith(
              nameKhmer: _name.text.trim(),
              abbreviationKhmer: _abbr.text.trim(),
            ),
          ),
          child: Text('រក្សាទុក'),
        ),
      ],
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.category});

  final MaterialCategory category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.category.nameKhmer);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('កែប្រភេទ'),
      content: SizedBox(width: 280, child: _dialogField(_name, 'ឈ្មោះ')),
      actions: [
        AdaptiveActionButton.text(
          onPressed: () => Navigator.pop(context),
          child: Text('បោះបង់'),
        ),
        AdaptiveActionButton.filled(
          onPressed: () => Navigator.pop(
            context,
            widget.category.copyWith(nameKhmer: _name.text.trim()),
          ),
          child: Text('រក្សាទុក'),
        ),
      ],
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.all(18), child: child);
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.fillHeight = false,
    this.scrollBody = false,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool fillHeight;
  final bool scrollBody;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final shouldScrollBody = scrollBody && hasBoundedHeight;
        return AppGlassSurface(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(AppEffects.panelRadius),
          tint: iPhoneColor(context, _card),
          borderColor: iPhoneColor(context, AppColors.glassHighlight),
          blur: AppEffects.glassBlur,
          shadows: AppShadows.glassCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: fillHeight || shouldScrollBody
                ? MainAxisSize.max
                : MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: iPhoneColor(context, _secondary)),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: iPhoneColor(context, _text),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width >= 600) ?trailing,
                ],
              ),
              if (MediaQuery.sizeOf(context).width < 600 && trailing != null)
                Padding(padding: EdgeInsets.only(top: 12), child: trailing!),
              SizedBox(height: 14),
              if (shouldScrollBody)
                _ScrollablePanelBody(child: child)
              else if (fillHeight)
                Expanded(child: child)
              else
                child,
            ],
          ),
        );
      },
    );
  }
}

class _ScrollablePanelBody extends StatefulWidget {
  const _ScrollablePanelBody({required this.child});

  final Widget child;

  @override
  State<_ScrollablePanelBody> createState() => _ScrollablePanelBodyState();
}

class _ScrollablePanelBodyState extends State<_ScrollablePanelBody> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _controller,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PanelList extends StatefulWidget {
  const _PanelList({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<_PanelList> createState() => _PanelListState();
}

class _PanelListState extends State<_PanelList> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _controller,
        padding: EdgeInsets.zero,
        itemCount: widget.itemCount,
        itemBuilder: widget.itemBuilder,
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile(this.label, this.value, {this.accent = _primary});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppGlassSurface(
      width: 176,
      padding: EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(SakuraTheme.radiusMd),
      tint: iPhoneColor(context, AppColors.surfaceGlassStrong),
      borderColor: iPhoneColor(context, _border),
      blur: 0,
      shadows: AppShadows.cardSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: iPhoneColor(context, _textSecondary),
              fontSize: 12,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListRow extends StatefulWidget {
  const _ListRow({
    this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onEdit,
  });

  final Widget? leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onEdit;

  @override
  State<_ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<_ListRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (isIPhoneLayout(context)) {
      return IPhoneCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (widget.leading != null) ...[
                  widget.leading!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: iPhoneColor(context, _textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.trailing != null || widget.onEdit != null)
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  if (widget.trailing != null) widget.trailing!,
                  if (widget.onEdit != null)
                    AdaptiveActionButton.textIcon(
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('កែ'),
                    ),
                ],
              ),
          ],
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: SakuraTheme.animFast,
        curve: SakuraTheme.animCurve,
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered
              ? SakuraTheme.cardHover
              : iPhoneColor(context, _surface),
          borderRadius: BorderRadius.circular(SakuraTheme.radiusMd),
          border: Border.all(
            color: _isHovered
                ? SakuraTheme.sakuraBorder.withValues(alpha: 0.5)
                : iPhoneColor(context, _border),
          ),
          boxShadow: _isHovered ? AppShadows.cardHover : AppShadows.cardSoft,
        ),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: iPhoneColor(context, _text),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: iPhoneColor(context, _textSecondary),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
            if (widget.onEdit != null)
              IconButton(
                tooltip: 'កែ',
                onPressed: widget.onEdit,
                icon: Icon(Icons.edit_outlined, size: 19),
              ),
          ],
        ),
      ),
    );
  }
}

String _productLabel(MaterialItem material) {
  final spec = material.spec.trim().isEmpty ? '' : ' ${material.spec}';
  return '${material.khmerName}$spec';
}

String _productResultLabel(ProductSaleResult result) {
  final spec = result.spec.trim().isEmpty ? '' : ' ${result.spec}';
  return '${result.materialNameKhmer}$spec';
}

String _summaryText(List<ProductSaleResult> results) {
  final totalPay = results.fold<double>(
    0,
    (sum, item) => sum + item.customerPayTotal,
  );
  final totalCost = results.fold<double>(
    0,
    (sum, item) => sum + item.ownerCostTotal,
  );
  final totalProfit = results.fold<double>(
    0,
    (sum, item) => sum + item.ownerProfit,
  );
  final buffer = StringBuffer()..writeln('សង្ខេបលក់');
  for (final item in results) {
    buffer.writeln(
      '${_productResultLabel(item)}: ${item.sellQuantity} ${item.unitKhmer} = ${item.packagingFullBoxes} កេស + ${item.packagingLooseItems} រាយ | ${MoneyFormatter.money(item.customerPayTotal)}',
    );
  }
  buffer
    ..writeln('អតិថិជនបង់សរុប: ${MoneyFormatter.money(totalPay)}')
    ..writeln('ថ្លៃដើមសរុប: ${MoneyFormatter.money(totalCost)}')
    ..writeln('ចំណេញសរុប: ${MoneyFormatter.money(totalProfit)}');
  return buffer.toString();
}

double? _parseDouble(String value) {
  final cleaned = value.replaceAll(',', '').trim();
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

int? _parseInt(String value) {
  final parsed = _parseDouble(value);
  return parsed?.round();
}

double? _price(
  List<MaterialPrice> prices,
  String materialId,
  String priceTypeId, {
  String? fallback,
}) {
  final now = DateTime.now();
  final salePriceCanFallbackFromZero =
      priceTypeId == PriceTypeIds.saleUnitPrice ||
      priceTypeId == PriceTypeIds.saleBoxPrice;
  for (final id in [priceTypeId, ?fallback]) {
    final matches =
        prices
            .where(
              (price) =>
                  price.materialId == materialId &&
                  price.priceTypeId == id &&
                  price.isEffectiveAt(now),
            )
            .toList()
          ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    if (matches.isNotEmpty) {
      final price = matches.first.price;
      if (id == priceTypeId &&
          price == 0 &&
          salePriceCanFallbackFromZero &&
          fallback != null) {
        continue;
      }
      return price;
    }
  }
  return null;
}

Widget _dialogField(
  TextEditingController controller,
  String label, {
  bool number = false,
}) {
  return SizedBox(
    width: 210,
    child: AdaptiveTextField(
      controller: controller,
      keyboardType: number
          ? TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(labelText: label),
    ),
  );
}

Widget _dropdown({
  required String label,
  required String value,
  required List<MapEntry<String, String>> items,
  required ValueChanged<String> onChanged,
}) {
  return SizedBox(
    width: 210,
    child: AdaptiveChoiceField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item.key,
              child: Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}

String _moneyOrDash(double? value) {
  return value == null ? '-' : MoneyFormatter.money(value);
}
