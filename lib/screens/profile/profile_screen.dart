import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../config/app_config.dart';
import '../../utils/navigation_service.dart';
import '../../models/user.dart';
import '../../l10n/app_localizations.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            l10n.userNotFound,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    final roleColor = Color(AppConfig.getRoleColor(user.role));
    final headerColor = isDark ? colorScheme.surfaceContainerHigh : roleColor;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF6F8FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ─── Premium Solid Header & Hero Block ───
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: headerColor.withValues(alpha: isDark ? 0.1 : 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -40,
                    right: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
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
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),

                  // Content Column
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 16,
                      20,
                      28,
                    ),
                    child: Column(
                      children: [
                        // Top row: Screen title + Edit Profile shortcut
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.profile,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
                              onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                              tooltip: l10n.editProfile,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Avatar with camera edit badge
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/edit-profile'),
                          child: Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: user.avatarUrl != null
                                      ? Image.network(
                                          user.avatarUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, e, st) =>
                                              _buildInitialsCircle(user, isDark ? colorScheme.primary : roleColor),
                                        )
                                      : _buildInitialsCircle(user, isDark ? colorScheme.primary : roleColor),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isDark ? colorScheme.primary : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 14,
                                    color: isDark ? Colors.white : roleColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Email
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Role Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            user.displayRole,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Cards Section ───
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
              child: Column(
                children: [
                  // Edit Profile banner tile
                  _buildEditProfileCard(context, colorScheme, l10n, isDark),
                  const SizedBox(height: 16),

                  // Personal Info Card
                  _buildProfileInfo(context, user, colorScheme, isDark),
                  const SizedBox(height: 16),

                  // Settings Card (with dynamic switches and modals)
                  _buildSettingsAndActions(context, auth, theme, colorScheme, isDark),
                  const SizedBox(height: 32),

                  // App Version Info
                  Text(
                    l10n.appVersion,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsCircle(User user, Color roleColor) {
    return Container(
      color: roleColor,
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildEditProfileCard(BuildContext context, ColorScheme colorScheme, AppLocalizations l10n, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: isDark ? 0.2 : 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/edit-profile'),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_rounded, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.editProfile,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.editProfileSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, User user, ColorScheme colorScheme, bool isDark) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.personalInfo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          _buildInfoRow(
            icon: Icons.email_outlined,
            iconColor: Colors.deepPurple.shade400,
            label: l10n.email,
            value: user.email,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.business_outlined,
            iconColor: Colors.teal.shade500,
            label: l10n.department,
            value: user.departmentName ?? l10n.notAssigned,
            colorScheme: colorScheme,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required ColorScheme colorScheme,
    bool isLast = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsAndActions(
    BuildContext context,
    AuthProvider auth,
    ThemeProvider theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final localeProvider = context.watch<LocaleProvider>();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Text(
              l10n.settings,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
          ),

          // ─── Theme Switcher Setting Tile ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                _iconWidget(
                  theme.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  Colors.amber.shade700,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.toggleTheme,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: theme.isDarkMode,
                  onChanged: (_) => theme.toggleTheme(),
                  activeThumbColor: Colors.amber.shade700,
                  activeTrackColor: Colors.amber.shade700.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // ─── Language Setting Tile ───
          _settingTile(
            onTap: () => _showLanguagePicker(context, localeProvider),
            icon: Icons.language_rounded,
            iconColor: Colors.blue.shade500,
            title: l10n.language,
            trailingWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                localeProvider.isKhmer ? l10n.languageKhmer : l10n.languageEnglish,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            colorScheme: colorScheme,
          ),

          // ─── Notifications Tile ───
          _settingTile(
            onTap: () => Navigator.pushNamed(context, '/notifications'),
            icon: Icons.notifications_none_rounded,
            iconColor: Colors.teal.shade500,
            title: l10n.notifications,
            colorScheme: colorScheme,
          ),

          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),

          // ─── Logout Tile ───
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _confirmLogout(context, auth),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    _iconWidget(Icons.logout_rounded, colorScheme.error),
                    const SizedBox(width: 16),
                    Text(
                      l10n.logout,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.error,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: colorScheme.error,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconWidget(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  Widget _settingTile({
    required VoidCallback onTap,
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailingWidget,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              _iconWidget(icon, iconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (trailingWidget != null) ...[
                trailingWidget,
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleProvider localeProvider) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.selectLanguage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // English option
              _buildLanguageOption(
                context: ctx,
                locale: const Locale('en'),
                flagIcon: CountryFlag.fromCountryCode(
                  'GB',
                  theme: const ImageTheme(
                    width: 32,
                    height: 24,
                    shape: RoundedRectangle(4),
                  ),
                ),
                label: 'English',
                sublabel: 'English',
                isSelected: !localeProvider.isKhmer,
                colorScheme: colorScheme,
                onTap: () {
                  localeProvider.setLocale(const Locale('en'));
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),

              // Khmer option
              _buildLanguageOption(
                context: ctx,
                locale: const Locale('km'),
                flagIcon: CountryFlag.fromCountryCode(
                  'KH',
                  theme: const ImageTheme(
                    width: 32,
                    height: 24,
                    shape: RoundedRectangle(4),
                  ),
                ),
                label: 'ភាសាខ្មែរ',
                sublabel: 'Khmer',
                isSelected: localeProvider.isKhmer,
                colorScheme: colorScheme,
                onTap: () {
                  localeProvider.setLocale(const Locale('km'));
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required Locale locale,
    required Widget flagIcon,
    required String label,
    required String sublabel,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.4)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            flagIcon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.logOutTitle),
        content: Text(l10n.logOutContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await auth.logout();
      NavigationService.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }
}