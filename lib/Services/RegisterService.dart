import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterService {
  Future<http.Response> sendRequest(Map<String, dynamic> jsonData) async {
    final url = Uri.parse("http://localhost:8000/api/auth/registration/"); //url gui
    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(jsonData),
    );
  }
}