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
  bool _isDownloading = false;

  Future<void> _handleAction(String endpoint, String successMsg, {Map<String, dynamic>? body}) async {
    final success = await context.read<DocumentProvider>().performAction(widget.document.id, endpoint, body: body);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      final error = context.read<DocumentProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error ?? 'Action failed'), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleDownload() async {
    setState(() => _isDownloading = true);
    final result = await ApiService.downloadAndOpenFile(widget.document.id, widget.document.title);
    if (!mounted) return;
    setState(() => _isDownloading = false);
    if (result['error'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleReportUpload() async {
    // 1. Initial File Selection Step
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

    // 2. Hard Stop Constraint: Catch heavy files early
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
          content: Text('The selected file "$fileName" is ${fileSizeInMB.toStringAsFixed(2)} MB.\n\nSystem security policies enforce a strict maximum limit of 10.00 MB per transmission.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go Back')),
          ],
        ),
      );
      return;
    }

    final reportNoteController = TextEditingController();
    
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
                const Text('Selected Attachment:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
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
                            Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('${fileSizeInMB.toStringAsFixed(2)} MB / 10.00 MB', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
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
              onPressed: () {
                reportNoteController.dispose();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Submit to VDG'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context); 
                
                setState(() => context.read<DocumentProvider>().isLoading = true);
                
                final uploadResult = await ApiService.uploadReport(widget.document.id, file);
                
                if (!mounted) return;
                setState(() => context.read<DocumentProvider>().isLoading = false);
                reportNoteController.dispose();

                if (uploadResult['error'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploadResult['message']), backgroundColor: Colors.red));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action report officially submitted to VDG!'), backgroundColor: Colors.green));
                  await context.read<DocumentProvider>().fetchUrgentFeed();
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final doc = widget.document;
    final isActionLoading = context.watch<DocumentProvider>().isLoading;
print("DEBUG RAW DOCUMENT RELATIONSHIPS: uploader=${doc.uploader}, department=${doc.department}");
    return Scaffold(
      appBar: AppBar(title: const Text('Document Details')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Control No: ${doc.controlNo}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const Divider(height: 32),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.person), title: const Text('Uploaded By'), subtitle: Text(doc.uploader?['name'] ?? 'Unknown')),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.business), title: const Text('Assigned Department'), subtitle: Text(doc.department?['name'] ?? 'Unassigned')),
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today), title: const Text('Creation Date'), subtitle: Text(doc.createdAt.split('T')[0])),
                const SizedBox(height: 24),
                if (doc.filePath != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isDownloading ? null : _handleDownload,
                      icon: _isDownloading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.download),
                      label: Text(_isDownloading ? 'Downloading...' : 'View Attached File'),
                    ),
                  ),
                const Spacer(),
                
                // Dedicated, clean separate button module
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
          if (isActionLoading) Container(color: Colors.black.withOpacity(0.3), child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}