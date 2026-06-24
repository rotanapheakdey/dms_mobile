import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_config.dart';
import '../widget/common/empty_state.dart';
import '../widget/common/loading_indicator.dart';
import '../widget/common/status_badge.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialArchive();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load initial archives automatically on start
  Future<void> _loadInitialArchive() async {
    setState(() {
      _isSearching = true;
      _localError = null;
    });

    try {
      await Provider.of<DocumentProvider>(context, listen: false)
          .searchArchive('');
      if (mounted) {
        setState(() {
          _hasSearched = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _localError = e.toString());
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
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
      _hasSearched = true;
      _isSearching = false;
      _localError = null;
    });
    Provider.of<DocumentProvider>(context, listen: false).searchArchive('');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final docProvider = Provider.of<DocumentProvider>(context);
    final user = authProvider.user;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Apply department restriction client-side if department/staff role
    final List<Document> archiveDocs = docProvider.archiveDocuments.where((doc) {
      if (user != null && (user.role == 'department' || user.role == 'staff')) {
        final deptName = user.departmentName;
        final docDeptName = doc.departmentName;
        if (deptName == null || docDeptName == null) return false;
        return docDeptName.toLowerCase() == deptName.toLowerCase();
      }
      return true;
    }).toList();

    // Use dynamic accent color based on user role
    final accentColor = Color(AppConfig.getRoleColor(user?.role ?? ''));
    final headerColor = isDark ? colorScheme.surfaceContainerHigh : Color(0xFF2A3A60); // Solid Indigo/Navy

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
                        color: Colors.white.withValues(alpha: 0.05),
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
                    MediaQuery.of(context).padding.top + 20,
                    16,
                    22,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Navigation Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.archiveSearch,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user?.role == 'department' || user?.role == 'staff'
                                      ? '${user?.departmentName ?? ""} ${l10n.archive}'
                                      : l10n.globalAccess,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Premium Integrated Search Field
                      Container(
                        height: 50,
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
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _performSearch(),
                                onChanged: (_) => setState(() {}),
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: l10n.searchArchive,
                                  hintStyle: TextStyle(
                                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(Icons.search_rounded, color: accentColor, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.cancel_rounded, color: colorScheme.onSurfaceVariant),
                                          onPressed: _clearSearch,
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: IconButton(
                                onPressed: _performSearch,
                                style: IconButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                ),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── API Error Banner ───
          if (_localError != null)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                        fontWeight: FontWeight.w600,
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

          // ─── Access Level Info Bar ───
          if (_hasSearched && !_isSearching && archiveDocs.isNotEmpty && _localError == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 13,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          user?.role == 'department' || user?.role == 'staff'
                              ? l10n.restricted
                              : l10n.globalAccess,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
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
                        fontWeight: FontWeight.w700,
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
    if (_isSearching) {
      return LoadingIndicator(message: l10n.searchingArchive);
    }

    if (!_hasSearched) {
      return EmptyState(
        title: l10n.archiveSearch,
        subtitle: l10n.searchArchiveHint,
        icon: Icons.manage_search_rounded,
      );
    }

    if (_localError != null && archiveDocs.isEmpty) {
      return EmptyState(
        title: l10n.noArchives,
        subtitle: _localError!,
        icon: Icons.error_outline_rounded,
        onAction: _clearSearch,
        actionLabel: l10n.clear,
      );
    }

    if (archiveDocs.isEmpty) {
      return EmptyState(
        title: l10n.noArchives,
        subtitle: l10n.noArchiveResults,
        icon: Icons.search_off_rounded,
        onAction: _clearSearch,
        actionLabel: l10n.clear,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: archiveDocs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = Color(doc.getStatusColor());
    final uploaderName = doc.uploaderName ?? l10n.unknown;
    final departmentName = doc.departmentName ?? l10n.global;
    final updatedDate = '${doc.updatedAt.day}/${doc.updatedAt.month}/${doc.updatedAt.year}';

    // Status tint blend for background
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
              // Thick left border status color bar
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
                              uploaderName,
                              Colors.deepPurple.shade400,
                              colorScheme,
                            ),
                            _buildMetaChip(
                              Icons.business_outlined,
                              departmentName,
                              Colors.teal.shade500,
                              colorScheme,
                            ),
                            _buildMetaChip(
                              Icons.access_time_rounded,
                              updatedDate,
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
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    size: 22,
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
}