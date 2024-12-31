import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_on_final/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<String>> getLikedPackages(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        return [];
      }

      final data = userDoc.data()!;
      return List<String>.from(data['likedPackages'] ?? []);
    } catch (e) {
      print('Error getting liked packages: $e');
      return [];
    }
  }
}

