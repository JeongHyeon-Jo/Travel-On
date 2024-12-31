import 'package:permission_handler/permission_handler.dart';

class PermissionsUtil {
  // 카메라 접근 권한 요청
  static Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isGranted) {
      return true;
    } else {
      status = await Permission.camera.request();
      return status.isGranted;
    }
  }
}
