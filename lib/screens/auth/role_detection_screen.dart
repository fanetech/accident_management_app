import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';

class RoleDetectionScreen extends StatefulWidget {
  const RoleDetectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleDetectionScreen> createState() => _RoleDetectionScreenState();
}

class _RoleDetectionScreenState extends State<RoleDetectionScreen> {
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _detectUserRole();
  }

  Future<void> _detectUserRole() async {
    // TODO: Récupérer le rôle de l'utilisateur depuis Firebase
    await Future.delayed(const Duration(seconds: 1)); // Simulation
    
    // Pour la démo, on alterne entre les rôles
    setState(() {
      _userRole = DateTime.now().second % 2 == 0
          ? AppConstants.clientRole
          : AppConstants.adminRole;
    });

    _navigateToRoleBasedScreen();
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
            // Animation de chargement
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Vérification du profil...',
              style: AppTheme.subheadingStyle,
            ),
            const SizedBox(height: 16),
            Text(
              'Redirection en cours',
              style: AppTheme.captionStyle,
            ),
            if (_userRole != null) ...[
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
                child: Text(
                  _userRole == AppConstants.clientRole
                      ? 'Module Client'
                      : 'Module Admin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
