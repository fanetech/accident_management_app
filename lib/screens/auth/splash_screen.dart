import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthAndNavigate();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _animationController.forward();
  }

  void _checkAuthAndNavigate() async {
    // Wait for animation
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    try {
      // Check if user is logged in
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Check if session is still valid
        final isValid = await _authService.isSessionValid();
        
        if (isValid) {
          // Session is valid, check user role and navigate
          final role = await _authService.getCurrentUserRole();
          
          if (mounted) {
            if (role == 'admin') {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.adminDashboardRoute,
              );
            } else if (role == 'client') {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.clientDashboardRoute,
              );
            } else {
              // Role not set, go to role detection
              Navigator.pushReplacementNamed(
                context,
                AppConstants.roleDetectionRoute,
              );
            }
          }
        } else {
          // Session expired, sign out and go to login
          await _authService.signOut();
          if (mounted) {
            _showSessionExpiredDialog();
          }
        }
      } else {
        // No user logged in, go to login
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            AppConstants.loginRoute,
          );
        }
      }
    } catch (e) {
      print('Error checking auth: $e');
      // On error, go to login
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppConstants.loginRoute,
        );
      }
    }
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.timer_off, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            const Text('Session expirée'),
          ],
        ),
        content: const Text(
          'Votre session a expiré après 24 heures. '
          'Veuillez vous reconnecter pour continuer.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(
                context,
                AppConstants.loginRoute,
              );
            },
            child: const Text('Se reconnecter'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animé
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medical_services,
                        size: 80,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            // Titre de l'application
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    AppConstants.appName,
                    style: AppTheme.headingStyle.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Système de prise en charge',
                    style: AppTheme.bodyStyle.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
            // Indicateur de chargement
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vérification de la session...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
