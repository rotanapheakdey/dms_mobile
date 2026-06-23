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
  int? _selectedDepartmentId;
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: l10n.selectDepartment,
                prefixIcon: Icon(Icons.business_rounded, color: colorScheme.onSurfaceVariant, size: 22),
              ),
              initialValue: _selectedDepartmentId,
              hint: Text(l10n.selectDepartment),
              isExpanded: true,
              items: widget.departments.isEmpty
                  ? []
                  : widget.departments.map((dept) {
                      return DropdownMenuItem<int>(
                        value: dept.id,
                        child: Text(dept.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
              onChanged: (value) => setState(() => _selectedDepartmentId = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.dgNoteOptional,
                prefixIcon: Icon(Icons.edit_note_rounded, color: colorScheme.onSurfaceVariant, size: 22),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
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
                onPressed: _selectedDepartmentId == null
                    ? null
                    : () {
                        final note = _noteController.text.trim().isEmpty
                            ? null
                            : _noteController.text.trim();
                        widget.onAssign(_selectedDepartmentId!, note);
                        Navigator.pop(context, {
                          'assigned_department_id': _selectedDepartmentId!,
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