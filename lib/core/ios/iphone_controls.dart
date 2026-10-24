import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'iphone_design.dart';

class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    this.controller,
    this.decoration,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.onTapOutside,
    this.onEditingComplete,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
    this.enabled,
    this.readOnly = false,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
  });
  final TextEditingController? controller;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged, onSubmitted;
  final void Function(PointerDownEvent)? onTapOutside;
  final VoidCallback? onEditingComplete;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines, minLines;
  final bool? enabled;
  final bool readOnly, autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  @override
  Widget build(BuildContext context) {
    if (!isIPhoneLayout(context)) {
      return TextField(
        controller: controller,
        decoration: decoration,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTapOutside: onTapOutside,
        onEditingComplete: onEditingComplete,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        minLines: minLines,
        enabled: enabled ?? true,
        readOnly: readOnly,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        autofocus: autofocus,
        textInputAction: textInputAction,
      );
    }
    final field = Semantics(
      label: decoration?.labelText ?? decoration?.hintText,
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTapOutside: onTapOutside,
        onEditingComplete: onEditingComplete,
        textAlign: textAlign,
        maxLines: maxLines,
        minLines: minLines,
        enabled: enabled ?? true,
        readOnly: readOnly,
        inputFormatters: inputFormatters,
        autofocus: autofocus,
        textInputAction: textInputAction ?? TextInputAction.done,
        placeholder: decoration?.labelText ?? decoration?.hintText,
        prefix:
            decoration?.prefixIcon ??
            (decoration?.prefixText == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(decoration!.prefixText!),
                  )),
        suffix:
            decoration?.suffixIcon ??
            (decoration?.suffixText == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      decoration!.suffixText!,
                      style: TextStyle(
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                        fontFamilyFallback: ['Roboto'],
                      ),
                    ),
                  )),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        style: (style ?? const TextStyle()).copyWith(
          fontSize: 16,
          fontFamily: 'NotoSansKhmer',
          fontFamilyFallback: ['Roboto'],
          color: CupertinoColors.label.resolveFrom(context),
        ),
        decoration: BoxDecoration(
          color: CupertinoColors.tertiarySystemFill.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedHeight && constraints.maxHeight < 76) {
          return field;
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (decoration?.labelText != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                  decoration!.labelText!,
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
            field,
            if (decoration?.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    decoration!.errorText!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ),
              )
            else if (decoration?.helperText != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  decoration!.helperText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

enum _ActionStyle { filled, outlined, text }

class AdaptiveChoiceField<T> extends StatelessWidget {
  const AdaptiveChoiceField({
    super.key,
    this.initialValue,
    required this.items,
    required this.onChanged,
    this.decoration = const InputDecoration(),
    this.isExpanded = false,
  });
  final T? initialValue;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;
  final InputDecoration decoration;
  final bool isExpanded;
  @override
  Widget build(BuildContext context) {
    if (!isIPhoneLayout(context)) {
      return DropdownButtonFormField<T>(
        initialValue: initialValue,
        items: items,
        onChanged: onChanged,
        decoration: decoration,
        isExpanded: isExpanded,
      );
    }
    final selected = items
        ?.where((item) => item.value == initialValue)
        .firstOrNull;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (decoration.labelText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text(
              decoration.labelText!,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        CupertinoButton.tinted(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          onPressed: onChanged == null
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  showCupertinoModalPopup<void>(
                    context: context,
                    builder: (sheetContext) => CupertinoActionSheet(
                      title: decoration.labelText == null
                          ? null
                          : Text(decoration.labelText!),
                      actions: [
                        for (final item
                            in (items ?? <DropdownMenuItem<T>>[]).where(
                              (item) => item.enabled,
                            ))
                          CupertinoActionSheetAction(
                            isDefaultAction: item.value == initialValue,
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              onChanged!(item.value);
                            },
                            child: item.child,
                          ),
                      ],
                      cancelButton: CupertinoActionSheetAction(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('បោះបង់'),
                      ),
                    ),
                  );
                },
          child: Row(
            children: [
              Expanded(child: selected?.child ?? const Text('ជ្រើសរើស')),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.chevron_down, size: 15),
            ],
          ),
        ),
      ],
    );
  }
}

