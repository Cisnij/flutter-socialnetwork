import 'package:my_app/Services/AuthService.dart';
import 'package:http/http.dart' as http;

class FriendService{
  Future<http.Response> addFriend(int id) async{
    return await authFetch(url: 'http://172.17.17.98:8000/api/friends/request/$id/');
  }

  Future<http.Response> listFriend() async{
    return await authGet(url: 'http://172.17.17.98:8000/api/friends/requests/incoming/');
  }
  Future<http.Response> acceptFriend(int id) async{
    return await authPut(url: 'http://172.17.17.98:8000/api/friends/request/$id/accept/');
  }
  
}