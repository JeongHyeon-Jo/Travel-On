import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:travel_on_final/features/chat/data/models/message_model.dart';
import 'package:travel_on_final/features/chat/domain/entities/message_entity.dart';
import 'package:travel_on_final/features/auth/data/models/user_model.dart';
import 'package:travel_on_final/features/search/domain/entities/travel_package.dart';
import 'package:travel_on_final/features/auth/presentation/providers/auth_provider.dart';
import 'package:travel_on_final/core/providers/navigation_provider.dart';
import 'package:provider/provider.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NavigationProvider _navigationProvider;

  List<MessageEntity> _messages = [];
  List<MessageEntity> get messages => _messages;

  StreamSubscription? _unreadCountSubscription;
  StreamSubscription? _messageSubscription;

  ChatProvider(this._navigationProvider);

  // 메시지 수신 및 구독
  void startListeningToMessages(String chatId) {
    stopListeningToMessages();

    try {
      _messageSubscription = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          _messages = snapshot.docs
              .map((doc) => MessageModel.fromDocument(doc).toEntity())
              .toList();
          notifyListeners();
        },
        onError: (error) {
          print("메시지 스트림 중 오류 발생: $error");
          _messages.clear();
          notifyListeners();
        },
      );
    } catch (e) {
      print("메시지 스트림 시작 실패: $e");
    }
  }

  // 채팅방 구독 중지
  void stopListeningToMessages() {
    try {
      _messageSubscription?.cancel();
      _messageSubscription = null;
      _messages.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } catch (e) {
      print("메시지 스트림 해제 중 오류 발생: $e");
    }
  }

  @override
  void dispose() {
    stopListeningToMessages();
    super.dispose();
  }

  // 읽지 않은 메시지 수 구독
  void startListeningToUnreadCounts(String userId) {
    _unreadCountSubscription = _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      _updateTotalUnreadCount(userId);
    });
  }

  // 로그아웃 시 호출할 메서드
  void clearDataOnLogout() {
    stopListeningToMessages();
    _unreadCountSubscription?.cancel();
    _unreadCountSubscription = null;
    _messages.clear();
    notifyListeners();
  }


  // 채팅방 생성 확인 및 생성
  Future<void> _ensureChatRoomExists(
      String chatId, BuildContext context, String otherUserId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatSnapshot = await chatRef.get();

      if (!chatSnapshot.exists && authProvider.currentUser != null) {
        String otherUserName = await _getOtherUserName(otherUserId);
        String otherUserProfileImage =
            await _getOtherUserProfileImage(otherUserId);

        await chatRef.set({
          'participants': [authProvider.currentUser!.id, otherUserId],
          'lastActivityTime': Timestamp.now(),
          'lastMessage': '',
          'usernames': {
            authProvider.currentUser!.id: authProvider.currentUser!.name,
            otherUserId: otherUserName,
          },
          'userProfileImages': {
            authProvider.currentUser!.id:
                authProvider.currentUser!.profileImageUrl ?? '',
            otherUserId: otherUserProfileImage,
          },
          'unreadCount': {
            authProvider.currentUser!.id: 0,
            otherUserId: 0,
          },
        });
      }
    } catch (e) {
      print("채팅방 생성 실패: $e");
    }
  }

  // 텍스트 및 이미지 메시지 전송
  Future<void> sendMessageToChat({
    required String chatId,
    required String text,
    required String otherUserId,
    XFile? imageFile,
    required BuildContext context,
    Map<String, dynamic>? packageData,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    await _ensureChatRoomExists(chatId, context, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    String imageUrl = '';
    if (imageFile != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = _storage.ref().child('chat_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(File(imageFile.path));
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      imageUrl = await taskSnapshot.ref.getDownloadURL();
    }

    await chatRef.collection('messages').add({
      'text': imageFile != null ? '[Image]' : text,
      'uId': authProvider.currentUser!.id,
      'username': authProvider.currentUser!.name,
      'createdAt': Timestamp.now(),
      if (imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      'profileImageUrl': authProvider.currentUser!.profileImageUrl,
    });

    await chatRef.update({
      'lastActivityTime': Timestamp.now(),
      'lastMessage': imageFile != null ? '[Image]' : text,
    });

    await incrementUnreadCount(chatId, otherUserId);

    await _firestore.collection('notifications').add({
      'userId': otherUserId,
      'title': '새로운 메시지',
      'message':
          '${authProvider.currentUser!.name}님이 메시지를 보냈습니다: ${imageFile != null ? '[Image]' : text}',
      'type': 'chat_message',
      'chatId': chatId,
      'createdAt': Timestamp.now(),
      'isRead': false,
    });

    notifyListeners();
  }

  // Firestore에서 사용자 이름 가져오기
  Future<String> _getOtherUserName(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc['name'] ?? 'Unknown' : 'Unknown';
    } catch (e) {
      print("사용자 이름 가져오기 실패: $e");
      return 'Unknown';
    }
  }

  // Firestore에서 사용자 프로필 이미지 가져오기
  Future<String> _getOtherUserProfileImage(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc['profileImageUrl'] ?? '' : '';
    } catch (e) {
      print("프로필 이미지 가져오기 실패: $e");
      return '';
    }
  }

  // 상대방 유저 정보 갖고오기
  Future<String> fetchOtherUserInfo(String otherUserId) async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(otherUserId).get();
    if (userSnapshot.exists) {
      final otherUserName = userSnapshot['name'] ?? 'Unknown User';
      return otherUserName;
    }
    return 'Unknown User';
  }

  // 상대방 정보 업데이트 메서드
  Future<void> updateOtherUserInfo(String chatId, String otherUserId) async {
    final otherUserName = await _getOtherUserName(otherUserId);
    final otherUserProfileImage = await _getOtherUserProfileImage(otherUserId);

    await _firestore.collection('chats').doc(chatId).update({
      'usernames.$otherUserId': otherUserName,
      'userProfileImages.$otherUserId': otherUserProfileImage,
    });
  }

  // 채팅방 나가기
  Future<void> leaveChatRoom(String chatId, String userId) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chatId);
      final chatSnapshot = await chatRef.get();

      if (chatSnapshot.exists) {
        final participants = List<String>.from(chatSnapshot['participants']);
        participants.remove(userId);

        if (participants.isEmpty) {
          await chatRef.delete();
        } else {
          await chatRef.update({'participants': participants});
        }
      }
    } catch (e) {
      print("채팅방 나가기 중 오류 발생: $e");
    }
  }

  /////////////////////////////////////////////////////////////
  /// 안읽은 메세지 관련 메서드

  // 읽지 않은 메시지 수 증가
  Future<void> incrementUnreadCount(String chatId, String otherUserId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    await chatRef.update({
      'unreadCount.$otherUserId': FieldValue.increment(1),
    });
  }

  // 사용자가 채팅방을 열면 그 방의 읽지 않은 메시지 수를 초기화
  Future<void> resetUnreadCount(String chatId, String userId) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.update({
      'unreadCount.$userId': 0,
    });

    _updateTotalUnreadCount(userId);
  }

  void _updateTotalUnreadCount(String userId) async {
    int totalUnread = 0;

    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final count = (data['unreadCount']?[userId] ?? 0) as int;
      totalUnread += count;
    }

    _navigationProvider.updateTotalUnreadCount(totalUnread);
  }

  ///////////////////////////////////////////////////////
  /// 사용자 정보 공유 관련 메서드

  // 사용자 정보를 상대방에게 메시지로 전송하는 메서드
  Future<void> sendUserDetailsMessage({
    required String chatId,
    required UserModel user,
    required String otherUserId,
    required BuildContext context,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    await _ensureChatRoomExists(chatId, context, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'text': '사용자 정보',
      'uId': authProvider.currentUser!.id,
      'username': authProvider.currentUser!.name,
      'createdAt': Timestamp.now(),
      'profileImageUrl': authProvider.currentUser!.profileImageUrl,
      'sharedUser': {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'profileImageUrl': user.profileImageUrl,
        'introduction': user.introduction,
      },
    });

    await chatRef.update({
      'lastActivityTime': Timestamp.now(),
      'lastMessage': '사용자 정보가 공유되었습니다.',
    });

    notifyListeners();
  }

  // 패키지 정보를 상대방에게 전송하는 메서드
  Future<void> sendPackageDetailsMessage({
    required String chatId,
    required TravelPackage package,
    required String otherUserId,
    required BuildContext context,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    await _ensureChatRoomExists(chatId, context, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'text': '패키지 정보',
      'uId': authProvider.currentUser!.id,
      'username': authProvider.currentUser!.name,
      'createdAt': Timestamp.now(),
      'profileImageUrl': authProvider.currentUser!.profileImageUrl,
      'sharedPackage': {
        'id': package.id,
        'title': package.title,
        'price': package.price,
        'guideName': package.guideName,
        'mainImage': package.mainImage,
        'description': package.description,
      },
    });

    await chatRef.update({
      'lastActivityTime': Timestamp.now(),
      'lastMessage': '패키지 정보가 공유되었습니다.',
    });

    notifyListeners();
  }

  // 장소 정보 메시지 보내기
  Future<void> sendLocationMessage({
    required String chatId,
    required String otherUserId,
    required BuildContext context,
    required String title,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) return;

    await _ensureChatRoomExists(chatId, context, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await chatRef.collection('messages').add({
      'text': '위치 정보',
      'uId': authProvider.currentUser!.id,
      'username': authProvider.currentUser!.name,
      'createdAt': Timestamp.now(),
      'profileImageUrl': authProvider.currentUser!.profileImageUrl,
      'location': {
        'title': title,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      },
    });

    await chatRef.update({
      'lastActivityTime': Timestamp.now(),
      'lastMessage': '위치 정보가 공유되었습니다.',
    });

    final querySnapshot = await chatRef
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .get();

    _messages = querySnapshot.docs
        .map((doc) => MessageModel.fromDocument(doc).toEntity())
        .toList();

    notifyListeners();
  }

  Future<void> ensureChatRoomExists(
      String chatId, BuildContext context, String otherUserId) async {
    await _ensureChatRoomExists(chatId, context, otherUserId);
  }
}
