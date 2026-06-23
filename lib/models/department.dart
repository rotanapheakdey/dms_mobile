class Department {
  final int id;
  final String name;
  final String? code;

  Department({
    required this.id,
    required this.name,
    this.code,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'],
      name: json['name'],
      code: json['code'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
  };
}