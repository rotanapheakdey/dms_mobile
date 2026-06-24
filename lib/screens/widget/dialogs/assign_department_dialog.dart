import 'package:flutter/material.dart';
import '../../../models/department.dart';
import '../../../l10n/app_localizations.dart';

class AssignDepartmentDialog extends StatefulWidget {
  final List<Department> departments;
  final Function(int, String?) onAssign;

  const AssignDepartmentDialog({
    super.key,
    required this.departments,
    required this.onAssign,
  });

  @override
  State<AssignDepartmentDialog> createState() => _AssignDepartmentDialogState();
}

class _AssignDepartmentDialogState extends State<AssignDepartmentDialog> {
  Department? _selectedDepartment;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),

      // ─── Header ───
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_ind_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.assignDepartmentTitle,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.assignDepartmentSubtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),

      // ─── Content ───
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ─── Department Picker ───
            Text(
              l10n.selectDepartment,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedDepartment != null
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                  width: _selectedDepartment != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surfaceContainerLowest,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Department>(
                  value: _selectedDepartment,
                  hint: Row(
                    children: [
                      Icon(Icons.business_rounded,
                          size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 10),
                      Text(
                        l10n.selectDepartment,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant),
                  dropdownColor: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  items: widget.departments.map((dept) {
                    return DropdownMenuItem<Department>(
                      value: dept,
                      child: Row(
                        children: [
                          Icon(Icons.business_outlined,
                              size: 16, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dept.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (dept) {
                    setState(() => _selectedDepartment = dept);
                  },
                ),
              ),
            ),

            // Selection confirmation chip
            if (_selectedDepartment != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      _selectedDepartment!.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ─── DG Note ───
            Text(
              l10n.dgNoteOptional,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.dgNoteOptional,
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                prefixIcon: Icon(Icons.edit_note_rounded,
                    color: colorScheme.onSurfaceVariant, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
      ),

      // ─── Actions ───
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
                child: Text(
                  l10n.cancel,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _selectedDepartment == null
                    ? null
                    : () {
                        final note = _noteController.text.trim().isEmpty
                            ? null
                            : _noteController.text.trim();
                        widget.onAssign(_selectedDepartment!.id, note);
                        Navigator.pop(context, {
                          'assigned_department_id': _selectedDepartment!.id,
                          'dg_note': note,
                        });
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.assign,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}