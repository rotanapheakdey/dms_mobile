class AuditLog {
  final int id;
  final String action;
  final String notes;
  final String userName;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.action,
    required this.notes,
    required this.userName,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'],
      action: json['action'],
      notes: json['notes'],
      userName: json['user']['name'] ?? 'Unknown',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get displayAction => action.replaceAll('_', ' ').toUpperCase();
}