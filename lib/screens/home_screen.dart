import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scannerdocument/models/document_category.dart';
import 'package:scannerdocument/models/document_domain.dart';
import 'package:scannerdocument/models/scanned_document.dart';
import 'package:scannerdocument/screens/document_detail_screen.dart';
import 'package:scannerdocument/screens/scan_screen.dart';
import 'package:scannerdocument/services/document_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final DocumentRepository repository;
  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode mode) onThemeModeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _query = '';
  DocumentCategory? _selectedCategory;
  bool _isLoading = true;
  List<ScannedDocument> _documents = const [];

  int get _documentsWithExtractedData =>
      _documents.where((document) => !document.extractedData.isEmpty).length;

  List<ScannedDocument> get _filteredDocuments {
    if (_selectedCategory == null) {
      return _documents;
    }

    return _documents
        .where(
          (document) =>
              document.extractedData.documentCategory == _selectedCategory,
        )
        .toList();
  }

  int _countByCategory(DocumentCategory category) {
    return _documents
        .where(
          (document) => document.extractedData.documentCategory == category,
        )
        .length;
  }

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoading = true;
    });

    final docs = await widget.repository.searchDocuments(_query);

    if (!mounted) {
      return;
    }

    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    _query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), _loadDocuments);
  }

  Future<void> _openScanner() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ScanScreen(repository: widget.repository),
      ),
    );

    if (created == true) {
      await _loadDocuments();
    }
  }

  Future<void> _openDetails(ScannedDocument document) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(
          repository: widget.repository,
          document: document,
        ),
      ),
    );

    if (changed == true) {
      await _loadDocuments();
    }
  }

  Future<void> _showAppearanceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apparence',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.settings_suggest_outlined),
                      label: Text('Systeme'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Clair'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Sombre'),
                    ),
                  ],
                  selected: {widget.themeMode},
                  onSelectionChanged: (selection) async {
                    final mode = selection.first;
                    await widget.onThemeModeChanged(mode);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(ScannedDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce document ?'),
        content: Text(document.title),
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

    return confirmed == true;
  }

  Future<void> _deleteDocument(ScannedDocument document) async {
    await widget.repository.deleteDocument(document.id);
    await _loadDocuments();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Document supprime.'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () async {
              await widget.repository.insertDocument(document);
              await _loadDocuments();
            },
          ),
        ),
      );
  }

  IconData _categoryIcon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.invoice:
        return Icons.receipt_long_rounded;
      case DocumentCategory.receipt:
        return Icons.point_of_sale_rounded;
      case DocumentCategory.contract:
        return Icons.description_rounded;
      case DocumentCategory.unknown:
        return Icons.folder_open_rounded;
    }
  }

  IconData _domainIcon(DocumentDomain domain) {
    switch (domain) {
      case DocumentDomain.electricity:
        return Icons.bolt_rounded;
      case DocumentDomain.water:
        return Icons.water_drop_rounded;
      case DocumentDomain.gas:
        return Icons.local_fire_department_rounded;
      case DocumentDomain.internet:
        return Icons.wifi_rounded;
      case DocumentDomain.telecom:
        return Icons.call_rounded;
      case DocumentDomain.rent:
        return Icons.home_rounded;
      case DocumentDomain.banking:
        return Icons.account_balance_rounded;
      case DocumentDomain.insurance:
        return Icons.shield_rounded;
      case DocumentDomain.government:
        return Icons.gavel_rounded;
      case DocumentDomain.retail:
        return Icons.storefront_rounded;
      case DocumentDomain.unknown:
        return Icons.layers_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'images/scanner_app_icon_transparent.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 8),
            const Text('Scanner Documents'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Apparence',
            onPressed: _showAppearanceSheet,
            icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        icon: const Icon(Icons.document_scanner),
        label: const Text('Scanner'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Card(
              margin: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A2A31), const Color(0xFF12353A)]
                        : [const Color(0xFFD6F4EF), const Color(0xFFE8F3FF)],
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
                          width: 110,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Scanne, classe et exporte tes documents localement.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _SecurityPill(
                          icon: Icons.offline_bolt_rounded,
                          text: '100% Offline',
                        ),
                        _SecurityPill(
                          icon: Icons.dns_rounded,
                          text: 'Sans serveur',
                        ),
                        _SecurityPill(
                          icon: Icons.lock_rounded,
                          text: 'Donnees locales',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _openScanner,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Nouveau scan'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher dans le texte scanne ou les donnees',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(Icons.clear_rounded),
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.folder_open_rounded,
                    label: 'Documents',
                    value: '${_documents.length}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Extraits',
                    value: '$_documentsWithExtractedData',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.filter_list_rounded,
                    label: 'Visibles',
                    value: '${_filteredDocuments.length}',
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: Text('Tous (${_documents.length})'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...DocumentCategory.values.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(_categoryIcon(category), size: 16),
                      label: Text(
                        '${category.label} (${_countByCategory(category)})',
                      ),
                      selected: _selectedCategory == category,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleDocs = _filteredDocuments;

    if (_documents.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = constraints.maxHeight > 48
              ? constraints.maxHeight - 48
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'images/scanner_full_logo_transparent.png',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Aucun document trouve.',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lance ton premier scan pour commencer ton archive locale.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _openScanner,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Commencer un scan'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    if (visibleDocs.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = constraints.maxHeight > 48
              ? constraints.maxHeight - 48
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_off_rounded, size: 34),
                        const SizedBox(height: 10),
                        Text(
                          'Aucun document pour ce filtre.',
                          style: Theme.of(context).textTheme.titleSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Essaie une autre categorie ou retire les filtres.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: visibleDocs.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final document = visibleDocs[index];
          final firstImagePath = document.imagePaths.isNotEmpty
              ? document.imagePaths.first
              : null;

          return Dismissible(
            key: ValueKey(document.id),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) => _confirmDelete(document),
            onDismissed: (_) => _deleteDocument(document),
            background: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerRight,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: _DocumentCard(
              document: document,
              createdAtLabel: DateFormat(
                'dd/MM/yyyy HH:mm',
              ).format(document.createdAt),
              thumbnailPath: firstImagePath,
              categoryIcon: _categoryIcon(
                document.extractedData.documentCategory,
              ),
              domainIcon: _domainIcon(document.extractedData.documentDomain),
              onTap: () => _openDetails(document),
            ),
          );
        },
      ),
    );
  }
}

class _SecurityPill extends StatelessWidget {
  const _SecurityPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.createdAtLabel,
    required this.thumbnailPath,
    required this.categoryIcon,
    required this.domainIcon,
    required this.onTap,
  });

  final ScannedDocument document;
  final String createdAtLabel;
  final String? thumbnailPath;
  final IconData categoryIcon;
  final IconData domainIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extraEntries = document.extractedData
        .toDisplayEntries()
        .where((entry) => entry.key != 'Type' && entry.key != 'Domaine')
        .take(2)
        .toList();

    final highlight = extraEntries.isEmpty
        ? 'Aucune donnee cle detectee.'
        : extraEntries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(' • ');

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumbnail(imagePath: thumbnailPath, size: 72),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _MetaBadge(
                          icon: categoryIcon,
                          label: document.extractedData.documentCategory.label,
                        ),
                        _MetaBadge(
                          icon: domainIcon,
                          label: document.extractedData.documentDomain.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          createdAtLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      highlight,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${document.imagePaths.length}p',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imagePath, this.size = 52});

  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final file = imagePath == null ? null : File(imagePath!);
    final exists = file != null && file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: exists
            ? Image.file(file, fit: BoxFit.cover)
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.description_outlined),
              ),
      ),
    );
  }
}
