import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _userCollection = "users";
  final String _sadhanaCollection = "sadhana";
  final String _adminEmail = "rhythmbharatarasadhana@gmail.com";

  // Check if current user is admin
  bool isCurrentUserAdmin() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    return currentUser.email?.toLowerCase() == _adminEmail.toLowerCase();
  }

  // Get current admin user
  User? getCurrentAdminUser() {
    final currentUser = _auth.currentUser;
    if (currentUser?.email?.toLowerCase() == _adminEmail.toLowerCase()) {
      return currentUser;
    }
    return null;
  }

  // Get all users with their data
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Access denied: Admin privileges required');
      }

      QuerySnapshot usersSnapshot = await _firestore
          .collection(_userCollection)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> users = [];

      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        userData['uid'] = userDoc.id;

        // Get user's sadhana data
        QuerySnapshot sadhanaSnapshot = await _firestore
            .collection(_userCollection)
            .doc(userDoc.id)
            .collection(_sadhanaCollection)
            .get();

        userData['sadhanaData'] = sadhanaSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        // Get user's heatmap data
        try {
          DocumentSnapshot heatmapDoc = await _firestore
              .collection(_userCollection)
              .doc(userDoc.id)
              .collection('jebamHeatmap')
              .doc('heatmap')
              .get();

          if (heatmapDoc.exists) {
            userData['heatmapData'] = heatmapDoc.data() as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('Error loading heatmap for user ${userDoc.id}: $e');
        }

        users.add(userData);
      }

      return users;
    } catch (e) {
      throw Exception('Failed to get all users: ${e.toString()}');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Access denied: Admin privileges required');
      }

      QuerySnapshot usersSnapshot = await _firestore
          .collection(_userCollection)
          .get();

      int totalUsers = usersSnapshot.docs.length;
      int activeUsers = 0;
      int totalJebamCount = 0;
      int totalTharpanamCompleted = 0;
      int totalHomamCompleted = 0;
      int totalDhaanamCompleted = 0;

      DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Check if user is active (logged in within last 30 days)
        if (userData['lastLogin'] != null) {
          DateTime lastLogin = (userData['lastLogin'] as Timestamp).toDate();
          if (lastLogin.isAfter(thirtyDaysAgo)) {
            activeUsers++;
          }
        }

        // Get user's sadhana data
        QuerySnapshot sadhanaSnapshot = await _firestore
            .collection(_userCollection)
            .doc(userDoc.id)
            .collection(_sadhanaCollection)
            .get();

        for (QueryDocumentSnapshot sadhanaDoc in sadhanaSnapshot.docs) {
          Map<String, dynamic> sadhanaData = sadhanaDoc.data() as Map<String, dynamic>;
          
          totalJebamCount += (sadhanaData['jebamCount'] as int?) ?? 0;
          
          if ((sadhanaData['tharpanamStatus'] as bool?) ?? false) {
            totalTharpanamCompleted++;
          }
          
          if ((sadhanaData['homamStatus'] as bool?) ?? false) {
            totalHomamCompleted++;
          }
          
          if ((sadhanaData['dhaanamStatus'] as bool?) ?? false) {
            totalDhaanamCompleted++;
          }
        }
      }

      return {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'inactiveUsers': totalUsers - activeUsers,
        'totalJebamCount': totalJebamCount,
        'totalTharpanamCompleted': totalTharpanamCompleted,
        'totalHomamCompleted': totalHomamCompleted,
        'totalDhaanamCompleted': totalDhaanamCompleted,
      };
    } catch (e) {
      throw Exception('Failed to get user statistics: ${e.toString()}');
    }
  }

  // Update any user's data
  Future<void> updateUserData(String userId, Map<String, dynamic> updateData) async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Access denied: Admin privileges required');
      }

      updateData['lastUpdated'] = FieldValue.serverTimestamp();
      updateData['updatedByAdmin'] = true;

      await _firestore
          .collection(_userCollection)
          .doc(userId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update user data: ${e.toString()}');
    }
  }

  // Delete user account and all data
  Future<void> deleteUser(String userId) async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Access denied: Admin privileges required');
      }

      final batch = _firestore.batch();

      // Delete sadhana subcollection
      QuerySnapshot sadhanaSnapshot = await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection(_sadhanaCollection)
          .get();

      for (QueryDocumentSnapshot doc in sadhanaSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete heatmap subcollection
      QuerySnapshot heatmapSnapshot = await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection('jebamHeatmap')
          .get();

      for (QueryDocumentSnapshot doc in heatmapSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete user document
      DocumentReference userDocRef = _firestore
          .collection(_userCollection)
          .doc(userId);
      batch.delete(userDocRef);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  // Update user's sadhana data
  Future<void> updateUserSadhanaData(
    String userId,
    String month,
    Map<String, dynamic> sadhanaData,
  ) async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Access denied: Admin privileges required');
      }

      sadhanaData['updatedAt'] = FieldValue.serverTimestamp();
      sadhanaData['updatedByAdmin'] = true;

      await _firestore
          .collection(_userCollection)
          .doc(userId)
          .collection(_sadhanaCollection)
          .doc(month)
          .set(sadhanaData, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update user sadhana data: ${e.toString()}');
    }
  }

  // Get monthly analytics
  Future<Map<String, dynamic>> getMonthlyAnalytics() async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Access denied: Admin privileges required');
      }

      Map<String, Map<String, int>> monthlyStats = {};
      
      QuerySnapshot usersSnapshot = await _firestore
          .collection(_userCollection)
          .get();

      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        QuerySnapshot sadhanaSnapshot = await _firestore
            .collection(_userCollection)
            .doc(userDoc.id)
            .collection(_sadhanaCollection)
            .get();

        for (QueryDocumentSnapshot sadhanaDoc in sadhanaSnapshot.docs) {
          String month = sadhanaDoc.id;
          Map<String, dynamic> data = sadhanaDoc.data() as Map<String, dynamic>;

          if (!monthlyStats.containsKey(month)) {
            monthlyStats[month] = {
              'totalUsers': 0,
              'jebamTotal': 0,
              'tharpanamCompleted': 0,
              'homamCompleted': 0,
              'dhaanamCompleted': 0,
            };
          }

          monthlyStats[month]!['totalUsers'] = monthlyStats[month]!['totalUsers']! + 1;
          monthlyStats[month]!['jebamTotal'] = monthlyStats[month]!['jebamTotal']! + ((data['jebamCount'] as int?) ?? 0);
          
          if ((data['tharpanamStatus'] as bool?) ?? false) {
            monthlyStats[month]!['tharpanamCompleted'] = monthlyStats[month]!['tharpanamCompleted']! + 1;
          }
          
          if ((data['homamStatus'] as bool?) ?? false) {
            monthlyStats[month]!['homamCompleted'] = monthlyStats[month]!['homamCompleted']! + 1;
          }
          
          if ((data['dhaanamStatus'] as bool?) ?? false) {
            monthlyStats[month]!['dhaanamCompleted'] = monthlyStats[month]!['dhaanamCompleted']! + 1;
          }
        }
      }

      return {'monthlyStats': monthlyStats};
    } catch (e) {
      throw Exception('Failed to get monthly analytics: ${e.toString()}');
    }
  }

  // Send notification to all users (Updated to actually broadcast)
  Future<void> sendNotificationToAllUsers(String title, String message) async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Access denied: Admin privileges required');
      }

      // Create admin notification document
      await _firestore.collection('admin_notifications').add({
        'title': title,
        'message': message,
        'sentAt': FieldValue.serverTimestamp(),
        'sentBy': _auth.currentUser?.email,
        'type': 'broadcast',
      });

      // Get all users and send individual notifications
      final usersSnapshot = await _firestore.collection(_userCollection).get();
      
      final batch = _firestore.batch();
      for (var userDoc in usersSnapshot.docs) {
        final notificationRef = _firestore.collection('notifications').doc();
        batch.set(notificationRef, {
          'title': title,
          'message': message,
          'type': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'userId': userDoc.id,
          'fromAdmin': true,
          'adminEmail': _auth.currentUser?.email,
        });
      }

      await batch.commit();

      debugPrint('Notification sent to all users: $title - $message');
    } catch (e) {
      throw Exception('Failed to send notification: ${e.toString()}');
    }
  }

  // Get system health metrics
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Access denied: Admin privileges required');
      }

      // Get total document counts
      QuerySnapshot usersSnapshot = await _firestore.collection(_userCollection).get();
      int totalUsers = usersSnapshot.docs.length;

      int totalSadhanaRecords = 0;
      int totalHeatmapRecords = 0;

      for (QueryDocumentSnapshot userDoc in usersSnapshot.docs) {
        QuerySnapshot sadhanaSnapshot = await _firestore
            .collection(_userCollection)
            .doc(userDoc.id)
            .collection(_sadhanaCollection)
            .get();
        totalSadhanaRecords += sadhanaSnapshot.docs.length;

        QuerySnapshot heatmapSnapshot = await _firestore
            .collection(_userCollection)
            .doc(userDoc.id)
            .collection('jebamHeatmap')
            .get();
        totalHeatmapRecords += heatmapSnapshot.docs.length;
      }

      return {
        'totalUsers': totalUsers,
        'totalSadhanaRecords': totalSadhanaRecords,
        'totalHeatmapRecords': totalHeatmapRecords,
        'databaseHealth': 'Good',
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get system health: ${e.toString()}');
    }
  }

  // Export all user data (for backup/analysis)
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      if (!isCurrentUserAdmin()) {
        throw Exception('Access denied: Admin privileges required');
      }

      List<Map<String, dynamic>> allUsers = await getAllUsers();
      Map<String, dynamic> systemStats = await getUserStatistics();
      Map<String, dynamic> monthlyAnalytics = await getMonthlyAnalytics();
      Map<String, dynamic> systemHealth = await getSystemHealth();

      return {
        'exportTimestamp': DateTime.now().toIso8601String(),
        'exportedBy': _auth.currentUser?.email,
        'users': allUsers,
        'systemStats': systemStats,
        'monthlyAnalytics': monthlyAnalytics,
        'systemHealth': systemHealth,
      };
    } catch (e) {
      throw Exception('Failed to export data: ${e.toString()}');
    }
  }
}