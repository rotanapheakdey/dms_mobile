class AppConstants {
  static const String appName = 'DMS';
  static const String appVersion = '1.0.0';

  static const int maxFileSizeMB = 10;
  static const List<String> allowedFileExtensions = ['pdf', 'doc', 'docx'];

  static const Map<String, String> statusLabels = {
    'pending_dg_init': 'Pending DG',
    'pending_dispatch': 'Pending Dispatch',
    'dg_directed': 'DG Directed',
    'pending_vdg_approval': 'Pending VDG',
    'pending_dg_approval': 'Pending DG',
    'dg_signed': 'DG Signed',
    'completed_archive': 'Archived',
  };
}