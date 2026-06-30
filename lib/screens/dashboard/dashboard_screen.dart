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
  late final Animation<double> _listFade;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _cardsFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );

    _cardsSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
    ));

    _listFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

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

  // ─── Role-specific accent color ───
  Color _roleColor(String? role, ColorScheme cs) {
    switch (role) {
      case 'dg':
        return const Color(0xFFD32F2F);
      case 'vdg':
        return const Color(0xFFE65100);
      case 'file_dept':
        return const Color(0xFF1565C0);
      case 'department':
        return const Color(0xFF2E7D32);
      case 'staff':
        return const Color(0xFF6A1B9A);
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doc = context.watch<DocumentProvider>();
    final user = auth.user;
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = _roleColor(user?.role, colorScheme);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([doc.loadUrgent(), doc.loadInbox()]);
          _animController.reset();
          _animController.forward();
        },
        color: accentColor,
        backgroundColor: colorScheme.surfaceContainerLow,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ─── Gradient Hero Header ───
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _headerFade,
                child: _buildHeroHeader(context, user, colorScheme, accentColor, doc),
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
                child: FadeTransition(
                  opacity: _listFade,
                  child: EmptyState(
                    title: context.l10n.allCaughtUp,
                    subtitle: context.l10n.noUrgentDocs,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _listFade,
                        child: _buildSectionHeader(
                          context,
                          title: context.l10n.urgentDocuments,
                          count: doc.urgentDocuments.length,
                          colorScheme: colorScheme,
                          accentColor: accentColor,
                        ),
                      ),
                    ),
                    SliverList.separated(
                      itemCount: doc.urgentDocuments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final document = doc.urgentDocuments[index];
                        return FadeTransition(
                          opacity: _listFade,
                          child: DocumentCard(
                            document: document,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/document',
                              arguments: {'id': document.id},
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: null,
    );
  }

  // ─── HERO HEADER with gradient + stats ───
  Widget _buildHeroHeader(
    BuildContext context,
    dynamic user,
    ColorScheme colorScheme,
    Color accentColor,
    DocumentProvider doc,
  ) {
    final l10n = context.l10n;
    final hour = DateTime.now().hour;

    String greeting;
    IconData greetingIcon;
    List<Color> gradientColors;

    if (hour < 12) {
      greeting = l10n.goodMorning;
      greetingIcon = Icons.wb_sunny_rounded;
      gradientColors = [
        const Color(0xFFFF8F00),
        const Color(0xFFFF6F00),
        accentColor,
      ];
    } else if (hour < 17) {
      greeting = l10n.goodAfternoon;
      greetingIcon = Icons.wb_cloudy_rounded;
      gradientColors = [
        accentColor,
        accentColor.withValues(alpha: 0.8),
        accentColor.withValues(alpha: 0.6),
      ];
    } else {
      greeting = l10n.goodEvening;
      greetingIcon = Icons.nights_stay_rounded;
      gradientColors = [
        const Color(0xFF1A237E),
        const Color(0xFF283593),
        accentColor,
      ];
    }

    final initial = user?.name?.isNotEmpty == true
        ? (user.name as String)[0].toUpperCase()
        : '?';

    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top row: greeting + avatar ──
                Row(
                  children: [
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(greetingIcon,
                                  size: 14,
                                  color: Colors.white.withValues(alpha: 0.85)),
                              const SizedBox(width: 6),
                              Text(
                                greeting,
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Role badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user_rounded,
                                    size: 12,
                                    color: Colors.white.withValues(alpha: 0.9)),
                                const SizedBox(width: 5),
                                Text(
                                  user?.displayRole ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.white.withValues(alpha: 0.95),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Stats Row ──
                SlideTransition(
                  position: _cardsSlide,
                  child: FadeTransition(
                    opacity: _cardsFade,
                    child: Row(
                      children: [
                        _buildStatChip(
                          label: l10n.filterPending,
                          count: doc.urgentDocuments.length,
                          icon: Icons.priority_high_rounded,
                          chipColor: Colors.red.shade300,
                        ),
                        const SizedBox(width: 10),
                        _buildStatChip(
                          label: l10n.filterInProgress,
                          count: doc.inboxDocuments.length,
                          icon: Icons.inbox_rounded,
                          chipColor: Colors.blue.shade300,
                        ),
                        const SizedBox(width: 10),
                        _buildStatChip(
                          label: l10n.documents,
                          count: doc.documents.length,
                          icon: Icons.description_rounded,
                          chipColor: Colors.green.shade300,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required String label,
    required int count,
    required IconData icon,
    required Color chipColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: chipColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4, left: 2, right: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accentColor, accentColor.withValues(alpha: 0.4)],
              ),
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
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/documents'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    context.l10n.viewAll,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: accentColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
