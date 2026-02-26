import 'package:flutter/material.dart';
import 'package:my_app/Controllers/FriendController.dart';
import 'package:my_app/Controllers/UserController.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Models/PostModel.dart';
import 'package:my_app/Services/TokenStorage.dart';
import 'package:my_app/Views/Screens/cache.dart';
import 'package:my_app/Views/Screens/post_item.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId}); // constructor bắt buộc truyền id vào để load ra profile

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final UserController _controller = UserController(); // gọi controller
  final FriendController _friendController = FriendController();

  Map<int, int> _allRequestIdMap = {}; // map để lưu  requestId (cho cả nhận và gửi)

  // khai báo các controller  để edit profile 
  bool _isEditing = false;
  final _editFormKey = GlobalKey<FormState>(); // global key để validate

  late TextEditingController _editFirstNameCtrl;
  late TextEditingController _editLastNameCtrl;
  late TextEditingController _editBioCtrl;
  late TextEditingController _editPhoneCtrl;
  DateTime? _editDob;


  late Future<UserModel> _userFuture; // khai báo đối tượng dạng bất đồng bộ lấy data sau gọi api
  late Future<List<PostModel>> _postFuture;
  late Future<List<UserModel>> _friendsFuture;

  bool get isMyProfile =>
      widget.userId == null ||
      widget.userId == AppSession.instance.myId; // check profile nếu ram đã lưu id , không thì trả false  

  // HÀM SYNC ĐỂ LẤY REQUEST ID TRƯỚC KHI THỰC HIỆN ---
  Future<void> _syncAllRequests() async {
    try {
      final income = await _friendController.incomeRequest(); // gọi nhận income request 
      if (income != null) { // nếu có income 
        for (var req in income) { // lọc ra và đem vào map 
          _allRequestIdMap[req['sender']['id']] = req['id']; 
        }
      }
      final sent = await _friendController.outgoingRequest(); // gọi nhận outgoing request 
      if (sent != null) {
        for (var req in sent) {
          _allRequestIdMap[req['receiver']['id']] = req['id']; // đem vào map 
        }
      }
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  Future<void> _reloadProfile() async { // hàm reload
    await _syncAllRequests(); // Đồng bộ ID trước
    if (isMyProfile) { // nếu là mình 
      _userFuture = _controller.userInfo(); // lấy ra profile mình 
      _postFuture =
          _userFuture.then((user) => _controller.userPosts(user.id!)); // lấy ra post mình 
      _friendsFuture =
          _userFuture.then((user) => _controller.viewFriends(user.id!)); // lấy ra bạn mình 
    } else {
      // không phải mình thì lấy ra profile và post ngkhac 
      _userFuture = _controller.viewPage(widget.userId!); 
      _postFuture = _controller.userPosts(widget.userId!);
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _syncAllRequests(); // Chạy đồng bộ ID ngay khi init

    if (isMyProfile) {
      _userFuture = _controller.userInfo(); // nếu true lấy profile và post và fr
      _postFuture =
          _userFuture.then((user) => _controller.userPosts(user.id!)); //lấy post
      _friendsFuture =
          _userFuture.then((user) => _controller.viewFriends(user.id!)); //lấy fr 
    } else {
      _userFuture = _controller.viewPage(widget.userId!); // chỉ load ra thông tin và post
      _postFuture = _controller.userPosts(widget.userId!);
    }
  }

  /// ===== FRIEND BUTTON TEXT =====
  String get friendButtonText {
    final session = AppSession.instance; // lấy ra session
    final id = widget.userId; // lấy ra id từ profile 

    if (id == null) return ''; // hàm check trong ram dựa vào id truyền vào profile và trả về giá trị 
    if (session.isFriend(id)) return 'Hủy kết bạn'; // nếu là bạn thì hiện text hủy kết bạn 
    if (session.isSent(id)) return 'Đã gửi'; // nếu có id trong map outgoing  thì hiện text hủy kết bạn 
    if (session.isReceive(id)) return 'Chờ xác nhận'; // nếu có id trong map income thì hiện text 
    return 'Kết bạn';
  }

  /// ===== FRIEND BUTTON ENABLE =====
  bool get canSendRequest { // khả năng nhấn của nút , check nếu là mình thì kh thể ấn gì 
    final id = widget.userId;
    if (id == null) return false;
    return true; // kh phải mình thì trả true 
  }

  /// ===== SHOW ALL FRIENDS MODAL =====
  void _showAllFriends(List<UserModel> friends) {
    showDialog( // mở dialog giữa màn hình
      context: context,
      builder: (_) => Dialog( // Dialog tự căn giữa màn hình
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // bo góc
        ),
        child: Container(
          width: double.maxFinite, // chiều rộng tối đa
          height: MediaQuery.of(context).size.height * 0.6, // chiều cao 60% màn hình
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bạn bè · ${friends.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton( // nút đóng
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              // danh sách bạn bè
              Expanded( // chiếm hết không gian còn lại trong Column
                child: GridView.builder(
                  itemCount: friends.length, // tất cả bạn bè thay vì chỉ 6
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 cột
                    mainAxisSpacing: 12, // khoảng cách dọc
                    crossAxisSpacing: 12, // khoảng cách ngang
                    childAspectRatio: 0.8, // tỉ lệ khung hình
                  ),
                  itemBuilder: (_, i) {
                    final f = friends[i];
                    return InkWell( // hiệu ứng khi nhấn
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.pop(context); // đóng dialog trước
                        Navigator.push( // rồi chuyển sang profile
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: f.id),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: f.picture != null
                                ? NetworkImage(f.picture!)
                                : null,
                            child: f.picture == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            f.firstName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isMyProfile ? 'Profile' : 'User Profile'), // nếu là mình thì profile còn k thì user profile 
        actions: [
          if (isMyProfile) // hành động đc build logout nếu là bản thân
            IconButton(
              icon: const Icon(Icons.logout), // icon 
              onPressed: () async { 
                await TokenStorage.clear(); // khi nhấn thì clear storage 
                AppSession.instance.clear(); // clear luôn cache 
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil( // chuyển trang k quay lại 
                    context,
                    '/login',
                    (_) => false,
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing; // khi nhấn thì chuyển trang thái edit thành true để nhận giá trị bàn phím
                });
              },
            ),
        ],
      ),
      body: FutureBuilder<UserModel>( // xây dựng dựa vào dữ liệu bất đồng bộ của th object
        future: _userFuture, //theo dõi giá trị userfuture 
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) { //đang load 
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnap.hasError) { // có lỗi 
            return Center(
              child: Text('Lỗi tải profile: ${userSnap.error}'),
            );
          }

          final user = userSnap.data!;
          if (_isEditing) { // nếu đang edit thì gán dữ liệu vào 
            _editFirstNameCtrl =
                TextEditingController(text: user.firstName);
            _editLastNameCtrl =
                TextEditingController(text: user.lastName);
            _editBioCtrl =
                TextEditingController(text: user.bio ?? '');
            _editPhoneCtrl =
                TextEditingController(text: user.phoneNumber ?? '');
            _editDob = user.dateOfBirth;
          }
        return RefreshIndicator( // kéo để reload 
          onRefresh: _reloadProfile,  // gọi hàm reload profile 
          child: ListView( // dạng list load ra post 
            children: [
              const SizedBox(height: 20),

              /// ===== AVATAR =====
              Center( // căn giữa 
                child: CircleAvatar( // ava hình tròn 
                  radius: 40, // bo tròn 
                  backgroundImage: // nếu có hình thì load 
                      user.picture != null ? NetworkImage(user.picture!) : null,
                  child: user.picture == null // nếu k có hình thì hiện icon 
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),

              const SizedBox(height: 10), // xuốn dòng 

              /// ===== NAME =====
              Center( // căn giữa 
                child: Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              /// ===== BIO =====
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24), //margin
                  child: Text(
                    user.bio!,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              /// ===== EDIT PROFILE  =====
              if (_isEditing && isMyProfile) ...[ // nếu is edit là true và là profile mình thì 
                const SizedBox(height: 16),
                Center(
                  child: Card( // load ra card giữa màn để edit 
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _editFormKey, // gán key để validate 
                        child: Column( // dạng hàng 
                          children: [
                            const Text(
                              'Chỉnh sửa thông tin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            //nhận giá trị
                            TextFormField( 
                              controller: _editFirstNameCtrl,
                              decoration:
                                  const InputDecoration(labelText: 'First name'),
                            ),

                            TextFormField(
                              controller: _editLastNameCtrl,
                              decoration:
                                  const InputDecoration(labelText: 'Last name'),
                            ),

                            TextFormField(
                              controller: _editPhoneCtrl,
                              decoration:
                                  const InputDecoration(labelText: 'Phone'),
                            ),

                            TextFormField(
                              controller: _editBioCtrl,
                              maxLines: 3,
                              decoration:
                                  const InputDecoration(labelText: 'Bio'),
                            ),

                            const SizedBox(height: 12),

                            ElevatedButton( // nút nhấn 
                              onPressed: () async {  // nhấn bất đồng bộ chờ xử lý 
                                final updated = UserModel( // gọi và gán đối tượng 
                                  id: user.id,
                                  firstName: _editFirstNameCtrl.text,
                                  lastName: _editLastNameCtrl.text,
                                  bio: _editBioCtrl.text,
                                  phoneNumber: _editPhoneCtrl.text,
                                  dateOfBirth: _editDob,
                                );

                                await _controller.userModify( // gọi hàm sửa trong controller 
                                  user.id!,
                                  updated,
                                );

                                setState(() { // reload 
                                  _isEditing = false;
                                  _userFuture = _controller.userInfo();
                                });
                              },
                              child: const Text('Lưu'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],


              /// ===== ACTION =====
              if (!isMyProfile) ...[ 
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: canSendRequest // hàm sẽ check nếu true thì được nếu else thì null
                        ? () async {
                            final session = AppSession.instance; // lấy ra cache 
                            final id = user.id!;

                            // Lấy requestId tương ứng với user đang xem
                            final rId = _allRequestIdMap[id];

                            if (session.isFriend(id)) { // nếu là bạn thì có thể hủy và xóa khỏi cache 
                              await _friendController.deleteRequest(id);
                              session.friendIds.remove(id);
                            } 
                            else if (session.isSent(id)) { // lấy ra nếu có id trong sentrequest list và xóa, remove khỏi cache
                              // CANCEL REQUEST - YÊU CẦU RID
                              if (rId != null) {
                                await _friendController.cancelRequest(rId); 
                                session.sentRequestIds.remove(id);
                                _allRequestIdMap.remove(id);
                              } else { // nếu k có request id thì gọi lại để gán và lấy ra lần nữa 
                                await _syncAllRequests(); // gọi lại 
                                final retryId = _allRequestIdMap[id]; //
                                if (retryId != null) {
                                  await _friendController.cancelRequest(retryId);
                                  session.sentRequestIds.remove(id);
                                }
                              }
                            } 
                            else if (session.isReceive(id)) {
                              // ACCEPT - YÊU CẦU RID
                              if (rId != null) {
                                await _friendController.acceptRequest(rId);
                                session.friendIds.add(id);
                                session.receiveRequestIds.remove(id);
                                _allRequestIdMap.remove(id);
                              } else {
                                await _syncAllRequests();
                                final retryId = _allRequestIdMap[id];
                                if (retryId != null) {
                                  await _friendController.acceptRequest(retryId);
                                  session.friendIds.add(id);
                                  session.receiveRequestIds.remove(id);
                                }
                              }
                            } 
                            else {
                              //  SEND REQUEST
                              await _friendController.sendRequest(id);
                              session.sentRequestIds.add(id);
                              await _syncAllRequests();
                            }
                            setState(() {});// reload trang
                          }
                        : null,
                    child: Text(friendButtonText), // lấy giá trị hàm trên để return ví dụ bạn bè, kết bạn dựa vào id 
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),

              if (isMyProfile) // load ra ds bạn bè nếu là bản thân 
                Padding( // khoảng cách
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder<List<UserModel>>( // lấy ra danh sách bạn bè
                    future: _friendsFuture, // theo dõi list 
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snap.hasError) {
                        return const Text('Lỗi tải danh sách bạn bè');
                      }

                      final friends = snap.data!;
                      if (friends.isEmpty) {
                        return const Text('Chưa có bạn bè');
                      }

                      final preview = friends.take(6).toList(); // lấy ra 6 bạn bè đầu tiên để preview

                      return Column( // dạng hàng bên trên là text dưới là ava và tên
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row( // row chứa text và see all 
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Friends · ${friends.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () => _showAllFriends(friends), // ← gọi hàm mở dialog toàn bộ bạn bè
                                child: const Text('See all'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          GridView.builder( // dạng lưới 
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),  // ko scroll
                            itemCount: preview.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3, // 3 cột 
                              mainAxisSpacing: 12, // khoảng cách dọc
                              crossAxisSpacing: 12, // khoảng cách ngang 
                              childAspectRatio: 0.8, // tỉ lệ khung hình 
                            ),
                            itemBuilder: (_, i) { // lấy ra từng profile và truyền vào profile build ra
                              final f = preview[i];
                              return InkWell( // hiệu ứng khi nhấn 
                                borderRadius:
                                    BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push( // nhấn vào bạn bè chuyển sang profile
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfileScreen(
                                        userId: f.id,
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: f.picture != null
                                          ? NetworkImage(f.picture!)
                                          : null,
                                      child: f.picture == null
                                          ? const Icon(Icons.person)
                                          : null,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      f.firstName ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          const Divider(),
                        ],
                      );
                    },
                  ),
                ),

              /// ===== POSTS =====
              FutureBuilder<List<PostModel>>( // hàm trả về post và load ra post trong post item 
                future: _postFuture,
                builder: (_, postSnap) {
                  if (postSnap.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (postSnap.hasError) {
                    return const Center(
                      child: Text('Lỗi tải bài viết'),
                    );
                  }

                  final posts = postSnap.data!;
                  if (posts.isEmpty) {
                    return const Center(
                      child: Text('Chưa có bài viết'),
                    );
                  }

                  return ListView.builder( // load ra post dạng listview 
                    shrinkWrap: true, // cho phép listview 
                    physics:
                        const NeverScrollableScrollPhysics(), // ko scroll 
                    itemCount: posts.length,
                    itemBuilder: (_, i) =>
                        PostItem(post: posts[i]), // truyền vào n post trong post item build ra 
                  );
                },
              ),
            ],
          ),
        );
        },
      ),
    );
  }
}