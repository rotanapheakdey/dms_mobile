class Document {
  final int id;
  final String controlNo;
  final String title;
  final String status;
  final String? filePath;
  final String? reportPath;
  final String? comment;
  final String? uploaderName;
  final String? departmentName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Document({
    required this.id,
    required this.controlNo,
    required this.title,
    required this.status,
    this.filePath,
    this.reportPath,
    this.comment,
    this.uploaderName,
    this.departmentName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      controlNo: json['control_no'],
      title: json['title'],
      status: json['status'],
      filePath: json['file_path'],
      reportPath: json['report_path'],
      comment: json['file_dept_comment'],
      uploaderName: json['uploader']?['name'],
      departmentName: json['department']?['name'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get displayStatus => status.replaceAll('_', ' ').toUpperCase();

  bool get isPendingDGInit => status == 'pending_dg_init';
  bool get isPendingDispatch => status == 'pending_dispatch';
  bool get isDGDirected => status == 'dg_directed';
  bool get isPendingVDGApproval => status == 'pending_vdg_approval';
  bool get isPendingDGApproval => status == 'pending_dg_approval';
  bool get isDGSigned => status == 'dg_signed';
  bool get isArchived => status == 'completed_archive';

  int getStatusColor() {
    const colors = {
      'pending_dg_init': 0xFFE53935,
      'pending_dispatch': 0xFFFB8C00,
      'dg_directed': 0xFF1E88E5,
      'pending_vdg_approval': 0xFF8E24AA,
      'pending_dg_approval': 0xFFFFB300,
      'dg_signed': 0xFF43A047,
      'completed_archive': 0xFF757575,
    };
    return colors[status] ?? 0xFF757575;
  }
}