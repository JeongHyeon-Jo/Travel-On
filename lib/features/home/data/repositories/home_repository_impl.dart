// lib/features/home/data/repositories/home_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/next_trip_entity.dart';
import '../../domain/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final FirebaseFirestore _firestore;

  HomeRepositoryImpl(this._firestore);

  @override
  Future<NextTripEntity?> getNextTrip(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reservations')
          .where('customerId', isEqualTo: userId)
          .where('status', isEqualTo: 'approved')
          .get();

      final reservations = snapshot.docs;
      if (reservations.isEmpty) return null;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final futureReservations = reservations.where((doc) {
        final reservationDate =
        (doc.data()['reservationDate'] as Timestamp).toDate();
        return DateTime(reservationDate.year, reservationDate.month,
            reservationDate.day)
            .isAfter(DateTime(now.year, now.month, now.day - 1));
      }).toList()
        ..sort((a, b) => (a.data()['reservationDate'] as Timestamp)
            .toDate()
            .compareTo((b.data()['reservationDate'] as Timestamp).toDate()));

      if (futureReservations.isEmpty) return null;

      final nextTrip = futureReservations.first.data();
      final tripDate = (nextTrip['reservationDate'] as Timestamp).toDate();
      final tripDateOnly =
      DateTime(tripDate.year, tripDate.month, tripDate.day);

      // 패키지 정보 가져오기
      final packageDoc = await _firestore
          .collection('packages')
          .doc(nextTrip['packageId'])
          .get();

      final packageData = packageDoc.data();

      final bool isTodayTrip = tripDateOnly.year == today.year &&
          tripDateOnly.month == today.month &&
          tripDateOnly.day == today.day;

      return NextTripEntity(
        packageTitle: packageData?['title'] ?? nextTrip['packageTitle'],
        packageTitleEn: packageData?['titleEn'],
        packageTitleJa: packageData?['titleJa'],
        packageTitleZh: packageData?['titleZh'],
        tripDate: tripDate,
        dDay: isTodayTrip ? null : tripDateOnly.difference(today).inDays,
        isTodayTrip: isTodayTrip,
      );
    } catch (e) {
      print('Error getting next trip: $e');
      return null;
    }
  }
}