import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_client.dart';

class DownloadService {
  final ApiClient _api = ApiClient();

  Future<bool> downloadDocument(int id, String fileName) async {
    try {
      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          return false;
        }
      }

      final result = await _api.downloadFile('/documents/$id/download');

      if (result['error'] == true) {
        return false;
      }

      final directory = await getExternalStorageDirectory();
      final filePath = '${directory?.path}/$fileName.pdf';
      final file = File(filePath);
      await file.writeAsBytes(result['data']);

      return true;
    } catch (e) {
      return false;
    }
  }
}