import 'package:flutter/material.dart';
import '../../../config/app_config.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    // Fetch the base color from your config, default to a neutral grey
    final baseColor = Color(AppConfig.statusColors[status] ?? 0xFF9E9E9E);
    
    // Clean up the text: e.g., "pending_dispatch" -> "PENDING DISPATCH"
    final displayText = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 10 : 16,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        // 1. Soft Translucent Background
        color: baseColor.withValues(alpha: 0.15),
        // 2. Modern Pill Shape
        borderRadius: BorderRadius.circular(24),
        // 3. Crisp Outline
        border: Border.all(
          color: baseColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          // 4. Colored text instead of plain white
          color: baseColor, 
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w800, // Extra bold to maintain readability on the soft background
          letterSpacing: 0.6, // Wider tracking looks fantastic on ALL CAPS badges
        ),
      ),
    );
  }
}