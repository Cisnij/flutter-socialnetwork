// Controllers/ChatController.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:my_app/Services/AuthService.dart';
import 'package:my_app/Services/TokenStorage.dart';

// ========== MESSAGE MODEL ==========
class MessageModel {
  final int id;
  final String content;
  final String messageType;
  final String createdAt;
  final Map<String, dynamic>? sender;

  MessageModel({
    required this.id,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.sender,
  });

  String get senderUserId => sender?['user']?.toString() ?? '';

  String get senderName {
    final first = sender?['first_name'] ?? '';
    final last = sender?['last_name'] ?? '';
    return '$first $last'.trim().isEmpty ? 'User' : '$first $last'.trim();
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'text',
      createdAt: json['created_at'] ?? '',
      sender: json['sender'],
    );
  }

  factory MessageModel.fromWebSocket(Map<String, dynamic> json) {
    final rawSenderId = json['sender_id'];
    final senderId = rawSenderId is int
        ? rawSenderId
        : int.tryParse(rawSenderId?.toString() ?? '');
    return MessageModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      content: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      sender: {
        'user': senderId,
        'first_name': json['sender'],
        'last_name': '',
      },
    );
  }
}

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
      if (profileId != null && profileId != myProfileId) return m['user']?['picture'];
    }
    return null;
  }

  int? getOtherProfileId(String myProfileId) {
    for (final m in members) {
      final profileId = m['user']?['id'];
      if (profileId != null && profileId.toString() != myProfileId) {
        return profileId is int ? profileId : int.tryParse(profileId.toString());
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

// ========== WEBSOCKET SERVICE ==========
class _ChatService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<MessageModel>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<MessageModel> get messages => _messageController.stream;
  Stream<String> get errors => _errorController.stream;

  Future<void> connect(int conversationId) async {
    final token = await TokenStorage.getAccessToken();
    final uri = Uri.parse('ws://localhost:8000/ws/chat/$conversationId/?token=$token');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          if (decoded.containsKey('error')) {
            _errorController.add(decoded['error']);
            return;
          }
          _messageController.add(MessageModel.fromWebSocket(decoded));
        } catch (e) {
          debugPrint('WebSocket parse error: $e');
        }
      },
      onError: (e) => _errorController.add('Mất kết nối'),
    );
  }

  void sendMessage(String message) {
    _channel?.sink.add(jsonEncode({'message': message}));
  }

  void disconnect() {
    _channel?.sink.close();
  }
}

// ========== CHAT CONTROLLER ==========
class ChatController {
  static const String _base = 'http://localhost:8000';
  final _chatService = _ChatService();

  Stream<MessageModel> get messages => _chatService.messages;
  Stream<String> get errors => _chatService.errors;

  Future<List<ConversationModel>> getConversations() async {
    final res = await authGet(url: '$_base/api/chat/conversations/');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []);
      return (list as List).map((e) => ConversationModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải danh sách chat');
  }

  Future<int> startConversation(int profileId) async {
    final res = await authFetch(url: '$_base/api/chat/start/$profileId/', body: {});
    if (res.statusCode == 200 || res.statusCode == 201) return jsonDecode(res.body)['id'];
    throw Exception('Không thể bắt đầu chat');
  }

  // API sort mới nhất trước (-created_at):
  //   trang 1 = tin mới nhất, next = trang cũ hơn
  //
  // Load trang 1, results đang mới→cũ → reverse thành cũ→mới để hiển thị đúng
  // nextUrl = next = trang cũ hơn, dùng khi kéo lên
  Future<(List<MessageModel>, String?)> getFirstPage(int conversationId) async {
    final res = await authGet(url: '$_base/api/chat/messages/list/$conversationId/');
    if (res.statusCode != 200) throw Exception('Lỗi tải tin nhắn');
    final data = jsonDecode(res.body);

    if (data is List) {
      final msgs = (data as List).map((e) => MessageModel.fromJson(e)).toList();
      return (msgs.reversed.toList(), null);
    }

    final results = data['results'] as List;
    // results: mới→cũ → reversed: cũ→mới
    final msgs = results.map((e) => MessageModel.fromJson(e)).toList().reversed.toList();
    return (msgs, data['next'] as String?);
  }

  // Kéo lên → load trang cũ hơn (next của trang hiện tại)
  // results đang mới→cũ → reverse thành cũ→mới → insertAll(0, ...) vào đầu list
  Future<(List<MessageModel>, String?)> getOlderPage(String url) async {
    final res = await authGet(url: url);
    if (res.statusCode != 200) throw Exception('Lỗi tải tin nhắn');
    final data = jsonDecode(res.body);
    final results = data['results'] as List;
    final msgs = results.map((e) => MessageModel.fromJson(e)).toList().reversed.toList();
    return (msgs, data['next'] as String?);
  }

  Future<void> connect(int conversationId) => _chatService.connect(conversationId);
  void sendMessage(String message) => _chatService.sendMessage(message);
  void disconnect() => _chatService.disconnect();

  Future<void> seenMessage(int conversationId) async {
    await authFetch(url: '$_base/api/chat/messages/seen/$conversationId/', body: {});
  }
}