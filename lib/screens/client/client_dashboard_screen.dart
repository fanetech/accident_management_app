import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/services/auth_service.dart';
import 'package:accident_management4/services/client_profile_service.dart';
import 'package:accident_management4/models/client_profile_model.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final AuthService _authService = AuthService();
  final ClientProfileService _profileService = ClientProfileService();
  
  bool _isLoading = true;
  ClientProfile? _userProfile;
  String _userName = 'Utilisateur';

  @override
  void initState() {
    super.initState();
    _checkProfileAndLoadData();
  }

  Future<void> _checkProfileAndLoadData() async {
    try {
      // Get current user profile
      final profile = await _profileService.getCurrentUserProfile();
      
      if (profile == null) {
        // No profile exists, redirect to profile completion
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/client/profile-completion');
        }
        return;
      }
      
      // Check if profile is complete
      if (!profile.isProfileComplete) {
        // Profile incomplete, show warning or redirect
        if (mounted) {
          _showIncompleteProfileDialog(profile);
        }
      }
      
      setState(() {
        _userProfile = profile;
        _userName = profile.displayName.isNotEmpty 
            ? profile.displayName 
            : 'Utilisateur';
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showIncompleteProfileDialog(ClientProfile profile) {
    final missingFields = profile.missingFields;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.warningColor),
            const SizedBox(width: 8),
            const Text('Profil Incomplet'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre profil est incomplet. Les informations suivantes sont manquantes:',
            ),
            const SizedBox(height: 16),
            ...missingFields.map((field) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.close, color: AppTheme.errorColor, size: 16),
                  const SizedBox(width: 8),
                  Text(field),
                ],
              ),
            )),
            const SizedBox(height: 16),
            const Text(
              'Ces informations sont essentielles en cas d\'urgence.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/client/profile-completion');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Compléter maintenant'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mon Espace'),
        backgroundColor: AppTheme.clientModuleColor,
        actions: [
          if (_userProfile != null && !_userProfile!.isProfileComplete)
            IconButton(
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () {
                _showIncompleteProfileDialog(_userProfile!);
              },
            ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/client/profile');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _checkProfileAndLoadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message with profile status
                    Card(
                      color: _userProfile?.isProfileComplete == true
                          ? AppTheme.successColor.withOpacity(0.1)
                          : AppTheme.warningColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _userProfile?.isProfileComplete == true
                                      ? Icons.check_circle
                                      : Icons.warning,
                                  color: _userProfile?.isProfileComplete == true
                                      ? AppTheme.successColor
                                      : AppTheme.warningColor,
                                  size: 32,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bienvenue, $_userName!',
                                        style: AppTheme.subheadingStyle,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _userProfile?.isProfileComplete == true
                                            ? 'Votre profil est complet ✓'
                                            : 'Profil à compléter',
                                        style: AppTheme.captionStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_userProfile?.isProfileComplete != true) ...[
                              const SizedBox(height: 16),
                              CustomButton(
                                text: 'Compléter mon profil',
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context, 
                                    '/client/profile-completion',
                                  );
                                },
                                type: ButtonType.primary,
                                icon: Icons.edit,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Profile Summary
                    Text(
                      'Résumé du Profil',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusCard(
                            'Contacts d\'urgence',
                            '${_userProfile?.emergencyContacts.length ?? 0}/3',
                            Icons.contact_phone,
                            _userProfile?.emergencyContacts.isNotEmpty == true
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatusCard(
                            'Empreinte',
                            _userProfile?.hasFingerprint == true 
                                ? 'Enregistrée' 
                                : 'Non enregistrée',
                            Icons.fingerprint,
                            _userProfile?.hasFingerprint == true
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatusCard(
                            'Téléphone',
                            _userProfile?.phoneNumber?.isNotEmpty == true
                                ? 'Configuré'
                                : 'Non configuré',
                            Icons.phone,
                            _userProfile?.phoneNumber?.isNotEmpty == true
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatusCard(
                            'Groupe sanguin',
                            _userProfile?.bloodType ?? 'Non défini',
                            Icons.bloodtype,
                            _userProfile?.bloodType?.isNotEmpty == true
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Quick Actions
                    Text(
                      'Actions Rapides',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildActionCard(
                          'Mon Profil',
                          Icons.person,
                          AppTheme.primaryColor,
                          () {
                            Navigator.pushNamed(context, '/client/profile');
                          },
                        ),
                        _buildActionCard(
                          'Contacts d\'urgence',
                          Icons.contact_phone,
                          AppTheme.clientModuleColor,
                          () {
                            Navigator.pushNamed(
                              context,
                              '/client/emergency-contacts',
                            );
                          },
                        ),
                        _buildActionCard(
                          'Informations médicales',
                          Icons.medical_services,
                          AppTheme.infoColor,
                          () {
                            Navigator.pushNamed(
                              context,
                              '/client/medical-info',
                            );
                          },
                        ),
                        _buildActionCard(
                          'Paramètres',
                          Icons.settings,
                          AppTheme.textSecondaryColor,
                          () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.settingsRoute,
                            );
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Emergency Button
                    Card(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emergency,
                              size: 48,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'En cas d\'urgence',
                              style: AppTheme.subheadingStyle,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Vos contacts seront automatiquement notifiés',
                              style: AppTheme.captionStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Appel d\'urgence',
                              onPressed: _handleEmergencyCall,
                              type: ButtonType.primary,
                              icon: Icons.phone,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: _userProfile?.isProfileComplete == true
          ? FloatingActionButton(
              onPressed: _showQRCode,
              backgroundColor: AppTheme.clientModuleColor,
              child: const Icon(Icons.qr_code),
              tooltip: 'Mon QR Code',
            )
          : null,
    );
  }

  Widget _buildStatusCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Icon(
                  color == AppTheme.successColor 
                      ? Icons.check_circle 
                      : Icons.warning,
                  color: color,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTheme.captionStyle,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppConstants.loginRoute,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _handleEmergencyCall() {
    // TODO: Implement emergency call functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Appel d\'urgence'),
          ],
        ),
        content: const Text(
          'Cette fonctionnalité notifiera tous vos contacts d\'urgence. '
          'Voulez-vous continuer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Send emergency notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contacts d\'urgence notifiés'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showQRCode() {
    // TODO: Generate and show QR code with user profile ID
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mon QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryColor, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2,
                  size: 150,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ID: ${_userProfile?.uid.substring(0, 8)}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
