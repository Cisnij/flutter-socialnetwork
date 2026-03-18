import 'package:http/http.dart' as http;
import 'dart:convert';


class LoginService {
  final String _baseUrl = "http://10.27.1.95:8000";
  Future<http.Response> sendRequest(Map<String, dynamic> jsonData) async { //function future dùng để chứa kết quả tương lai, ở đây là async nên future sẽ lấy kết quả sau
  // bên trong là Map dùng để chứa jsonData
    final url = Uri.parse("$_baseUrl/api/auth/login/"); //url gui future
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(jsonData),
    );
  }
  Future<http.Response> resetPass(Map<String, dynamic> jsonData) async { 
  // bên trong là Map dùng để chứa jsonData
    final url = Uri.parse("$_baseUrl/api/auth/password/reset/");
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(jsonData),
    );
  }
}