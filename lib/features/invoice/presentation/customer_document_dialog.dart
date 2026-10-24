import '../../../core/ios/iphone_controls.dart';
import '../../../core/ios/iphone_design.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/sakura_theme.dart';
import '../domain/invoice_document.dart';
import '../services/customer_document_image_service.dart';
import '../services/customer_document_png_save_service.dart';
import '../services/invoice_pdf_asset_loader.dart';
import '../services/invoice_pdf_service.dart';

typedef CustomerDocumentCopyCallback =
    Future<void> Function(InvoiceDocument document);
typedef CustomerDocumentSaveCallback =
    Future<String?> Function(InvoiceDocument document);

enum _CustomerDocumentAction { idle, copying, saving }

/// A review-first customer document flow. The dialog remains open after either
/// export action so users can inspect, copy, and save the same 4K image.
class CustomerDocumentDialog extends StatefulWidget {
  const CustomerDocumentDialog({
    super.key,
    required this.initialDocument,
    this.onCopy,
    this.onSave,
  });

  final InvoiceDocument initialDocument;
  final CustomerDocumentCopyCallback? onCopy;
  final CustomerDocumentSaveCallback? onSave;

  @override
  State<CustomerDocumentDialog> createState() => _CustomerDocumentDialogState();
}

class _CustomerDocumentDialogState extends State<CustomerDocumentDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;
  late CustomerDocumentType _documentType;
  _CustomerDocumentAction _action = _CustomerDocumentAction.idle;

  bool get _isBusy => _action != _CustomerDocumentAction.idle;

  @override
  void initState() {
    super.initState();
    _documentType = widget.initialDocument.documentType;
    _nameController = TextEditingController(
      text: widget.initialDocument.customerName,
    );
    _phoneController = TextEditingController(
      text: widget.initialDocument.customerPhone,
    );
    _addressController = TextEditingController(
      text: widget.initialDocument.customerAddress,
    );
    _noteController = TextEditingController(text: widget.initialDocument.note);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = _documentFromFields();
    return Dialog(
      insetPadding: EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1120, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogHeader(document: document, enabled: !_isBusy),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 20, 24, 18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final form = _detailsForm(document);
                    final preview = _CustomerDocumentPreview(
                      document: document,
                    );
                    if (constraints.maxWidth >= 860) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: form),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(
                              height: 510,
                              child: VerticalDivider(
                                width: 1,
                                color: iPhoneColor(
                                  context,
                                  AppColors.borderSoft,
                                ),
                              ),
                            ),
                          ),
                          Expanded(flex: 6, child: preview),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        form,
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(
                            color: iPhoneColor(context, AppColors.borderSoft),
                          ),
                        ),
                        preview,
                      ],
                    );
                  },
                ),
              ),
            ),
            _actionBar(),
          ],
        ),
      ),
    );
  }

  Widget _detailsForm(InvoiceDocument document) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ប្រភេទឯកសារ',
          style: TextStyle(
            color: iPhoneColor(context, AppColors.textPrimary),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10),
        _documentTypeSelector(),
        SizedBox(height: 16),
        _DocumentSummary(document: document),
        SizedBox(height: 20),
        Text(
          'ព័ត៌មានអតិថិជន',
          style: TextStyle(
            color: iPhoneColor(context, AppColors.textPrimary),
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12),
        _field(
          key: ValueKey('customer-document-name'),
          controller: _nameController,
          label: 'ឈ្មោះអតិថិជន',
          icon: Icons.person_outline_rounded,
        ),
        SizedBox(height: 12),
        _field(
          key: ValueKey('customer-document-phone'),
          controller: _phoneController,
          label: 'លេខទូរស័ព្ទ',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        SizedBox(height: 12),
        _field(
          key: ValueKey('customer-document-address'),
          controller: _addressController,
          label: 'អាសយដ្ឋាន',
          icon: Icons.location_on_outlined,
        ),
        SizedBox(height: 12),
        _field(
          key: ValueKey('customer-document-note'),
          controller: _noteController,
          label: 'ចំណាំ (ជាជម្រើស)',
          icon: Icons.notes_rounded,
          maxLines: 2,
        ),
        SizedBox(height: 12),
        Text(
          'ព័ត៌មាននេះមិនត្រូវបានរក្សាទុកទេ។ ឯកសារបង្ហាញតែសម្ភារៈ '
          'បរិមាណ តម្លៃលក់ និងចំនួនទឹកប្រាក់។',
          style: TextStyle(
            color: iPhoneColor(context, AppColors.textMuted),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _actionBar() {
    final document = _documentFromFields();
    return Container(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 18),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: iPhoneColor(context, AppColors.borderSoft)),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          AdaptiveActionButton.text(
            onPressed: _isBusy ? null : () => Navigator.maybePop(context),
            child: Text('បោះបង់'),
          ),
          AdaptiveActionButton.outlinedIcon(
            key: ValueKey('customer-document-copy-4k'),
            onPressed: _isBusy ? null : _copy,
            icon: _action == _CustomerDocumentAction.copying
                ? _ActionProgress()
                : Icon(Icons.copy_all_rounded, size: 19),
            label: Text('ចម្លង PNG 4K'),
          ),
          AdaptiveActionButton.filledIcon(
            key: ValueKey('customer-document-save-4k'),
            onPressed: _isBusy ? null : () => _save(document),
            icon: _action == _CustomerDocumentAction.saving
                ? _ActionProgress()
                : Icon(Icons.save_alt_rounded, size: 19),
            label: Text('រក្សាទុក PNG 4K'),
          ),
        ],
      ),
    );
  }

  Widget _documentTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final type in CustomerDocumentType.values)
          ChoiceChip(
            label: Text(type.khmerTitle),
            avatar: Icon(
              type == CustomerDocumentType.invoice
                  ? Icons.receipt_long_rounded
                  : Icons.request_quote_rounded,
              size: 18,
            ),
            selected: _documentType == type,
            onSelected: _isBusy
                ? null
                : (_) => setState(() => _documentType = type),
          ),
      ],
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return AdaptiveTextField(
      key: key,
      controller: controller,
      enabled: !_isBusy,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  InvoiceDocument _documentFromFields() {
    return widget.initialDocument.copyWithCustomer(
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerAddress: _addressController.text.trim(),
      note: _noteController.text.trim(),
      documentType: _documentType,
    );
  }

  Future<void> _copy() async {
    final document = _documentFromFields();
    setState(() => _action = _CustomerDocumentAction.copying);
    try {
      final callback = widget.onCopy ?? _copyToClipboard;
      await callback(document);
      if (!mounted) return;
      _showSnackBar('បានចម្លង PNG 4K ទៅ Clipboard រួចហើយ។');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('មិនអាចចម្លង PNG 4K បាន៖ $error');
    } finally {
      if (mounted) setState(() => _action = _CustomerDocumentAction.idle);
    }
  }

  Future<void> _save(InvoiceDocument document) async {
    setState(() => _action = _CustomerDocumentAction.saving);
    try {
      final callback = widget.onSave ?? _saveToSelectedLocation;
      final savedPath = await callback(document);
      if (!mounted || savedPath == null) return;
      _showSnackBar('បានរក្សាទុក PNG 4K រួចហើយ។');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('មិនអាចរក្សាទុក PNG 4K បាន៖ $error');
    } finally {
      if (mounted) setState(() => _action = _CustomerDocumentAction.idle);
    }
  }

  void _showSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<CustomerDocumentImageService> _imageService() async {
    final assets = await loadInvoicePdfAssets();
    final pdfService = InvoicePdfService(assets: assets);
    return CustomerDocumentImageService(
      buildPdf: pdfService.buildShareImagePdf,
    );
  }

  Future<void> _copyToClipboard(InvoiceDocument document) async {
    final imageService = await _imageService();
    await imageService.copy4kImage(document);
  }

  Future<String?> _saveToSelectedLocation(InvoiceDocument document) async {
    final imageService = await _imageService();
    return CustomerDocumentPngSaveService(
      imageService: imageService,
    ).save4kPng(document);
  }
}

