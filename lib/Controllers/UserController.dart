import 'dart:convert';
import 'package:my_app/Models/PostModel.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Services/UserService.dart';

class UserController {
  final UserService _service = UserService();

  Future<UserModel> userInfo() async { //Future chứa đối tượng để return về chính đối tượng đó
    final res = await _service.userInformation();

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return UserModel.fromJson(data.first);
    } else {
      throw Exception('Có lỗi khi lấy thông tin user');
    }
  }

  Future<UserModel> viewPage(int id) async {
    final res = await _service.viewPage(id);

    if (res.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Có lỗi khi xem trang cá nhân');
    }
  }


  Future<UserModel> userModify(int id, UserModel model) async {
    final res = await _service.userModify(model.toJson(), id);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(res.body);
      return UserModel.fromJson(data);
    } else {
      throw Exception('Có lỗi khi cập nhật user');
    }
  } 

  Future<List<UserModel>> viewFriends() async {
    final res = await _service.viewFriends();

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => UserModel.fromJson(e)).toList(); // sau khi có data lấy ra data, từng thừng con biến nó thành data thường r bỏ vào list
    } else {
      throw Exception('Có lỗi khi lấy danh sách bạn bè');
    }
  }
  Future<List<PostModel>> userPosts(int userId) async {
  final res = await _service.userPost(userId);

  if (res.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(res.body);
    final List results = data['results'];

    return results.map((e) => PostModel.fromJson(e)).toList(); // chuyển từng thành con thành fromJson và biến thành list
  } else {
    throw Exception('Có lỗi khi lấy bài viết của user');
  }
}
Future<List<UserModel>> searchUser(String name) async{
  final res = await _service.search(name);
  if (res.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(res.body);
    final List results = data['results'];
    return results.map((e) => UserModel.fromJson(e)).toList();
  } else {
    throw Exception('Có lỗi khi lấy thông tin user');
  }
}

}
