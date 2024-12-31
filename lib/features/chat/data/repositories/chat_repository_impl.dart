import 'package:travel_on_final/features/chat/domain/entities/message_entity.dart';
import 'package:travel_on_final/features/chat/domain/repositories/chat_repository.dart';
import 'package:travel_on_final/features/chat/data/models/message_model.dart';
import 'package:travel_on_final/features/chat/data/sources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<MessageEntity>> getMessages(String chatId) {
    return remoteDataSource.getMessages(chatId).map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<void> sendMessage(String chatId, MessageEntity message) {
    final messageModel = MessageModel(
      id: '',
      text: message.text,
      uId: message.uId,
      createdAt: message.createdAt,
    );
    return remoteDataSource.sendMessage(chatId, messageModel);
  }
}
