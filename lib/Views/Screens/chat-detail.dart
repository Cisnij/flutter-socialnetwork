// Views/Screens/chat_tab_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_app/Controllers/ChatController.dart';
import 'package:my_app/Controllers/UserController.dart';
import 'package:my_app/Models/UserModel.dart';
import 'package:my_app/Services/TokenStorage.dart';

// ========== CHAT TAB SCREEN ==========
class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({super.key});

  @override
  State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen> {
  final _chatController = ChatController();
  final _userController = UserController();

  List<UserModel> _friends = [];
  List<ConversationModel> _conversations = [];
  String? _myProfileId;
  bool _loadingFriends = true;
  bool _loadingConvs = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myProfileId = await TokenStorage.getProfileId();
    await Future.wait([_loadFriends(), _loadConversations()]); //đợi hàm chạy hết
  }

  Future<void> _loadFriends() async {
    try {
      final user = await _userController.userInfo();
      final friends = await _userController.viewFriends(user.id!);
      if (mounted) setState(() { _friends = friends; _loadingFriends = false; });
    } catch (e) {
      debugPrint('Load friends error: $e');
      if (mounted) setState(() => _loadingFriends = false);
    }
  }

  Future<void> _loadConversations() async {
    try {
      final convs = await _chatController.getConversations();
      if (mounted) setState(() { _conversations = convs; _loadingConvs = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingConvs = false);
    }
  }

  Future<void> _openChat(int profileId, String title, {String? picture}) async {
    try {
      final convId = await _chatController.startConversation(profileId);
      if (!mounted) return;

      // ✅ set unread = 0 ngay lập tức trên UI trước khi push, không cần đợi server
      setState(() {
        final idx = _conversations.indexWhere((c) => c.id == convId);
        if (idx != -1) {
          _conversations[idx] = ConversationModel(
            id: _conversations[idx].id,
            isGroup: _conversations[idx].isGroup,
            createdAt: _conversations[idx].createdAt,
            members: _conversations[idx].members,
            lastMessage: _conversations[idx].lastMessage,
            unreadCount: 0, // ✅ set về 0 ngay lập tức
          );
        }
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: convId, title: title, avatarUrl: picture),
        ),
      ).then((_) async {
        // reload lại để đồng bộ với server sau khi pop về
        await Future.delayed(const Duration(milliseconds: 500)); // delay để backend ghi seen xong
        _loadConversations();
      });
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
        title: const Text('Tin nhắn',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          // IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => await Future.wait([_loadFriends(), _loadConversations()]),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text('Bạn bè', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  SizedBox(
                    height: 90,
                    child: _loadingFriends
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : _friends.isEmpty
                            ? const Center(child: Text('Chưa có bạn bè', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _friends.length,
                                itemBuilder: (_, i) {
                                  final f = _friends[i];
                                  final name = '${f.firstName ?? ''} ${f.lastName ?? ''}'.trim();
                                  return GestureDetector(
                                    onTap: () => _openChat(f.id!, name.isEmpty ? 'Chat' : name, picture: f.picture),
                                    child: Container(
                                      width: 68,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Column(
                                        children: [
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 28,
                                                backgroundImage: f.picture != null ? NetworkImage(f.picture!) : null,
                                                backgroundColor: Colors.blue.shade100,
                                                child: f.picture == null
                                                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                        style: const TextStyle(fontWeight: FontWeight.bold))
                                                    : null,
                                              ),
                                              Positioned(
                                                right: 0, bottom: 0,
                                                child: Container(
                                                  width: 14, height: 14,
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
            _loadingConvs
                ? const SliverToBoxAdapter(
                    child: Padding(padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2))))
                : _conversations.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(padding: EdgeInsets.only(top: 60),
                            child: Center(child: Text('Chưa có đoạn chat nào', style: TextStyle(color: Colors.grey)))))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) {
                            final conv = _conversations[i];
                            final title = conv.getTitle(_myProfileId ?? '');
                            final picture = conv.getOtherPicture(_myProfileId ?? '');
                            final unread = conv.unreadCount;
                            return InkWell(
                              onTap: () => _openChat(
                                conv.getOtherProfileId(_myProfileId ?? '') ?? conv.id,
                                title, picture: picture,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundImage: picture != null ? NetworkImage(picture) : null,
                                      backgroundColor: Colors.blue.shade100,
                                      child: picture == null
                                          ? Text(title.isNotEmpty ? title[0].toUpperCase() : '?',
                                              style: const TextStyle(fontWeight: FontWeight.bold))
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: TextStyle(
                                              fontWeight: unread > 0
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            conv.lastContent.isEmpty ? 'Bắt đầu cuộc trò chuyện' : conv.lastContent,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: unread > 0
                                                  ? Colors.black87
                                                  : Colors.grey.shade600,
                                              fontWeight: unread > 0
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatTime(conv.lastTime),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: unread > 0 ? Colors.blue : Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (unread > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              unread > 99 ? '99+' : '$unread',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
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

// ========== CHAT SCREEN ==========
class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String title;
  final String? avatarUrl;
  const ChatScreen({super.key, required this.conversationId, required this.title, this.avatarUrl});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = ChatController();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription? _msgSub;
  StreamSubscription? _errSub;

  // index 0 = cũ nhất (trên cùng), cuối = mới nhất (dưới cùng)
  List<MessageModel> _messages = [];
  String? _myUserId;
  bool _loading = true;
  bool _loadingMore = false;
  String? _olderPageUrl; // next = trang cũ hơn, null = đã hết

  @override
  void initState() {
    super.initState();
    _init();
    _scrollController.addListener(() {
      // kéo lên gần đầu → load tin cũ hơn
      if (_scrollController.position.pixels <= 150 &&
          !_loadingMore &&
          _olderPageUrl != null) {
        _loadOlderMessages();
      }
    });
  }

  Future<void> _init() async {
    _myUserId = await TokenStorage.getId();

    try {
      // trang 1 = mới nhất, reversed → cũ nhất ở index 0
      final (msgs, nextUrl) = await _controller.getFirstPage(widget.conversationId);
      _olderPageUrl = nextUrl; // next = trang cũ hơn

      if (mounted) {
        setState(() { _messages = msgs; _loading = false; });
        // scroll xuống dưới cùng (tin mới nhất)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }

      // ✅ seen TRƯỚC khi connect WebSocket, có await để đảm bảo backend ghi xong
      await _controller.seenMessage(widget.conversationId);

      await _controller.connect(widget.conversationId);

      // tin mới từ WebSocket → add vào cuối (dưới cùng)
      _msgSub = _controller.messages.listen((msg) {
        if (!mounted) return;
        setState(() => _messages.add(msg));

        // ✅ seen lại mỗi khi nhận tin mới qua WebSocket để unread luôn = 0 khi đang trong chat
        _controller.seenMessage(widget.conversationId);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });

      _errSub = _controller.errors.listen((err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      });
    } catch (e) {
      debugPrint('init error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_loadingMore || _olderPageUrl == null) return;
    setState(() => _loadingMore = true);

    try {
      final (olderMsgs, nextUrl) = await _controller.getOlderPage(_olderPageUrl!);
      _olderPageUrl = nextUrl;

      if (mounted) {
        final oldOffset = _scrollController.offset;
        final oldMax = _scrollController.position.maxScrollExtent;

        setState(() {
          _messages.insertAll(0, olderMsgs); // tin cũ hơn vào đầu list
          _loadingMore = false;
        });

        // giữ scroll position không nhảy lên đầu
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final newMax = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(oldOffset + (newMax - oldMax));
        });
      }
    } catch (e) {
      debugPrint('loadOlder error: $e');
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _controller.sendMessage(text);
    _textController.clear();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _errSub?.cancel();
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
          onPressed: () async {
            // ✅ gọi seen lần cuối trước khi pop để chắc chắn backend đã ghi xong
            await _controller.seenMessage(widget.conversationId);
            if (mounted) Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
              backgroundColor: Colors.blue.shade100,
              child: widget.avatarUrl == null
                  ? Text(widget.title.isNotEmpty ? widget.title[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                const Text('Đang hoạt động', style: TextStyle(color: Colors.green, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_loadingMore) const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final msg = _messages[i];
                      final isMe = msg.senderUserId == _myUserId;
                      final showAvatar = !isMe &&
                          (i == _messages.length - 1 ||
                              _messages[i + 1].senderUserId != msg.senderUserId);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isMe)
                              showAvatar
                                  ? CircleAvatar(
                                      radius: 14,
                                      backgroundImage: widget.avatarUrl != null
                                          ? NetworkImage(widget.avatarUrl!) : null,
                                      backgroundColor: Colors.blue.shade100,
                                      child: widget.avatarUrl == null
                                          ? Text(msg.senderName.isNotEmpty
                                              ? msg.senderName[0].toUpperCase() : '?',
                                              style: const TextStyle(fontSize: 10))
                                          : null,
                                    )
                                  : const SizedBox(width: 28),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.65),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue : Colors.grey.shade200,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 18),
                                  ),
                                ),
                                child: Text(msg.content,
                                    style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
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
                              borderRadius: BorderRadius.circular(24)),
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Aa',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onSubmitted: (_) => _send(),
                            maxLines: null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                          child: const Icon(Icons.send, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 4),
              ],
            ),
    );
  }
}