class AdaptiveActionButton extends StatelessWidget {
  const AdaptiveActionButton.filled({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.onLongPress,
  }) : _kind = _ActionStyle.filled,
       icon = null;
  const AdaptiveActionButton.filledIcon({
    super.key,
    required this.onPressed,
    required Widget label,
    required this.icon,
    this.style,
    this.onLongPress,
  }) : _kind = _ActionStyle.filled,
       child = label;
  const AdaptiveActionButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.onLongPress,
  }) : _kind = _ActionStyle.outlined,
       icon = null;
  const AdaptiveActionButton.outlinedIcon({
    super.key,
    required this.onPressed,
    required Widget label,
    required this.icon,
    this.style,
    this.onLongPress,
  }) : _kind = _ActionStyle.outlined,
       child = label;
  const AdaptiveActionButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
    this.onLongPress,
  }) : _kind = _ActionStyle.text,
       icon = null;
  const AdaptiveActionButton.textIcon({
    super.key,
    required this.onPressed,
    required Widget label,
    required this.icon,
    this.style,
    this.onLongPress,
  }) : _kind = _ActionStyle.text,
       child = label;
  final VoidCallback? onPressed, onLongPress;
  final Widget child;
  final Widget? icon;
  final ButtonStyle? style;
  final _ActionStyle _kind;
  @override
  Widget build(BuildContext context) {
    if (!isIPhoneLayout(context)) {
      return switch (_kind) {
        _ActionStyle.filled =>
          icon == null
              ? FilledButton(
                  onPressed: onPressed,
                  onLongPress: onLongPress,
                  style: style,
                  child: child,
                )
              : FilledButton.icon(
                  onPressed: onPressed,
                  onLongPress: onLongPress,
                  style: style,
                  icon: icon,
                  label: child,
                ),
        _ActionStyle.outlined =>
          icon == null
              ? OutlinedButton(
                  onPressed: onPressed,
                  onLongPress: onLongPress,
                  style: style,
                  child: child,
                )
              : OutlinedButton.icon(
                  onPressed: onPressed,
                  onLongPress: onLongPress,
                  style: style,
                  icon: icon,
                  label: child,
                ),
        _ActionStyle.text =>
          icon == null
              ? TextButton(
                  onPressed: onPressed,
                  onLongPress: onLongPress,
                  style: style,
                  child: child,
                )
              : TextButton.icon(
                  onPressed: onPressed,
                  onLongPress: onLongPress,
                  style: style,
                  icon: icon,
                  label: child,
                ),
      };
    }
    final content = icon == null
        ? child
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon!,
              const SizedBox(width: 8),
              Flexible(child: child),
            ],
          );
    return CupertinoButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: BorderRadius.circular(16),
      color: _kind == _ActionStyle.filled
          ? CupertinoTheme.of(context).primaryColor
          : _kind == _ActionStyle.outlined
          ? CupertinoColors.tertiarySystemFill.resolveFrom(context)
          : null,
      foregroundColor: _kind == _ActionStyle.filled
          ? CupertinoColors.white
          : CupertinoTheme.of(context).primaryColor,
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontFamily: 'NotoSansKhmer',
          fontFamilyFallback: ['Roboto'],
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        child: content,
      ),
    );
  }
}

class IPhoneSearchField extends StatelessWidget {
  const IPhoneSearchField({
    super.key,
    required this.controller,
    required this.placeholder,
  });
  final TextEditingController controller;
  final String placeholder;
  @override
  Widget build(BuildContext context) => CupertinoSearchTextField(
    controller: controller,
    placeholder: placeholder,
    style: TextStyle(
      fontFamily: 'NotoSansKhmer',
      fontFamilyFallback: ['Roboto'],
      fontSize: 16,
      color: CupertinoColors.label.resolveFrom(context),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    borderRadius: BorderRadius.circular(14),
    onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
  );
}

class IPhoneEmptyState extends StatelessWidget {
  const IPhoneEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = CupertinoIcons.tray,
  });
  final String title;
  final String? message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 42,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!, textAlign: TextAlign.center),
          ],
        ],
      ),
    ),
  );
}

Future<bool> confirmIPhoneAction(
  BuildContext context, {
  required String title,
  required String action,
}) async =>
    await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(title),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
      ),
    ) ??
    false;

/// Shared content card; glass is reserved for floating navigation surfaces.
class IPhoneCard extends StatelessWidget {
  const IPhoneCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
        context,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class IPhoneGallery extends StatelessWidget {
  const IPhoneGallery({super.key, required this.image, required this.title});
  final ImageProvider image;
  final String title;
  @override
  Widget build(BuildContext context) => IPhonePage(
    title: title,
    child: Center(
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Image(image: image, fit: BoxFit.contain, gaplessPlayback: true),
      ),
    ),
  );
}
