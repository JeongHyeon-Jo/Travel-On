class ReservationEntity {
  final String id;
  final String packageId;
  final String packageTitle;
  final String customerId;
  final String customerName;
  final String guideName;
  final String guideId;
  final DateTime reservationDate;
  final DateTime requestedAt;
  final String status; // pending, approved, rejected, cancelled
  final double price;

  ReservationEntity({
    required this.id,
    required this.packageId,
    required this.packageTitle,
    required this.customerId,
    required this.customerName,
    required this.guideName,
    required this.guideId,
    required this.reservationDate,
    required this.requestedAt,
    required this.status,
    required this.price,
  });
}