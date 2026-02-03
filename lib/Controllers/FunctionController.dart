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
}
