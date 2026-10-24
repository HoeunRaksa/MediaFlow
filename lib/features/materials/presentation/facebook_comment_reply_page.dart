import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../core/ios/iphone_controls.dart';
import '../../../core/ios/iphone_design.dart';
import '../../../core/theme/sakura_theme.dart';
import '../../ceiling_calculator/domain/ceiling_khmer_replies.dart';
import '../../ceiling_calculator/presentation/screens/ceiling_calculator_screen.dart';
import '../../pvc_quantity_calculator/data/pvc_physical_catalog.dart';
import '../../pvc_quantity_calculator/domain/pvc_quantity_calculation_service.dart';
import '../../pvc_quantity_calculator/domain/pvc_quantity_models.dart';

/// Compact one-page workflow for answering a Facebook comment quickly.
class FacebookCommentReplyPage extends StatefulWidget {
  const FacebookCommentReplyPage({super.key});
  @override
  State<FacebookCommentReplyPage> createState() => _FacebookCommentReplyPageState();
}

class _FacebookCommentReplyPageState extends State<FacebookCommentReplyPage> {
  final _length = TextEditingController(text: '6');
  final _width = TextEditingController(text: '4.2');
  final _count = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _ceilingReplies = CeilingKhmerReplies();
  int _category = 0;
  bool _details = false;
  bool _copying = false;
  String? _feedback;
  List<String> _lines = const [];
  double _area = 0;
  Timer? _debounce;

  @override
  void initState() { super.initState(); for (final c in [_length, _width, _count, _price]) { c.addListener(_schedule); } _schedule(); }
  @override
  void dispose() { _debounce?.cancel(); for (final c in [_length, _width, _count, _price]) { c.dispose(); } super.dispose(); }
  void _schedule() { _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 80), _recalculate); }

  Future<void> _recalculate() async {
    final l = double.tryParse(_length.text) ?? 0, w = double.tryParse(_width.text) ?? 0;
    final n = int.tryParse(_count.text) ?? 0; _area = l * w * n;
    if (_area <= 0 || n <= 0) { if (mounted) setState(() => _lines = const []); return; }
    final state = context.read<AppState>();
    if (_category == 0) {
      final ids = ['ceiling_6mm', 'long_t_3m', 'short_t_06m', 'v_iron_295m'];
      final rows = <String>[];
      for (final id in ids) { final m = state.materials.where((x) => x.id == id).firstOrNull; if (m == null) continue; final r = CeilingCalculatorEngine.calculateSingleProduct(state: state, material: m, areaM2: _area, templateId: 'ceiling_full_set'); if (r != null) rows.add('${m.khmerName}: ${r.sellQuantity} ${m.unitKhmer}'); }
      _lines = rows;
    } else {
      final products = const PvcPhysicalCatalog().build(state.materials);
      final zones = products.map((p) => PvcQuantityZone(id: p.sortOrder, name: p.nameKhmer, product: p, inputMode: p.isLinearAccessory ? PvcZoneInputMode.perimeterStrip : PvcZoneInputMode.dimensions, lengthM: l, widthM: w, stripWidthM: p.widthMm == null ? null : p.widthMm! / 1000)).toList();
      final result = await PvcQuantityCalculationService().calculate(groups: [PvcMeasurementGroup(id: 1, name: 'Facebook', inputMode: PvcGroupInputMode.dimensions, roomCount: n, lengthM: l, widthM: w, zones: zones)]);
      _lines = [for (final row in result.products) '${row.product.nameKhmer}: ${row.quantity} ${row.unitLabel}'];
    }
    if (mounted) setState(() {});
  }

  String get _reply { final measurement = 'ទំហំ ${_length.text}m × ${_width.text}m ចំនួន ${_count.text} បន្ទប់ (សរុប ${_area.toStringAsFixed(2)}m²)'; return _category == 0 ? _ceilingReplies.render(CeilingReplyData(priceRange: 'តាមការគណនា', details: [measurement, ..._lines])) : ['សួស្តីបង 🙏', 'ក្ដារ PVC៖ $measurement', ..._lines].join('\n'); }
  Future<void> _copy() async { if (_copying || _lines.isEmpty) return; setState(() { _copying = true; _feedback = null; }); try { await Clipboard.setData(ClipboardData(text: _reply)); if (mounted) setState(() => _feedback = 'បានចម្លងរួចរាល់'); } catch (_) { if (mounted) setState(() => _feedback = 'មិនអាចចម្លងបានទេ'); } finally { if (mounted) setState(() => _copying = false); } }

  @override
  Widget build(BuildContext context) => IPhonePage(title: 'Facebook Reply', child: ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 28), children: [
    CupertinoSlidingSegmentedControl<int>(groupValue: _category, onValueChanged: (v) { if (v != null) setState(() { _category = v; _feedback = null; }); _schedule(); }, children: const {0: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('ពិដាន 60×60')), 1: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('ក្ដារ PVC'))}),
    const SizedBox(height: 12),
    Wrap(spacing: 8, runSpacing: 8, children: [SizedBox(width: 120, child: AdaptiveTextField(controller: _length, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'បណ្ដោយ'))), SizedBox(width: 120, child: AdaptiveTextField(controller: _width, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ទទឹង'))), SizedBox(width: 110, child: AdaptiveTextField(controller: _count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ចំនួន')))]),
    const SizedBox(height: 8), Text('ផ្ទៃសរុប៖ ${_area.toStringAsFixed(2)} m²', style: const TextStyle(fontWeight: FontWeight.w700)),
    const SizedBox(height: 8), AdaptiveActionButton.filledIcon(key: const ValueKey('facebook-copy-reply'), onPressed: _lines.isEmpty || _copying ? null : _copy, icon: const Icon(Icons.copy_rounded), label: const Text('Copy Reply')),
    if (_feedback != null) Padding(padding: const EdgeInsets.only(top: 6), child: Semantics(liveRegion: true, child: Text(_feedback!))),
    const SizedBox(height: 10), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.all(Radius.circular(14))), child: SelectableText(_reply.isEmpty ? 'បញ្ចូលទំហំ ដើម្បីបង្កើតចម្លើយ។' : _reply, style: const TextStyle(fontFamily: 'NotoSansKhmer', height: 1.55))),
    const SizedBox(height: 8), ExpansionTile(title: const Text('លម្អិតសម្ភារៈ'), initiallyExpanded: _details, onExpansionChanged: (v) => setState(() => _details = v), children: [for (final line in _lines) ListTile(dense: true, title: Text(line))]),
  ]));
}
