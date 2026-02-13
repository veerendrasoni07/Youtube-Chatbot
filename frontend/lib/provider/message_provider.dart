import 'package:flutter_riverpod/legacy.dart';
import 'package:frontend/model/message.dart';

class MessageProvider extends StateNotifier<List<Message>> {
  MessageProvider() : super([]);

  void addMessage(Message msg) {
    state = [...state, msg];
  }

  void clearMessages() {
    state = [];
  }



}
final messageProvider = StateNotifierProvider<MessageProvider, List<Message>>((ref) {
  return MessageProvider();
});