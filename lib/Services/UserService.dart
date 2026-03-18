import 'package:http/http.dart' as http;
import 'package:my_app/Services/AuthService.dart';

class UserService{
  final _baseurl ='http://10.27.1.95:8000';
  Future<http.Response> userInformation() async{
    return await authGet(url: '$_baseurl/api/user/'); //ok 
  }
  Future<http.Response> userPost(int id) async{
    return await authGet(url: '$_baseurl/api/user/post/userpage/$id/'); //ok
  }
  Future<http.Response> viewPage(int id) async{
    return await authGet(url: '$_baseurl/api/auth/profile/userpage/$id'); //ok
  }
  Future<http.Response> userModify(Map<String, dynamic> jsonData, int id) async{
    return await authPut(url: '$_baseurl/api/user/profile/$id/', body: jsonData); //ok
  }
  Future<http.Response> viewFriends(int id) async{
    return await authGet(url: '$_baseurl/api/friends/$id/'); //ok
  }

  Future<http.Response> search(String name) async{
    return await authGet(url: '$_baseurl/api/user/profile/?search=$name'); //ok
  }
}