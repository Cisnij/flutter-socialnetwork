import 'package:http/http.dart' as http;
import 'package:my_app/Services/AuthService.dart';

class PostService {
  Future<http.Response> createPost(Map<String, dynamic> data) async { //tạo post
    return await authFetch(
      url: 'http://localhost:8000/api/user/post/create/',
      body: data,
    );
  }

  /// Sửa post, update và retreive
  Future<http.Response> delPost(int id,) async {
    return await authDelete(
      url: 'http://localhost:8000/api/user/post/$id/',
    );
  }


  /// Xem post theo id
  Future<http.Response> getFeedPost() async {
    return await authGet(
      url: 'http://localhost:8000/api/user/post/show',
    );
  }
}

