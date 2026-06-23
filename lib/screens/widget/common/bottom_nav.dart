import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int notificationCount;
  final VoidCallback? onUploadTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
    this.onUploadTap,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _scaleControllers;
  late List<Animation<double>> _scaleAnimations;

  // Upload FAB animation
  late AnimationController _fabController;
  late Animation<double> _fabScale;
  late Animation<double> _fabRotation;

  static const int _itemCount = 4;

  @override
  void initState() {
    super.initState();

    _scaleControllers = List.generate(
      _itemCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
        value: i == widget.currentIndex ? 1.0 : 0.0,
      ),
    );
    _scaleAnimations = _scaleControllers
        .map((c) => Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.elasticOut),
            ))
        .toList();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
    _fabRotation = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final c in _scaleControllers) {
      c.dispose();
    }
    _fabController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    // Scale feedback
    _scaleControllers[index].forward().then((_) {
      _scaleControllers[index].reverse();
    });
    // Haptic
    HapticFeedback.lightImpact();
    widget.onTap(index);
  }

  void _handleFabTap() async {
    HapticFeedback.mediumImpact();
    await _fabController.forward();
    await _fabController.reverse();
    widget.onUploadTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    // The 4 nav items split around the center FAB
    // Positions: 0=Home, 1=Documents, [FAB], 2=Archive, 3=Profile
    final leftItems = [
      _NavItem(
        index: 0,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: l10n.navHome,
      ),
      _NavItem(
        index: 1,
        icon: Icons.description_outlined,
        selectedIcon: Icons.description_rounded,
        label: l10n.documents,
      ),
    ];
    final rightItems = [
      _NavItem(
        index: 2,
        icon: Icons.archive_outlined,
        selectedIcon: Icons.archive_rounded,
        label: l10n.navArchive,
      ),
      _NavItem(
        index: 3,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: l10n.navProfile,
        notificationCount: 0,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        mediaQuery.padding.bottom + 12,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // ─── Floating bar ───
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.92)
                      : colorScheme.surfaceContainerLow.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: isDark ? 0.4 : 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left items
                    ...leftItems.map(
                      (item) => Expanded(
                        child: _buildNavItem(
                          context,
                          item: item,
                          colorScheme: colorScheme,
                        ),
                      ),
                    ),
                    // Center FAB space
                    const SizedBox(width: 72),
                    // Right items
                    ...rightItems.map(
                      (item) => Expanded(
                        child: _buildNavItem(
                          context,
                          item: item,
                          colorScheme: colorScheme,
                          notifCount: item.index == 3 ? widget.notificationCount : 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Center Upload FAB ───
          Positioned(
            top: -22,
            child: AnimatedBuilder(
              animation: Listenable.merge([_fabScale, _fabRotation]),
              builder: (context, _) {
                return Transform.scale(
                  scale: _fabScale.value,
                  child: Transform.rotate(
                    angle: _fabRotation.value * 2 * 3.14159,
                    child: GestureDetector(
                      onTap: _handleFabTap,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: colorScheme.onPrimary,
                          size: 28,
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
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required _NavItem item,
    required ColorScheme colorScheme,
    int notifCount = 0,
  }) {
    final isSelected = widget.currentIndex == item.index;

    return GestureDetector(
      onTap: () => _handleTap(item.index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimations[item.index],
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimations[item.index].value,
          child: child,
        ),
        child: SizedBox(
          height: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon + indicator pill
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Animated pill background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 48 : 0,
                    height: isSelected ? 32 : 0,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  // Icon
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: child,
                    ),
                    child: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      key: ValueKey('${item.index}_$isSelected'),
                      size: 22,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  // Notification badge
                  if (notifCount > 0)
                    Positioned(
                      right: -8,
                      top: -6,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notifCount > 9 ? '9+' : '$notifCount',
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  letterSpacing: isSelected ? 0.3 : 0,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Active dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(top: 3),
                width: isSelected ? 4 : 0,
                height: isSelected ? 4 : 0,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int notificationCount;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.notificationCount = 0,
  });
}