import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../domain/entities/notification.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final NavigationProvider _navigationProvider;
  final List<NotificationEntity> _notifications = [];
  bool _isLoading = false;
  String? _error;

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationProvider(
      this._firestore, this._messaging, this._navigationProvider)
      : _auth = FirebaseAuth.instance {
    _initNotifications();
  }

  List<NotificationEntity> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> _initNotifications() async {
    // 로컬 알림 초기화
    const androidInitialize =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitialize = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidInitialize,
      iOS: iosInitialize,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림 탭 핸들링
        print('Notification tapped: ${response.payload}');
      },
    );

    // iOS이면서 개발자 계정이 없는 경우 FCM 초기화 건너뛰기
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      print('iOS 플랫폼에서는 개발자 계정 설정 전까지 푸시 알림이 제한됩니다.');
      return;
    }

    // FCM 권한 요청
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // FCM 토큰 가져오기
      String? token = await _messaging.getToken();
      if (token != null) {
        final user = _auth.currentUser;
        if (user != null) {
          // 토큰을 Firestore에 저장
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': token,
          });
        }
      }

      // 토큰 갱신 리스너
      _messaging.onTokenRefresh.listen((newToken) async {
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': newToken,
          });
        }
      });

      // FCM 메시지 핸들링
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (message.data['type'] == 'chat_message') {
      // 채팅 메시지 알림일 경우 기본 알림음 사용
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond,
        message.notification?.title ?? '새로운 메시지',
        message.notification?.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_channel',
            '채팅 알림',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
          ),
        ),
        payload: message.data['chatId'], // 수정필요
      );
      // 채팅 메시지의 경우 _showLocalNotification 호출하지 않음
    } else {
      // 채팅 메시지가 아닌 경우에만 로컬 알림 표시
      await _showLocalNotification(message);
    }

    // 알림 목록 새로고침
    loadNotifications();
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // 알림 목록 새로고침
    loadNotifications();
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      details,
    );
  }

  Future<void> loadNotifications() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _auth.currentUser;
      if (user == null) {
        _error = '로그인이 필요합니다';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('type', isNotEqualTo: 'chat_message')
          .get();

      _notifications.clear();
      _notifications.addAll(
        querySnapshot.docs.map((doc) {
          final data = doc.data();
          return NotificationEntity(
            id: doc.id,
            userId: data['userId'] ?? '',
            title: data['title'] ?? '',
            message: data['message'] ?? '',
            type: data['type'] ?? '',
            createdAt: (data['createdAt'] as Timestamp).toDate(),
            isRead: data['isRead'] ?? false,
            reservationId: data['reservationId'],
            chatId: data['chatId'],
          );
        }),
      );

      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 채팅 알림은 제외하고 일반 알림만 카운트
      final normalUnreadCount = _notifications.where((n) => !n.isRead).length;

      // NavigationProvider의 updateTotalUnreadCount 호출 제거
      // _navigationProvider.updateTotalUnreadCount(unreadCount);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        // 읽지 않은 알림 수 업데이트
        final unreadCount = _notifications.where((n) => !n.isRead).length;
        _navigationProvider.updateTotalUnreadCount(unreadCount);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = _notifications.where((n) => !n.isRead);

      for (var notification in unreadNotifications) {
        final ref = _firestore.collection('notifications').doc(notification.id);
        batch.update(ref, {'isRead': true});
      }

      await batch.commit();

      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
