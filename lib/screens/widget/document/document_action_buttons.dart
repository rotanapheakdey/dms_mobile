import 'package:flutter/material.dart';
import 'package:dms_mobile/models/document.dart';

class DocumentActionButtons extends StatelessWidget {
  final Document document;
  final String? userRole;
  final VoidCallback onAssign;
  final VoidCallback onDispatch;
  final VoidCallback onUploadReport;
  final VoidCallback onVDGSign;
  final VoidCallback onDGSign;
  final VoidCallback onArchive;

  const DocumentActionButtons({
    super.key,
    required this.document,
    required this.userRole,
    required this.onAssign,
    required this.onDispatch,
    required this.onUploadReport,
    required this.onVDGSign,
    required this.onDGSign,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final status = document.status;
    final colorScheme = Theme.of(context).colorScheme;

    if (status == 'pending_dg_init' && userRole == 'dg') {
      return _buildActionButton(
        context,
        label: 'Assign Department',
        icon: Icons.assignment_rounded,
        onPressed: onAssign,
        color: colorScheme.primary,
      );
    }

    if (status == 'pending_dispatch' && userRole == 'file_dept') {
      return _buildActionButton(
        context,
        label: 'Dispatch',
        icon: Icons.send_rounded,
        onPressed: onDispatch,
        color: Colors.orange.shade700,
      );
    }

    if (status == 'dg_directed' && (userRole == 'department' || userRole == 'staff')) {
      return _buildActionButton(
        context,
        label: 'Upload Report',
        icon: Icons.upload_file_rounded,
        onPressed: onUploadReport,
        color: Colors.teal.shade600,
      );
    }

    if (status == 'pending_vdg_approval' && userRole == 'vdg') {
      return _buildActionButton(
        context,
        label: 'Sign (VDG)',
        icon: Icons.draw_rounded,
        onPressed: onVDGSign,
        color: Colors.purple.shade600,
      );
    }

    if (status == 'pending_dg_approval' && userRole == 'dg') {
      return _buildActionButton(
        context,
        label: 'Sign (DG)',
        icon: Icons.verified_rounded,
        onPressed: onDGSign,
        color: Colors.green.shade600,
      );
    }

    if (status == 'dg_signed' && userRole == 'file_dept') {
      return _buildActionButton(
        context,
        label: 'Archive',
        icon: Icons.archive_rounded,
        onPressed: onArchive,
        color: Colors.blueGrey.shade600,
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}