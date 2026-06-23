import 'package:flutter/material.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onOk;
  final String buttonText;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.onOk,
    this.buttonText = 'Done', // "Done" or "Awesome" feels more modern than "OK"
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Using a refined green to universally signify success, 
    // while adapting to dark/light mode opacities.
    final successColor = Colors.green.shade600;
    final successBackground = Colors.green.withValues(alpha: 0.15);

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Smooth, modern rounded corners
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      
      // --- Premium Centered Header ---
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: successBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: successColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),

      // --- Subtle Centered Content ---
      content: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),

      // --- Full-Width Modern Button ---
      actions: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onOk?.call();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.primary, // Keeps the button tied to your app's theme
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Helper Method ---
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onOk,
    String buttonText = 'Done',
  }) async {
    await showDialog(
      context: context,
      builder: (_) => SuccessDialog(
        title: title,
        message: message,
        onOk: onOk,
        buttonText: buttonText,
      ),
    );
  }
}