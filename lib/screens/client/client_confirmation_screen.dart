import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/models/person_model.dart';

class ClientConfirmationScreen extends StatefulWidget {
  const ClientConfirmationScreen({Key? key}) : super(key: key);

  @override
  State<ClientConfirmationScreen> createState() =>
      _ClientConfirmationScreenState();
}

class _ClientConfirmationScreenState extends State<ClientConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic>? _personData;
  String _generatedId = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _personData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (_personData != null) {
      _generatedId = _personData!['personId'] ?? '';
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
    
    // Haptic feedback for success
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_personData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: AppTheme.errorColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppTheme.errorColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Données manquantes',
                style: AppTheme.headingStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Les informations de la personne n\'ont pas été trouvées',
                style: AppTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Retour',
                onPressed: () => Navigator.pop(context),
                icon: Icons.arrow_back,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Enregistrement réussi'),
        backgroundColor: AppTheme.successColor,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Success animation
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.successColor,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 80,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Success message
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'Enregistrement terminé !',
                      style: AppTheme.headingStyle.copyWith(
                        color: AppTheme.successColor,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Les informations et les empreintes digitales ont été sauvegardées avec succès dans la base de données Firebase.',
                      style: AppTheme.bodyStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Person summary
              _buildPersonSummary(),
              const SizedBox(height: 24),
              // Generated ID
              _buildGeneratedId(),
              const SizedBox(height: 24),
              // Statistics card
              _buildStatisticsCard(),
              const SizedBox(height: 40),
              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonSummary() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.clientModuleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.person,
                      color: AppTheme.clientModuleColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Informations enregistrées',
                    style: AppTheme.subheadingStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildInfoRow(
                'Nom complet',
                '${_personData!['firstName']} ${_personData!['lastName']}',
                Icons.badge,
              ),
              const SizedBox(height: 16),
              Text(
                'Contacts d\'urgence',
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ...(_personData!['emergencyContacts'] as List<EmergencyContact>)
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final contact = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.clientModuleColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.name,
                              style: AppTheme.bodyStyle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  _maskPhoneNumber(contact.phoneNumber),
                                  style: AppTheme.captionStyle,
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.family_restroom, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  contact.relationship,
                                  style: AppTheme.captionStyle,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.fingerprint,
                      color: AppTheme.successColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Empreintes digitales capturées',
                            style: AppTheme.bodyStyle.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '✓ Pouce gauche  ✓ Auriculaire droit',
                            style: AppTheme.captionStyle.copyWith(
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTheme.bodyStyle,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedId() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        color: AppTheme.clientModuleColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.clientModuleColor.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.qr_code,
                color: AppTheme.clientModuleColor,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Identifiant unique',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SelectableText(
                    _generatedId.isNotEmpty ? _generatedId : 'ID-${DateTime.now().millisecondsSinceEpoch}',
                    style: AppTheme.headingStyle.copyWith(
                      color: AppTheme.clientModuleColor,
                      fontSize: 18,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.copy, color: AppTheme.clientModuleColor),
                    onPressed: () {
                      final id = _generatedId.isNotEmpty ? _generatedId : 'ID-${DateTime.now().millisecondsSinceEpoch}';
                      Clipboard.setData(ClipboardData(text: id));
                      _showSuccessSnackBar('Identifiant copié dans le presse-papiers');
                    },
                    tooltip: 'Copier l\'identifiant',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.people, '3', 'Contacts'),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              _buildStatItem(Icons.fingerprint, '2', 'Empreintes'),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              _buildStatItem(Icons.check_circle, '100%', 'Complet'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.clientModuleColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.headingStyle.copyWith(
            fontSize: 18,
            color: AppTheme.clientModuleColor,
          ),
        ),
        Text(
          label,
          style: AppTheme.captionStyle,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          CustomButton(
            text: 'Nouvel enregistrement',
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.clientRegisterRoute,
              );
            },
            icon: Icons.person_add,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Voir la liste des personnes',
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                AppConstants.clientPeopleListRoute,
              );
            },
            type: ButtonType.outline,
            icon: Icons.list_alt,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.clientDashboardRoute,
                (route) => false,
              );
            },
            icon: const Icon(Icons.dashboard),
            label: const Text('Retour au tableau de bord'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 6) return phoneNumber;
    final start = phoneNumber.substring(0, 6);
    final end = phoneNumber.substring(phoneNumber.length - 2);
    final masked = '*' * (phoneNumber.length - 8);
    return '$start$masked$end';
  }
}
