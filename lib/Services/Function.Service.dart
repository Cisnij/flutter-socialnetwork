import 'package:http/http.dart' as http;
import 'package:my_app/Services/AuthService.dart';

class FunctionService{
  final _baseurl= 'http://10.27.1.95:8000';
  Future<http.Response> react(int id, Map<String, dynamic> jsonData) async{
    return await authFetch(url: '$_baseurl/posts/$id/react/', body:jsonData); //ok
  }

  Future<http.Response> createComment(int post_id, Map<String, dynamic> jsonData) async{
    return await authFetch(url: '$_baseurl/api/user/comments/post/$post_id', body: jsonData); //ok 
  }

  Future<http.Response> listComment(int post_id) async{
    return await authGet(url: '$_baseurl/api/user/comments/post/$post_id'); //ok
  }

    Future<http.Response> delComment(int comment_id) async{
    return await authDelete(url: '$_baseurl/api/user/comments/$comment_id/'); //ok
  }
  Future<http.Response> getNoti() async{
    return await authGet(url: '$_baseurl/api/notifications/'); //ok
  }
}

// thêm lấy ra reaction