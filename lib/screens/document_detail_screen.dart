import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:scannerdocument/models/scanned_document.dart';
import 'package:scannerdocument/services/document_repository.dart';
import 'package:scannerdocument/services/export_service.dart';

class DocumentDetailScreen extends StatefulWidget {
  const DocumentDetailScreen({
    super.key,
    required this.repository,
    required this.document,
  });

  final DocumentRepository repository;
  final ScannedDocument document;

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  final ExportService _exportService = ExportService();
  bool _isBusy = false;
  int _selectedImageIndex = 0;

  Future<void> _deleteDocument() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce document ?'),
        content: const Text('Cette action supprime la copie locale.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isBusy = true;
    });

    await widget.repository.deleteDocument(widget.document.id);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  Future<void> _copyOcrText() async {
    final text = widget.document.ocrText.trim();
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

  Future<void> _export(ExportFormat format) async {
    setState(() {
      _isBusy = true;
    });

    try {
      final file = await _exportService.exportDocument(widget.document, format);
      await _exportService.shareExportedFile(file);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export cree: ${file.path}')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur export: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _openImageFullScreen(String imagePath) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final file = File(imagePath);
        final exists = file.existsSync();

        return Dialog.fullscreen(
          child: Scaffold(
            appBar: AppBar(title: const Text('Apercu document')),
            body: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: exists
                  ? InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 5,
                      child: Image.file(file, fit: BoxFit.contain),
                    )
                  : const Text('Image indisponible'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final createdAt = DateFormat('dd/MM/yyyy HH:mm').format(document.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          document.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _isBusy ? null : _copyOcrText,
            icon: const Icon(Icons.copy),
            tooltip: 'Copier texte',
          ),
          IconButton(
            onPressed: _isBusy ? null : _deleteDocument,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isBusy) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                _DocumentHeaderCard(document: document, createdAt: createdAt),
                const SizedBox(height: 12),
                _MetaCard(document: document, createdAt: createdAt),
                const SizedBox(height: 16),
                const _SectionTitle('Exporter'),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _ExportLogoButton(
                      label: 'PDF',
                      subtitle: 'Document',
                      icon: Icons.picture_as_pdf_rounded,
                      color: const Color(0xFFD93636),
                      onTap: _isBusy ? null : () => _export(ExportFormat.pdf),
                    ),
                    _ExportLogoButton(
                      label: 'EXCEL',
                      subtitle: 'Tableur .xlsx',
                      icon: Icons.table_view_rounded,
                      color: const Color(0xFF148A3B),
                      onTap: _isBusy ? null : () => _export(ExportFormat.xlsx),
                    ),
                    _ExportLogoButton(
                      label: 'JSON',
                      subtitle: 'Donnees',
                      icon: Icons.data_object_rounded,
                      color: const Color(0xFF2D69C7),
                      onTap: _isBusy ? null : () => _export(ExportFormat.json),
                    ),
                    _ExportLogoButton(
                      label: 'TXT',
                      subtitle: 'Texte',
                      icon: Icons.description_rounded,
                      color: const Color(0xFF5A6470),
                      onTap: _isBusy ? null : () => _export(ExportFormat.txt),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Apercu pages'),
                const SizedBox(height: 8),
                _ImagesPreview(
                  imagePaths: document.imagePaths,
                  selectedIndex: _selectedImageIndex,
                  onSelect: (index) {
                    setState(() {
                      _selectedImageIndex = index;
                    });
                  },
                  onOpenFullScreen: _openImageFullScreen,
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Donnees extraites'),
                const SizedBox(height: 8),
                _ExtractedDataCard(
                  entries: document.extractedData.toDisplayEntries(),
                ),
                const SizedBox(height: 16),
                const _SectionTitle('Texte scanne'),
                const SizedBox(height: 8),
                _OcrCard(text: document.ocrText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.document, required this.createdAt});

  final ScannedDocument document;
  final String createdAt;

  @override
  Widget build(BuildContext context) {
    final data = document.extractedData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Cree le $createdAt')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.pages_outlined, size: 18),
                const SizedBox(width: 8),
                Text('Pages: ${document.imagePaths.length}'),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Type: ${data.documentCategory.label}')),
                Chip(label: Text('Domaine: ${data.documentDomain.label}')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentHeaderCard extends StatelessWidget {
  const _DocumentHeaderCard({required this.document, required this.createdAt});

  final ScannedDocument document;
  final String createdAt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A2A31), const Color(0xFF12353A)]
                : [const Color(0xFFDDF5F1), const Color(0xFFF2F7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'images/scanner_app_icon_transparent.png',
              width: 38,
              height: 38,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Cree le $createdAt',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${document.imagePaths.length} pages',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagesPreview extends StatelessWidget {
  const _ImagesPreview({
    required this.imagePaths,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenFullScreen,
  });

  final List<String> imagePaths;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Future<void> Function(String imagePath) onOpenFullScreen;

  @override
  Widget build(BuildContext context) {
    if (imagePaths.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Apercu non disponible',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final safeIndex = selectedIndex.clamp(0, imagePaths.length - 1);
    final selectedPath = imagePaths[safeIndex];
    final selectedFile = File(selectedPath);
    final selectedExists = selectedFile.existsSync();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: selectedExists
                  ? () => onOpenFullScreen(selectedPath)
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  child: selectedExists
                      ? Image.file(selectedFile, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 28,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagePaths.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final path = imagePaths[index];
                  final file = File(path);
                  final exists = file.existsSync();
                  final isSelected = index == safeIndex;

                  return GestureDetector(
                    onTap: () => onSelect(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: exists
                            ? Image.file(file, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtractedDataCard extends StatelessWidget {
  const _ExtractedDataCard({required this.entries});

  final List<MapEntry<String, String>> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text('Aucune donnee structuree detectee.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < entries.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        entries[i].key,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entries[i].value)),
                  ],
                ),
              ),
              if (i != entries.length - 1)
                Divider(
                  height: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OcrCard extends StatelessWidget {
  const _OcrCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          text.trim().isEmpty ? 'Texte vide.' : text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ExportLogoButton extends StatelessWidget {
  const _ExportLogoButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    final cardColor = Theme.of(context).colorScheme.surfaceContainerHigh;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDisabled
                      ? color.withValues(alpha: 0.25)
                      : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: isDisabled ? color.withValues(alpha: 0.55) : color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
