class Document {
  final int id;
  final String controlNo;
  final String title;
  final String status;
  final String? filePath;
  final Map<String, dynamic>? uploader;
  final Map<String, dynamic>? department;
  final String createdAt;

  Document({
    required this.id,
    required this.controlNo,
    required this.title,
    required this.status,
    this.filePath,
    this.uploader,
    this.department,
    required this.createdAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      title: json['title'],
      controlNo: json['control_no'],
      status: json['status'],
      filePath: json['file_path'],
      createdAt: json['created_at'],
      uploader: json['uploader'] ?? json['user'], 
      department: json['assigned_department'] ?? json['department'],
    );
  }
}