import 'package:my_app/Controllers/FriendController.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Controllers/UserController.dart';

class AppSession { // khai báo lưu nhanh user và friend để hạn chế gọi api và lọc ra bạn bè nhanh
  static final AppSession instance = AppSession._();//constructor private
  AppSession._();

  final UserController _userController = UserController(); // khai báo controller
  final FriendController _friendController = FriendController(); // khai báo controller

  UserModel? me; // khỏi tạo object oop
  int? get myId => me?.id; // hàm get viết gọn cho class
  final Set<int> friendIds = {}; // set chứa id
  final Set<int> sentRequestIds = {}; //set chứa id đã gửi
  final Set<int> receiveRequestIds = {33};
  bool _loaded = false;

  Future<void> init() async { // hàm khởi tạo
    if (_loaded) return; // đã load rồi thì khỏi gọi nữa

    me = await _userController.userInfo(); // gọi api lấy ra thông tin user hiện tại

    final friends = await _userController.viewFriends(me!.id!); // gọi api lấy ra friend
    friendIds.addAll(friends.map((e) => e.id!)); // thêm id vào set đã khai báo

    final requests = await _friendController.outgoingRequest();
    sentRequestIds.addAll(requests.map((e) => e['receiver']['id'] as int)); // lưu vào map cái id receiver 

    final receive = await _friendController.incomeRequest();
    receiveRequestIds.addAll(receive.map((e) => e['sender']['id'] as int));
    _loaded = true;
  }

  bool isMe(int? id) => id != null && id == myId; // trả true nếu id ko null và id = id mình
  bool isFriend(int? id) => id != null && friendIds.contains(id); // true nếu có id trong set
  bool isSent(int? id) => id != null && sentRequestIds.contains(id); // true nếu có id trong set
  bool isReceive(int? id) => id != null && receiveRequestIds.contains(id);

  void clear() { // hàm clear cache
    me = null;
    friendIds.clear();
    sentRequestIds.clear();
    _loaded = false;
  }
}
