import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_state.dart';
import '../../../core/ios/iphone_controls.dart';
import '../../ceiling_calculator/domain/ceiling_khmer_replies.dart';
import '../../ceiling_calculator/presentation/screens/ceiling_calculator_screen.dart';
import '../../pvc_quantity_calculator/domain/pvc_khmer_replies.dart';

/// Compact one-page workflow for answering a Facebook comment quickly.
class FacebookCommentReplyPage extends StatefulWidget {
  const FacebookCommentReplyPage({super.key});
  @override
  State<FacebookCommentReplyPage> createState() => _FacebookCommentReplyPageState();
}

class _FacebookCommentReplyPageState extends State<FacebookCommentReplyPage> {
  final _length = TextEditingController(text: '6');
  final _width = TextEditingController(text: '4.2');
  final _measurement = TextEditingController(text: '6x4.2');
  final _count = TextEditingController(text: '1');
  final _price = TextEditingController();
  final _ceilingReplies = CeilingKhmerReplies();
  final _pvcReplies = PvcKhmerReplies()..next();
  final _extraRooms = <_ReplyRoom>[];
  final _ceilingMaterialIds = <String>{
    'ceiling_6mm', 'long_t_3m', 'short_t_06m', 'v_iron_295m',
  };
  int _ceilingInputMode = 0;
  int _category = 0;
  bool _copying = false;
  String? _feedback;
  List<String> _lines = const [];
  double _area = 0;
  Timer? _debounce;

