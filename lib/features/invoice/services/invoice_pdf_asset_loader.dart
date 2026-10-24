import 'package:flutter/services.dart';

import '../../../core/constants/app_constants.dart';
import 'invoice_pdf_service.dart';

Future<InvoicePdfAssets> loadInvoicePdfAssets({AssetBundle? bundle}) async {
  final assetBundle = bundle ?? rootBundle;
  final values = await Future.wait([
    assetBundle.load(AppConstants.brandLogoAsset),
    assetBundle.load('assets/fonts/NotoSansKhmer-Regular.ttf'),
    assetBundle.load('assets/fonts/NotoSansKhmer-Bold.ttf'),
    assetBundle.load('assets/fonts/Roboto-Regular.ttf'),
  ]);
  return InvoicePdfAssets(
    logo: values[0].buffer.asUint8List(),
    regularFont: values[1].buffer.asUint8List(),
    boldFont: values[2].buffer.asUint8List(),
    latinFont: values[3].buffer.asUint8List(),
  );
}
