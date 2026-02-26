import 'package:flutter/material.dart';
import 'package:my_app/Controllers/FriendController.dart';
import 'package:my_app/Controllers/UserController.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Views/Screens/profile.dart';
import 'package:my_app/Views/Screens/cache.dart';

class FriendSuggestScreen extends StatefulWidget {
  const FriendSuggestScreen({super.key});

  @override
  State<FriendSuggestScreen> createState() => _FriendSuggestScreenState();
}

class _FriendSuggestScreenState extends State<FriendSuggestScreen> {

  // gọi controller 
  final UserController _controller = UserController();
  final FriendController _friendController = FriendController();

  List<UserModel> _users = []; // khởi tạo list user 
  bool _loading = false;
  // khởi tạo tất cả request kể cả gửi và nhận
  Map<int, int> _allRequestIdMap = <int, int>{}; 

  @override
  void initState() {
    super.initState();
    // Khởi tạo map trống trước khi gọi API
    _allRequestIdMap = {}; 
    _syncAllRequests();
  }

  Future<void> _syncAllRequests() async { // hàm lấy lại tất cả income và sent 
    try {
      final income = await _friendController.incomeRequest();
      final sent = await _friendController.outgoingRequest();
      // Tạo một map tạm thời để tránh xung đột kiểu dữ liệu
      final Map<int, int> tempMap = {};

      if (income != null) { // nếu income không null thì đem vào temp map và lấy ra user và id 
        for (var req in income) {
          if (req['sender'] != null && req['sender']['id'] != null) {
            tempMap[req['sender']['id']] = req['id'];
          }
        }
      }

      if (sent != null) { // // nếu sent không null thì đem vào temp map và lấy ra user và id 
        for (var req in sent) {
          if (req['receiver'] != null && req['receiver']['id'] != null) {
            tempMap[req['receiver']['id']] = req['id'];
          }
        }
      }

      if (mounted) { // chống lỗi khi tải, đảm bảo còn widget trước khi gọi set state vẽ lại UI
        setState(() {
          _allRequestIdMap = tempMap;
        });
      }
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  Future<void> _search(String name) async { //hàm search user 
    if (name.isEmpty) { //check điều kiện 
      setState(() => _users = []);
      return;
    }
    setState(() => _loading = true);
    try {
      // Luôn đảm bảo sync lại ID trước khi hiện kết quả search
      await _syncAllRequests(); 
      final result = await _controller.searchUser(name); // gọi controller để search tên 
      setState(() => _users = result ?? []); 
    } catch (e) {
      debugPrint("Search error: ${e.toString()}");
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Kết bạn'), centerTitle: true),
      body: Column( // tất cả bọc trong column theo hàng
        children: [
          Padding( // tạo khoảng trông xung quanh widget con 
            padding: const EdgeInsets.all(12), // padding đều 12px 
            child: TextField( // trường text để nhập 
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Tìm bạn theo tên...', 
                prefixIcon: const Icon(Icons.search),
                filled: true, // được phép thay đổi màu
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), // dạng ô bo tròn
              ),
            ),
          ),
          Expanded( // chiếm hết phần còn lại trong column 
            child: _loading // nếu loading là true
                ? const Center(child: CircularProgressIndicator()) 
                : _users.isEmpty
                    ? const Center(child: Text('Không có kết quả'))
                    : ListView.builder( // tạo widget danh sách cuộn 
                        itemCount: _users.length, // số lượng user trong mảng
                        itemBuilder: (_, i) { // build user thành n widget và khi nhấn sẽ nhớ id để gọi profile 
                          final user = _users[i];  // lấy user từ thứ i trong list 
                          final int? id = user.id; // lấy user id 
                          if (id == null) return const SizedBox.shrink(); // nếu null thì không render gì 

                          //LẤY RID AN TOÀN: Nếu map null thì rId cũng null
                          final int? rId = _allRequestIdMap[id];

                          return ListTile( // listtile là widget cột, giống list view nhưng chia theo 3 cột  
                            leading: GestureDetector( // theo dỗi tap 
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(userId: id))); // nhấn thì lấy user id đó gọi load ra profile
                              },
                              child: CircleAvatar( // avatar tròn
                                backgroundImage: user.picture != null ? NetworkImage(user.picture!) : null,
                                child: user.picture == null ? const Icon(Icons.person) : null,
                              ),
                            ),
                            title: Text('${user.firstName} ${user.lastName}', style: const TextStyle(fontWeight: FontWeight.w600)),

                            trailing: Builder( // nút bấm dùng cho list tile ở hàng ngang 3 
                              builder: (_) {
                                if (session.isMe(id)) return const SizedBox.shrink(); // return nothing nếu là mình 

                                // 1. Bạn bè -> Unfriend (Dùng id)
                                if (session.isFriend(id)) {
                                  return ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
                                    onPressed: () async {
                                      await _friendController.deleteRequest(id);
                                      session.friendIds.remove(id);
                                      setState(() {});
                                    },
                                    child: const Text('Hủy kết bạn', style: TextStyle(color: Colors.red)),
                                  );
                                }

                                // 2. Chờ xác nhận -> Accept (Dùng rId)
                                if (session.isReceive(id)) {
                                  return ElevatedButton(
                                    onPressed: () async {
                                      if (rId != null) {
                                        await _friendController.acceptRequest(rId);
                                        session.friendIds.add(id);
                                        session.receiveRequestIds.remove(id);
                                        setState(() {});
                                      } else {
                                        await _syncAllRequests(); // Thử sync lại nếu thiếu ID
                                      }
                                    },
                                    child: const Text('Chấp nhận'),
                                  );
                                }

                                // 3. Đã gửi -> Cancel (Dùng rId)
                                if (session.isSent(id)) {
                                  return OutlinedButton( // nút bấm nền trong suốt 
                                    onPressed: () async {
                                      if (rId != null) {
                                        await _friendController.cancelRequest(rId);
                                        session.sentRequestIds.remove(id);
                                        setState(() {});
                                      } else {
                                        await _syncAllRequests();
                                      }
                                    },
                                    child: const Text('Hủy lời mời'),
                                  );
                                }

                                // 4. Người lạ -> Add (Dùng id)
                                return ElevatedButton( // nút bấm có màu 
                                  onPressed: () async {
                                    await _friendController.sendRequest(id);
                                    session.sentRequestIds.add(id);
                                    await _syncAllRequests();
                                    setState(() {});
                                  },
                                  child: const Text('Kết bạn'),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}