import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/reservation_model.dart';

class ReservationProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  List<ReservationModel> _reservations = [];

  ReservationProvider(this._firestore);

  List<ReservationModel> get reservations => _reservations;

  Future<void> createReservation({
    required String packageId,
    required String packageTitle,
    required String customerId,
    required String customerName,
    required String guideName,
    required String guideId,
    required DateTime reservationDate,
    required double price,
    required int participants,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // 패키지 정보 가져오기
        final packageDoc =
            await _firestore.collection('packages').doc(packageId).get();
        final packageData = packageDoc.data()!;

        // 인원 수 검증
        final minParticipants = packageData['minParticipants'] as int;
        final maxParticipants = packageData['maxParticipants'] as int;

        if (participants < minParticipants || participants > maxParticipants) {
          throw '올바르지 않은 인원 수입니다';
        }
        // 이미 예약이 있는지 확인
        final start = DateTime(
            reservationDate.year, reservationDate.month, reservationDate.day);
        final end = start.add(const Duration(days: 1));

        // 예약 가능 여부 다시 확인
        final existingReservations = await _firestore
            .collection('reservations')
            .where('packageId', isEqualTo: packageId)
            .where('status', isEqualTo: 'approved')
            .where('reservationDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('reservationDate', isLessThan: Timestamp.fromDate(end))
            .get();

        if (existingReservations.docs.isNotEmpty) {
          throw '이미 예약이 마감된 날짜입니다';
        }

        // 예약 생성
        final reservationRef = _firestore.collection('reservations').doc();
        await reservationRef.set({
          'packageId': packageId,
          'packageTitle': packageTitle,
          'customerId': customerId,
          'customerName': customerName,
          'guideName': guideName,
          'guideId': guideId,
          'reservationDate': Timestamp.fromDate(reservationDate),
          'requestedAt': Timestamp.fromDate(DateTime.now()),
          'status': 'pending',
          'price': price,
          'participants': participants, // 여기에서 인원 수 저장
        });

        // 알림 생성
        await _firestore.collection('notifications').add({
          'userId': guideId,
          'title': '새로운 예약 요청',
          'message':
              '$customerName님이 $packageTitle 패키지를 예약 신청했습니다. ($participants명)',
          'type': 'reservation_request',
          'reservationId': reservationRef.id,
          'chatId': '',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      });

      notifyListeners();
    } catch (e) {
      print('Error creating reservation: $e');
      rethrow;
    }
  }

  Future<void> updateReservationStatus(
      String reservationId, String status) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final reservationRef =
            _firestore.collection('reservations').doc(reservationId);
        final reservationDoc = await transaction.get(reservationRef);

        if (!reservationDoc.exists) {
          throw '예약을 찾을 수 없습니다';
        }

        final data = reservationDoc.data()!;

        // 상태 업데이트
        transaction.update(reservationRef, {
          'status': status,
        });

        // 승인된 경우, 같은 날짜의 다른 예약들은 자동으로 거절
        if (status == 'approved') {
          final sameDate = (data['reservationDate'] as Timestamp).toDate();
          final start = DateTime(sameDate.year, sameDate.month, sameDate.day);
          final end = start.add(const Duration(days: 1));

          // 같은 날짜의 다른 예약들 가져오기
          final otherReservations = await _firestore
              .collection('reservations')
              .where('packageId', isEqualTo: data['packageId'])
              .where('reservationDate',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(start))
              .where('reservationDate', isLessThan: Timestamp.fromDate(end))
              .where('status', isEqualTo: 'pending') // 대기 중인 예약만
              .get();

          // 다른 예약들 모두 거절로 변경
          for (var doc in otherReservations.docs) {
            if (doc.id != reservationId) {
              transaction.update(doc.reference, {
                'status': 'rejected',
              });
            }
          }
        }

        // 알림 생성
        final notificationRef = _firestore.collection('notifications').doc();
        transaction.set(notificationRef, {
          'userId': data['customerId'],
          'title': '예약 상태 변경',
          'message':
              '${data['packageTitle']} 패키지의 예약이 ${_getStatusMessage(status)}되었습니다.',
          'type': 'reservation_update',
          'reservationId': reservationId,
          'chatId': '',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      });

      notifyListeners();
    } catch (e) {
      print('Error updating reservation status: $e');
      rethrow;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'approved':
        return '승인';
      case 'rejected':
        return '거절';
      default:
        return status;
    }
  }

  Future<void> loadReservations(String userId, {bool isGuide = false}) async {
    try {
      final queryField = isGuide ? 'guideId' : 'customerId';
      final snapshot = await _firestore
          .collection('reservations')
          .where(queryField, isEqualTo: userId)
          .orderBy('requestedAt', descending: true)
          .get();

      _reservations = snapshot.docs
          .map(
              (doc) => ReservationModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      notifyListeners();
    } catch (e) {
      print('Error loading reservations: $e');
      rethrow;
    }
  }

  // 패키지의 현재 예약 가능 여부 확인
  Future<bool> isPackageAvailable(String packageId) async {
    try {
      final packageDoc =
          await _firestore.collection('packages').doc(packageId).get();
      if (!packageDoc.exists) return false;

      final currentParticipants =
          packageDoc.data()?['currentParticipants'] ?? 0;
      final maxParticipants = packageDoc.data()?['maxParticipants'] ?? 0;

      return currentParticipants < maxParticipants;
    } catch (e) {
      print('Error checking package availability: $e');
      return false;
    }
  }

  Future<bool> isDateAvailable(String packageId, DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      // 해당 날짜의 승인된 예약이 있는지 확인
      final snapshot = await _firestore
          .collection('reservations')
          .where('packageId', isEqualTo: packageId)
          .where('status', isEqualTo: 'approved') // 승인된 예약만 확인
          .where('reservationDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('reservationDate', isLessThan: Timestamp.fromDate(end))
          .get();

      // 승인된 예약이 하나라도 있으면 false 반환
      return snapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking date availability: $e');
      return false;
    }
  }

  Future<List<ReservationModel>> getMonthReservations(
    String packageId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('packageId', isEqualTo: packageId)
          .where('status', isEqualTo: 'approved')
          .where('reservationDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('reservationDate',
              isLessThan: Timestamp.fromDate(end.add(const Duration(days: 1))))
          .get();

      return snapshot.docs
          .map(
              (doc) => ReservationModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Error getting month reservations: $e');
      return [];
    }
  }
}
