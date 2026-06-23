import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../l10n/app_localizations.dart';
import '../widget/common/loading_indicator.dart';
import '../../utils/validation.dart';

class DocumentUploadScreen extends StatefulWidget {
  const DocumentUploadScreen({super.key});

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();

  File? _selectedFile;
  String? _fileName;
  int? _fileSize;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final size = await file.length();

        // Validate file size (10MB max)
        final sizeError = Validation.validateFileSize(size, 10);
        if (sizeError != null) {
          setState(() {
            _errorMessage = sizeError;
            _selectedFile = null;
            _fileName = null;
            _fileSize = null;
          });
          return;
        }

        setState(() {
          _selectedFile = file;
          _fileName = result.files.single.name;
          _fileSize = size;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _fileName = null;
      _fileSize = null;
      _errorMessage = null;
    });
  }

  Future<void> _submitUpload() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;

    if (_selectedFile == null) {
      setState(() => _errorMessage = l10n.noFileChosen);
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final docProvider = context.read<DocumentProvider>();
      final success = await docProvider.uploadDocument(
        title: _titleController.text.trim(),
        filePath: _selectedFile!.path,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );

      if (success) {
        setState(() {
          _successMessage = l10n.uploadSuccess;
          _isUploading = false;
        });

        // Brief delay so user sees success message before popping
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(() {
          _errorMessage = docProvider.errorMessage ?? l10n.uploadFailed;
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = context.l10n.error;
        _isUploading = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Check permission early
    if (!auth.canUpload) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(context.l10n.uploadDocument),
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 72, color: colorScheme.error.withValues(alpha: 0.5)),
                const SizedBox(height: 24),
                Text(
                  context.l10n.accessDenied,
                  style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.noPermissionUpload,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.goBack),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.newDocument, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LoadingIndicator(),
                  const SizedBox(height: 16),
                  Text(context.l10n.uploading, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Status Banners ---
                    if (_errorMessage != null)
                      _buildBanner(
                        colorScheme.errorContainer,
                        colorScheme.onErrorContainer,
                        Icons.error_outline_rounded,
                        _errorMessage!,
                        isError: true,
                      ),
                    if (_successMessage != null)
                      _buildBanner(
                        colorScheme.primaryContainer,
                        colorScheme.onPrimaryContainer,
                        Icons.check_circle_outline_rounded,
                        _successMessage!,
                        isError: false,
                      ),
                    if (_errorMessage != null || _successMessage != null) const SizedBox(height: 24),

                    // --- Form Inputs ---
                    Text(
                      context.l10n.documentDetails,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(
                        hint: context.l10n.documentTitleHint,
                        icon: Icons.title_rounded,
                        colorScheme: colorScheme,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? context.l10n.documentTitleRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      decoration: _buildInputDecoration(
                        hint: context.l10n.commentHint,
                        icon: Icons.notes_rounded,
                        colorScheme: colorScheme,
                      ).copyWith(alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 32),

                    // --- File Upload Zone ---
                    Text(
                      context.l10n.fileAttachment,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildFilePicker(colorScheme, textTheme),
                    const SizedBox(height: 48),

                    // --- Action Buttons ---
                    FilledButton(
                      onPressed: _selectedFile == null ? null : _submitUpload,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        context.l10n.uploadDocument,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(context.l10n.cancel, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- UI Helpers ---

  Widget _buildBanner(Color bgColor, Color textColor, IconData icon, String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
          ),
          if (isError)
            InkWell(
              onTap: () => setState(() => _errorMessage = null),
              child: Icon(Icons.close_rounded, color: textColor.withValues(alpha: 0.7), size: 18),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorScheme.error, width: 1.8),
      ),
    );
  }

  Widget _buildFilePicker(ColorScheme colorScheme, TextTheme textTheme) {
    final hasFile = _selectedFile != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: hasFile
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasFile
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: _pickFile,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: hasFile
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getFileIcon(_fileName ?? ''), color: colorScheme.onPrimary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName ?? 'Unknown',
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFileSize(_fileSize ?? 0),
                            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
                      onPressed: _clearFile,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_rounded,
                      size: 48,
                      color: colorScheme.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.tapToBrowse,
                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.supportedFormats,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
