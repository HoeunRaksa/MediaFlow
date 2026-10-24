import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ios/iphone_controls.dart';
import '../../../../core/ios/iphone_design.dart';
import '../../../../core/theme/sakura_theme.dart';
import '../../domain/pvc_khmer_replies.dart';

/// Reuses the existing PVC Khmer reply engine and stateful copy/randomize
/// workflow. `compactMobile` changes presentation only; Windows keeps the
/// original spacing and typography.
class PvcReplyGenerator extends StatefulWidget {
  const PvcReplyGenerator({super.key, this.compactMobile = false});

  final bool compactMobile;

  @override
  State<PvcReplyGenerator> createState() => _PvcReplyGeneratorState();
}

class _PvcReplyGeneratorState extends State<PvcReplyGenerator> {
  final _price = TextEditingController();
  final _replies = PvcKhmerReplies()..next();
  bool _copying = false;
  bool _validate = false;
  String? _feedback;

  String get _reply => _replies.reply(_price.text);

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  bool _valid() {
    if (_reply.isNotEmpty) return true;
    setState(() => _validate = true);
    return false;
  }

  Future<void> _copy() async {
    if (_copying || !_valid()) return;
    final current = _reply;
    setState(() {
      _copying = true;
      _feedback = null;
    });
    try {
      await Clipboard.setData(ClipboardData(text: current));
      if (!mounted) return;
      setState(() {
        _replies.next();
        _feedback = 'Copied! Next reply is ready.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _feedback = 'Could not copy. Please try again.');
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compactMobile;
    final gap = compact ? 8.0 : 16.0;
    return AppGlassSurface(
      padding: EdgeInsets.all(compact ? 12 : 18),
      borderRadius: BorderRadius.circular(
        compact ? 16 : AppEffects.panelRadius,
      ),
      tint: iPhoneColor(context, AppColors.surfaceGlass),
      borderColor: iPhoneColor(context, AppColors.glassHighlight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Random Khmer Reply Generator',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: compact ? 14 : null,
              fontWeight: compact ? FontWeight.w900 : null,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            'Enter a price, then copy a reply. Each copy prepares the next one.',
            style: compact
                ? const TextStyle(fontSize: 11.5, height: 1.3)
                : null,
          ),
          SizedBox(height: gap),
          AdaptiveTextField(
            key: const ValueKey('pvc-reply-price'),
            controller: _price,
            enabled: !_copying,
            decoration: InputDecoration(
              labelText: 'Price per sheet',
              helperText: compact
                  ? null
                  : 'Enter a price or placeholder, such as 20.5 or 20.X.',
              errorText: _validate && _reply.isEmpty
                  ? 'Enter a price to generate a reply.'
                  : null,
              border: const OutlineInputBorder(),
              isDense: compact,
            ),
            onChanged: (_) => setState(() {
              _validate = true;
              _feedback = null;
            }),
          ),
          SizedBox(height: gap),
          Container(
            padding: EdgeInsets.all(compact ? 10 : 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(compact ? 11 : 12),
            ),
            child: SelectableText(
              _reply.isEmpty
                  ? 'Enter a price to preview your Khmer reply.'
                  : _reply,
              key: const ValueKey('pvc-reply-preview'),
              style: TextStyle(
                fontFamily: 'NotoSansKhmer',
                fontSize: compact ? 14 : 18,
                height: compact ? 1.5 : 1.7,
              ),
            ),
          ),
          SizedBox(height: gap),
          Wrap(
            spacing: compact ? 8 : 12,
            runSpacing: compact ? 8 : 10,
            children: [
              AdaptiveActionButton.filledIcon(
                onPressed: _copying ? null : _copy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy & Generate Next'),
              ),
              AdaptiveActionButton.outlinedIcon(
                onPressed: _copying
                    ? null
                    : () {
                        if (!_valid()) return;
                        setState(() {
                          _replies.next();
                          _feedback = null;
                        });
                      },
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text('Randomize'),
              ),
            ],
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 8),
            Semantics(liveRegion: true, child: Text(_feedback!)),
          ],
        ],
      ),
    );
  }
}
