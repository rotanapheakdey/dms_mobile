import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
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
    });

    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    await docProvider.searchArchive(query);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _hasSearched = false;
    });
    Provider.of<DocumentProvider>(context, listen: false).clearArchive();
  }

  @override
  Widget build(BuildContext context) {
    final docProvider = Provider.of<DocumentProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final archiveDocs = docProvider.archiveDocuments;
    final isLoading = docProvider.isLoading;
    final userRole = authProvider.user?.role ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.archiveSearch),
        actions: [
          if (_hasSearched && archiveDocs.isNotEmpty)
            TextButton(
              onPressed: _clearSearch,
              child: Text(context.l10n.clear),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: CustomSearchBar(
              controller: _searchController,
              hint: context.l10n.searchArchive,
              onSearch: _performSearch,
              onClear: _clearSearch,
            ),
          ),

          // Access Level & Result Count
          if (_hasSearched && !isLoading && archiveDocs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getAccessLevelIcon(userRole),
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getAccessLevelText(userRole),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${archiveDocs.length} result(s)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _buildContent(
              isLoading,
              archiveDocs,
              _hasSearched,
              userRole,
              colorScheme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    bool isLoading,
    List<dynamic> archiveDocs,
    bool hasSearched,
    String userRole,
    ColorScheme colorScheme,
  ) {
    if (isLoading) {
      return const Center(child: LoadingIndicator(message: 'Searching archive...'));
    }

    if (!hasSearched) {
      return const EmptyState(
        title: 'Search Archive',
        subtitle: 'Enter a keyword or control number\nto find past documents.',
        icon: Icons.archive_outlined,
      );
    }

    if (archiveDocs.isEmpty) {
      return const EmptyState(
        title: 'No Results Found',
        subtitle: 'We couldn\'t find any documents\nmatching your search term.',
        icon: Icons.search_off_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
      itemCount: archiveDocs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final doc = archiveDocs[index];
        return _buildDocumentCard(context, doc, userRole, colorScheme);
      },
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    dynamic doc,
    String userRole,
    ColorScheme colorScheme,
  ) {
    final isAccessible = _isDocumentAccessible(doc, userRole);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isAccessible
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DocumentDetailScreen(documentId: doc.id),
                    ),
                  );
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Document Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Document Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              doc.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: doc.status, small: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doc.controlNo,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            doc.uploaderName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.business_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doc.departmentName ?? 'Global',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Action Indicator
                Icon(
                  isAccessible ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
                  color: isAccessible
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : colorScheme.error.withValues(alpha: 0.8),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  bool _isDocumentAccessible(dynamic doc, String userRole) {
    if (userRole == 'dg' || userRole == 'file_dept') {
      return true;
    }
    if (['vdg', 'department', 'staff'].contains(userRole)) {
      return true;
    }
    return false;
  }

  IconData _getAccessLevelIcon(String userRole) {
    if (userRole == 'dg' || userRole == 'file_dept') {
      return Icons.public_rounded;
    }
    return Icons.shield_outlined;
  }

  String _getAccessLevelText(String userRole) {
    if (userRole == 'dg' || userRole == 'file_dept') {
      return 'Global Access';
    }
    return 'Restricted';
  }
}