import 'dart:convert';
import 'package:my_app/Services/Function.Service.dart';
import 'package:my_app/Models/FunctionModel.dart';

class FunctionController {
  final _service = FunctionService();

  Future<List<ReactionCount>> reactPost(int postId,String type,) async {
    final model = ReactModel(type: type);

    final res = await _service.react(postId, model.toJson());

    if (res.statusCode == 200 || res.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(res.body); // chuyển data sau decode thành map
      final List list = data['count']; // 👈 lấy mảng count
      return list.map((e) => ReactionCount.fromJson(e)).toList(); // đưa data vào để chuyển sang dạng dữ liệu để tạo object
    }

    final data = jsonDecode(res.body);
    throw Exception(data['message'] ?? 'React failed');
  }

  Future<List<CommentModel>> listComment(int postId) async {
    final res = await _service.listComment(postId); // gọi api
    if (res.statusCode == 200 || res.statusCode == 201) {
      final List<dynamic> data = jsonDecode(res.body); // chuyển data nhận về thành list
      return data
          .map((e) => CommentModel.fromJson(e)) // với từng thằng con đem qua parse với model và đem vào list
          .toList();
    } else {
      throw Exception('Không lấy được danh sách comment');
    }
  }

  Future <CommentModel> createComment(int post_id, String content) async{
    final model =CommentModel(content: content);
    final res = await _service.createComment(post_id, model.toJSon());
    if (res.statusCode == 200 || res.statusCode == 201){
      final data = jsonDecode(res.body);
      return CommentModel.fromJson(data);
    }
    else{
      throw Exception('Xảy ra lỗi'); 
    }
  }

  Future<bool> delComment (int id) async{
    final res = await _service.delComment(id);
    if (res.statusCode == 200 || res.statusCode == 204){
      return true;
    }
    return false;
  }

  Future<List<InAppNotification>> noti() async {
    final res = await _service.getNoti();
    if(res.statusCode ==200 ){
      final List<dynamic> data = jsonDecode(res.body)['results'];
      return data.map((e) => InAppNotification.fromJson(e)).toList();
    }
    else{
      throw Exception('Lỗi khi lấy thông báo');
    }
  }
}
