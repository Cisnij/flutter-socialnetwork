import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_app/Services/AuthService.dart';
import 'package:my_app/Services/TokenStorage.dart';

class PostService {
  final _baseurl ='http://10.27.1.95:8000';

  Future<http.Response> createPost({required String title,List<File> images = const [],}) async {
    final uri = Uri.parse('$_baseurl/api/user/post/create/v2/');
    final request = http.MultipartRequest('POST', uri); // post dạng multipart cho truyền file
    final token = await TokenStorage.getAccessToken(); //lấy token xác thực
    request.headers['Authorization'] = 'Bearer $token';// thêm headers
    request.fields['title'] = title;  //gán title vào trường
    for (final img in images) { // duyệt qu từng ảnh trong list và thêm vào request 
      request.files.add(
        await http.MultipartFile.fromPath(
          'photos',
          img.path,
        ),
      );
    }
    final streamed = await request.send(); // gửi request
    return await http.Response.fromStream(streamed); // nhận res
  }


  /// Sửa post, update và retreive
  Future<http.Response> delPost(int id,) async { //ok
    return await authDelete(
      url: '$_baseurl/api/user/post/$id/',
    );
  }


  /// Xem post theo id
  Future<http.Response> getFeedPost() async { //ok 
    return await authGet(
      url: '$_baseurl/api/user/post/show',
    );
  }
  
  /// Sửa post theo id, dùng PATCH để chỉ cập nhật title
  Future<http.Response> editPost(int id, String title) async {
    final uri = Uri.parse('$_baseurl/api/user/post/$id/');
    final token = await TokenStorage.getAccessToken(); // lấy token xác thực
    return await http.patch( // patch chỉ cập nhật 1 phần, khác put là update toàn bộ
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'title': title}), // chỉ gửi title cần sửa
    );
  }
}

