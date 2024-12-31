import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  int _totalUnreadCount = 0;
  int get totalUnreadCount => _totalUnreadCount;

  // 읽지 않은 메시지 표시를 빈 문자열 또는 숫자로 반환
  String get totalUnreadDisplay => _totalUnreadCount > 0
      ? (_totalUnreadCount > 99 ? '99+' : _totalUnreadCount.toString())
      : '';

  bool _shouldResetChatListScreen = false;
  bool get shouldResetChatListScreen => _shouldResetChatListScreen;

  void setIndex(int index) {
    _currentIndex = index;
    if (index == 2) {
      // 채팅 탭으로 이동할 때
      _shouldResetChatListScreen = true;
    }
    notifyListeners();
  }

  void updateTotalUnreadCount(int count) {
    _totalUnreadCount = count;
    notifyListeners();
  }

  void confirmChatListReset() {
    _shouldResetChatListScreen = false;
    notifyListeners();
  }
}
