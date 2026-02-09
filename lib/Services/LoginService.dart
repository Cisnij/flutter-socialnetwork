import 'package:http/http.dart' as http;
import 'dart:convert';


class LoginService {
  Future<http.Response> sendRequest(Map<String, dynamic> jsonData) async { //function future dùng để chứa kết quả tương lai, ở đây là async nên future sẽ lấy kết quả sau
  // bên trong là Map dùng để chứa jsonData
    final url = Uri.parse("http://localhost:8000/api/auth/login/"); //url gui future
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(jsonData),
    );
  }
}