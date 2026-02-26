// Controllers/ChatController.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:my_app/Services/AuthService.dart';
import 'package:my_app/Services/TokenStorage.dart';

// ===== MODEL =====
class MessageModel {
  final int id;
  final String content;    // REST API trả về 'content'
  final String messageType;
  final String createdAt;
  final Map<String, dynamic>? sender; // ProfileSerializer nested

  MessageModel({
    required this.id,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.sender,
  });

  // lấy username để phân biệt bubble trái/phải
  String get senderUsername => sender?['id']?.toString() ?? '';

  // lấy tên hiển thị trong bubble
  String get senderName {
    final first = sender?['first_name'] ?? '';
    final last = sender?['last_name'] ?? '';
    return '$first $last'.trim().isEmpty ? senderUsername : '$first $last'.trim();
  }

  // parse từ REST API (MessageSerializer trả về 'content')
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'text',
      createdAt: json['created_at'] ?? '',
      sender: json['sender'],
    );
  }

  // parse từ WebSocket (consumer trả về 'message' thay vì 'content')
  factory MessageModel.fromWebSocket(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      content: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      createdAt: json['created_at'] ?? '',
      sender: {'user': {'username': json['sender']}}, // WebSocket chỉ trả về username string
    );
  }
}

// ===== WEBSOCKET SERVICE =====
class _ChatService {
  WebSocketChannel? _channel;
  final _messageController = StreamController<MessageModel>.broadcast(); // broadcast để nhiều widget lắng nghe
  final _errorController = StreamController<String>.broadcast(); // lỗi từ server (block, pending...)

  Stream<MessageModel> get messages => _messageController.stream;
  Stream<String> get errors => _errorController.stream;

  Future<void> connect(int conversationId) async {
    final token = await TokenStorage.getAccessToken();
    // token qua query param vì WebSocket không có Authorization header
    final uri = Uri.parse('ws://localhost:8000/ws/chat/$conversationId/?token=$token');
    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen(
      (data) {
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          if (decoded.containsKey('error')) {
            _errorController.add(decoded['error']); // server báo lỗi → hiện snackbar
            return;
          }
          _messageController.add(MessageModel.fromWebSocket(decoded)); // tin nhắn bình thường
        } catch (e) {
          print('WebSocket parse error: $e');
        }
      },
      onError: (e) => _errorController.add('Mất kết nối'),
      onDone: () => print('WebSocket closed'),
    );
  }

  void sendMessage(String message) {
    _channel?.sink.add(jsonEncode({'message': message})); // gửi lên server, consumer.receive() nhận
  }

  void disconnect() {
    _channel?.sink.close();
    _messageController.close();
    _errorController.close();
  }
}

// ===== CONTROLLER =====
class ChatController {
  static const String _base = 'http://localhost:8000';

  // WebSocket service dùng nội bộ, ChatScreen lấy qua getter
  final _chatService = _ChatService();
  Stream<MessageModel> get messages => _chatService.messages;
  Stream<String> get errors => _chatService.errors;

  // bắt đầu hoặc lấy conversation với người bạn, truyền vào profile_id
  // StartConversationAPIView: get_object_or_404(Profile, id=user_id)
  Future<int> startConversation(int profileId) async {
    final res = await authFetch(
      url: '$_base/api/chat/start/$profileId/',
      body: {},
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body)['id']; // trả về conversation_id để mở ChatScreen
    }
    throw Exception('Không thể bắt đầu cuộc trò chuyện');
  }

  // lấy lịch sử tin nhắn - ConversationMessage view
  Future<List<MessageModel>> getMessages(int conversationId) async {
    final res = await authGet(url: '$_base/api/chat/messages/list/$conversationId/');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final list = data is List ? data : (data['results'] ?? []); // handle pagination
      return (list as List).map((e) => MessageModel.fromJson(e)).toList();
    }
    throw Exception('Lỗi tải tin nhắn');
  }

  // kết nối WebSocket
  Future<void> connect(int conversationId) => _chatService.connect(conversationId);

  // gửi tin nhắn qua WebSocket
  void sendMessage(String message) => _chatService.sendMessage(message);

  // ngắt WebSocket khi thoát màn hình
  void disconnect() => _chatService.disconnect();

  // đánh dấu đã xem khi mở màn hình
  Future<void> seenMessage(int conversationId) async {
    await authFetch(url: '$_base/api/chat/messages/seen/$conversationId/', body: {});
  }
}