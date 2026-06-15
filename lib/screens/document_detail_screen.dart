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
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      if (await file.length() > 10485760) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File exceeds 10MB limit'), backgroundColor: Colors.red));
        return;
      }
      setState(() => context.read<DocumentProvider>().isLoading = true);
      final uploadResult = await ApiService.uploadReport(widget.document.id, file);
      if (!mounted) return;
      setState(() => context.read<DocumentProvider>().isLoading = false);

      if (uploadResult['error'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(uploadResult['message']), backgroundColor: Colors.red));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action report uploaded successfully!'), backgroundColor: Colors.green));
        await context.read<DocumentProvider>().fetchUrgentFeed();
        Navigator.pop(context);
      }
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