import 'dart:convert';
import 'package:my_app/Services/PostService.dart';
import 'package:my_app/Models/PostModel.dart';

class PostController{
  final _service = PostService();

  Future<PostModel> createPost(String title) async { // tạo post
    final model = PostModel(title: title);
    final res = await _service.createPost(model.toJson()); // gọi api truyền vào data đã được model chuyển thành json

    if (res.statusCode == 201 || res.statusCode == 200) {
      final data = jsonDecode(res.body); // chuyển thành map
      return PostModel.fromJson(data); // tạo object từ map
    } else {
      throw Exception('Xảy ra lỗi');
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


}