import 'package:equatable/equatable.dart';

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime sentAt;
  final bool isRead;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.sentAt,
    required this.isRead,
  });

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        receiverId,
        text,
        sentAt,
        isRead,
      ];
}


