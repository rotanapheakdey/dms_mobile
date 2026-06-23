import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../config/app_config.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _pickedImage;
  bool _isSaving = false;
  bool _showNewPass = false;
  bool _showConfirmPass = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ─── PICK IMAGE ───
  Future<void> _pickImage() async {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
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
              l10n.photoOptions,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            _buildPhotoOption(
              ctx,
              icon: Icons.photo_library_rounded,
              label: l10n.fromGallery,
              color: colorScheme.primary,
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                  maxWidth: 800,
                );
                if (picked != null) {
                  setState(() => _pickedImage = File(picked.path));
                }
              },
            ),
            const SizedBox(height: 12),
            _buildPhotoOption(
              ctx,
              icon: Icons.camera_alt_rounded,
              label: l10n.takePhoto,
              color: Colors.teal,
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                  maxWidth: 800,
                );
                if (picked != null) {
                  setState(() => _pickedImage = File(picked.path));
                }
              },
            ),
            // Show remove option only if user has an avatar
            if (context.read<AuthProvider>().user?.avatarUrl != null ||
                _pickedImage != null) ...[
              const SizedBox(height: 12),
              _buildPhotoOption(
                ctx,
                icon: Icons.delete_outline_rounded,
                label: l10n.removePhoto,
                color: colorScheme.error,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _pickedImage = null);
                  _removeAvatar();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption(
    BuildContext ctx, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(ctx).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── REMOVE AVATAR ───
  Future<void> _removeAvatar() async {
    final auth = context.read<AuthProvider>();
    final l10n = context.l10n;
    if (auth.user?.avatarUrl == null) return;

    final success = await auth.removeAvatar();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(success ? l10n.avatarRemoved : l10n.profileUpdateFailed),
          ],
        ),
        backgroundColor: success ? Colors.green.shade600 : Colors.red.shade600,
      ),
    );
  }

  // ─── SAVE PROFILE ───
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = context.l10n;
    final auth = context.read<AuthProvider>();

    // Validate passwords match
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
    if (newPass.isNotEmpty && newPass != confirmPass) {
      setState(() => _errorMessage = l10n.passwordsDoNotMatch);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    bool success = false;

    // Upload new avatar first (separate endpoint)
    if (_pickedImage != null) {
      success = await auth.updateAvatar(_pickedImage!.path);
      if (!success && mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = auth.errorMessage ?? l10n.profileUpdateFailed;
        });
        return;
      }
    }

    // Save profile fields (name, email, password)
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final currentUser = auth.user;

    final hasChanges = (currentUser?.name != name) ||
        (currentUser?.email != email) ||
        newPass.isNotEmpty;

    if (hasChanges) {
      success = await auth.updateProfile(
        name: name,
        email: email,
        password: newPass.isNotEmpty ? newPass : null,
      );
    } else {
      success = true;
    }

    if (!mounted) return;

    setState(() => _isSaving = false);

    if (success) {
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _pickedImage = null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(l10n.profileUpdated),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _errorMessage = auth.errorMessage ?? l10n.profileUpdateFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final roleColor = Color(AppConfig.getRoleColor(user?.role ?? 'staff'));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ─── Sliver AppBar with avatar ───
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: colorScheme.surface,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back_rounded, size: 20, color: colorScheme.onSurface),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (!_isSaving)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(
                      onPressed: _save,
                      style: TextButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        l10n.saveChanges,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        roleColor.withValues(alpha: 0.15),
                        colorScheme.surface,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),

                      // ─── Avatar ───
                      GestureDetector(
                        onTap: _isSaving ? null : _pickImage,
                        child: Stack(
                          children: [
                            // Avatar circle
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: roleColor.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _pickedImage != null
                                    ? Image.file(_pickedImage!, fit: BoxFit.cover)
                                    : user?.avatarUrl != null
                                        ? Image.network(
                                            user!.avatarUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, e, st) => _buildInitialsAvatar(user, roleColor),
                                          )
                                        : _buildInitialsAvatar(user, roleColor),
                              ),
                            ),
                            // Camera badge
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.surface,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  color: colorScheme.onPrimary,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        l10n.editProfile,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.editProfileSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Form Body ───
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error banner
                      if (_errorMessage != null) ...[
                        _buildErrorBanner(_errorMessage!, colorScheme),
                        const SizedBox(height: 16),
                      ],

                      // ─── Personal Info Section ───
                      _buildSectionLabel(l10n.personalInfo, colorScheme),
                      const SizedBox(height: 12),

                      // Name field
                      _buildTextField(
                        controller: _nameController,
                        label: l10n.fullName,
                        hint: l10n.fullNameHint,
                        icon: Icons.person_rounded,
                        colorScheme: colorScheme,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.nameRequired
                            : null,
                      ),
                      const SizedBox(height: 14),

                      // Email field
                      _buildTextField(
                        controller: _emailController,
                        label: l10n.email,
                        hint: l10n.emailHint,
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        colorScheme: colorScheme,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.emailRequired;
                          }
                          if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) {
                            return l10n.validEmail;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 28),

                      // ─── Read-only Info ───
                      _buildSectionLabel('${l10n.personalInfo} — ${l10n.role}', colorScheme),
                      const SizedBox(height: 12),

                      _buildReadOnlyRow(
                        icon: Icons.verified_user_rounded,
                        label: l10n.role,
                        value: user?.displayRole ?? '-',
                        color: roleColor,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 10),
                      _buildReadOnlyRow(
                        icon: Icons.business_rounded,
                        label: l10n.department,
                        value: user?.departmentName ?? l10n.notAssigned,
                        color: colorScheme.secondary,
                        colorScheme: colorScheme,
                      ),

                      const SizedBox(height: 28),

                      // ─── Security Section ───
                      _buildSectionLabel(l10n.newPassword, colorScheme, icon: Icons.lock_rounded),
                      const SizedBox(height: 4),
                      Text(
                        l10n.newPasswordHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // New password
                      _buildPasswordField(
                        controller: _newPasswordController,
                        label: l10n.newPassword,
                        hint: l10n.newPasswordHint,
                        isVisible: _showNewPass,
                        onToggle: () => setState(() => _showNewPass = !_showNewPass),
                        colorScheme: colorScheme,
                        validator: (v) {
                          if (v != null && v.isNotEmpty && v.length < 6) {
                            return l10n.passwordMinLength;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm password
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: l10n.confirmPassword,
                        hint: l10n.confirmPassword,
                        isVisible: _showConfirmPass,
                        onToggle: () => setState(() => _showConfirmPass = !_showConfirmPass),
                        colorScheme: colorScheme,
                        validator: (v) {
                          if (_newPasswordController.text.isNotEmpty &&
                              v != _newPasswordController.text) {
                            return l10n.passwordsDoNotMatch;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 36),

                      // ─── Save Button ───
                      _isSaving
                          ? Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      l10n.savingChanges,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : FilledButton(
                              onPressed: _save,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.save_rounded, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.saveChanges,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      const SizedBox(height: 12),

                      // Cancel button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          foregroundColor: colorScheme.onSurfaceVariant,
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD HELPERS ───

  Widget _buildInitialsAvatar(User? user, Color roleColor) {
    return Container(
      color: roleColor,
      child: Center(
        child: Text(
          user?.initials ?? '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, ColorScheme colorScheme, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
        ] else ...[
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
    required ColorScheme colorScheme,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(Icons.lock_rounded, size: 20, color: colorScheme.onSurfaceVariant),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.lock_outline_rounded, size: 14, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colorScheme.onErrorContainer, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: colorScheme.onErrorContainer, size: 18),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
