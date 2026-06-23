import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widget/common/empty_state.dart';
import '../widget/common/loading_indicator.dart';
import '../widget/common/status_badge.dart';
import '../../models/document.dart';
import 'document_detail_screen.dart';
import 'document_upload_screen.dart';

class DocumentListScreen extends StatefulWidget {
  const DocumentListScreen({super.key});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'all',
    'pending_dg_init',
    'pending_dispatch',
    'dg_directed',
    'pending_vdg_approval',
    'pending_dg_approval',
    'dg_signed',
    'completed_archive',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().loadDocuments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final docProvider = context.watch<DocumentProvider>();
    final documents = _getFilteredDocuments(docProvider.documents);
    final user = authProvider.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.documents),
        actions: [
          // Search Toggle
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded,
              color: _isSearchVisible ? colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => docProvider.loadDocuments(),
          ),
          // Upload (if permission)
          if (user?.canUpload == true)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Icon(Icons.add_circle_outline_rounded, color: colorScheme.primary),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentUploadScreen()),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Search Bar ───
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isSearchVisible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchDocuments,
                        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.cancel_rounded, color: colorScheme.onSurfaceVariant),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ─── Filter Chips ───
          _buildFilterChips(colorScheme),
          const SizedBox(height: 8),

          // ─── Document List ───
          Expanded(
            child: docProvider.isLoading
                ? LoadingIndicator(message: context.l10n.loadingDocuments)
                : documents.isEmpty
                    ? EmptyState(
                        title: context.l10n.noDocumentsFound,
                        subtitle: context.l10n.noDocuments,
                        icon: Icons.description_outlined,
                      )
                    : RefreshIndicator(
                        onRefresh: () => docProvider.loadDocuments(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                          itemCount: documents.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            return _buildDocumentCard(context, doc, colorScheme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ─── FILTER CHIPS ───
  Widget _buildFilterChips(ColorScheme colorScheme) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;

          final label = filter == 'all'
              ? context.l10n.allDocuments
              : context.l10n.statusLabel(filter);

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── DOCUMENT CARD ───
  Widget _buildDocumentCard(BuildContext context, Document doc, ColorScheme colorScheme) {
    final statusColor = Color(doc.getStatusColor());

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: doc.id)),
            );
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Tag & Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            doc.controlNo,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        StatusBadge(status: doc.status, small: true),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      doc.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),

                    // Bottom Row: Metadata
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          doc.uploaderName ?? 'Unknown',
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.business_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doc.departmentName ?? context.l10n.unassigned,
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time_rounded, size: 12, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(doc.createdAt),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Color Bar
              Container(
                height: 3,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.8),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HELPERS ───
  List<Document> _getFilteredDocuments(List<Document> documents) {
    List<Document> filtered = documents;

    if (_selectedFilter != 'all') {
      filtered = filtered.where((doc) => doc.status == _selectedFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((doc) {
        return doc.title.toLowerCase().contains(query) ||
            doc.controlNo.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}