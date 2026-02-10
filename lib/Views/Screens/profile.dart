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

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserController _controller = UserController(); // gọi controller
  final FriendController _friendController = FriendController();

  // === BIẾN THÊM VÀO ĐỂ FIX LỖI REQUEST ID ===
  Map<int, int> _allRequestIdMap = {}; // Lưu: userId -> requestId (cho cả nhận và gửi)

  // ===== EDIT USER =====
  bool _isEditing = false;
  final _editFormKey = GlobalKey<FormState>();

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
      widget.userId == AppSession.instance.myId; // check profile nếu ram đã lưu id

  // --- HÀM SYNC ĐỂ LẤY REQUEST ID TRƯỚC KHI THỰC HIỆN ---
  Future<void> _syncAllRequests() async {
    try {
      // 1. Lấy lời mời nhận được (Income)
      final income = await _friendController.incomeRequest();
      if (income != null) {
        for (var req in income) {
          _allRequestIdMap[req['sender']['id']] = req['id'];
        }
      }
      // 2. Lấy lời mời đã gửi (Sent) - Để lấy rid cho nút Cancel
      final sent = await _friendController.outgoingRequest(); 
      if (sent != null) {
        for (var req in sent) {
          _allRequestIdMap[req['receiver']['id']] = req['id'];
        }
      }
    } catch (e) {
      debugPrint("Sync error: $e");
    }
  }

  Future<void> _reloadProfile() async { // hàm reload
    await _syncAllRequests(); // Đồng bộ ID trước
    if (isMyProfile) {
      _userFuture = _controller.userInfo();
      _postFuture =
          _userFuture.then((user) => _controller.userPosts(user.id!));
      _friendsFuture =
          _userFuture.then((user) => _controller.viewFriends(user.id!));
    } else {
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
    final session = AppSession.instance;
    final id = widget.userId;

    if (id == null) return ''; // hàm check trong ram dựa vào id truyền vào profile và trả về giá trị 
    if (session.isFriend(id)) return 'Hủy kết bạn';
    if (session.isSent(id)) return 'Đã gửi';
    if (session.isReceive(id)) return 'Chờ xác nhận';
    return 'Kết bạn';
  }

  /// ===== FRIEND BUTTON ENABLE =====
  bool get canSendRequest { // khả năng nhấn của nút , check nếu là mình thì kh thể ấn gì 
    final id = widget.userId;
    if (id == null) return false;
    return true;
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isMyProfile ? 'Profile' : 'User Profile'),
        actions: [
          if (isMyProfile) // hành động đc build logout nếu là bản thân
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await TokenStorage.clear();
                AppSession.instance.clear();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
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
        future: _userFuture,
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnap.hasError) {
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
        return RefreshIndicator(
          onRefresh: _reloadProfile, 
          child: ListView(
            children: [
              const SizedBox(height: 20),

              /// ===== AVATAR =====
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      user.picture != null ? NetworkImage(user.picture!) : null,
                  child: user.picture == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),

              const SizedBox(height: 10),

              /// ===== NAME =====
              Center(
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
              /// ===== EDIT PROFILE (ADD ONLY) =====
              if (_isEditing && isMyProfile) ...[
                const SizedBox(height: 16),
                Center(
                  child: Card(
                    elevation: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _editFormKey,
                        child: Column(
                          children: [
                            const Text(
                              'Chỉnh sửa thông tin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

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

                            ElevatedButton(
                              onPressed: () async {
                                final updated = UserModel(
                                  id: user.id,
                                  firstName: _editFirstNameCtrl.text,
                                  lastName: _editLastNameCtrl.text,
                                  bio: _editBioCtrl.text,
                                  phoneNumber: _editPhoneCtrl.text,
                                  dateOfBirth: _editDob,
                                );

                                await _controller.userModify(
                                  user.id!,
                                  updated,
                                );

                                setState(() {
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
                            final session = AppSession.instance;
                            final id = user.id!;

                            // Lấy requestId tương ứng với user đang xem
                            final rId = _allRequestIdMap[id];

                            if (session.isFriend(id)) {
                              await _friendController.deleteRequest(id);
                              session.friendIds.remove(id);
                            } 
                            else if (session.isSent(id)) {
                              // CANCEL REQUEST - YÊU CẦU RID
                              if (rId != null) {
                                await _friendController.cancelRequest(rId); 
                                session.sentRequestIds.remove(id);
                                _allRequestIdMap.remove(id);
                              } else {
                                await _syncAllRequests();
                                final retryId = _allRequestIdMap[id];
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder<List<UserModel>>(
                    future: _friendsFuture,
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

                      final preview = friends.take(6).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                onPressed: () {},
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
                              crossAxisCount: 3, // các khoảng cách
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.8,
                            ),
                            itemBuilder: (_, i) { // lấy ra từng profile và truyền vào profile build ra
                              final f = preview[i];
                              return InkWell( // hiệu ứng ấn
                                borderRadius:
                                    BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
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
              FutureBuilder<List<PostModel>>(
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

                  return ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (_, i) =>
                        PostItem(post: posts[i]),
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