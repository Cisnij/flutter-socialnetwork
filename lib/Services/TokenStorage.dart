import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// async cho phép chạy song song hoặc cho phép dừng và chạy sau
// await là chạy tuần tự cái này xong trả về mới tới cái kia
import 'package:flutter/material.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(); // khai báo khởi tạo storage

  static Future<void> saveTokens({ required String access,required String refresh,}) async {// hàm lưu token vào secure storage
    await _storage.write(key: 'access_token', value: access); // dấu _ trước là private, storage write là ghi vào storage
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  static Future<String?> getAccessToken() => // hàm get accesstoken, giống return
      _storage.read(key: 'access_token');

  static Future<String?> getRefreshToken() => // hàm get refreshtoken
      _storage.read(key: 'refresh_token');
  static Future<void> clear() => _storage.deleteAll(); // hàm clear

  static Future<bool> checkLogin() async{
    final access= await _storage.read(key: 'access_token');
    if(access!=null)
    {
      return true;
    }
    return false;
  }

  static Future<void> saveId({required String id}) async{
    await _storage.write(key: 'userId', value:id);
  }
  static Future<String?> getId() async{
    return _storage.read(key: 'userId');
  }
  Future<void> logout(BuildContext context) async {
  const storage = FlutterSecureStorage();
  await storage.delete(key: 'access_token'); 
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
}
}

//cách dùng TokenStorage.getAccessToken hay TokenStorage.saveTokens 