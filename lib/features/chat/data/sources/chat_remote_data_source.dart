import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_on_final/features/chat/data/models/message_model.dart';

class ChatRemoteDataSource {
  final FirebaseFirestore firestore;

  ChatRemoteDataSource(this.firestore);

  Stream<List<MessageModel>> getMessages(String chatId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList());
  }

  Future<void> sendMessage(String chatId, MessageModel message) async {
    await firestore.collection('chats').doc(chatId).collection('messages').add(message.toMap());
  }
}
