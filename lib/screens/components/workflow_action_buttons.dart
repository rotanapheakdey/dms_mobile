import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../models/document.dart';
import 'assign_department_dialog.dart';

import '../../utils/dialog_helper.dart';

class WorkflowActionButtons extends StatelessWidget {
  final Document document;
  final String? userRole;
  final Function(String endpoint, String message, {Map<String, dynamic>? body})
  onActionTriggered;
  final VoidCallback onUploadReportTriggered;

  const WorkflowActionButtons({
    super.key,
    required this.document,
    required this.userRole,
    required this.onActionTriggered,
    required this.onUploadReportTriggered,
  });
  Future<void> _showDispatchDialog(BuildContext context) async {
    final noteController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dispatch Document'),
          content: TextFormField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Dispatch Note (Optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close input layout

                // Prompt confirmation
                final confirm = await DialogHelper.showConfirmation(
                  context: context,
                  title: 'Confirm Dispatch',
                  content:
                      'Are you sure you want to officially forward this document to the assigned department workspace?',
                  confirmLabel: 'Dispatch',
                  icon: Icons.send_rounded,
                );

                if (confirm) {
                  onActionTriggered(
                    'dispatch',
                    'Document officially dispatched!',
                    body: noteController.text.trim().isNotEmpty
                        ? {'dispatch_note': noteController.text.trim()}
                        : null,
                  );
                }
              },
              child: const Text('Confirm Dispatch'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = document.status;

    // Phase 2: Assign (DG role only) - Back to one-tap confirmation!
    if (status == 'pending_dg_init' && userRole == 'dg') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.assignment_ind),
        label: const Text('Assign Department'),
        onPressed: () async {
          final selection = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (_) => const AssignDepartmentDialog(),
          );
          
          if (selection != null) {
            onActionTriggered('direct', 'Document directed. Official template generated!', body: selection);
          }
        },
      );
    }

    // Phase 3: Dispatch (File Dept)
    if (status == 'pending_dispatch' && userRole == 'file_dept') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.send),
        label: const Text('Dispatch to Department'),
        onPressed: () => _showDispatchDialog(context),
      );
    }

    // Phase 4: Upload Action Work (Staff/Dept)
    if (status == 'dg_directed' &&
        (userRole == 'department' || userRole == 'staff')) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload Action Report'),
        onPressed: onUploadReportTriggered,
      );
    }

    // Phase 5: VDG Verification Sign
    if (status == 'pending_vdg_approval' && userRole == 'vdg') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.draw),
        label: const Text('Sign Report (VDG)'),
        onPressed: () =>
            onActionTriggered('vdg-sign', 'Signed and verified by VDG!'),
      );
    }

    // Phase 6: DG Final Administrative Sign
    if (status == 'pending_dg_approval' && userRole == 'dg') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.verified),
        label: const Text('Apply Final Signature'),
        onPressed: () async {
          final confirm = await DialogHelper.showConfirmation(
            context: context,
            title: 'Apply Executive Signature',
            content: 'Are you sure you want to apply your digital administrative sign-off to this action report?',
            confirmLabel: 'Apply Signature',
            confirmColor: Colors.green.shade700,
            icon: Icons.draw,
          );
          
          if (confirm) {
            onActionTriggered('dg-sign', 'Document final-signed by DG!');
          }
        },
      );
    }

    // Phase 7: Permanent Storage Archive (File Dept)
    if (status == 'dg_signed' && userRole == 'file_dept') {
      return ElevatedButton.icon(
        icon: const Icon(Icons.archive),
        label: const Text('Archive Document permanently'),
        onPressed: () => onActionTriggered(
          'archive',
          'Document locked and safely archived!',
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
