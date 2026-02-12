import 'package:my_app/Services/AuthService.dart';
import 'package:http/http.dart' as http;

class FriendService{
  Future<http.Response> addFriend(int id) async{
    return await authFetch(url: 'http://localhost:8000/api/friends/request/$id/'); //ok
  }
  Future<http.Response> listFriend() async{
    return await authGet(url: 'http://localhost:8000/api/friends/requests/incoming/');//ok 
  }
  Future<http.Response> acceptFriend(int id) async{
    return await authPut(url: 'http://localhost:8000/api/friends/request/$id/accept/'); //ok
  }
  Future<http.Response> deleteFriend(int id) async{
    return await authDelete(url: 'http://localhost:8000/api/friends/unfriend/$id/'); // ok
  }
  Future<http.Response> outgoingRequest() async{
    return await authGet(url: 'http://localhost:8000/api/friends/requests/outgoing/'); //ok
  }
  Future<http.Response> cancelFriend(int id) async{
    return await authDelete(url: 'http://localhost:8000/api/friends/request/$id/cancel/'); //ok 
  }
  Future<http.Response> rejectFriend(int id) async{
    return await authPut(url: 'http://localhost:8000/api/friends/request/$id/reject/'); //ok 
  }


  
}