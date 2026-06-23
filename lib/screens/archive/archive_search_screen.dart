import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widget/common/search_bar.dart';
import '../widget/common/empty_state.dart';
import '../widget/common/loading_indicator.dart';
import '../widget/common/status_badge.dart';
import '../documents/document_detail_screen.dart';

class ArchiveSearchScreen extends StatefulWidget {
  const ArchiveSearchScreen({super.key});

  @override
  State<ArchiveSearchScreen> createState() => _ArchiveSearchScreenState();
}

class _ArchiveSearchScreenState extends State<ArchiveSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;
  bool _isSearching = false; // local loading flag — not shared with other screens
  String? _localError;       // local error message

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterSearchTerm)),
      );
      return;
    }

    setState(() {
      _hasSearched = true;
      _isSearching = true;
      _localError = null;
    });

    try {
      await Provider.of<DocumentProvider>(context, listen: false)
          .searchArchive(query);

      // Check if provider stored an error
      if (mounted) {
        final err = Provider.of<DocumentProvider>(context, listen: false).errorMessage;
        if (err != null) {
          setState(() => _localError = err);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _localError = e.toString());
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearched = false;
      _isSearching = false;
      _localError = null;
    });
    Provider.of<DocumentProvider>(context, listen: false).clearArchive();
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    final archiveDocs = docProvider.archiveDocuments;
    final accessLevel = docProvider.archiveAccessLevel;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    final isGlobal = accessLevel.toLowerCase().contains('global');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.archiveSearch),
        actions: [
          if (_hasSearched)
            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: Text(l10n.clear),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search Bar ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: CustomSearchBar(
              controller: _searchController,
              hint: l10n.searchArchive,
              onSearch: _performSearch,
              onClear: _clearSearch,
            ),
          ),

          // ─── API Error Banner ───
          if (_localError != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: colorScheme.onErrorContainer, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _localError!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _localError = null),
                    child: Icon(Icons.close_rounded,
                        color: colorScheme.onErrorContainer, size: 16),
                  ),
                ],
              ),
            ),

          // ─── Access Level & Result Count ───
          if (_hasSearched && !_isSearching && archiveDocs.isNotEmpty && _localError == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isGlobal
                          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isGlobal ? Icons.public_rounded : Icons.shield_outlined,
                          size: 13,
                          color: isGlobal ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          accessLevel.isNotEmpty ? accessLevel : l10n.restricted,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isGlobal ? colorScheme.primary : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${archiveDocs.length} ${l10n.results}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Content ───
          Expanded(
            child: _buildContent(context, archiveDocs, colorScheme, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Document> archiveDocs,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    // Local loading (not shared with provider)
    if (_isSearching) {
      return LoadingIndicator(message: l10n.searchingArchive);
    }

    // Not yet searched
    if (!_hasSearched) {
      return EmptyState(
        title: l10n.archiveSearch,
        subtitle: l10n.searchArchiveHint,
        icon: Icons.manage_search_rounded,
      );
    }

    // Error occurred (shown in banner above, list is empty)
    if (_localError != null) {
      return EmptyState(
        title: l10n.noArchives,
        subtitle: _localError!,
        icon: Icons.error_outline_rounded,
        onAction: _clearSearch,
        actionLabel: l10n.clear,
      );
    }

    // Searched, no results
    if (archiveDocs.isEmpty) {
      return EmptyState(
        title: l10n.noArchives,
        subtitle: l10n.noArchiveResults,
        icon: Icons.search_off_rounded,
        onAction: _clearSearch,
        actionLabel: l10n.clear,
      );
    }

    // Show results
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
      itemCount: archiveDocs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _buildDocumentCard(context, archiveDocs[index], colorScheme, l10n);
      },
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    Document doc,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final uploaderName = doc.uploaderName ?? l10n.unknown;
    final departmentName = doc.departmentName ?? l10n.global;
    final updatedDate = '${doc.updatedAt.day}/${doc.updatedAt.month}/${doc.updatedAt.year}';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      color: colorScheme.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentDetailScreen(documentId: doc.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Archive icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            doc.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: doc.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Control No.
                    Row(
                      children: [
                        Icon(Icons.tag_rounded,
                            size: 12, color: colorScheme.primary.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          doc.controlNo,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            letterSpacing: 0.6,
                            color: colorScheme.primary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Meta chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _chip(Icons.person_outline_rounded, uploaderName, colorScheme),
                        _chip(Icons.business_outlined, departmentName, colorScheme),
                        _chip(Icons.calendar_today_outlined, updatedDate, colorScheme),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}