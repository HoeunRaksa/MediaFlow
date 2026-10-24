import '../../../../core/ios/iphone_controls.dart';
import '../../../../core/ios/iphone_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/sakura_theme.dart';
import '../../domain/pvc_khmer_replies.dart';

class PvcReplyGenerator extends StatefulWidget {
  const PvcReplyGenerator({super.key});

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
    return AppGlassSurface(
      padding: EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(AppEffects.panelRadius),
      tint: iPhoneColor(context, AppColors.surfaceGlass),
      borderColor: iPhoneColor(context, AppColors.glassHighlight),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Random Khmer Reply Generator',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 6),
          Text(
            'Enter a price, then copy a reply. Each copy prepares the next one.',
          ),
          SizedBox(height: 16),
          AdaptiveTextField(
            key: ValueKey('pvc-reply-price'),
            controller: _price,
            enabled: !_copying,
            decoration: InputDecoration(
              labelText: 'Price per sheet',
              helperText: 'Enter a price or placeholder, such as 20.5 or 20.X.',
              errorText: _validate && _reply.isEmpty
                  ? 'Enter a price to generate a reply.'
                  : null,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {
              _validate = true;
              _feedback = null;
            }),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              _reply.isEmpty
                  ? 'Enter a price to preview your Khmer reply.'
                  : _reply,
              key: ValueKey('pvc-reply-preview'),
              style: TextStyle(
                fontFamily: 'NotoSansKhmer',
                fontSize: 18,
                height: 1.7,
              ),
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              AdaptiveActionButton.filledIcon(
                onPressed: _copying ? null : _copy,
                icon: Icon(Icons.copy_rounded),
                label: Text('Copy & Generate Next'),
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
                icon: Icon(Icons.shuffle_rounded),
                label: Text('Randomize'),
              ),
            ],
          ),
          if (_feedback != null) ...[
            SizedBox(height: 8),
            Semantics(liveRegion: true, child: Text(_feedback!)),
          ],
        ],
      ),
    );
  }
}
