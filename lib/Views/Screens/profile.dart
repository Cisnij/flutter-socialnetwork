import 'package:flutter/material.dart';
import 'package:my_app/Controllers/FriendController.dart';
import 'package:my_app/Controllers/UserController.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Models/PostModel.dart';
import 'package:my_app/Services/TokenStorage.dart';
import 'package:my_app/Views/Screens/post_item.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserController _controller = UserController();
  final FriendController _friendController = FriendController();

  late Future<UserModel> _userFuture;
  late Future<List<PostModel>> _postFuture;
  late Future<List<UserModel>> _friendsFuture; // hàm future chứ list friend sau khi gọi api

  bool get isMyProfile => widget.userId == null;

  @override
  void initState() {
    super.initState();

    if (isMyProfile) {
      _userFuture = _controller.userInfo();
      _postFuture =
          _userFuture.then((user) => _controller.userPosts(user.id!));
      _friendsFuture =
        _userFuture.then((user) => _controller.viewFriends(user.id!)); // gán friend future cho data trả về 
    } else {
      _userFuture = _controller.viewPage(widget.userId!);
      _postFuture = _controller.userPosts(widget.userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isMyProfile ? 'Profile' : 'User Profile'),
        actions: [
          if (isMyProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await TokenStorage.clear();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (_) => false,
                  );
                }
              },
            ),
        ],
      ),
      body: FutureBuilder<UserModel>(
        future: _userFuture, // 
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

          return ListView(
            children: [
              const SizedBox(height: 20),

              /// ================= AVATAR =================
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

              /// ================= NAME =================
              Center(
                child: Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              /// ================= BIO =================
              if (user.bio != null && user.bio!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    user.bio!,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              /// ================= ACTION =================
              if (!isMyProfile) ...[
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _friendController.sendRequest(user.id!);
                    },
                    child: const Text('Add Friend'),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),

              /// ================= FRIEND PREVIEW =================
              if (isMyProfile)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: FutureBuilder<List<UserModel>>(
                    future: _friendsFuture, // theo dỗi friend future nếu có data thì theo dõi giá trị
                    builder: (context, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
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
                          /// header
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Friends · ${friends.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // sau này mở screen danh sách bạn bè
                                },
                                child: const Text('See all'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          /// grid preview
                          GridView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: preview.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.8,
                            ),
                            itemBuilder: (_, i) {
                              final f = preview[i];
                              return InkWell(
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

              /// ================= POSTS =================
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
          );
        },
      ),
    );
  }
}
