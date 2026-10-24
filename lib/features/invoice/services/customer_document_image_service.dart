import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../domain/invoice_document.dart';
import 'invoice_pdf_service.dart';

typedef CustomerDocumentPdfBuilder =
    Future<Uint8List> Function(InvoiceDocument document);
typedef CustomerDocumentImageRasterizer =
    Future<Uint8List> Function(Uint8List pdfBytes);
typedef CustomerDocumentImageClipboardWriter =
    Future<void> Function(Uint8List pngBytes);
typedef CustomerDocumentRasterAvailability = Future<bool> Function();

class CustomerDocumentImageService {
  CustomerDocumentImageService({
    required CustomerDocumentPdfBuilder buildPdf,
    CustomerDocumentImageRasterizer? rasterize,
    CustomerDocumentImageClipboardWriter? writeToClipboard,
    CustomerDocumentRasterAvailability? canRasterize,
  }) : _buildPdf = buildPdf,
       _rasterize = rasterize ?? rasterize4k,
       _writeToClipboard = writeToClipboard ?? writePngToClipboard,
       _canRasterize = canRasterize ?? supportsRasterization;

  static const targetWidthPixels = 3840;
  static const targetDpi = 256.0;

  final CustomerDocumentPdfBuilder _buildPdf;
  final CustomerDocumentImageRasterizer _rasterize;
  final CustomerDocumentImageClipboardWriter _writeToClipboard;
  final CustomerDocumentRasterAvailability _canRasterize;

  Future<void> copy4kImage(InvoiceDocument document) async {
    await ensure4kRenderingAvailable();
    final image = await render4kImage(document);
    await _writeToClipboard(image);
  }

  /// Confirms that this platform can create the same 3840px PNG used by both
  /// the clipboard and the user-selected Save As destination.
  Future<void> ensure4kRenderingAvailable() async {
    if (!await _canRasterize()) {
      throw StateError('ឧបករណ៍នេះមិនគាំទ្រការបង្កើតរូបភាព 4K ទេ។');
    }
  }

  Future<Uint8List> render4kImage(InvoiceDocument document) async {
    final pdfBytes = await _buildPdf(document);
    return _rasterize(pdfBytes);
  }

  static Future<bool> supportsRasterization() async {
    return (await Printing.info()).canRaster;
  }

  static Future<Uint8List> rasterize4k(Uint8List pdfBytes) async {
    final pages = await Printing.raster(
      pdfBytes,
      pages: const [0],
      dpi: targetDpi,
    ).toList();
    if (pages.length != 1) {
      throw StateError('មិនអាចបង្កើតរូបភាពឯកសារអតិថិជនបានទេ។');
    }
    return pages.single.toPng();
  }

  static Future<void> writePngToClipboard(Uint8List pngBytes) {
    return FlutterClipboard.copyImage(pngBytes);
  }

  static double get renderedWidthPixels =>
      InvoicePdfService.shareImageWidthPoints / PdfPageFormat.inch * targetDpi;
}
