import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/models/client_profile_model.dart';
import 'package:accident_management4/services/client_profile_service.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';
import 'package:accident_management4/widgets/custom_button.dart';

class MedicalInfoScreen extends StatefulWidget {
  const MedicalInfoScreen({Key? key}) : super(key: key);

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  final ClientProfileService _profileService = ClientProfileService();
  final _formKey = GlobalKey<FormState>();
  
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  ClientProfile? _currentProfile;
  
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  
  // Common allergies for quick selection
  final List<String> _commonAllergies = [
    'Pénicilline',
    'Aspirine',
    'Ibuprofène',
    'Sulfamides',
    'Latex',
    'Arachides',
    'Fruits de mer',
    'Gluten',
    'Lactose',
  ];
  
  // Common conditions for quick selection
  final List<String> _commonConditions = [
    'Diabète',
    'Hypertension',
    'Asthme',
    'Épilepsie',
    'Maladie cardiaque',
    'Insuffisance rénale',
    'Anémie',
    'VIH/SIDA',
    'Hépatite',
  ];

  @override
  void initState() {
    super.initState();
    _loadMedicalInfo();
  }

  Future<void> _loadMedicalInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentProfile = profile;
          _bloodTypeController.text = profile.bloodType ?? '';
          
          if (profile.medicalInfo != null) {
            _allergiesController.text = profile.medicalInfo!['allergies'] ?? '';
            _medicationsController.text = profile.medicalInfo!['medications'] ?? '';
            _conditionsController.text = profile.medicalInfo!['conditions'] ?? '';
            _notesController.text = profile.medicalInfo!['notes'] ?? '';
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _allergiesController.dispose();
    _medicationsController.dispose();
    _conditionsController.dispose();
    _bloodTypeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveMedicalInfo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _profileService.updateProfile(
        bloodType: _bloodTypeController.text.isEmpty ? null : _bloodTypeController.text,
        medicalInfo: {
          'allergies': _allergiesController.text.trim(),
          'medications': _medicationsController.text.trim(),
          'conditions': _conditionsController.text.trim(),
          'notes': _notesController.text.trim(),
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informations médicales enregistrées'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addToField(TextEditingController controller, String value) {
    final currentText = controller.text.trim();
    if (currentText.isEmpty) {
      controller.text = value;
    } else if (!currentText.contains(value)) {
      controller.text = '$currentText, $value';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Informations Médicales'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: _isLoading && _currentProfile == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Important Notice
                    Card(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: AppTheme.warningColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Ces informations peuvent sauver votre vie en cas d\'urgence. Soyez précis et complet.',
                                style: AppTheme.captionStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Blood Type
                    Text(
                      'Groupe Sanguin',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _bloodTypeController.text.isEmpty ? null : _bloodTypeController.text,
                      decoration: InputDecoration(
                        labelText: 'Sélectionnez votre groupe sanguin',
                        prefixIcon: const Icon(Icons.bloodtype),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _bloodTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _bloodTypeController.text = value ?? '';
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Allergies
                    Text(
                      'Allergies',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Listez vos allergies',
                      hint: 'Ex: Pénicilline, Arachides, Latex...',
                      controller: _allergiesController,
                      prefixIcon: const Icon(Icons.warning),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _commonAllergies.map((allergy) {
                        return ActionChip(
                          label: Text(allergy),
                          onPressed: () => _addToField(_allergiesController, allergy),
                          backgroundColor: AppTheme.errorColor.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Current Medications
                    Text(
                      'Médicaments Actuels',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Médicaments que vous prenez régulièrement',
                      hint: 'Ex: Insuline, Aspirine, etc.',
                      controller: _medicationsController,
                      prefixIcon: const Icon(Icons.medication),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Medical Conditions
                    Text(
                      'Conditions Médicales',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Maladies chroniques ou conditions',
                      hint: 'Ex: Diabète, Hypertension, Asthme...',
                      controller: _conditionsController,
                      prefixIcon: const Icon(Icons.medical_services),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _commonConditions.map((condition) {
                        return ActionChip(
                          label: Text(condition),
                          onPressed: () => _addToField(_conditionsController, condition),
                          backgroundColor: AppTheme.infoColor.withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Additional Notes
                    Text(
                      'Notes Additionnelles',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Autres informations importantes',
                      hint: 'Informations supplémentaires pour les secours...',
                      controller: _notesController,
                      prefixIcon: const Icon(Icons.note),
                      maxLines: 4,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Privacy Notice
                    Card(
                      color: AppTheme.infoColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lock, color: AppTheme.infoColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Confidentialité',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.infoColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ces informations sont strictement confidentielles et ne seront partagées qu\'avec les services d\'urgence en cas de nécessité.',
                                    style: AppTheme.captionStyle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    CustomButton(
                      text: 'Enregistrer',
                      onPressed: _saveMedicalInfo,
                      isLoading: _isLoading,
                      icon: Icons.save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: AppTheme.infoColor),
            const SizedBox(width: 8),
            const Text('Importance des informations médicales'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pourquoi c\'est important?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Permet aux secours d\'éviter les erreurs médicales\n'
                '• Accélère le diagnostic et le traitement\n'
                '• Prévient les réactions allergiques dangereuses\n'
                '• Informe sur les interactions médicamenteuses',
              ),
              SizedBox(height: 16),
              Text(
                'Conseils:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Soyez précis sur les noms des médicaments\n'
                '• Incluez les dosages si possible\n'
                '• Mentionnez toutes les allergies connues\n'
                '• Mettez à jour régulièrement ces informations',
              ),
              SizedBox(height: 16),
              Text(
                'En cas d\'urgence:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Les secours auront accès immédiat à ces informations via votre QR code ou votre profil.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
