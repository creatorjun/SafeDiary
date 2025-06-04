
enum MessageType {
  CHAT,
  JOIN,
  LEAVE;

  String toJson() => name;
  static MessageType fromJson(String? jsonValue) {
    if (jsonValue == null) return MessageType.CHAT; // 기본값 또는 오류 처리
    return MessageType.values.firstWhere(
          (e) => e.name.toLowerCase() == jsonValue.toLowerCase(),
      orElse: () => MessageType.CHAT, // 매칭되는 값이 없을 경우 기본값
    );
  }
}

class ChatMessage {
  final String? id;
  final MessageType type;
  final String? content;
  final String senderUid;
  final String? senderNickname;
  final String? receiverUid;
  final int timestamp; // Epoch milliseconds
  final bool isRead;

  ChatMessage({
    this.id,
    required this.type,
    this.content,
    required this.senderUid,
    this.senderNickname,
    this.receiverUid,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      type: MessageType.fromJson(json['type'] as String?),
      content: json['content'] as String?,
      senderUid: json['senderUid'] as String,
      senderNickname: json['senderNickname'] as String?,
      receiverUid: json['receiverUid'] as String?,
      timestamp: json['timestamp'] as int,
      isRead: json['isRead'] as bool? ?? json['read'] as bool? ?? false, // API 명세에 read (writeOnly)도 있어서 isRead 우선
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'content': content,
      'senderUid': senderUid,
      'senderNickname': senderNickname,
      'receiverUid': receiverUid,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: $type, content: $content, senderUid: $senderUid, senderNickname: $senderNickname, receiverUid: $receiverUid, timestamp: $timestamp, isRead: $isRead)';
  }
}

class PaginatedChatMessagesResponse {
  final List<ChatMessage> messages;
  final bool hasNextPage;
  final int? oldestMessageTimestamp;

  PaginatedChatMessagesResponse({
    required this.messages,
    required this.hasNextPage,
    this.oldestMessageTimestamp,
  });

  factory PaginatedChatMessagesResponse.fromJson(Map<String, dynamic> json) {
    var messagesList = json['messages'] as List? ?? [];
    List<ChatMessage> messages =
    messagesList.map((i) => ChatMessage.fromJson(i)).toList();

    return PaginatedChatMessagesResponse(
      messages: messages,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      oldestMessageTimestamp: json['oldestMessageTimestamp'] as int?,
    );
  }
}