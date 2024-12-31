import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_on_final/features/chat/domain/entities/message_entity.dart';

class MessageModel {
  final String id;
  final String text;
  final String uId;
  final Timestamp createdAt;
  String? profileImageUrl;
  String? imageUrl;
  Map<String, dynamic>? sharedUser;
  Map<String, dynamic>? sharedPackage;
  Map<String, dynamic>? location;

  MessageModel({
    required this.id,
    required this.text,
    required this.uId,
    required this.createdAt,
    this.profileImageUrl,
    this.imageUrl,
    this.sharedUser,
    this.sharedPackage,
    this.location,
  });

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    return MessageModel(
      id: doc.id,
      text: data?['text'] ?? '',
      uId: data?['uId'] ?? '',
      createdAt: data?['createdAt'] ?? Timestamp.now(),
      profileImageUrl: data?['profileImageUrl'],
      imageUrl: data?['imageUrl'],
      sharedUser: data?['sharedUser'],
      sharedPackage: data?['sharedPackage'],
      location: data?['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'uId': uId,
      'createdAt': createdAt,
      'profileImageUrl': profileImageUrl,
      'imageUrl': imageUrl,
      if (sharedUser != null) 'sharedUser': sharedUser,
      if (sharedPackage != null) 'sharedPackage': sharedPackage,
      if (location != null) 'location': location,
    };
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      text: text,
      uId: uId,
      createdAt: createdAt,
      profileImageUrl: profileImageUrl,
      imageUrl: imageUrl,
      sharedUser: sharedUser,
      sharedPackage: sharedPackage,
      location: location,
    );
  }
}
