import 'package:my_app/Services/AuthService.dart';
import 'package:http/http.dart' as http;

class FriendService{
  final _baseurl ='http://10.27.1.95:8000';
  Future<http.Response> addFriend(int id) async{
    return await authFetch(url: '$_baseurl/api/friends/request/$id/'); //ok
  }
  Future<http.Response> listFriend() async{
    return await authGet(url: '$_baseurl/api/friends/requests/incoming/');//ok 
  }
  Future<http.Response> acceptFriend(int id) async{
    return await authPut(url: '$_baseurl/api/friends/request/$id/accept/'); //ok
  }
  Future<http.Response> deleteFriend(int id) async{
    return await authDelete(url: '$_baseurl/api/friends/unfriend/$id/'); // ok
  }
  Future<http.Response> outgoingRequest() async{
    return await authGet(url: '$_baseurl/api/friends/requests/outgoing/'); //ok
  }
  Future<http.Response> cancelFriend(int id) async{
    return await authDelete(url: '$_baseurl/api/friends/request/$id/cancel/'); //ok 
  }
  Future<http.Response> rejectFriend(int id) async{
    return await authPut(url: '$_baseurl/api/friends/request/$id/reject/'); //ok 
  }


  
}