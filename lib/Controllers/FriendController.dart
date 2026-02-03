import 'dart:convert';
import 'package:my_app/Services/FriendService.dart';

class FriendController {
  final _service = FriendService();

  List<dynamic> requests = []; // khai báo list
  bool isLoading = false;

  Future<List<dynamic>> incomeRequest() async {
    isLoading = true;

    final res = await _service.listFriend();

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body); // lấy ra body
      requests = data; //gán body vào list
      isLoading = false;
      return requests; // trả về list
    } else {
      isLoading = false;
      throw Exception('Load failed');
    }
  }

  /// Gửi lời mời kết bạn
  Future<bool> sendRequest(int id) async {
    isLoading = true;

    final res = await _service.addFriend(id);

    isLoading = false;
    return res.statusCode == 201;
  }
  
    Future<bool> acceptRequest(int id) async {
    isLoading = true;

    final res = await _service.acceptFriend(id);

    isLoading = false;
    return res.statusCode == 201;
  }
}

