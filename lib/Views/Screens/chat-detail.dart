// Views/Screens/chat_tab_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_app/Controllers/ChatController.dart';
import 'package:my_app/Controllers/UserController.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Services/TokenStorage.dart';
import 'package:my_app/Services/AuthService.dart';

// ========== CONVERSATION MODEL ==========
class ConversationModel {
  final int id;
  final bool isGroup;
  final String createdAt;
  final List<Map<String, dynamic>> members;
  final Map<String, dynamic>? lastMessage;

  ConversationModel({
    required this.id,
    required this.isGroup,
    required this.createdAt,
    required this.members,
    this.lastMessage,
  });

  // so sánh bằng profile id vì ProfileSerializer không có username
  String getTitle(String myProfileId) {
    if (isGroup) return 'Nhóm chat';
    for (final m in members) {
      final profileId = m['user']?['id']?.toString();
      if (profileId != null && profileId != myProfileId) {
        final first = m['user']?['first_name'] ?? '';
        final last = m['user']?['last_name'] ?? '';
        final name = '$first $last'.trim();
        return name.isEmpty ? 'User $profileId' : name;
      }
    }
    return 'Conversation $id';
  }

  String? getOtherPicture(String myProfileId) {
    for (final m in members) {
      final profileId = m['user']?['id']?.toString();
      if (profileId != null && profileId != myProfileId) {
        return m['user']?['picture'];
      }
    }
    return null;
  }

  int? getOtherProfileId(String myProfileId) {
    for (final m in members) {
      final profileId = m['user']?['id'];
      if (profileId != null && profileId.toString() != myProfileId) {
        return profileId;
      }
    }
    return null;
  }

  String get lastContent => lastMessage?['content'] ?? '';
  String get lastTime => lastMessage?['created_at'] ?? '';

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      isGroup: json['is_group'] ?? false,
      createdAt: json['created_at'] ?? '',
      members: List<Map<String, dynamic>>.from(json['members'] ?? []),
      lastMessage: json['last_message'],
    );
  }
}

