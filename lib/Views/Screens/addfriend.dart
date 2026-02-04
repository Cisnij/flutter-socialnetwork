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
  final UserController _controller = UserController();
  final FriendController _friendController = FriendController();

  List<UserModel> _users = [];
  bool _loading = false;

  /// ================= SEARCH =================
  Future<void> _search(String name) async {
    if (name.isEmpty) {
      setState(() => _users = []);
      return;
    }

    setState(() => _loading = true);

    try {
      final result = await _controller.searchUser(name);
      setState(() => _users = result);
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSession.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết bạn'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// ================= SEARCH BOX =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Tìm bạn theo tên...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// ================= RESULT =================
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? const Center(child: Text('Không có kết quả'))
                    : ListView.builder(
                        itemCount: _users.length,
                        itemBuilder: (_, i) {
                          final user = _users[i];
                          final int? id = user.id;

                          return ListTile(
                            leading: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProfileScreen(userId: id),
                                  ),
                                );
                              },
                              child: CircleAvatar(
                                backgroundImage: user.picture != null
                                    ? NetworkImage(user.picture!)
                                    : null,
                                child: user.picture == null
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                            ),
                            title: Text(
                              '${user.firstName} ${user.lastName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            /// ================= ACTION =================
                            trailing: Builder(
                              builder: (_) {
                                // 1️⃣ chính mình
                                if (session.isMe(id)) {
                                  return const SizedBox.shrink();
                                }

                                // 2️⃣ đã là bạn
                                if (session.isFriend(id)) {
                                  return const Text(
                                    'Bạn bè',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                }

                                // 3️⃣ người đó gửi lời mời cho tôi
                                if (session.isReceive(id)) {
                                  return ElevatedButton(
                                    onPressed: () async {
                                      final ok = await _friendController
                                          .acceptRequest(id!);
                                      if (ok && mounted) {
                                        // reload cache cho chắc
                                        session.clear();
                                        await session.init();
                                        setState(() {});
                                      }
                                    },
                                    child: const Text('Chấp nhận'),
                                  );
                                }

                                // 4️⃣ tôi đã gửi cho người đó
                                if (session.isSent(id)) {
                                  return const Text(
                                    'Đã gửi',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  );
                                }

                                // 5️⃣ người lạ
                                return ElevatedButton(
                                  onPressed: () async {
                                    final ok = await _friendController
                                        .sendRequest(id!);
                                    if (ok && mounted) {
                                      session.sentRequestIds.add(id);
                                      setState(() {});
                                    }
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
