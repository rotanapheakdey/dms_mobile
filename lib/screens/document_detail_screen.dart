import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../models/document.dart';
import '../providers/auth_provider.dart';
import '../providers/document_provider.dart';
import '../services/api_service.dart';
import 'components/workflow_action_buttons.dart';

class DocumentDetailScreen extends StatefulWidget {
  final Document document;
  const DocumentDetailScreen({super.key, required this.document});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  // Distinct loading states for the split file views
  bool _isDownloading = false;
  bool _isDownloadingDirective = false;

  Future<void> _handleAction(
    String endpoint,
    String successMsg, {
    Map<String, dynamic>? body,
  }) async {
    setState(() => context.read<DocumentProvider>().isLoading = true);

    final result = await ApiService.call(
      'POST',
      '/documents/${widget.document.id}/$endpoint',
      body: body,
    );

    if (!mounted) return;
    setState(() => context.read<DocumentProvider>().isLoading = false);

    if (result['error'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg), backgroundColor: Colors.green),
      );
      await context.read<DocumentProvider>().fetchUrgentFeed();
      Navigator.pop(context);
    }
  }

  // --- PRIMARY FILE DOWNLOAD ---
  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    
    final result = await ApiService.downloadAndOpenFile(
      widget.document.id,
      widget.document.title,
    );
    
    if (!mounted) return;
    setState(() => _isDownloading = false);
    
    if (result['error'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  // --- SECONDARY DIRECTIVE DOWNLOAD ---
  Future<void> _handleDirectiveDownload() async {
    setState(() => _isDownloadingDirective = true);
    
    // We pass a custom title and the isDirective flag to the API service
    final result = await ApiService.downloadAndOpenFile(
      widget.document.id,
      '${widget.document.controlNo}_DG_Directive',
      isDirective: true, 
    );
    
    if (!mounted) return;
    setState(() => _isDownloadingDirective = false);
    
    if (result['error'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  // --- ACTION REPORT UPLOAD (With Lifecycle Deadlock Fix) ---
  Future<void> _handleReportUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result == null || result.files.single.path == null) return;

    File file = File(result.files.single.path!);
    int fileSizeBytes = await file.length();
    double fileSizeInMB = fileSizeBytes / (1024 * 1024);
    String fileName = result.files.single.name;

    if (!mounted) return;

    if (fileSizeBytes > 10485760) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('File Too Heavy'),
            ],
          ),
          content: Text(
            'The selected file "$fileName" is ${fileSizeInMB.toStringAsFixed(2)} MB.\n\nSystem security policies enforce a strict maximum limit of 10.00 MB per transmission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
      return;
    }

    final reportNoteController = TextEditingController();
    final docProvider = context.read<DocumentProvider>();
    bool shouldSubmit = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Review Action Report'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Attachment:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '${fileSizeInMB.toStringAsFixed(2)} MB / 10.00 MB',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: reportNoteController,
                  decoration: const InputDecoration(
                    labelText: 'Report Description / Notes (Optional)',
                    border: OutlineInputBorder(),
                    hintText: 'Add an executive summary for the VDG...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Submit to VDG'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                shouldSubmit = true;
                Navigator.pop(context); // Close dialog BEFORE firing async request
              },
            ),
          ],
        );
      },
    );

    // Execute upload safely outside the dialog layout tree
    if (shouldSubmit) {
      try {
        setState(() => docProvider.isLoading = true);

        final uploadResult = await ApiService.uploadReport(widget.document.id, file);

        if (!mounted) return;

        if (uploadResult['error'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(uploadResult['message']), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Action report officially submitted to VDG!'), backgroundColor: Colors.green),
          );
          await docProvider.fetchUrgentFeed();
          Navigator.pop(context);
        }
      } finally {
        if (mounted) setState(() => docProvider.isLoading = false);
        reportNoteController.dispose();
      }
    } else {
      reportNoteController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final doc = widget.document;
    final isActionLoading = context.watch<DocumentProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Document Details')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Control No: ${doc.controlNo}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person),
                  title: const Text('Uploaded By'),
                  subtitle: Text(doc.uploader?['name'] ?? 'Unknown'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.business),
                  title: const Text('Assigned Department'),
                  subtitle: Text(doc.department?['name'] ?? 'Unassigned'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Creation Date'),
                  subtitle: Text(doc.createdAt.split('T')[0]),
                ),
                const SizedBox(height: 24),

                // --- SLOT 1: THE PRIMARY INCOMING FILE ---
                if (doc.filePath != null) ...[
                  const Text(
                    'Primary Document:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isDownloading ? null : _handleDownload,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf, color: Colors.red),
                      label: Text(_isDownloading ? 'Downloading Primary...' : 'View Primary Attachment'),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // --- SLOT 2: THE SECONDARY DG DIRECTIVE TEMPLATE ---
                if (doc.status != 'pending_dg_init') ...[
                  const Text(
                    'Executive Assignment Directive:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DG_Assignment_Directive.pdf',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                'Includes digital signature and official ministerial seal.',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        // Active Download Trigger Button
                        IconButton(
                          icon: _isDownloadingDirective
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                                )
                              : const Icon(Icons.remove_red_eye, color: Colors.blue),
                          onPressed: _isDownloadingDirective ? null : _handleDirectiveDownload,
                        ),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: WorkflowActionButtons(
                    document: doc,
                    userRole: user?['role'],
                    onActionTriggered: _handleAction,
                    onUploadReportTriggered: _handleReportUpload,
                  ),
                ),
              ],
            ),
          ),
          if (isActionLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}