class _ActionProgress extends StatelessWidget {
  const _ActionProgress();

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: 17,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );
}

class _DocumentSummary extends StatelessWidget {
  const _DocumentSummary({required this.document});

  final InvoiceDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.surfaceSoft),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iPhoneColor(context, AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            color: iPhoneColor(context, AppColors.primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '${document.lines.length} មុខ • ${document.totalQuantity} ឯកតា',
              style: TextStyle(
                color: iPhoneColor(context, AppColors.textPrimary),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '\$${document.grandTotal.toStringAsFixed(2)}',
            style: TextStyle(
              color: iPhoneColor(context, AppColors.primary),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerDocumentPreview extends StatelessWidget {
  const _CustomerDocumentPreview({required this.document});

  final InvoiceDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('customer-document-preview'),
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.surfaceSoft),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iPhoneColor(context, AppColors.borderSoft)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                color: iPhoneColor(context, AppColors.primary),
              ),
              SizedBox(width: 8),
              Text(
                'ពិនិត្យមើលលម្អិត',
                style: TextStyle(
                  color: iPhoneColor(context, AppColors.textPrimary),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBrandLogo(size: 38),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.primary),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      document.documentTitleEnglish,
                      style: TextStyle(
                        color: iPhoneColor(context, AppColors.textMuted),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                document.invoiceNumber,
                style: TextStyle(
                  color: iPhoneColor(context, AppColors.textSecondary),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          _PreviewCustomer(document: document),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: iPhoneColor(context, AppColors.borderSoft)),
          ),
          for (final line in document.lines) _PreviewLine(line: line),
          SizedBox(height: 8),
          Divider(color: iPhoneColor(context, AppColors.borderSoft)),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'សរុប',
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.textPrimary),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '\$${document.grandTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: iPhoneColor(context, AppColors.primary),
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: iPhoneColor(
                context,
                AppColors.primary,
              ).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'PNG 4K • ទទឹង 3840 px',
              style: TextStyle(
                color: iPhoneColor(context, AppColors.primary),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCustomer extends StatelessWidget {
  const _PreviewCustomer({required this.document});

  final InvoiceDocument document;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (document.customerPhone.isNotEmpty) document.customerPhone,
      if (document.customerAddress.isNotEmpty) document.customerAddress,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'អតិថិជន',
          style: TextStyle(
            color: iPhoneColor(context, AppColors.textMuted),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 3),
        Text(
          document.customerName.isEmpty ? 'អតិថិជនទូទៅ' : document.customerName,
          style: TextStyle(
            color: iPhoneColor(context, AppColors.textPrimary),
            fontWeight: FontWeight.w800,
          ),
        ),
        if (details.isNotEmpty)
          Text(
            details.join(' • '),
            style: TextStyle(
              color: iPhoneColor(context, AppColors.textSecondary),
              fontSize: 12,
            ),
          ),
        if (document.note.isNotEmpty) ...[
          SizedBox(height: 5),
          Text(
            document.note,
            style: TextStyle(
              color: iPhoneColor(context, AppColors.textSecondary),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.line});

  final InvoiceLine line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.description,
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.textPrimary),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (line.specification.isNotEmpty)
                  Text(
                    line.specification,
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.textMuted),
                      fontSize: 11,
                    ),
                  ),
                SizedBox(height: 3),
                Text(
                  '${line.quantity} ${line.unit}',
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.textSecondary),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (line.packageBreakdown case final breakdown?)
                  Text(
                    breakdown,
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.textMuted),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 12),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 148),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (line.salePriceLabel.isNotEmpty)
                  Text(
                    line.salePriceLabel,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: iPhoneColor(context, AppColors.textMuted),
                      fontSize: 10,
                    ),
                  ),
                Text(
                  '\$${line.lineTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.textPrimary),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({required this.document, required this.enabled});

  final InvoiceDocument document;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 18, 16, 16),
      decoration: BoxDecoration(
        color: iPhoneColor(context, AppColors.surfaceGlassStrong),
        border: Border(
          bottom: BorderSide(color: iPhoneColor(context, AppColors.borderSoft)),
        ),
      ),
      child: Row(
        children: [
          AppBrandLogo(size: 52),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.primary),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${document.documentTitleKhmer} • PNG 4K',
                  style: TextStyle(
                    color: iPhoneColor(context, AppColors.textSecondary),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            document.invoiceNumber,
            style: TextStyle(
              color: iPhoneColor(context, AppColors.textSecondary),
              fontSize: 12,
            ),
          ),
          SizedBox(width: 4),
          IconButton(
            tooltip: 'បិទ',
            onPressed: enabled ? () => Navigator.maybePop(context) : null,
            icon: Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
