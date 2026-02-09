import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:my_app/Services/TokenStorage.dart';

class FirebaseService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static const String _baseUrl = "http://localhost:8000/";

  static Future<void> init() async {
    // Xin quyền (iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Lấy token lần đầu
    final token = await _fcm.getToken(); // hàm lấy token của firebase
    if (token != null) {
      await _sendTokenToBackend(token); // gửi token lên backend
    }

    // Token refresh (BẮT BUỘC)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) { // lắng nghe sự kiện khi firebase đổi token, sẽ gọi để lưu lại 
      _sendTokenToBackend(newToken);
    });
  }

  /// =========================
  /// SEND TOKEN TO BACKEND
  /// =========================
  /// 
  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final accessToken = await TokenStorage.getAccessToken(); // lấy access Token đảm bảo đang đăng nhập
      if (accessToken == null) return;

      final uri = Uri.parse("$_baseUrl/fcm/token/");

      await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken", // truyền vào access để xác minh auth
        },
        body: jsonEncode({
          "token": token, // mã hóa token vừa get 
          "device": Platform.isIOS ? "ios" : "android", // body là ioss nếu hàm trả true else là android
        }),
      );
    } catch (e) {
      print("❌ Send FCM token failed: $e");
    }
  }

}
