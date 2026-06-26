import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_config.dart';
import '../widget/common/empty_state.dart';
import '../widget/common/loading_indicator.dart';
import '../widget/common/status_badge.dart';
import '../../models/document.dart';

class DocumentListScreen extends StatefulWidget {
  final bool isTab;
  const DocumentListScreen({super.key, this.isTab = false});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isAscending = false;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use dynamic accent color based on user role
    final accentColor = Color(AppConfig.getRoleColor(user?.role ?? ''));
    final headerColor = isDark ? colorScheme.surfaceContainerHigh : accentColor;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF6F8FB),
      body: Column(
        children: [
          // ─── Solid Premium Top Header Panel ───
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: headerColor.withValues(alpha: isDark ? 0.1 : 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative Circle Lines
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -20,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.04),
                        width: 8,
                      ),
                    ),
                  ),
                ),

                // Content Column
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    MediaQuery.of(context).padding.top + 12,
                    16,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Navigation Row
                      Row(
                        children: [
                          if (!widget.isTab) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                onPressed: () => Navigator.pop(context),
                                tooltip: context.l10n.back,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.documents,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${documents.length} ${context.l10n.resultsFound}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                              onPressed: () => docProvider.loadDocuments(),
                              tooltip: context.l10n.refresh,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Premium Search Bar & Sort Row Inline
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isDark ? colorScheme.surfaceContainerLowest : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) => setState(() => _searchQuery = value),
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: context.l10n.searchDocuments,
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(Icons.search_rounded, color: accentColor, size: 20),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.cancel_rounded, color: colorScheme.onSurfaceVariant),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark ? colorScheme.surfaceContainerLowest : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                color: accentColor,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _isAscending = !_isAscending),
                              tooltip: _isAscending ? context.l10n.sortOldestFirst : context.l10n.sortNewestFirst,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Horizontal Metrics breakdown cards ───
          const SizedBox(height: 14),
          _buildMetricsRow(context, docProvider, colorScheme),

          // ─── Dynamic filter chips list ───
          const SizedBox(height: 14),
          _buildFilterChips(colorScheme, user?.role),
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
                        color: accentColor,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: documents.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            return _buildDocumentCard(context, doc, colorScheme);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: user?.canUpload == true
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, '/upload'),
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(
                context.l10n.newDocument,
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
              ),
              elevation: 4,
            )
          : null,
    );
  }

  // ─── METRICS ROW ───
  Widget _buildMetricsRow(BuildContext context, DocumentProvider docProvider, ColorScheme colorScheme) {
    final allDocs = docProvider.documents;
    final totalCount = allDocs.length;
    final pendingCount = allDocs.where((d) => d.status.startsWith('pending') || d.status == 'pending_dg_init').length;
    final archiveCount = allDocs.where((d) => d.status == 'completed_archive').length;
    final inProgressCount = totalCount - pendingCount - archiveCount;

    return SizedBox(
      height: 66,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildMetricCard(
            context: context,
            label: context.l10n.filterPending,
            count: pendingCount.toString(),
            color: const Color(0xFFE53935), // Solid vibrant red
            icon: Icons.pending_actions_rounded,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 10),
          _buildMetricCard(
            context: context,
            label: context.l10n.filterInProgress,
            count: inProgressCount.toString(),
            color: const Color(0xFF1E88E5), // Solid vibrant blue
            icon: Icons.sync_rounded,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 10),
          _buildMetricCard(
            context: context,
            label: context.l10n.filterCompleted,
            count: archiveCount.toString(),
            color: const Color(0xFF43A047), // Solid vibrant green
            icon: Icons.task_alt_rounded,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  // ─── METRICS CARD ───
  Widget _buildMetricCard({
    required BuildContext context,
    required String label,
    required String count,
    required Color color,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 128,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTER CHIPS ───
  Widget _buildFilterChips(ColorScheme colorScheme, String? userRole) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 42,
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

          // Find the precise status color for dots and background
          final filterColor = filter == 'all'
              ? Color(AppConfig.getRoleColor(userRole ?? ''))
              : Color(AppConfig.statusColors[filter] ?? 0xFF757575);

          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? filterColor
                    : (isDark ? colorScheme.surfaceContainerHigh : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? filterColor
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: filterColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (filter != 'all') ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? Colors.white : filterColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = Color(doc.getStatusColor());

    // Clean status-tinted blend to give cards soft color identity
    final cardBgColor = isDark
        ? Color.alphaBlend(statusColor.withValues(alpha: 0.08), colorScheme.surfaceContainerHigh)
        : Color.alphaBlend(statusColor.withValues(alpha: 0.05), Colors.white);

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thick solid vertical status indicator bar on the left
              Container(
                width: 6,
                color: statusColor,
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/document',
                      arguments: {'id': doc.id},
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Row: Control No + Status Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                doc.controlNo,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            StatusBadge(status: doc.status, small: true),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title Text
                        Text(
                          doc.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Comment/Note preview (if available)
                        if (doc.comment != null && doc.comment!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    doc.comment!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Meta details chips Wrap
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildMetaChip(
                              Icons.person_outline_rounded,
                              doc.uploaderName ?? 'Unknown',
                              Colors.deepPurple.shade400,
                              colorScheme,
                            ),
                            _buildMetaChip(
                              Icons.business_outlined,
                              doc.departmentName ?? context.l10n.unassigned,
                              Colors.teal.shade500,
                              colorScheme,
                            ),
                            _buildMetaChip(
                              Icons.access_time_rounded,
                              _formatDate(doc.createdAt),
                              Colors.blue.shade500,
                              colorScheme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── META CHIP WIDGET ───
  Widget _buildMetaChip(IconData icon, String text, Color iconColor, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
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

    // Sort by date (createdAt)
    filtered = List<Document>.from(filtered);
    filtered.sort((a, b) {
      if (_isAscending) {
        return a.createdAt.compareTo(b.createdAt);
      } else {
        return b.createdAt.compareTo(a.createdAt);
      }
    });

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
      return context.l10n.justNow;
    }
  }
}