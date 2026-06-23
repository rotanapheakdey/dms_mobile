import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/document.dart';
import '../../providers/auth_provider.dart';
import '../../providers/document_provider.dart';
import '../../services/document_service.dart';
import '../../l10n/app_localizations.dart';
import '../widget/dialogs/assign_department_dialog.dart';
import '../widget/dialogs/dispatch_dialog.dart';
import '../widget/dialogs/report_upload_dialog.dart';
import '../widget/common/loading_indicator.dart';
import '../widget/common/status_badge.dart';
import '../widget/document/document_action_buttons.dart';
import '../widget/document/document_status_timeline.dart';

class DocumentDetailScreen extends StatefulWidget {
  final int documentId;
  const DocumentDetailScreen({super.key, required this.documentId});

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  Document? _document;
  bool _isLoading = true;
  String? _error;

  final DocumentService _service = DocumentService();

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final doc = await _service.getDocument(widget.documentId);
      if (doc != null) {
        setState(() => _document = doc);
      } else {
        setState(() => _error = 'Document not found');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load document');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDocument() async {
    await _loadDocument();
  }

  // ─── DOWNLOAD FILE ───
  Future<void> _downloadFile() async {
    if (_document == null) return;
    final l10n = context.l10n;
    try {
      final result = await _service.downloadFile(_document!.id);
      if (result['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(l10n.downloadSuccess),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? l10n.downloadFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.downloadFailed}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // ─── SHOW ASSIGN DIALOG ───
  Future<void> _showAssignDialog(BuildContext context, int documentId) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final l10n = context.l10n;
    final docProvider = Provider.of<DocumentProvider>(context, listen: false);
    await docProvider.loadDepartments();
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (_) => AssignDepartmentDialog(
        departments: docProvider.departments,
        onAssign: (deptId, note) {},
      ),
    );

    if (result != null && mounted) {
      final success = await _service.assignDocument(
        id: documentId,
        departmentId: result['assigned_department_id'],
        note: result['dg_note'],
      );

      if (success == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(l10n.assignSuccess),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _refreshDocument();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(success), backgroundColor: errorColor),
        );
      }
    }
  }

  // ─── SHOW DISPATCH DIALOG ───
  Future<void> _showDispatchDialog(BuildContext context, int documentId) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final l10n = context.l10n;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => DispatchDialog(onDispatch: (comment) {}),
    );

    if (result != null && mounted) {
      final error = await _service.dispatchDocument(
        id: documentId,
        comment: result,
      );

      if (error == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(l10n.dispatchSuccess),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _refreshDocument();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: errorColor),
        );
      }
    }
  }

  // ─── SHOW REPORT UPLOAD DIALOG ───
  Future<void> _showReportUploadDialog(
    BuildContext context,
    int documentId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final l10n = context.l10n;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => ReportUploadDialog(onUpload: (filePath) {}),
    );

    if (result != null && mounted) {
      final error = await _service.uploadReport(
        id: documentId,
        filePath: result,
      );

      if (error == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(l10n.reportUploadSuccess),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _refreshDocument();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: errorColor),
        );
      }
    }
  }

  // ─── SIGN VDG ───
  Future<void> _signVDG(int documentId) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.signAsVDG),
        content: Text(l10n.signAsVDGContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.sign),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final error = await _service.signDocument(documentId, true);

      if (error == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(l10n.signAsVDGSuccess),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _refreshDocument();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  // ─── SIGN DG ───
  Future<void> _signDG(int documentId) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.signAsDG),
        content: Text(l10n.signAsDGContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: Text(l10n.sign),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final error = await _service.signDocument(documentId, false);

      if (error == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(l10n.signAsDGSuccess),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _refreshDocument();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  // ─── ARCHIVE DOCUMENT ───
  Future<void> _archiveDocument(int documentId) async {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.archiveTitle),
        content: Text(l10n.archiveContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: Text(l10n.archive),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final error = await _service.archiveDocument(documentId);

      if (error == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text(l10n.archiveSuccess),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _refreshDocument();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(title: Text(context.l10n.documentDetail)),
        body: LoadingIndicator(message: context.l10n.loading),
      );
    }

    if (_error != null || _document == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(title: Text(context.l10n.documentDetail)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _error ?? context.l10n.documentNotFound,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.goBack,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _loadDocument,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final doc = _document!;


    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(context.l10n.documentDetail),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _downloadFile,
            tooltip: context.l10n.downloadFile,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshDocument,
            tooltip: context.l10n.refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDocument,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header Card ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            doc.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        StatusBadge(status: doc.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        doc.controlNo,
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Details Card ───
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.documentDetails,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.person_outline_rounded, context.l10n.uploadedBy, doc.uploaderName ?? context.l10n.unassigned, colorScheme),
                    _buildInfoRow(Icons.business_outlined, context.l10n.department, doc.departmentName ?? context.l10n.unassigned, colorScheme),
                    _buildInfoRow(Icons.calendar_today_rounded, context.l10n.createdAt, _formatDateTime(doc.createdAt), colorScheme),
                    _buildInfoRow(Icons.update_rounded, context.l10n.updatedAt, _formatDateTime(doc.updatedAt), colorScheme, isLast: true),
                  ],
                ),
              ),

              // ─── Comment Section ───
              if (doc.comment != null && doc.comment!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 18, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.comment,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        doc.comment!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ─── Status Timeline ───
              DocumentStatusTimeline(document: doc),

              const SizedBox(height: 24),

              // ─── Action Buttons ───
              DocumentActionButtons(
                document: doc,
                userRole: user?.role,
                onAssign: () => _showAssignDialog(context, doc.id),
                onDispatch: () => _showDispatchDialog(context, doc.id),
                onUploadReport: () => _showReportUploadDialog(context, doc.id),
                onVDGSign: () => _signVDG(doc.id),
                onDGSign: () => _signDG(doc.id),
                onArchive: () => _archiveDocument(doc.id),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── INFO ROW ───
  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme colorScheme, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
