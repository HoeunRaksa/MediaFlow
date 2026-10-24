import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/constants/app_constants.dart';
import '../domain/invoice_document.dart';

class InvoicePdfAssets {
  const InvoicePdfAssets({
    required this.logo,
    required this.regularFont,
    required this.boldFont,
    required this.latinFont,
  });

  final Uint8List logo;
  final Uint8List regularFont;
  final Uint8List boldFont;
  final Uint8List latinFont;
}

class InvoicePdfService {
  const InvoicePdfService({required this.assets});

  final InvoicePdfAssets assets;

  static const shareImageWidthPoints = 1080.0;

  static final PdfColor _navy = PdfColor.fromHex('#0B2A57');
  static final PdfColor _gold = PdfColor.fromHex('#B88419');
  static final PdfColor _ink = PdfColor.fromHex('#1E293B');
  static final PdfColor _muted = PdfColor.fromHex('#64748B');
  static final PdfColor _line = PdfColor.fromHex('#DCE3EA');
  static final PdfColor _soft = PdfColor.fromHex('#F4F6F8');

  Future<Uint8List> build(
    InvoiceDocument invoice, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    final document = _documentFor(invoice);

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.fromLTRB(34, 32, 34, 30),
        header: (context) => _header(invoice),
        footer: (context) => _footer(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _customerBlock(invoice),
          pw.SizedBox(height: 22),
          _lineItems(invoice.lines),
          pw.SizedBox(height: 18),
          _totals(invoice),
          if (invoice.note.trim().isNotEmpty) ...[
            pw.SizedBox(height: 18),
            _note(invoice.note.trim()),
          ],
        ],
      ),
    );
    return document.save();
  }

  Future<Uint8List> buildShareImagePdf(InvoiceDocument invoice) async {
    final document = _documentFor(invoice);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          shareImageWidthPoints,
          _sharePageHeight(invoice),
        ),
        margin: const pw.EdgeInsets.fromLTRB(52, 46, 52, 38),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _header(invoice),
            pw.SizedBox(height: 26),
            _customerBlock(invoice),
            pw.SizedBox(height: 26),
            _lineItems(invoice.lines),
            pw.SizedBox(height: 22),
            _totals(invoice),
            if (invoice.note.trim().isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _note(invoice.note.trim()),
            ],
            pw.Spacer(),
            _shareFooter(),
          ],
        ),
      ),
    );
    return document.save();
  }

  pw.Document _documentFor(InvoiceDocument invoice) {
    final regular = pw.Font.ttf(assets.regularFont.buffer.asByteData());
    final bold = pw.Font.ttf(assets.boldFont.buffer.asByteData());
    final latin = pw.Font.ttf(assets.latinFont.buffer.asByteData());
    return pw.Document(
      title:
          '${invoice.documentTitleEnglish} ${invoice.invoiceNumber} - '
          '${AppConstants.appName}',
      author: AppConstants.appName,
      creator: AppConstants.appName,
      theme: pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        fontFallback: [latin],
      ),
    );
  }

  double _sharePageHeight(InvoiceDocument invoice) {
    final noteHeight = invoice.note.trim().isEmpty ? 0.0 : 68.0;
    final height = 390.0 + (invoice.lines.length * 82.0) + noteHeight;
    return height < 660.0 ? 660.0 : height;
  }

  pw.Widget _header(InvoiceDocument invoice) {
    final logo = pw.MemoryImage(assets.logo);
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 66,
              height: 66,
              padding: const pw.EdgeInsets.all(2),
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: _line, width: 0.8),
              ),
              child: pw.ClipOval(child: pw.Image(logo, fit: pw.BoxFit.cover)),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    AppConstants.appName,
                    style: pw.TextStyle(
                      color: _navy,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'សម្ភារៈសំណង់ និងដេគ័រទំនើប',
                    style: pw.TextStyle(color: _muted, fontSize: 9.5),
                  ),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  invoice.documentTitleKhmer,
                  style: pw.TextStyle(
                    color: _navy,
                    fontSize: 19,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  invoice.documentTitleEnglish,
                  style: pw.TextStyle(
                    color: _gold,
                    fontSize: 8.5,
                    letterSpacing: 1.6,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  invoice.invoiceNumber,
                  style: pw.TextStyle(color: _ink, fontSize: 8.5),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 11),
        pw.Container(height: 2.2, color: _navy),
        pw.Container(height: 0.9, color: _gold),
      ],
    );
  }

  pw.Widget _customerBlock(InvoiceDocument invoice) {
    final date =
        '${invoice.issuedAt.day.toString().padLeft(2, '0')}/'
        '${invoice.issuedAt.month.toString().padLeft(2, '0')}/'
        '${invoice.issuedAt.year}';
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _soft,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: _line, width: 0.6),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _labelValue('អតិថិជន', invoice.customerName),
                pw.SizedBox(height: 5),
                _labelValue('លេខទូរស័ព្ទ', invoice.customerPhone),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _labelValue('កាលបរិច្ឆេទ', date),
                pw.SizedBox(height: 5),
                _labelValue('អាសយដ្ឋាន', invoice.customerAddress),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _labelValue(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        style: pw.TextStyle(color: _ink, fontSize: 9),
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _navy),
          ),
          pw.TextSpan(text: value.trim().isEmpty ? '—' : value.trim()),
        ],
      ),
    );
  }

  pw.Widget _lineItems(List<InvoiceLine> lines) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
        bottom: pw.BorderSide(color: _line, width: 0.7),
      ),
      columnWidths: const {
        0: pw.FixedColumnWidth(28),
        1: pw.FlexColumnWidth(4.4),
        2: pw.FixedColumnWidth(48),
        3: pw.FixedColumnWidth(52),
        4: pw.FixedColumnWidth(66),
        5: pw.FixedColumnWidth(72),
      },
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: _navy),
          children: [
            _headerCell('ល.រ', align: pw.TextAlign.center),
            _headerCell('បរិយាយ'),
            _headerCell('ចំនួន', align: pw.TextAlign.center),
            _headerCell('ឯកតា', align: pw.TextAlign.center),
            _headerCell('តម្លៃលក់', align: pw.TextAlign.right),
            _headerCell('សរុប', align: pw.TextAlign.right),
          ],
        ),
        for (var index = 0; index < lines.length; index++)
          pw.TableRow(
            verticalAlignment: pw.TableCellVerticalAlignment.middle,
            decoration: pw.BoxDecoration(
              color: index.isOdd ? _soft : PdfColors.white,
            ),
            children: [
              _bodyCell('${index + 1}', align: pw.TextAlign.center),
              _descriptionCell(lines[index]),
              _bodyCell('${lines[index].quantity}', align: pw.TextAlign.center),
              _bodyCell(lines[index].unit, align: pw.TextAlign.center),
              _bodyCell(
                lines[index].salePriceLabel.trim().isEmpty
                    ? _money(lines[index].unitPrice)
                    : lines[index].salePriceLabel,
                align: pw.TextAlign.right,
              ),
              _bodyCell(
                _money(lines[index].lineTotal),
                align: pw.TextAlign.right,
                bold: true,
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _headerCell(
    String value, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _bodyCell(
    String value, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      child: pw.Text(
        value,
        textAlign: align,
        style: pw.TextStyle(
          color: _ink,
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _descriptionCell(InvoiceLine line) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            line.description,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (line.specification.trim().isNotEmpty)
            pw.Text(
              line.specification,
              style: pw.TextStyle(color: _muted, fontSize: 7.4),
            ),
          if (line.packageBreakdown case final breakdown?)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 3),
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E8EEF7'),
                borderRadius: pw.BorderRadius.circular(2.5),
              ),
              child: pw.Text(
                breakdown,
                style: pw.TextStyle(color: _navy, fontSize: 7.2),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _totals(InvoiceDocument invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 235,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _line, width: 0.7),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          children: [
            _totalRow('ចំនួនសម្ភារៈសរុប', '${invoice.totalQuantity}'),
            pw.Container(height: 0.6, color: _line),
            _totalRow('សរុបរង', _money(invoice.subtotal)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: pw.BoxDecoration(
                color: _navy,
                borderRadius: const pw.BorderRadius.only(
                  bottomLeft: pw.Radius.circular(4),
                  bottomRight: pw.Radius.circular(4),
                ),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'តម្លៃសរុប',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    _money(invoice.grandTotal),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(color: _muted, fontSize: 8)),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _note(String note) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: _gold, width: 2.2)),
        color: _soft,
      ),
      child: pw.Text(
        'ចំណាំ: $note',
        style: pw.TextStyle(color: _ink, fontSize: 8.5),
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(height: 0.6, color: _line),
        pw.SizedBox(height: 7),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'សូមអរគុណដែលបានជឿទុកចិត្តលើ ${AppConstants.appName}',
              style: pw.TextStyle(color: _muted, fontSize: 7.5),
            ),
            pw.Text(
              'ទំព័រ ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(color: _muted, fontSize: 7.5),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _shareFooter() {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(height: 0.7, color: _line),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'សូមអរគុណដែលបានជឿទុកចិត្តលើ ${AppConstants.appName}',
              style: pw.TextStyle(color: _muted, fontSize: 10),
            ),
            pw.Text(
              'រូបភាពចែករំលែក 4K',
              style: pw.TextStyle(color: _muted, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';
}
