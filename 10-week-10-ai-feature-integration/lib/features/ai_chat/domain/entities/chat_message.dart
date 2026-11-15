class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
}
