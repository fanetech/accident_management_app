import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class to help set up admin users
/// This should only be used in a secure environment or during initial setup
class AdminSetup {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create an admin user directly in Firebase
  /// This method should be called from a secure environment
  static Future<void> createAdminDirectly({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      // First, check if user already exists
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw 'Un utilisateur avec cet email existe déjà';
      }

      // Create the user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw 'Échec de la création du compte admin';
      }

      // Update display name
      await userCredential.user!.updateDisplayName(displayName);
      
      // Create admin document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber ?? '',
        'role': 'admin',
        'userType': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileCompleted': false,
        'isAdmin': true, // Additional flag for clarity
      });

      print('Admin user created successfully: $email');
      
      // Sign out after creating admin
      await _auth.signOut();
      
    } catch (e) {
      print('Error creating admin: $e');
      throw e;
    }
  }

  /// Convert an existing user to admin
  /// Requires the user's UID
  static Future<void> convertUserToAdmin(String uid) async {
    try {
      // Check if user document exists
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        throw 'User document not found for UID: $uid';
      }

      // Update the user's role to admin
      await _firestore.collection('users').doc(uid).update({
        'role': 'admin',
        'userType': 'admin',
        'isAdmin': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('User $uid converted to admin successfully');
    } catch (e) {
      print('Error converting user to admin: $e');
      throw e;
    }
  }

  /// Check if a user is an admin
  static Future<bool> isUserAdmin(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        return false;
      }

      final data = userDoc.data()!;
      final role = data['role'] ?? data['userType'] ?? '';
      
      return role == 'admin' || data['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// List all admin users
  static Future<List<Map<String, dynamic>>> getAllAdmins() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return querySnapshot.docs
          .map((doc) => {
                'uid': doc.id,
                'email': doc.data()['email'],
                'displayName': doc.data()['displayName'],
                'createdAt': doc.data()['createdAt'],
              })
          .toList();
    } catch (e) {
      print('Error fetching admins: $e');
      return [];
    }
  }
}
