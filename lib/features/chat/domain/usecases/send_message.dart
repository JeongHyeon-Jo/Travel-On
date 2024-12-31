import 'package:travel_on_final/features/chat/domain/entities/message_entity.dart';
import 'package:travel_on_final/features/chat/domain/repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  Future<void> call(String chatId, MessageEntity message) async {
    await repository.sendMessage(chatId, message);
  }
}
