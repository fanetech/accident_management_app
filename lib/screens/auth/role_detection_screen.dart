import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/services/auth_service.dart';

class RoleDetectionScreen extends StatefulWidget {
  const RoleDetectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleDetectionScreen> createState() => _RoleDetectionScreenState();
}

class _RoleDetectionScreenState extends State<RoleDetectionScreen> {
  final AuthService _authService = AuthService();
  String? _userRole;
  String? _userName;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _detectUserRole();
  }

  Future<void> _detectUserRole() async {
    try {
      // Get current user
      final User? currentUser = _authService.currentUser;
      
      if (currentUser == null) {
        // No user logged in, redirect to login
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
        }
        return;
      }

      // Fetch user document from Firestore
      final userDoc = await _authService.getUserDocument(currentUser.uid);
      
      if (!userDoc.exists) {
        setState(() {
          _errorMessage = 'Profil utilisateur introuvable';
          _isLoading = false;
        });
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      
      setState(() {
        _userRole = userData['role'] ?? AppConstants.clientRole;
        _userName = userData['displayName'] ?? currentUser.displayName ?? 'Utilisateur';
        _isLoading = false;
      });

      // Update last login
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // Navigate after a short delay to show the role
      await Future.delayed(const Duration(seconds: 1));
      _navigateToRoleBasedScreen();
      
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la détection du rôle: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _navigateToRoleBasedScreen() {
    if (_userRole == null) return;

    final route = _userRole == AppConstants.clientRole
        ? AppConstants.clientDashboardRoute
        : AppConstants.adminDashboardRoute;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo or animation
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      )
                    : Icon(
                        _errorMessage != null
                            ? Icons.error_outline
                            : Icons.check_circle,
                        size: 60,
                        color: _errorMessage != null
                            ? AppTheme.errorColor
                            : AppTheme.successColor,
                      ),
              ),
            ),
            const SizedBox(height: 32),
            
            if (_errorMessage != null) ...[
              Text(
                'Erreur',
                style: AppTheme.subheadingStyle.copyWith(
                  color: AppTheme.errorColor,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _errorMessage!,
                  style: AppTheme.captionStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    AppConstants.loginRoute,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Retour à la connexion',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ] else if (_isLoading) ...[
              Text(
                'Vérification du profil...',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 16),
              Text(
                'Redirection en cours',
                style: AppTheme.captionStyle,
              ),
            ] else if (_userRole != null) ...[
              Text(
                'Bienvenue, $_userName!',
                style: AppTheme.subheadingStyle,
              ),
              const SizedBox(height: 16),
              Text(
                'Redirection vers votre espace',
                style: AppTheme.captionStyle,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _userRole == AppConstants.clientRole
                      ? AppTheme.clientModuleColor
                      : AppTheme.adminModuleColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _userRole == AppConstants.clientRole
                          ? Icons.person
                          : Icons.admin_panel_settings,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _userRole == AppConstants.clientRole
                          ? 'Module Client'
                          : 'Module Administrateur',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
