import 'package:http/http.dart' as http;
import 'package:my_app/Services/AuthService.dart';

class PostService {
  Future<http.Response> createPost(Map<String, dynamic> data) async { //tạo post
    return await authFetch(
      url: 'http://172.17.17.98:55394/api/user/post/create/',
      body: data,
    );
  }

  /// Sửa post, update và retreive
  Future<http.Response> modifyPost(int id,Map<String, dynamic> data,) async {
    return await authPut(
      url: 'http://172.17.17.98:8000/api/user/post/$id/',
      body: data,
    );
  }


  /// Xem post theo id
  Future<http.Response> getFeedPost() async {
    return await authGet(
      url: 'http://172.17.17.98:8000/api/user/post/show',
    );
  }
}

