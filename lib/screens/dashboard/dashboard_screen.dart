import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widget/document/document_card.dart';
import '../widget/common/empty_state.dart';
import '../widget/common/loading_indicator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _headerFade;
  late final Animation<double> _cardsFade;
  late final Animation<Offset> _cardsSlide;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _cardsFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    );

    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DocumentProvider>().loadUrgent();
        context.read<DocumentProvider>().loadInbox();
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doc = context.watch<DocumentProvider>();
    final user = auth.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            doc.loadUrgent(),
            doc.loadInbox(),
          ]);
        },
        color: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerLow,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ─── Safe area top padding ───
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top + 8),
            ),

            // ─── Header ───
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: _buildHeader(context, user, colorScheme),
              ),
            ),

            // ─── Stats Cards ───
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _cardsSlide,
                child: FadeTransition(
                  opacity: _cardsFade,
                  child: _buildStatsCards(context, doc, colorScheme),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Urgent Documents Section ───
            if (doc.isLoading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: LoadingIndicator(message: ''),
              )
            else if (doc.urgentDocuments.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: context.l10n.allCaughtUp,
                  subtitle: context.l10n.noUrgentDocs,
                  icon: Icons.check_circle_outline,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        context,
                        title: context.l10n.urgentDocuments,
                        count: doc.urgentDocuments.length,
                        colorScheme: colorScheme,
                      ),
                    ),
                    SliverList.separated(
                      itemCount: doc.urgentDocuments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final document = doc.urgentDocuments[index];
                        return DocumentCard(
                          document: document,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/document',
                              arguments: {'id': document.id},
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: auth.canUpload
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/upload'),
              tooltip: context.l10n.uploadDocument,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  // ─── HEADER ───
  Widget _buildHeader(BuildContext context, user, ColorScheme colorScheme) {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;
    String greeting = l10n.goodMorning;
    IconData greetingIcon = Icons.wb_sunny_rounded;
    if (hour >= 12 && hour < 17) {
      greeting = l10n.goodAfternoon;
      greetingIcon = Icons.wb_sunny_outlined;
    }
    if (hour >= 17) {
      greeting = l10n.goodEvening;
      greetingIcon = Icons.dark_mode_outlined;
    }

    final initial = user?.name?.isNotEmpty == true
        ? user.name[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          // ── Avatar ──
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.7),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // ── Text ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(greetingIcon, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name ?? 'User',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Role Badge ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user?.displayRole ?? '',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS CARDS ───
  Widget _buildStatsCards(
    BuildContext context,
    DocumentProvider doc,
    ColorScheme colorScheme,
  ) {
    final l10n = context.l10n;
    final urgentCount = doc.urgentDocuments.length;
    final inboxCount = doc.inboxDocuments.length;
    final totalCount = doc.documents.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            context,
            title: l10n.filterPending,
            count: urgentCount,
            color: colorScheme.error,
            icon: Icons.warning_amber_rounded,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            title: l10n.filterInProgress,
            count: inboxCount,
            color: colorScheme.primary,
            icon: Icons.inbox_rounded,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            context,
            title: l10n.documents,
            count: totalCount,
            color: colorScheme.tertiary,
            icon: Icons.description_rounded,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SECTION HEADER ───
  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/documents'),
            child: Row(
              children: [
                Text(
                  context.l10n.viewAll,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
