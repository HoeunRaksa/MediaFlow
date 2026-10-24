import '../../../../core/ios/iphone_controls.dart';
import '../../../../core/ios/iphone_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/sakura_theme.dart';
import '../../domain/ceiling_khmer_replies.dart';

class CeilingReplyGenerator extends StatefulWidget {
  const CeilingReplyGenerator({super.key, required this.data});
  final CeilingReplyData data;

  @override
  State<CeilingReplyGenerator> createState() => _CeilingReplyGeneratorState();
}

class _CeilingReplyGeneratorState extends State<CeilingReplyGenerator>
    with AutomaticKeepAliveClientMixin {
  final _replies = CeilingKhmerReplies();
  bool _copying = false;
  String? _feedback;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(CeilingReplyGenerator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.signature != widget.data.signature) {
      _replies.next();
      _feedback = null;
    }
  }

  Future<void> _copy() async {
    if (_copying) return;
    final text = _replies.render(widget.data);
    setState(() {
      _copying = true;
      _feedback = null;
    });
    try {
      await Clipboard.setData(ClipboardData(text: text));
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
    super.build(context);
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.surface),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iPhoneColor(context, AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Random Khmer Ceiling Reply',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: 12),
          SelectableText(
            _replies.render(widget.data),
            key: ValueKey('ceiling-random-reply-preview'),
            style: TextStyle(
              fontFamily: 'NotoSansKhmer',
              fontSize: 15,
              height: 1.7,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AdaptiveActionButton.filledIcon(
                key: ValueKey('ceiling-reply-copy-next'),
                onPressed: _copying ? null : _copy,
                icon: Icon(Icons.copy_rounded, size: 16),
                label: Text('Copy & Generate Next'),
              ),
              AdaptiveActionButton.outlinedIcon(
                key: ValueKey('ceiling-reply-randomize'),
                onPressed: _copying
                    ? null
                    : () => setState(() {
                        _replies.next();
                        _feedback = null;
                      }),
                icon: Icon(Icons.shuffle_rounded, size: 16),
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
