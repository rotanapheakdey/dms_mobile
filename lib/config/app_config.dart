class AppConfig {
  static const String apiBaseUrl = 'http://127.0.0.1/api';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const Map<String, int> statusColors = {
    'pending_dg_init': 0xFFE53935,
    'pending_dispatch': 0xFFFB8C00,
    'dg_directed': 0xFF1E88E5,
    'pending_vdg_approval': 0xFF8E24AA,
    'pending_dg_approval': 0xFFFFB300,
    'dg_signed': 0xFF43A047,
    'completed_archive': 0xFF757575,
  };

  static const Map<String, int> roleColors = {
    'file_dept': 0xFF1A73E8,
    'dg': 0xFFD32F2F,
    'vdg': 0xFFE65100,
    'department': 0xFF388E3C,
    'staff': 0xFF7B1FA2,
  };

  static String getStatusDisplay(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  static int getStatusColor(String status) {
    return statusColors[status] ?? 0xFF757575;
  }

  static int getRoleColor(String role) {
    return roleColors[role] ?? 0xFF757575;
  }
}