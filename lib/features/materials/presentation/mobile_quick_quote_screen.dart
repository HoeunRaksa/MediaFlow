import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../ceiling_calculator/presentation/screens/ceiling_calculator_screen.dart';
import '../../pvc_quantity_calculator/presentation/screens/pvc_quantity_calculator_screen.dart';

enum QuickQuoteProduct { ceiling, pvc }

/// Phone-only shell for the quick quotation workflow.
///
/// The two calculator children keep their own existing state and calculation
/// engines. This widget only changes how the user selects the product mode.
class MobileQuickQuoteScreen extends StatefulWidget {
  const MobileQuickQuoteScreen({
    super.key,
    this.initialProduct = QuickQuoteProduct.ceiling,
  });

  final QuickQuoteProduct initialProduct;

  @override
  State<MobileQuickQuoteScreen> createState() => _MobileQuickQuoteScreenState();
}

class _MobileQuickQuoteScreenState extends State<MobileQuickQuoteScreen> {
  late QuickQuoteProduct _product = widget.initialProduct;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SingleChildScrollView(
        key: const ValueKey('mobile-quick-quote-scroll'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CupertinoSlidingSegmentedControl<QuickQuoteProduct>(
              groupValue: _product,
              onValueChanged: (value) {
                if (value == null) return;
                FocusManager.instance.primaryFocus?.unfocus();
                setState(() => _product = value);
              },
              children: const {
                QuickQuoteProduct.ceiling: Padding(
                  padding: EdgeInsets.symmetric(vertical: 9),
                  child: Text('ពិដាន 60×60'),
                ),
                QuickQuoteProduct.pvc: Padding(
                  padding: EdgeInsets.symmetric(vertical: 9),
                  child: Text('ក្ដារ PVC'),
                ),
              },
            ),
            const SizedBox(height: 8),
            IndexedStack(
              index: _product.index,
              children: const [
                CeilingCalculatorScreen(compactMobile: true),
                PvcQuantityCalculatorScreen(compactMobile: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
