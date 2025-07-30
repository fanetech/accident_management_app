import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/models/person_model.dart';
import 'package:uuid/uuid.dart';

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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateId();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _personData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _saveData();
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
  }

  void _generateId() {
    // Générer un ID unique pour la personne
    final uuid = const Uuid();
    _generatedId = 'ACC-${DateTime.now().year}-${uuid.v4().substring(0, 8).toUpperCase()}';
  }

  Future<void> _saveData() async {
    setState(() => _isSaving = true);

    try {
      // TODO: Sauvegarder les données dans Firebase
      await Future.delayed(const Duration(seconds: 2)); // Simulation
      
      HapticFeedback.mediumImpact();
      _showSuccessSnackBar(AppConstants.registrationSuccessMessage);
    } catch (e) {
      _showErrorSnackBar(AppConstants.genericErrorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_personData == null) {
      return const Scaffold(
        body: Center(
          child: Text('Erreur: Données manquantes'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Confirmation'),
        backgroundColor: AppTheme.clientModuleColor,
        automaticallyImplyLeading: false,
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
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 60,
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
                      'Enregistrement réussi !',
                      style: AppTheme.headingStyle.copyWith(
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Les informations ont été enregistrées avec succès',
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppTheme.clientModuleColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Résumé des informations',
                    style: AppTheme.subheadingStyle,
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildInfoRow('Nom complet',
                  '${_personData!['firstName']} ${_personData!['lastName']}'),
              const SizedBox(height: 12),
              Text(
                'Contacts d\'urgence:',
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...(_personData!['emergencyContacts'] as List<EmergencyContact>)
                  .asMap()
                  .entries
                  .map((entry) {
                final index = entry.key;
                final contact = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.clientModuleColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppTheme.clientModuleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${contact.relationship} - ${_maskPhoneNumber(contact.phoneNumber)}',
                              style: AppTheme.captionStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: AppTheme.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Empreintes digitales capturées',
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
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
        color: AppTheme.clientModuleColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Identifiant généré',
                style: AppTheme.bodyStyle,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _generatedId,
                    style: AppTheme.headingStyle.copyWith(
                      color: AppTheme.clientModuleColor,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedId));
                      _showSuccessSnackBar('ID copié dans le presse-papiers');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          CustomButton(
            text: 'Nouvel enregistrement',
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppConstants.clientRegisterRoute,
                    );
                  },
            icon: Icons.person_add,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Retour au tableau de bord',
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppConstants.clientDashboardRoute,
                      (route) => false,
                    );
                  },
            type: ButtonType.outline,
            icon: Icons.dashboard,
          ),
        ],
      ),
    );
  }

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 6) return phoneNumber;
    final start = phoneNumber.substring(0, 4);
    final end = phoneNumber.substring(phoneNumber.length - 2);
    final masked = '*' * (phoneNumber.length - 6);
    return '$start$masked$end';
  }
}
