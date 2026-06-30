class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? departmentId;
  final String? departmentName;
  final String? avatarUrl;
  final String? signatureUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
    this.avatarUrl,
    this.signatureUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      departmentId: json['department_id'],
      departmentName: json['department']?['name'] ?? json['department_name'],
      avatarUrl: json['avatar_url'] ?? json['avatar'],
      signatureUrl: json['signature_url'] ?? json['signature'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'department_id': departmentId,
    'department_name': departmentName,
    'avatar_url': avatarUrl,
    'signature_url': signatureUrl,
  };

  bool get isFileDept => role == 'file_dept';
  bool get isDG => role == 'dg';
  bool get isVDG => role == 'vdg';
  bool get isDepartment => role == 'department';
  bool get isStaff => role == 'staff';

  bool get canUpload => role == 'file_dept';
  bool get canAssign => role == 'dg';
  bool get canDispatch => role == 'file_dept';
  bool get canVDGSign => role == 'vdg';
  bool get canDGSign => role == 'dg';
  bool get canArchive => role == 'file_dept';
  bool get canManageUsers => role == 'dg';

  String get displayRole => role.replaceAll('_', ' ').toUpperCase();

  // Initials for avatar placeholder
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  User copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    String? signatureUrl,
    bool clearAvatar = false,
    bool clearSignature = false,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role,
      departmentId: departmentId,
      departmentName: departmentName,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      signatureUrl: clearSignature ? null : (signatureUrl ?? this.signatureUrl),
    );
  }
}