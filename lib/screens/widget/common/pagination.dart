import 'dart:math';
import 'package:flutter/material.dart';

class Pagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const Pagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    // --- Smart Sliding Window Logic ---
    // Shows a max of 5 pages, keeping the current page centered when possible.
    int startPage = max(1, currentPage - 2);
    int endPage = min(totalPages, startPage + 4);
    
    // Adjust start page if we hit the end of the list
    if (endPage - startPage < 4) {
      startPage = max(1, endPage - 4);
    }

    final pages = List.generate(endPage - startPage + 1, (index) => startPage + index);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- Previous Arrow ---
          _buildNavArrow(
            icon: Icons.chevron_left_rounded,
            isEnabled: currentPage > 1,
            onTap: () => onPageChanged(currentPage - 1),
            colorScheme: colorScheme,
          ),
          
          const SizedBox(width: 8),

          // --- Page Numbers ---
          ...pages.map((pageNumber) {
            final isSelected = pageNumber == currentPage;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildPageIndicator(
                pageNumber: pageNumber,
                isSelected: isSelected,
                onTap: () => onPageChanged(pageNumber),
                colorScheme: colorScheme,
              ),
            );
          }),

          const SizedBox(width: 8),

          // --- Next Arrow ---
          _buildNavArrow(
            icon: Icons.chevron_right_rounded,
            isEnabled: currentPage < totalPages,
            onTap: () => onPageChanged(currentPage + 1),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildNavArrow({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return IconButton(
      onPressed: isEnabled ? onTap : null,
      style: IconButton.styleFrom(
        backgroundColor: isEnabled 
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.transparent,
        foregroundColor: isEnabled 
            ? colorScheme.onSurfaceVariant 
            : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon, size: 22),
    );
  }

  Widget _buildPageIndicator({
    required int pageNumber,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          shape: BoxShape.circle,
          // Add a subtle border to unselected items for depth
          border: isSelected 
              ? null 
              : Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            pageNumber.toString(),
            style: TextStyle(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}