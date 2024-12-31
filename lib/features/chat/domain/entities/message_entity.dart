import 'package:cloud_firestore/cloud_firestore.dart';

class MessageEntity {
  final String id;
  final String text;
  final String uId;
  final Timestamp createdAt;
  final String? profileImageUrl;
  final String? imageUrl;
  final Map<String, dynamic>? sharedUser;
  final Map<String, dynamic>? sharedPackage;
  final Map<String, dynamic>? location;

  MessageEntity({
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
}
