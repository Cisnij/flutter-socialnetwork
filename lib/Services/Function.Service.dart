import 'package:http/http.dart' as http;
import 'package:my_app/Services/AuthService.dart';

class FunctionService{
  Future<http.Response> react(int id, Map<String, dynamic> jsonData) async{
    return await authFetch(url: 'http://localhost:8000/posts/$id/react/', body:jsonData); //ok
  }

  Future<http.Response> createComment(int post_id, Map<String, dynamic> jsonData) async{
    return await authFetch(url: 'http://localhost:8000/api/user/comments/post/$post_id', body: jsonData); //ok 
  }

  Future<http.Response> listComment(int post_id) async{
    return await authGet(url: 'http://localhost:8000/api/user/comments/post/$post_id'); //ok
  }

    Future<http.Response> delComment(int comment_id) async{
    return await authDelete(url: 'http://localhost:8000/api/user/comments/$comment_id/'); //ok
  }
  Future<http.Response> getNoti() async{
    return await authGet(url: 'http://localhost:8000/api/notifications/'); //ok
  }
}

// thêm lấy ra reaction