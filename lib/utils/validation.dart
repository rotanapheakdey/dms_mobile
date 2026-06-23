class Validation {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateFileSize(int sizeInBytes, int maxMB) {
    final sizeInMB = sizeInBytes / (1024 * 1024);
    if (sizeInMB > maxMB) {
      return 'File size exceeds ${maxMB}MB limit';
    }
    return null;
  }

  static String? validateFileExtension(String fileName, List<String> extensions) {
    final ext = fileName.split('.').last.toLowerCase();
    if (!extensions.contains(ext)) {
      return 'File must be ${extensions.join(', ')}';
    }
    return null;
  }
}