  @override
  void initState() { super.initState(); for (final c in [_length, _width, _measurement, _count, _price]) { c.addListener(_schedule); } _schedule(); }
  @override
  void dispose() { _debounce?.cancel(); for (final c in [_length, _width, _measurement, _count, _price]) { c.dispose(); } for (final room in _extraRooms) { room.dispose(); } super.dispose(); }
  void _schedule() { _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 80), _recalculate); }

  Future<void> _recalculate() async {
    final dimension = _parseDimensions(_measurement.text);
    final l = double.tryParse(_length.text) ?? 0, w = double.tryParse(_width.text) ?? 0;
    final n = int.tryParse(_count.text) ?? 0;
    final ceilingArea = _ceilingInputMode == 0
        ? (dimension?.$1 ?? 0) * (dimension?.$2 ?? 0) * n
        : (_parseArea(_measurement.text) ?? 0) * n;
    _area = _category == 0 ? ceilingArea + _extraRooms.fold(0, (sum, room) => sum + room.area) : l * w * n;
    if (_area <= 0 || n <= 0) { if (mounted) setState(() => _lines = const []); return; }
    final state = context.read<AppState>();
    if (_category == 0) {
      final ids = _ceilingMaterialIds;
      final rows = <String>[];
      for (final id in ids) { final m = state.materials.where((x) => x.id == id).firstOrNull; if (m == null) continue; final r = CeilingCalculatorEngine.calculateSingleProduct(state: state, material: m, areaM2: _area, templateId: 'ceiling_full_set'); if (r != null) rows.add('${m.khmerName}: ${r.sellQuantity} ${m.unitKhmer}'); }
      _lines = rows;
    } else {
      // PVC Facebook replies intentionally reuse the existing price-only
      // generator. The full PVC construction calculator remains separate.
      _lines = const [];
    }
    if (mounted) setState(() {});
  }

  String get _reply { final measurement = _category == 0 ? 'ទំហំ ${_measurement.text} ចំនួន ${_count.text} បន្ទប់ (សរុប ${_area.toStringAsFixed(2)}m²)' : 'ទំហំ ${_length.text}m × ${_width.text}m ចំនួន ${_count.text} បន្ទប់ (សរុប ${_area.toStringAsFixed(2)}m²)'; return _category == 0 ? _ceilingReplies.render(CeilingReplyData(priceRange: 'តាមការគណនា', details: [measurement, ..._lines])) : _pvcReplies.reply(_price.text); }
  Future<void> _copy() async { final canCopy = _category == 0 ? _lines.isNotEmpty : _reply.isNotEmpty; if (_copying || !canCopy) return; setState(() { _copying = true; _feedback = null; }); try { await Clipboard.setData(ClipboardData(text: _reply)); if (mounted) setState(() { if (_category == 0) { _ceilingReplies.next(); } else { _pvcReplies.next(); } _feedback = 'បានចម្លងរួចរាល់ — ចម្លើយថ្មីរួចរាល់'; }); } catch (_) { if (mounted) setState(() => _feedback = 'មិនអាចចម្លងបានទេ'); } finally { if (mounted) setState(() => _copying = false); } }
  void _randomize() { setState(() { if (_category == 0) { _ceilingReplies.next(); } else { _pvcReplies.next(); } _feedback = null; }); }
  void _addRoom() { setState(() { final room = _ReplyRoom()..listen(_schedule); _extraRooms.add(room); }); }
  void _removeRoom(int index) { setState(() { _extraRooms.removeAt(index).dispose(); }); _schedule(); }
  (double, double)? _parseDimensions(String value) {
    final match = RegExp(r'^\s*([0-9]+(?:[.,][0-9]+)?)\s*[x×*]\s*([0-9]+(?:[.,][0-9]+)?)\s*(?:m)?\s*$', caseSensitive: false).firstMatch(value);
    if (match == null) return null;
    return (double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0, double.tryParse(match.group(2)!.replaceAll(',', '.')) ?? 0);
  }
  double? _parseArea(String value) => double.tryParse(value.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''));

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(12, 8, 12, 20), children: [
    Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: const Color(0xFFE8EEF8), borderRadius: BorderRadius.circular(12)), child: CupertinoSlidingSegmentedControl<int>(groupValue: _category, onValueChanged: (v) { if (v != null) setState(() { _category = v; _feedback = null; }); _schedule(); }, children: const {0: Padding(padding: EdgeInsets.symmetric(vertical: 9), child: Text('▰  ពិដាន 60×60')), 1: Padding(padding: EdgeInsets.symmetric(vertical: 9), child: Text('▱  ក្ដារ PVC'))})),
    const SizedBox(height: 12),
    if (_category == 0) ...[
      CupertinoSlidingSegmentedControl<int>(groupValue: _ceilingInputMode, onValueChanged: (value) { if (value != null) setState(() => _ceilingInputMode = value); _schedule(); }, children: const {0: Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Text('បណ្ដោយ × ទទឹង')), 1: Padding(padding: EdgeInsets.symmetric(vertical: 7), child: Text('ផ្ទៃផ្ទាល់'))}),
      const SizedBox(height: 6),
      Row(children: [Expanded(child: AdaptiveTextField(controller: _measurement, keyboardType: TextInputType.text, decoration: InputDecoration(labelText: _ceilingInputMode == 0 ? 'ទំហំ (ឧ. 6x4.2)' : 'ផ្ទៃ (ឧ. 25.5m²)'))), const SizedBox(width: 6), SizedBox(width: 82, child: AdaptiveTextField(controller: _count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ចំនួន')))]),
    ] else Row(children: [Expanded(child: AdaptiveTextField(controller: _length, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'កម្ពស់ (m)'))), const SizedBox(width: 6), Expanded(child: AdaptiveTextField(controller: _width, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ទទឹង (m)'))), const SizedBox(width: 6), SizedBox(width: 82, child: AdaptiveTextField(controller: _count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ចំនួន')))]),
    if (_category == 0) ...[
      for (var i = 0; i < _extraRooms.length; i++) Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Row(children: [Expanded(child: AdaptiveTextField(controller: _extraRooms[i].length, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'បន្ទប់ ${i + 2} • បណ្ដោយ'))), const SizedBox(width: 6), Expanded(child: AdaptiveTextField(controller: _extraRooms[i].width, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ទទឹង'))), const SizedBox(width: 6), SizedBox(width: 82, child: AdaptiveTextField(controller: _extraRooms[i].count, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ចំនួន'))), IconButton(onPressed: () => _removeRoom(i), icon: const Icon(Icons.close_rounded, size: 18))]),
      ),
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: _addRoom, icon: const Icon(Icons.add_rounded, size: 18), label: const Text('បន្ថែមបន្ទប់'))),
    ],
    if (_category == 1) ...[const SizedBox(height: 6), AdaptiveTextField(controller: _price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'តម្លៃ / សន្លឹក'))],
    const SizedBox(height: 8), Row(children: [Expanded(child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)), child: Text('ផ្ទៃសរុប\n${_area.toStringAsFixed(2)} m²', style: const TextStyle(color: Color(0xFF163F7A), fontWeight: FontWeight.w800)))), const SizedBox(width: 8), Expanded(child: AdaptiveActionButton.filledIcon(key: const ValueKey('facebook-copy-reply'), onPressed: (_category == 0 ? _lines.isEmpty : _reply.isEmpty) || _copying ? null : _copy, icon: const Icon(Icons.copy_rounded, size: 18), label: const Text('ចម្លងចម្លើយ')))]),
    if (_feedback != null) Padding(padding: const EdgeInsets.only(top: 6), child: Semantics(liveRegion: true, child: Text(_feedback!))),
    const SizedBox(height: 10), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(14)), child: SelectableText(_reply.isEmpty ? 'បញ្ចូលទំហំ ដើម្បីបង្កើតចម្លើយ។' : _reply, style: const TextStyle(fontFamily: 'NotoSansKhmer', height: 1.5))),
    const SizedBox(height: 8), Row(mainAxisAlignment: MainAxisAlignment.end, children: [AdaptiveActionButton.outlinedIcon(onPressed: _randomize, icon: const Icon(Icons.shuffle_rounded, size: 18), label: const Text('Randomize'))]),
    if (_category == 0) ...[
      const SizedBox(height: 4),
      ExpansionTile(title: const Text('☷  សម្ភារៈ និងជម្រើសបន្ថែម', style: TextStyle(fontWeight: FontWeight.w800)), initiallyExpanded: false, children: [
        for (final id in const ['ceiling_6mm', 'long_t_3m', 'short_t_06m', 'v_iron_295m'])
          CheckboxListTile(dense: true, value: _ceilingMaterialIds.contains(id), title: Text(id), onChanged: (value) { setState(() { if (value == true) { _ceilingMaterialIds.add(id); } else { _ceilingMaterialIds.remove(id); } }); _schedule(); }),
        for (final line in _lines) ListTile(dense: true, title: Text(line)),
      ]),
    ],
  ]);
}

class _ReplyRoom {
  _ReplyRoom()
      : length = TextEditingController(text: '6'),
        width = TextEditingController(text: '4.2'),
        count = TextEditingController(text: '1');
  final TextEditingController length;
  final TextEditingController width;
  final TextEditingController count;
  double get area => (double.tryParse(length.text) ?? 0) * (double.tryParse(width.text) ?? 0) * (int.tryParse(count.text) ?? 0);
  void dispose() { length.dispose(); width.dispose(); count.dispose(); }
  void listen(VoidCallback callback) { length.addListener(callback); width.addListener(callback); count.addListener(callback); }
}
