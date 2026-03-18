import 'dart:convert';
import 'dart:io';
import 'package:my_app/Services/PostService.dart';
import 'package:my_app/Models/PostModel.dart';

class PostController{
  final _service = PostService();

  Future<PostModel> createPost({required String title, List<File> images = const [],}) async {
      final res = await _service.createPost(title: title,images: images,);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        return PostModel.fromJson(data);
      } else {
        throw Exception('Tạo post thất bại');
    }
  }



  Future<bool> delPost(int id) async { // sửa post
    final res = await _service.delPost(id,);

    if (res.statusCode == 200 || res.statusCode == 204) {
      return true;
    }
    return false;
  }


  
  Future<List<PostModel>> getFeed() async {
    final res = await _service.getFeedPost();

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);

      final List results = data['results']; 

      return results
          .map((e) => PostModel.fromJson(e)) // lấy ra từng thằng con, biến nó thành dữ liệu thường và đưa vào list
          .toList();
    } else {
      throw Exception('Lỗi xảy ra');
    }
  }

  /// Gọi service sửa post, trả về PostModel mới sau khi cập nhật
  Future<PostModel> editPost(int id, String title) async {
    final res = await _service.editPost(id, title); // gọi service

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return PostModel.fromJson(data); // parse lại model mới từ response
    } else {
      throw Exception('Sửa post thất bại');
    }
  }
}