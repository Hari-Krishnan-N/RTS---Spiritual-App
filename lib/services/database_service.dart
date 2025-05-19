import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userCollection = "users";
  final String _sadhanaCollection = "sadhana";

  // Add or update a user in the database
  Future<void> addUser(String userId, Map<String, dynamic> userInfoMap) async {
    try {
      // First check if user already exists
      final docSnapshot =
          await _firestore.collection(_userCollection).doc(userId).get();

      if (docSnapshot.exists) {
        // If user exists, update only new fields without overwriting existing data
        return await _firestore.collection(_userCollection).doc(userId).update({
          ...userInfoMap,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        // If user doesn't exist, create new document
        return await _firestore.collection(_userCollection).doc(userId).set({
          ...userInfoMap,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add user: ${e.toString()}');
    }
  }

  // Update specific user fields
  Future<void> updateUser(
    String userId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      return await _firestore.collection(_userCollection).doc(userId).update({
        ...updateData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Get user data by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(_userCollection).doc(userId).get();

      if (documentSnapshot.exists) {
        return documentSnapshot.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // Save sadhana data
  Future<void> saveSadhanaData(
    String userId,
    Map<String, dynamic> sadhanaData,
  ) async {
    try {
      // Store reference to user document
      DocumentReference userRef = _firestore
          .collection(_userCollection)
          .doc(userId);

      // Save sadhana data in a subcollection
      await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection(_sadhanaCollection)
          .doc(sadhanaData['month'])
          .set({
            ...sadhanaData,
            'updatedAt': FieldValue.serverTimestamp(),
            'user': userRef,
          }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save sadhana data: ${e.toString()}');
    }
  }

  // Get sadhana data for a specific month
  Future<Map<String, dynamic>?> getSadhanaDataForMonth(
    String userId,
    String month,
  ) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore
              .collection(_userCollection)
              .doc(userId)
              .collection(_sadhanaCollection)
              .doc(month)
              .get();

      if (documentSnapshot.exists) {
        return documentSnapshot.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get sadhana data: ${e.toString()}');
    }
  }

  // Get all sadhana data for a user
  Future<List<Map<String, dynamic>>> getAllSadhanaData(String userId) async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore
              .collection(_userCollection)
              .doc(userId)
              .collection(_sadhanaCollection)
              .orderBy('updatedAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('Failed to get all sadhana data: ${e.toString()}');
    }
  }

  // Save jebam heatmap data
  Future<void> saveJebamHeatmap(
    String userId,
    Map<String, int> heatmapData,
  ) async {
    try {
      await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection('jebamHeatmap')
          .doc('heatmap')
          .set({
            'data': heatmapData,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save jebam heatmap: ${e.toString()}');
    }
  }

  // Get jebam heatmap data
  Future<Map<String, int>?> getJebamHeatmap(String userId) async {
    try {
      DocumentSnapshot documentSnapshot =
          await _firestore
              .collection(_userCollection)
              .doc(userId)
              .collection('jebamHeatmap')
              .doc('heatmap')
              .get();

      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> heatmapData = data['data'] as Map<String, dynamic>;

        // Convert back to Map<String, int>
        return heatmapData.map((key, value) => MapEntry(key, value as int));
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get jebam heatmap: ${e.toString()}');
    }
  }
}
