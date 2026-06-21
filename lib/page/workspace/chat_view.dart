import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startbuddy/models/startup.dart';
import 'package:startbuddy/models/chat.dart';
import 'package:startbuddy/service/db/db_service.dart';
import 'package:startbuddy/service/http.dart';
import 'package:startbuddy/theme.dart';
import 'package:startbuddy/widgets/markdown_text.dart';

class ChatView extends StatefulWidget {
  final Startup startup;

  const ChatView({super.key, required this.startup});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final DbService _db = DbService();
  final HttpService _http = HttpService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String? _chatId;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadChatSession();
  }

  Future<void> _loadChatSession() async {
    try {
      setState(() => _loading = true);
      // Load chats for this startup
      final chatsData = await _db.fetchChatsForStartup(widget.startup.id);

      if (!mounted) return;

      if (chatsData.isNotEmpty) {
        final chat = StartupChat.fromJson(chatsData.first);
        _chatId = chat.id;
        final msgsData = await _db.fetchMessagesForChat(_chatId!);

        if (!mounted) return;
        setState(() {
          _messages = msgsData.map((m) => ChatMessage.fromJson(m)).toList();
          _loading = false;
        });
        _scrollToBottom();
      } else {
        setState(() {
          _messages = [];
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load chat: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    _messageController.clear();
    setState(() {
      _sending = true;
      // Optimistic user message update
      _messages.add(
        ChatMessage(
          id: '',
          createdAt: DateTime.now(),
          chatId: _chatId ?? '',
          sender: 'user',
          content: text,
        ),
      );
    });
    _scrollToBottom();

    try {
      final response = await _http.chat(
        startupId: widget.startup.id,
        chatId: _chatId,
        message: text,
      );

      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['ok'] == true) {
        final data = body['data'];
        final String newChatId = data['chatId'];
        final String reply = data['message'];

        if (!mounted) return;

        setState(() {
          _chatId = newChatId;
          _messages.add(
            ChatMessage(
              id: '',
              createdAt: DateTime.now(),
              chatId: newChatId,
              sender: 'ai',
              content: reply,
            ),
          );
          _sending = false;
        });
        _scrollToBottom();
      } else {
        throw Exception(body['error']?['message'] ?? 'Failed to get reply');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
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
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Co-Founder',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Always available for feedback & strategy',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Chat Message List
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Start a conversation with your co-founder',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: AppTheme.textSecondaryDark,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isUser = message.sender == 'user';

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? AppTheme.primary : AppTheme.darkCard,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isUser ? 20 : 0),
                            bottomRight: Radius.circular(isUser ? 0 : 20),
                          ),
                          border: isUser
                              ? null
                              : Border.all(
                                  color: Colors.white.withOpacity(0.04),
                                ),
                        ),
                        child: MarkdownText(text: message.content),
                      ),
                    );
                  },
                ),
        ),

        // Chat Input Bar
        if (_sending)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Co-founder is thinking...',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.04)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    fillColor: AppTheme.darkCard,
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primary,
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
