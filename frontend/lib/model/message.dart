// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Message {
  final bool isUser;
  final String message;
  final String sessionId;

  Message({required this.message, required this.sessionId, required this.isUser});

  


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isUser': isUser,
      'message': message,
      'sessionId': sessionId,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      isUser: map['isUser'] as bool,
      message: map['message'] as String,
      sessionId: map['sessionId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory Message.fromJson(String source) => Message.fromMap(json.decode(source) as Map<String, dynamic>);
}