// ========== CHAT TAB SCREEN ==========
class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({super.key});

  @override
  State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen> {
  static const String _base = 'http://localhost:8000';

  final _chatController = ChatController();
  final _userController = UserController();

  List<UserModel> _friends = [];
  List<ConversationModel> _conversations = [];
  String? _myProfileId; // dùng profile id thay vì username vì ProfileSerializer không có username
  bool _loadingFriends = true;
  bool _loadingConvs = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myProfileId = await TokenStorage.getId(); // lấy profile id
    await Future.wait([_loadFriends(), _loadConversations()]);
  }

  Future<void> _loadFriends() async {
    try {
      // giống ProfileScreen: userInfo() trước để lấy id đúng, sau đó viewFriends(id)
      final user = await _userController.userInfo();
      final friends = await _userController.viewFriends(user.id!);
      if (mounted) setState(() { _friends = friends; _loadingFriends = false; });
    } catch (e) {
      debugPrint("Load friends error: $e");
      if (mounted) setState(() => _loadingFriends = false);
    }
  }

  Future<void> _loadConversations() async {
    try {
      final res = await authGet(url: '$_base/api/chat/conversations/');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['results'] ?? []);
        final convs = (list as List).map((e) => ConversationModel.fromJson(e)).toList();
        if (mounted) setState(() { _conversations = convs; _loadingConvs = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingConvs = false);
    }
  }

  Future<void> _openChat(int profileId, String title, {String? picture}) async {
    try {
      final convId = await _chatController.startConversation(profileId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: convId,
            title: title,
            avatarUrl: picture,
          ),
        ),
      ).then((_) => _loadConversations()); // refresh list khi quay lại
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở cuộc trò chuyện')),
      );
    }
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black),
            onPressed: () {}, // TODO: tìm kiếm người mới
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.wait([_loadFriends(), _loadConversations()]),
        child: CustomScrollView(
          slivers: [

            // ===== PHẦN BẠN BÈ ACTIVE (hàng ngang) =====
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Bạn bè',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  SizedBox(
                    height: 90,
                    child: _loadingFriends
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : _friends.isEmpty
                            ? const Center(
                                child: Text('Chưa có bạn bè', style: TextStyle(color: Colors.grey)),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _friends.length,
                                itemBuilder: (_, i) {
                                  final f = _friends[i];
                                  final name = '${f.firstName ?? ''} ${f.lastName ?? ''}'.trim();
                                  return GestureDetector(
                                    onTap: () => _openChat(
                                      f.id!,
                                      name.isEmpty ? 'Chat' : name,
                                      picture: f.picture,
                                    ),
                                    child: Container(
                                      width: 68,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Column(
                                        children: [
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 28,
                                                backgroundImage: f.picture != null
                                                    ? NetworkImage(f.picture!)
                                                    : null,
                                                backgroundColor: Colors.blue.shade100,
                                                child: f.picture == null
                                                    ? Text(
                                                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      )
                                                    : null,
                                              ),
                                              // chấm xanh online (UI only)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.white, width: 2),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            name.isEmpty ? 'User' : name.split(' ').first,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  const Divider(height: 16),
                ],
              ),
            ),

            // ===== PHẦN DANH SÁCH ĐOẠN CHAT =====
            _loadingConvs
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : _conversations.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(
                            child: Text('Chưa có đoạn chat nào', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final conv = _conversations[i];
                            final title = conv.getTitle(_myProfileId ?? '');
                            final picture = conv.getOtherPicture(_myProfileId ?? '');
                            final lastMsg = conv.lastContent;
                            final lastTime = _formatTime(conv.lastTime);

                            return InkWell(
                              onTap: () => _openChat(
                                // lấy profile_id của người kia từ members
                                conv.getOtherProfileId(_myProfileId ?? '') ?? conv.id,
                                title,
                                picture: picture,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    // avatar
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage: picture != null ? NetworkImage(picture) : null,
                                      backgroundColor: Colors.blue.shade100,
                                      child: picture == null
                                          ? Text(
                                              title.isNotEmpty ? title[0].toUpperCase() : '?',
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    // tên + tin nhắn cuối
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            lastMsg.isEmpty ? 'Bắt đầu cuộc trò chuyện' : lastMsg,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // thời gian
                                    Text(
                                      lastTime,
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: _conversations.length,
                        ),
                      ),
          ],
        ),
      ),
    );
  }

}

// ========== CHAT SCREEN (giống Messenger) ==========
class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String title;
  final String? avatarUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
    this.avatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ChatController();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  StreamSubscription<MessageModel>? _messageSub;
  StreamSubscription<String>? _errorSub;

  List<MessageModel> _messages = [];
  String? _myUsername;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myUsername = await TokenStorage.getId();

    try {
      final history = await _controller.getMessages(widget.conversationId);
      if (mounted) {
        setState(() { _messages = history; _loading = false; });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }

    _messageSub = _controller.messages.listen((msg) {
      if (!mounted) return;
      setState(() => _messages.add(msg));
      _scrollToBottom();
    });

    _errorSub = _controller.errors.listen((error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    });

    try {
      await _controller.connect(widget.conversationId);
      await _controller.seenMessage(widget.conversationId);
    } catch (_) {}
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _controller.sendMessage(text);
    _textController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _errorSub?.cancel();
    _controller.disconnect();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context), // quay lại
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.avatarUrl != null
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              backgroundColor: Colors.blue.shade100,
              child: widget.avatarUrl == null
                  ? Text(
                      widget.title.isNotEmpty ? widget.title[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Text(
                  'Đang hoạt động',
                  style: TextStyle(color: Colors.green, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // danh sách tin nhắn
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg.senderUsername == _myUsername;
                      final showAvatar = !isMe &&
                          (i == _messages.length - 1 ||
                              _messages[i + 1].senderUsername != msg.senderUsername);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // avatar người khác
                            if (!isMe)
                              showAvatar
                                  ? CircleAvatar(
                                      radius: 14,
                                      backgroundImage: widget.avatarUrl != null
                                          ? NetworkImage(widget.avatarUrl!)
                                          : null,
                                      backgroundColor: Colors.blue.shade100,
                                      child: widget.avatarUrl == null
                                          ? Text(
                                              msg.senderName.isNotEmpty
                                                  ? msg.senderName[0].toUpperCase()
                                                  : '?',
                                              style: const TextStyle(fontSize: 10),
                                            )
                                          : null,
                                    )
                                  : const SizedBox(width: 28),

                            const SizedBox(width: 6),

                            // bubble
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.65,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.blue
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: isMe
                                        ? const Radius.circular(18)
                                        : const Radius.circular(4),
                                    bottomRight: isMe
                                        ? const Radius.circular(4)
                                        : const Radius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  msg.content,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // input gửi tin nhắn
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Aa',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                            maxLines: null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                // padding cho keyboard
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 4),
              ],
            ),
    );
  }
}