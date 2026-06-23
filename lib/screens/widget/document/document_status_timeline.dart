import 'package:flutter/material.dart';
import '../../../models/document.dart';

class DocumentStatusTimeline extends StatelessWidget {
  final Document document;

  const DocumentStatusTimeline({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final statuses = [
      {'status': 'pending_dg_init', 'label': 'Uploaded', 'desc': 'Document entered the system', 'icon': Icons.cloud_upload_rounded},
      {'status': 'pending_dispatch', 'label': 'Assigned', 'desc': 'Awaiting department assignment', 'icon': Icons.assignment_ind_rounded},
      {'status': 'dg_directed', 'label': 'Dispatched', 'desc': 'Sent to respective department', 'icon': Icons.send_rounded},
      {'status': 'pending_vdg_approval', 'label': 'Reported', 'desc': 'Action report uploaded', 'icon': Icons.summarize_rounded},
      {'status': 'pending_dg_approval', 'label': 'VDG Signed', 'desc': 'Approved by Vice Director', 'icon': Icons.draw_rounded},
      {'status': 'dg_signed', 'label': 'DG Signed', 'desc': 'Final approval granted', 'icon': Icons.verified_rounded},
      {'status': 'completed_archive', 'label': 'Archived', 'desc': 'Stored securely in records', 'icon': Icons.archive_rounded},
    ];

    int currentIndex = statuses.indexWhere((s) => s['status'] == document.status);
    if (currentIndex == -1) currentIndex = statuses.length - 1;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tracking Status',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;
            final isFuture = index > currentIndex;
            final isLast = index == statuses.length - 1;

            return _buildTimelineNode(
              context,
              item: item,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isFuture: isFuture,
              isLast: isLast,
              colorScheme: colorScheme,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(
    BuildContext context, {
    required Map<String, dynamic> item,
    required bool isCompleted,
    required bool isCurrent,
    required bool isFuture,
    required bool isLast,
    required ColorScheme colorScheme,
  }) {
    // Determine colors based on state
    final iconColor = isFuture ? colorScheme.onSurfaceVariant : colorScheme.onPrimary;
    final nodeColor = isFuture ? colorScheme.surfaceContainerHighest : colorScheme.primary;
    final lineColor = isCompleted ? colorScheme.primary : colorScheme.surfaceContainerHighest;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- LEFT COLUMN: Timeline Graphic ---
          Column(
            children: [
              // The Node
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: colorScheme.primaryContainer, width: 4)
                      : null,
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    isCompleted ? Icons.check_rounded : item['icon'] as IconData,
                    size: 18,
                    color: iconColor,
                  ),
                ),
              ),
              // The Connecting Line
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: lineColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // --- RIGHT COLUMN: Content Card ---
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24), // Space between cards
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCurrent ? colorScheme.surfaceContainerHighest : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isCurrent 
                      ? Border.all(color: colorScheme.outlineVariant)
                      : Border.all(color: Colors.transparent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['label'] as String,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isFuture
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['desc'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isFuture
                                ? colorScheme.onSurfaceVariant.withValues(alpha: 0.7)
                                : colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
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
}