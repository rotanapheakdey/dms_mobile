import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/document_provider.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  
  File? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      
      final fileSize = await file.length();
      if (fileSize > 10485760) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File exceeds 10MB limit'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        _selectedFile = file;
      });
    }
  }

  Future<void> _submitUpload() async {
    if (_formKey.currentState!.validate() && _selectedFile != null) {
      setState(() => _isUploading = true);

      final result = await ApiService.uploadDocument(
        title: _titleController.text.trim(),
        file: _selectedFile!,
        comment: _commentController.text.trim(),
      );

      setState(() => _isUploading = false);

      if (!mounted) return;

      if (result.containsKey('error') && result['error'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully!'), backgroundColor: Colors.green),
        );
        context.read<DocumentProvider>().fetchUrgentFeed();
        Navigator.pop(context); 
      }
    } else if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to upload.'), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Document')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.blue.withOpacity(0.05),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.upload_file, size: 48, color: _selectedFile != null ? Colors.green : Colors.blue),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFile != null 
                            ? _selectedFile!.path.split('/').last 
                            : 'Tap to select PDF or Word Document (Max 10MB)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedFile != null ? Colors.green : Colors.black87,
                            fontWeight: _selectedFile != null ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'File Department Comment (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 32),

                // Upload Button
                ElevatedButton(
                  onPressed: _isUploading ? null : _submitUpload,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isUploading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('UPLOAD DOCUMENT', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}