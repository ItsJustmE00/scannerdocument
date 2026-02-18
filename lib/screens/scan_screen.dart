import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scannerdocument/models/document_category.dart';
import 'package:scannerdocument/models/document_domain.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:scannerdocument/models/extracted_data.dart';
import 'package:scannerdocument/models/scanned_document.dart';
import 'package:scannerdocument/services/document_repository.dart';
import 'package:scannerdocument/services/document_scanner_service.dart';
import 'package:scannerdocument/services/ocr_service.dart';
import 'package:scannerdocument/utils/data_extractor.dart';
import 'package:uuid/uuid.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.repository});

  final DocumentRepository repository;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final DocumentScannerService _scannerService = DocumentScannerService();
  final OcrService _ocrService = OcrService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _ocrTextController = TextEditingController();
  final TextEditingController _invoiceNumberController =
      TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final Uuid _uuid = const Uuid();

  bool _isBusy = false;
  String _status = 'Pret';
  List<String> _capturedImagePaths = const [];
  String _ocrText = '';
  ExtractedData _extractedData = const ExtractedData();
  DocumentCategory _selectedCategory = DocumentCategory.unknown;
  DocumentDomain _selectedDomain = DocumentDomain.unknown;

  @override
  void dispose() {
    _ocrService.dispose();
    _titleController.dispose();
    _ocrTextController.dispose();
    _invoiceNumberController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _scanAndProcess({bool appendPages = false}) async {
    setState(() {
      _isBusy = true;
      _status = appendPages
          ? 'Ajout de nouvelles pages...'
          : 'Ouverture du scanner...';
    });

    try {
      final scannedPaths = await _scannerService.scanDocuments(maxPages: 12);

      if (scannedPaths.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _status = 'Aucun document capture.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan annule ou aucun document detecte.'),
          ),
        );
        return;
      }

      final mergedPaths = appendPages
          ? [..._capturedImagePaths, ...scannedPaths]
          : scannedPaths;

      setState(() {
        _capturedImagePaths = mergedPaths;
        _status = 'Analyse du texte en cours...';
      });

      final ocrText = await _ocrService.extractTextFromImagesWithProgress(
        mergedPaths,
        onProgress: (current, total) {
          if (!mounted) {
            return;
          }
          setState(() {
            _status = 'Analyse du texte page $current/$total...';
          });
        },
      );
      final extractedData = DataExtractor.extract(ocrText);

      if (!mounted) {
        return;
      }

      final autoTitle = extractedData.invoiceNumber == null
          ? '${extractedData.documentCategory.label} ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'
          : 'Facture ${extractedData.invoiceNumber}';

      setState(() {
        _ocrText = ocrText;
        _extractedData = extractedData;
        _selectedCategory = extractedData.documentCategory;
        _selectedDomain = extractedData.documentDomain;
        _status = ocrText.trim().isEmpty
            ? 'Analyse terminee, aucun texte detecte.'
            : 'Analyse terminee, type: ${extractedData.documentCategory.label}, domaine: ${extractedData.documentDomain.label}.';

        if (_titleController.text.trim().isEmpty) {
          _titleController.text = autoTitle;
        }
      });
      _syncEditorsFromCurrentData();

      if (ocrText.replaceAll(RegExp(r'\s+'), '').length < 20) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Texte peu lisible: essaie plus de lumiere ou importe depuis la galerie.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Erreur pendant le scan du texte.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur scan texte: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _syncEditorsFromCurrentData() {
    _ocrTextController.text = _ocrText;
    _invoiceNumberController.text = _extractedData.invoiceNumber ?? '';
    _dateController.text = _extractedData.date ?? '';
    _amountController.text = _extractedData.amount ?? '';
    _currencyController.text = _extractedData.currency ?? '';
    _emailController.text = _extractedData.email ?? '';
    _phoneController.text = _extractedData.phone ?? '';
    _selectedCategory = _extractedData.documentCategory;
    _selectedDomain = _extractedData.documentDomain;
  }

  String? _normalizeOptional(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  ExtractedData _buildExtractedDataFromEditors() {
    return ExtractedData(
      invoiceNumber: _normalizeOptional(_invoiceNumberController.text),
      date: _normalizeOptional(_dateController.text),
      amount: _normalizeOptional(_amountController.text),
      currency: _normalizeOptional(_currencyController.text),
      email: _normalizeOptional(_emailController.text),
      phone: _normalizeOptional(_phoneController.text),
      documentCategory: _selectedCategory,
      documentDomain: _selectedDomain,
    );
  }

  void _applyEditorChanges() {
    setState(() {
      _ocrText = _ocrTextController.text;
      _extractedData = _buildExtractedDataFromEditors();
    });
  }

  Future<void> _reanalyzeEditedText() async {
    final editedText = _ocrTextController.text.trim();
    final extracted = DataExtractor.extract(editedText);

    setState(() {
      _ocrText = editedText;
      _extractedData = extracted;
      _selectedCategory = extracted.documentCategory;
      _selectedDomain = extracted.documentDomain;
      _status = 'Texte reanalyse avec succes.';
    });
    _syncEditorsFromCurrentData();

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Donnees detectees mises a jour.')),
    );
  }

  Future<void> _removeCapturedPage(int index) async {
    if (index < 0 || index >= _capturedImagePaths.length) {
      return;
    }

    final updatedPaths = [..._capturedImagePaths]..removeAt(index);
    setState(() {
      _capturedImagePaths = updatedPaths;
    });

    if (updatedPaths.isEmpty) {
      setState(() {
        _status = 'Toutes les pages ont ete retirees.';
        _ocrText = '';
        _extractedData = const ExtractedData();
        _selectedCategory = DocumentCategory.unknown;
        _selectedDomain = DocumentDomain.unknown;
      });
      _syncEditorsFromCurrentData();
      return;
    }

    setState(() {
      _isBusy = true;
      _status = 'Mise a jour des donnees apres suppression...';
    });

    try {
      final refreshedText = await _ocrService.extractTextFromImagesWithProgress(
        updatedPaths,
        onProgress: (current, total) {
          if (!mounted) {
            return;
          }
          setState(() {
            _status = 'Reanalyse page $current/$total...';
          });
        },
      );
      final refreshedData = DataExtractor.extract(refreshedText);

      if (!mounted) {
        return;
      }

      setState(() {
        _ocrText = refreshedText;
        _extractedData = refreshedData;
        _selectedCategory = refreshedData.documentCategory;
        _selectedDomain = refreshedData.documentDomain;
        _status = 'Suppression effectuee et donnees mises a jour.';
      });
      _syncEditorsFromCurrentData();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Erreur pendant la reanalyse.';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur reanalyse: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _copyOcrText() async {
    final text = _ocrTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Texte vide.')));
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Texte copie.')));
  }

  Future<void> _saveDocument() async {
    _applyEditorChanges();
    final normalizedText = _ocrTextController.text.trim();
    final editedData = _buildExtractedDataFromEditors();

    if (_capturedImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun document a enregistrer.')),
      );
      return;
    }

    if (normalizedText.isEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aucun texte detecte'),
          content: const Text(
            'Aucun texte n\'a ete detecte. Voulez-vous sauvegarder les images quand meme ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }
    }

    setState(() {
      _isBusy = true;
      _status = 'Sauvegarde locale...';
    });

    try {
      final persistedImagePaths = await _copyImagesToAppStorage(
        _capturedImagePaths,
      );
      final fallbackTitle =
          'Document ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}';
      final customTitle = _titleController.text.trim();
      final title = customTitle.isEmpty ? fallbackTitle : customTitle;

      final document = ScannedDocument(
        id: _uuid.v4(),
        title: title,
        imagePaths: persistedImagePaths,
        ocrText: normalizedText,
        extractedData: editedData,
        createdAt: DateTime.now(),
      );

      await widget.repository.insertDocument(document);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _status = 'Erreur sauvegarde locale.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur sauvegarde locale: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<List<String>> _copyImagesToAppStorage(List<String> sourcePaths) async {
    final appDir = await getApplicationDocumentsDirectory();
    final scansDir = Directory(p.join(appDir.path, 'scans'));
    await scansDir.create(recursive: true);

    final copied = <String>[];

    for (final sourcePath in sourcePaths) {
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        continue;
      }

      final extension = p.extension(sourcePath).isEmpty
          ? '.jpg'
          : p.extension(sourcePath);
      final destination = p.join(scansDir.path, '${_uuid.v4()}$extension');
      final file = await sourceFile.copy(destination);
      copied.add(file.path);
    }

    return copied;
  }

  IconData _statusIcon() {
    final statusLower = _status.toLowerCase();
    if (statusLower.contains('erreur')) {
      return Icons.error_outline_rounded;
    }
    if (_isBusy || statusLower.contains('analyse')) {
      return Icons.sync_rounded;
    }
    if (statusLower.contains('terminee') ||
        statusLower.contains('sauvegarde')) {
      return Icons.check_circle_outline_rounded;
    }
    return Icons.info_outline_rounded;
  }

  Color _statusColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final statusLower = _status.toLowerCase();
    if (statusLower.contains('erreur')) {
      return scheme.error;
    }
    if (_isBusy || statusLower.contains('analyse')) {
      return scheme.primary;
    }
    if (statusLower.contains('terminee') ||
        statusLower.contains('sauvegarde')) {
      return scheme.tertiary;
    }
    return scheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'images/scanner_app_icon_transparent.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text('Nouveau scan'),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors:
                              Theme.of(context).brightness == Brightness.dark
                              ? [
                                  const Color(0xFF1D2F37),
                                  const Color(0xFF1D3E45),
                                ]
                              : [
                                  const Color(0xFFE7F4F2),
                                  const Color(0xFFF3F7FF),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Image.asset(
                                'images/scanner_full_logo_transparent.png',
                                width: 102,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Capture nette, analyse locale et sauvegarde immediate.',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isBusy
                                      ? null
                                      : () =>
                                            _scanAndProcess(appendPages: false),
                                  icon: const Icon(Icons.camera_alt_rounded),
                                  label: Text(
                                    _capturedImagePaths.isEmpty
                                        ? 'Scanner document'
                                        : 'Nouveau scan',
                                  ),
                                ),
                              ),
                              if (_capturedImagePaths.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isBusy
                                        ? null
                                        : () => _scanAndProcess(
                                            appendPages: true,
                                          ),
                                    icon: const Icon(Icons.add_photo_alternate),
                                    label: const Text('Ajouter pages'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(_statusIcon(), color: statusColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _status,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if (_isBusy) ...[
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              minHeight: 5,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre du document',
                      prefixIcon: Icon(Icons.title_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_capturedImagePaths.isNotEmpty)
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.photo_library_outlined),
                                const SizedBox(width: 8),
                                Text(
                                  'Pages scannees (${_capturedImagePaths.length})',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 86,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _capturedImagePaths.length,
                                separatorBuilder: (_, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final file = File(_capturedImagePaths[index]);
                                  final exists = file.existsSync();
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: SizedBox(
                                      width: 86,
                                      height: 86,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          exists
                                              ? Image.file(
                                                  file,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest,
                                                  alignment: Alignment.center,
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                                ),
                                          Positioned(
                                            right: 6,
                                            bottom: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.65,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: InkWell(
                                              onTap: _isBusy
                                                  ? null
                                                  : () => _removeCapturedPage(
                                                      index,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.6),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close_rounded,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_capturedImagePaths.isNotEmpty)
                    const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.dataset_outlined),
                              const SizedBox(width: 8),
                              Text(
                                'Donnees detectees (modifiable)',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<DocumentCategory>(
                            key: ValueKey(_selectedCategory),
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Type document',
                              prefixIcon: Icon(Icons.category_rounded),
                            ),
                            items: DocumentCategory.values
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category.label),
                                  ),
                                )
                                .toList(),
                            onChanged: _isBusy
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                    _applyEditorChanges();
                                  },
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<DocumentDomain>(
                            key: ValueKey(_selectedDomain),
                            initialValue: _selectedDomain,
                            decoration: const InputDecoration(
                              labelText: 'Domaine',
                              prefixIcon: Icon(Icons.layers_rounded),
                            ),
                            items: DocumentDomain.values
                                .map(
                                  (domain) => DropdownMenuItem(
                                    value: domain,
                                    child: Text(domain.label),
                                  ),
                                )
                                .toList(),
                            onChanged: _isBusy
                                ? null
                                : (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() {
                                      _selectedDomain = value;
                                    });
                                    _applyEditorChanges();
                                  },
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _invoiceNumberController,
                            enabled: !_isBusy,
                            onChanged: (_) => _applyEditorChanges(),
                            decoration: const InputDecoration(
                              labelText: 'Numero facture / reference',
                              prefixIcon: Icon(Icons.tag_rounded),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _dateController,
                            enabled: !_isBusy,
                            onChanged: (_) => _applyEditorChanges(),
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              prefixIcon: Icon(Icons.event_rounded),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  enabled: !_isBusy,
                                  onChanged: (_) => _applyEditorChanges(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Montant',
                                    prefixIcon: Icon(Icons.payments_rounded),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _currencyController,
                                  enabled: !_isBusy,
                                  onChanged: (_) => _applyEditorChanges(),
                                  decoration: const InputDecoration(
                                    labelText: 'Devise',
                                    prefixIcon: Icon(
                                      Icons.currency_exchange_rounded,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            enabled: !_isBusy,
                            onChanged: (_) => _applyEditorChanges(),
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_rounded),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            enabled: !_isBusy,
                            onChanged: (_) => _applyEditorChanges(),
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Telephone',
                              prefixIcon: Icon(Icons.phone_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final textLength =
                                  '${_ocrTextController.text.trim().length} caracteres';
                              final titleStyle = Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700);
                              final countWidget = Text(
                                textLength,
                                style: Theme.of(context).textTheme.labelMedium,
                              );
                              final reanalyzeButton = TextButton.icon(
                                onPressed: _isBusy
                                    ? null
                                    : _reanalyzeEditedText,
                                icon: const Icon(Icons.auto_fix_high_rounded),
                                label: const Text('Reanalyser'),
                              );

                              if (constraints.maxWidth < 360) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.text_snippet_outlined),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Texte scanne',
                                            style: titleStyle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [reanalyzeButton, countWidget],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  const Icon(Icons.text_snippet_outlined),
                                  const SizedBox(width: 8),
                                  Text('Texte scanne', style: titleStyle),
                                  const Spacer(),
                                  reanalyzeButton,
                                  const SizedBox(width: 4),
                                  countWidget,
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 180),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _ocrTextController,
                              enabled: !_isBusy,
                              onChanged: (_) => _applyEditorChanges(),
                              minLines: 8,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText:
                                    'Le texte scanne apparaitra ici apres le scan.',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _isBusy ? null : _copyOcrText,
                        icon: const Icon(Icons.copy_rounded),
                        label: const Text('Copier texte'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: _isBusy || _capturedImagePaths.isEmpty
                            ? null
                            : _saveDocument,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Sauvegarder'),
                      ),
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
}
