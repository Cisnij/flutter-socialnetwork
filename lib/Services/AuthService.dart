
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_app/Services/TokenStorage.dart';

Future<String?> refreshAccessToken() async {
  
  final refreshToken = await TokenStorage.getRefreshToken();// Lấy refresh token đã lưu
  if (refreshToken == null) return null;

  final url = Uri.parse(
    'http://localhost:8000/api/auth/token/refresh/',
  );

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "refresh": refreshToken,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final newAccess = data['access'];

    await TokenStorage.saveTokens(
      access: newAccess,
      refresh: refreshToken,
    );

    return newAccess;
  }
  return null; // thất bại
}
//==================POST====================================================
// hàm gọi post đảm bảo luôn trong trạng thái bảo mật login token, ? ở map để cho phép null
Future<http.Response> authFetch({required String url, Map<String, dynamic>? body, bool retry = true}) async { // bool retry tránh loop vô hạn, chỉ lặp 1 lần, và nếu gọi lại thì retry false đẻ không lặp nữa
  final accessToken = await TokenStorage.getAccessToken();
  final response = await http.post(
    Uri.parse(url),
    headers: {
      "Content-Type": "application/json",
      if (accessToken != null) // không null mới truyền,nếu null sẽ k truyền và lỗi lần post 1
        "Authorization": "Bearer $accessToken",
    },
    body: body !=null ? jsonEncode(body) : null, // if body khác null thì? chuyển sang json else: null
  );

  if (response.statusCode == 401 && retry) {// Nếu access hết hạn và chưa thử lại lần nào tức retry = True thì refresh access và post lại
    final newAccess = await refreshAccessToken();

    if (newAccess != null) { // khác null là thành công
      return authFetch(
        url: url,
        body: body,
        retry: false, // không cần gửi lại
      );
    } else {
      // Refresh cũng hết hạn thì xóa và login lại, bởi vì nếu dùng rftoken để lấy actoken mà còn k lấy được thì hết hạn
      await TokenStorage.clear();
      throw Exception("SESSION_EXPIRED");
    }
  }
  return response;
}
//================GET===================================================
// hàm get với token
Future<http.Response> authGet({required String url, bool retry = true}) async{
  final accessToken = await TokenStorage.getAccessToken();
  final res = await http.get(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
        if(accessToken != null)
          'Authorization': 'Bearer $accessToken'
      },
  );
  if( res.statusCode != 200 && retry ){
    final newAccess= await refreshAccessToken();
    if(newAccess != null){
      return authGet(url: url, retry: false);
    }
    else{
      await TokenStorage.clear();
      throw Exception("Session expired. Please login again.");
    }
  }
  return res;
}

//============================ PUT=========================================
Future<http.Response> authPut({
  required String url,
  Map<String, dynamic>? body,
  bool retry = true,
}) async {
  final accessToken = await TokenStorage.getAccessToken();

  final response = await http.put(
    Uri.parse(url), //url
    headers: {
      "Content-Type": "application/json",
      if (accessToken != null) // nếu có access thì truyền k thì lỗi khi truyền
        "Authorization": "Bearer $accessToken",
    },
    body: body != null ? jsonEncode(body) : null, // nếu body không null thì chuyển json sang dạng thường k thì null
  );

  // Access token hết hạn, refresh rồi PUT lại 1 lần nữa, sau đó còn lỗi thì quay lại login
  if (response.statusCode == 401 && retry) {
    final newAccess = await refreshAccessToken();

    if (newAccess != null) {
      return authPut(
        url: url,
        body: body,
        retry: false,
      );
    } else {
      await TokenStorage.clear();
      throw Exception("Session expired. Please login again.");
    }
  }

  return response;
}
