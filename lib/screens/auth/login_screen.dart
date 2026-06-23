import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // --- Animation Controllers ---
  late final AnimationController _entranceController;
  late final AnimationController _buttonController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _formFade;

  @override
  void initState() {
    super.initState();

    // Staggered entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Button press animation
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    // Logo: fade + scale (0% → 40%)
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    // Title: slide up + fade (20% → 60%)
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
    ));
    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
    );

    // Form card: slide up + fade (40% → 100%)
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    ));
    _formFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // --- Gradient Background ---
          _buildBackground(colorScheme, brightness),

          // --- Decorative Circles ---
          _buildDecorativeShapes(colorScheme, brightness, screenSize),

          // --- Main Content ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Animated Logo ---
                      _buildAnimatedLogo(colorScheme),
                      const SizedBox(height: 28),

                      // --- Animated Title ---
                      _buildAnimatedTitle(colorScheme),
                      const SizedBox(height: 36),

                      // --- Glassmorphism Form Card ---
                      _buildFormCard(authProvider, colorScheme, brightness),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Background Gradient
  // ─────────────────────────────────────────────
  Widget _buildBackground(ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF0D1117),
                  const Color(0xFF161B22),
                  const Color(0xFF0D1117),
                ]
              : [
                  const Color(0xFFF0F4FF),
                  const Color(0xFFE8EEFF),
                  const Color(0xFFF5F0FF),
                ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Decorative Floating Shapes
  // ─────────────────────────────────────────────
  Widget _buildDecorativeShapes(
      ColorScheme colorScheme, Brightness brightness, Size screenSize) {
    final isDark = brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned(
          top: -screenSize.height * 0.12,
          right: -screenSize.width * 0.2,
          child: Container(
            width: screenSize.width * 0.7,
            height: screenSize.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        colorScheme.primary.withValues(alpha: 0.08),
                        Colors.transparent,
                      ]
                    : [
                        colorScheme.primary.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -screenSize.height * 0.08,
          left: -screenSize.width * 0.25,
          child: Container(
            width: screenSize.width * 0.6,
            height: screenSize.width * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: isDark
                    ? [
                        colorScheme.tertiary.withValues(alpha: 0.06),
                        Colors.transparent,
                      ]
                    : [
                        colorScheme.tertiary.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Animated Logo
  // ─────────────────────────────────────────────
  Widget _buildAnimatedLogo(ColorScheme colorScheme) {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 10),
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }


  // ─────────────────────────────────────────────
  // Animated Title Section
  // ─────────────────────────────────────────────
  Widget _buildAnimatedTitle(ColorScheme colorScheme) {
    final l10n = context.l10n;
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleFade,
        child: Column(
          children: [
            Text(
              'Document\nManagement',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loginSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurfaceVariant,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Glassmorphism Form Card
  // ─────────────────────────────────────────────
  Widget _buildFormCard(
      AuthProvider authProvider, ColorScheme colorScheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    return SlideTransition(
      position: _formSlide,
      child: FadeTransition(
        opacity: _formFade,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.9),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Error Banner ---
                    _buildErrorBanner(authProvider, colorScheme),

                    // --- Email Input ---
                    _buildEmailField(colorScheme, isDark),
                    const SizedBox(height: 16),

                    // --- Password Input ---
                    _buildPasswordField(colorScheme, isDark),
                    const SizedBox(height: 16),

                    // --- Remember Me & Forgot Password ---
                    _buildRememberForgotRow(colorScheme),
                    const SizedBox(height: 28),

                    // --- Sign In Button ---
                    _buildSignInButton(authProvider, colorScheme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Animated Error Banner
  // ─────────────────────────────────────────────
  Widget _buildErrorBanner(AuthProvider authProvider, ColorScheme colorScheme) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: authProvider.errorMessage != null
          ? Padding(
              key: ValueKey(authProvider.errorMessage),
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.onErrorContainer,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        authProvider.errorMessage!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => authProvider.clearError(),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            color: colorScheme.onErrorContainer.withValues(alpha: 0.7),
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  // ─────────────────────────────────────────────
  // Email Text Field
  // ─────────────────────────────────────────────
  Widget _buildEmailField(ColorScheme colorScheme, bool isDark) {
    final l10n = context.l10n;
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: _buildInputDecoration(
        label: l10n.email,
        hint: l10n.emailHint,
        icon: Icons.alternate_email_rounded,
        colorScheme: colorScheme,
        isDark: isDark,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.emailRequired;
        if (!value.contains('@') || !value.contains('.')) {
          return l10n.validEmail;
        }
        return null;
      },
    );
  }

  // ─────────────────────────────────────────────
  // Password Text Field
  // ─────────────────────────────────────────────
  Widget _buildPasswordField(ColorScheme colorScheme, bool isDark) {
    final l10n = context.l10n;
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _handleLogin(),
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: _buildInputDecoration(
        label: l10n.password,
        hint: '••••••••',
        icon: Icons.lock_outline_rounded,
        colorScheme: colorScheme,
        isDark: isDark,
      ).copyWith(
        suffixIcon: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              key: ValueKey(_obscurePassword),
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return l10n.passwordRequired;
        if (value.length < 6) return l10n.passwordMinLength;
        return null;
      },
    );
  }

  // ─────────────────────────────────────────────
  // Remember Me & Forgot Password Row
  // ─────────────────────────────────────────────
  Widget _buildRememberForgotRow(ColorScheme colorScheme) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: _rememberMe,
            activeColor: colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            side: BorderSide(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              width: 1.5,
            ),
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Remember me',
          style: TextStyle(
            fontSize: 13.5,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Gradient Sign In Button with Press Animation
  // ─────────────────────────────────────────────
  Widget _buildSignInButton(
      AuthProvider authProvider, ColorScheme colorScheme) {
    final l10n = context.l10n;
    return GestureDetector(
      onTapDown: authProvider.isLoading
          ? null
          : (_) => _buttonController.forward(),
      onTapUp: authProvider.isLoading
          ? null
          : (_) {
              _buttonController.reverse();
              _handleLogin();
            },
      onTapCancel: authProvider.isLoading
          ? null
          : () => _buttonController.reverse(),
      child: AnimatedBuilder(
        animation: _buttonController,
        builder: (context, child) {
          final scale = 1.0 - (_buttonController.value * 0.03);
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: authProvider.isLoading
                  ? [
                      colorScheme.primary.withValues(alpha: 0.6),
                      colorScheme.primary.withValues(alpha: 0.5),
                    ]
                  : [
                      colorScheme.primary,
                      HSLColor.fromColor(colorScheme.primary)
                          .withLightness(
                            (HSLColor.fromColor(colorScheme.primary).lightness - 0.05)
                                .clamp(0.0, 1.0),
                          )
                          .toColor(),
                    ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: authProvider.isLoading
                ? []
                : [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: authProvider.isLoading
                  ? SizedBox(
                      key: const ValueKey('loader'),
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      key: const ValueKey('text'),
                      l10n.login,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Reusable Input Decoration
  // ─────────────────────────────────────────────
  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
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
      errorStyle: TextStyle(
        color: colorScheme.error,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
