import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    String? role,
  }) async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile with display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _createUserDocument(
          uid: userCredential.user!.uid,
          email: email,
          displayName: displayName,
          phoneNumber: phoneNumber,
          role: role,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Une erreur inattendue s\'est produite';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save session after successful login
      if (userCredential.user != null) {
        final role = await getCurrentUserRole();
        await _saveSession(role);
        
        // Update last login in Firestore
        await updateUserDocument(
          uid: userCredential.user!.uid,
          updates: {'lastLogin': FieldValue.serverTimestamp()},
        );
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Une erreur inattendue s\'est produite';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _clearSession();
    } catch (e) {
      throw 'Erreur lors de la déconnexion';
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Une erreur inattendue s\'est produite';
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    String? phoneNumber,
    String? role,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'role': role ?? 'client', // Use provided role or default to client
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors de la création du profil utilisateur';
    }
  }

  // Update user document
  Future<void> updateUserDocument({
    required String uid,
    Map<String, dynamic>? updates,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...?updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Erreur lors de la mise à jour du profil';
    }
  }

  // Get user document
  Future<DocumentSnapshot> getUserDocument(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      throw 'Erreur lors de la récupération du profil';
    }
  }

  // Get current user role
  Future<String?> getCurrentUserRole() async {
    try {
      final user = currentUser;
      if (user == null) return null;
      
      final doc = await getUserDocument(user.uid);
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      return data['role'] as String?;
    } catch (e) {
      return null;
    }
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role == 'admin';
  }

  // Check if user is client
  Future<bool> isClient() async {
    final role = await getCurrentUserRole();
    return role == 'client';
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete user from Firebase Auth
        await user.delete();
        // Clear session
        await _clearSession();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Une erreur inattendue s\'est produite';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email';
      case 'invalid-email':
        return 'L\'adresse email est invalide';
      case 'user-disabled':
        return 'Ce compte a été désactivé';
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'too-many-requests':
        return 'Trop de tentatives. Veuillez réessayer plus tard';
      case 'operation-not-allowed':
        return 'Cette opération n\'est pas autorisée';
      case 'network-request-failed':
        return 'Erreur de connexion réseau';
      default:
        return 'Une erreur s\'est produite: ${e.message}';
    }
  }
  
  // Session management helpers
  Future<void> _saveSession(String? role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_login_time', DateTime.now().millisecondsSinceEpoch);
    if (role != null) {
      await prefs.setString('user_role', role);
    }
  }
  
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_login_time');
    await prefs.remove('user_role');
  }
  
  // Check if session is still valid
  Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLoginTime = prefs.getInt('last_login_time');
    
    if (lastLoginTime == null) return false;
    
    final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    
    // Session is valid for 24 hours
    return difference.inHours < 24;
  }
  
  // Auto logout if session expired
  Future<void> checkAndHandleSession() async {
    final isValid = await isSessionValid();
    if (!isValid && currentUser != null) {
      await signOut();
    }
  }
}
