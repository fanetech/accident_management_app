import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accident_management4/core/constants/app_constants.dart';

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users
  Stream<QuerySnapshot> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update user role
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'roleUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors de la mise à jour du rôle: $e';
    }
  }

  // Make user admin
  Future<void> makeUserAdmin(String userId) async {
    await updateUserRole(userId, AppConstants.adminRole);
  }

  // Make user client
  Future<void> makeUserClient(String userId) async {
    await updateUserRole(userId, AppConstants.clientRole);
  }

  // Get users by role
  Stream<QuerySnapshot> getUsersByRole(String role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Search users
  Future<List<DocumentSnapshot>> searchUsers(String query) async {
    try {
      final emailQuery = await _firestore
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: query)
          .where('email', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      final nameQuery = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(10)
          .get();

      // Combine and deduplicate results
      final Map<String, DocumentSnapshot> uniqueUsers = {};
      
      for (var doc in emailQuery.docs) {
        uniqueUsers[doc.id] = doc;
      }
      
      for (var doc in nameQuery.docs) {
        uniqueUsers[doc.id] = doc;
      }

      return uniqueUsers.values.toList();
    } catch (e) {
      throw 'Erreur lors de la recherche: $e';
    }
  }

  // Toggle user role
  Future<void> toggleUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw 'Utilisateur introuvable';
      }

      final currentRole = doc.data()?['role'] ?? AppConstants.clientRole;
      final newRole = currentRole == AppConstants.adminRole
          ? AppConstants.clientRole
          : AppConstants.adminRole;

      await updateUserRole(userId, newRole);
    } catch (e) {
      throw 'Erreur lors du changement de rôle: $e';
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      
      int totalUsers = 0;
      int adminCount = 0;
      int clientCount = 0;

      for (var doc in snapshot.docs) {
        totalUsers++;
        final role = doc.data()['role'] ?? AppConstants.clientRole;
        if (role == AppConstants.adminRole) {
          adminCount++;
        } else {
          clientCount++;
        }
      }

      return {
        'total': totalUsers,
        'admins': adminCount,
        'clients': clientCount,
      };
    } catch (e) {
      throw 'Erreur lors de la récupération des statistiques: $e';
    }
  }

  // Create initial admin (use this for first admin setup)
  Future<void> createInitialAdmin(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw 'Aucun utilisateur trouvé avec cet email';
      }

      final userId = querySnapshot.docs.first.id;
      await makeUserAdmin(userId);
    } catch (e) {
      throw 'Erreur lors de la création de l\'admin: $e';
    }
  }
}
