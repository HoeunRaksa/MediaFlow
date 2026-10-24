import '../ios/iphone_controls.dart';
import '../ios/iphone_design.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../theme/sakura_theme.dart';

/// Compact, elegant Product Image Thumbnail Widget matching Sakura pastel theme.
class ProductImageThumbnail extends StatelessWidget {
  const ProductImageThumbnail({
    super.key,
    required this.imagePath,
    this.width = 38,
    this.height = 38,
    this.borderRadius = 8,
    this.productName,
    this.enablePreview = true,
  });

  final String? imagePath;
  final double width;
  final double height;
  final double borderRadius;
  final String? productName;
  final bool enablePreview;

  bool get _hasValidImage {
    if (imagePath == null || imagePath!.trim().isEmpty) return false;
    if (kIsWeb) return imagePath!.startsWith('data:image/');
    try {
      return File(imagePath!).existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _hasValidImage;

    final child = RepaintBoundary(
      child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderSoft, width: 1),
        boxShadow: AppShadows.cardSoft,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: hasImage
            ? Image(
                image: ResizeImage(
                  kIsWeb
                      ? NetworkImage(imagePath!)
                      : FileImage(File(imagePath!)) as ImageProvider,
                  width: (width * MediaQuery.devicePixelRatioOf(context)).round(),
                  height: (height * MediaQuery.devicePixelRatioOf(context)).round(),
                ),
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _placeholderIcon(),
              )
            : _placeholderIcon(),
      ),
      ),
    );

    if (enablePreview && hasImage) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onLongPress: isIPhoneLayout(context)
              ? () => showCupertinoModalPopup<void>(
                  context: context,
                  builder: (sheetContext) => CupertinoActionSheet(
                    title: Text(productName ?? 'រូបភាពផលិតផល'),
                    actions: [
                      CupertinoActionSheetAction(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _openPhoneGallery(context);
                        },
                        child: const Text('បើករូបភាព'),
                      ),
                    ],
                    cancelButton: CupertinoActionSheetAction(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('បោះបង់'),
                    ),
                  ),
                )
              : null,
          onTap: () {
            if (isIPhoneLayout(context)) {
              _openPhoneGallery(context);
              return;
            }
            showDialog<void>(
              context: context,
              builder: (_) => ProductImagePreviewDialog(
                imagePath: imagePath!,
                productName: productName,
              ),
            );
          },
          child: child,
        ),
      );
    }

    return child;
  }

  void _openPhoneGallery(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => IPhoneGallery(
          image: kIsWeb
              ? NetworkImage(imagePath!)
              : FileImage(File(imagePath!)) as ImageProvider,
          title: productName ?? 'រូបភាពផលិតផល',
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Icon(
      Icons.image_outlined,
      size: (width * 0.50).clamp(14.0, 24.0),
      color: AppColors.primaryDeep.withValues(alpha: 0.45),
    );
  }
}

/// Image Preview Dialog showing larger image and product details.
class ProductImagePreviewDialog extends StatelessWidget {
  const ProductImagePreviewDialog({
    super.key,
    required this.imagePath,
    this.productName,
  });

  final String imagePath;
  final String? productName;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          const Icon(
            Icons.photo_outlined,
            color: AppColors.primaryDeep,
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              productName ?? 'រូបភាពផលិតផល',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        height: 350,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            color: AppColors.background,
            alignment: Alignment.center,
            child: Image(
              image: kIsWeb
                  ? NetworkImage(imagePath)
                  : FileImage(File(imagePath)) as ImageProvider,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text('មិនអាចបង្ហាញរូបភាពបានទេ'),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('បិទ', style: TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}
