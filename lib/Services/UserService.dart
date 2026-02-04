import 'package:http/http.dart' as http;
import 'package:my_app/Services/AuthService.dart';

class UserService{

  Future<http.Response> userInformation() async{
    return await authGet(url: 'http://10.0.2.2:8000/api/user/');
  }
  Future<http.Response> userPost(int id) async{
    return await authGet(url: 'http://10.0.2.2:8000/api/user/post/userpage/$id/');
  }
  Future<http.Response> viewPage(int id) async{
    return await authGet(url: 'http://10.0.2.2:8000/api/auth/profile/userpage/$id');
  }
  Future<http.Response> userModify(Map<String, dynamic> jsonData, int id) async{
    return await authPut(url: 'http://10.0.2.2:8000/api/user/profile/$id/', body: jsonData);
  }
  Future<http.Response> viewFriends(int id) async{
    return await authGet(url: 'http://10.0.2.2:8000/api/friends/$id/');
  }

  Future<http.Response> search(String name) async{
    return await authGet(url: 'http://10.0.2.2:8000/api/user/profile/?last_name=$name');
  }
}