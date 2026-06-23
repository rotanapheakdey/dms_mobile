import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSearch;
  final VoidCallback? onClear;
  final String hint;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.onSearch,
    this.onClear,
    this.hint = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // ─── Text Field ───
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch?.call(),
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 15,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),

              // Search Icon (Left)
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(
                  Icons.search_rounded,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),

              // Clear Button (Right) — only shows when text is present
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.cancel_rounded,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      onPressed: () {
                        controller.clear();
                        onClear?.call();
                      },
                      splashRadius: 20,
                    ),
                  );
                },
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
          ),
        ),

        // ─── Search Button ───
        const SizedBox(width: 10),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            final hasText = value.text.isNotEmpty;
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: hasText ? 1.0 : 0.4,
              child: FilledButton(
                onPressed: hasText ? onSearch : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size(0, 52),
                ),
                child: const Icon(Icons.search_rounded, size: 20),
              ),
            );
          },
        ),
      ],
    );
  }
}