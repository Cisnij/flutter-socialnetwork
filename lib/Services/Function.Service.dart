import 'package:http/http.dart' as http;
import 'package:my_app/Services/AuthService.dart';

class FunctionService{
  Future<http.Response> react(int id, Map<String, dynamic> jsonData) async{
    return await authFetch(url: 'http://10.0.2.2:8000/posts/$id/react/', body:jsonData);
  }
}

// thêm lấy ra reaction