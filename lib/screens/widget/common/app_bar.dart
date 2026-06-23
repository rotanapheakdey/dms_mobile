import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final bool showLeading;
  final Widget? leading;
  final Widget? titleWidget;
  final Color? backgroundColor;
  final bool centerTitle;
  final double elevation;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackPressed,
    this.showLeading = true,
    this.leading,
    this.titleWidget,
    this.backgroundColor,
    this.centerTitle = false,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: elevation,
      centerTitle: centerTitle,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      
      leading: _buildLeading(context, colorScheme),
      
      title: titleWidget ?? _buildTitle(context, colorScheme),
      
      actions: actions ?? _buildDefaultActions(context),
      
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(
          height: 0.5,
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context, ColorScheme colorScheme) {
    if (!showLeading) return null;
    if (leading != null) return leading;

    if (showBackButton) {
      return IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: colorScheme.onSurface,
        ),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
        splashRadius: 24,
        padding: const EdgeInsets.all(8),
      );
    }

    return null;
  }

  Widget _buildTitle(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context) {
    return [];
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 0.5);
}