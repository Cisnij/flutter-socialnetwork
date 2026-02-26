import 'package:flutter/material.dart';
import 'package:my_app/Views/Screens/chat.dart';

enum ChatViewState { list, detail }

class ChatTabScreen extends StatefulWidget {
  const ChatTabScreen({Key? key}) : super(key: key);

  @override
  State<ChatTabScreen> createState() => _ChatTabScreenState();
}

class _ChatTabScreenState extends State<ChatTabScreen> {
  ChatViewState _state = ChatViewState.list;

  int? _conversationId;
  String? _title;

  void _openConversation(int id, String title) {
    setState(() {
      _conversationId = id;
      _title = title;
      _state = ChatViewState.detail;
    });
  }

  void _backToList() {
    setState(() {
      _state = ChatViewState.list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _state == ChatViewState.list
          ? _buildConversationList()
          : ChatScreen(
              conversationId: _conversationId!,
              title: _title!,
              onBack: _backToList,
            ),
    );
  }

  Widget _buildConversationList() {
    // TODO: Sau này load từ API
    final conversations = [
      {'id': 1, 'name': 'Nguyễn Văn A'},
      {'id': 2, 'name': 'Trần Văn B'},
    ];

    return ListView.builder(
      key: const ValueKey('list'),
      itemCount: conversations.length,
      itemBuilder: (_, index) {
        final conv = conversations[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(conv['name'] as String),
          subtitle: const Text("Tin nhắn gần nhất..."),
          onTap: () => _openConversation(
            conv['id'] as int,
            conv['name'] as String,
          ),
        );
      },
    );
  }
}