import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:my_app/Services/AuthService.dart';
import 'package:my_app/Services/TokenStorage.dart';

class PostService {
Future<http.Response> createPost({required String title,List<File> images = const [],}) async {
  final uri = Uri.parse('http://localhost:8000/api/user/post/create/');
  final request = http.MultipartRequest('POST', uri); // post dạng multipart cho truyền file
  final token = await TokenStorage.getAccessToken(); //lấy token xác thực
  request.headers['Authorization'] = 'Bearer $token';// thêm headers
  // TEXT
  request.fields['title'] = title;  //gán title vào trường
  // IMAGES (optional)
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
      url: 'http://localhost:8000/api/user/post/$id/',
    );
  }


  /// Xem post theo id
  Future<http.Response> getFeedPost() async { //ok 
    return await authGet(
      url: 'http://localhost:8000/api/user/post/show',
    );
  }
}

