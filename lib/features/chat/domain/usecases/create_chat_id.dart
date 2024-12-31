class CreateChatId {
  String call(String userId, String otherUserId) {
    final sortedIds = [userId, otherUserId]..sort((a, b) => b.compareTo(a));
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}