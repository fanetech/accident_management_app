import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/models/client_profile_model.dart';
import 'package:accident_management4/services/client_profile_service.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({Key? key}) : super(key: key);

  @override
  State<ProfileCompletionScreen> createState() => _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final ClientProfileService _profileService = ClientProfileService();
  final _formKey = GlobalKey<FormState>();
  
  // Personal Info Controllers
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  
  // Emergency Contacts Controllers
  final List<Map<String, TextEditingController>> _contactControllers = [];
  
  // Medical Info
  final _allergiesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _conditionsController = TextEditingController();
  
  bool _isLoading = false;
  int _currentStep = 0;
  ClientProfile? _currentProfile;
  
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _relationships = ['Époux/Épouse', 'Parent', 'Enfant', 'Frère/Sœur', 'Ami(e)', 'Autre'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _initializeContactControllers();
  }

  void _initializeContactControllers() {
    for (int i = 0; i < 3; i++) {
      _contactControllers.add({
        'name': TextEditingController(),
        'phone': TextEditingController(),
        'relationship': TextEditingController(),
      });
    }
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.getCurrentUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _currentProfile = profile;
        _phoneController.text = profile.phoneNumber ?? '';
        _addressController.text = profile.address ?? '';
        _bloodTypeController.text = profile.bloodType ?? '';
        _selectedDateOfBirth = profile.dateOfBirth;
        
        // Load emergency contacts
        for (int i = 0; i < profile.emergencyContacts.length && i < 3; i++) {
          _contactControllers[i]['name']!.text = profile.emergencyContacts[i].name;
          _contactControllers[i]['phone']!.text = profile.emergencyContacts[i].phoneNumber;
          _contactControllers[i]['relationship']!.text = profile.emergencyContacts[i].relationship;
        }
        
        // Load medical info
        if (profile.medicalInfo != null) {
          _allergiesController.text = profile.medicalInfo!['allergies'] ?? '';
          _medicationsController.text = profile.medicalInfo!['medications'] ?? '';
          _conditionsController.text = profile.medicalInfo!['conditions'] ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _conditionsController.dispose();
    for (var controllers in _contactControllers) {
      controllers.forEach((key, controller) => controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Compléter votre profil'),
        backgroundColor: AppTheme.primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          // Stepper headers
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Informations'),
                _buildStepConnector(),
                _buildStepIndicator(1, 'Urgence'),
                _buildStepConnector(),
                _buildStepIndicator(2, 'Médical'),
                _buildStepConnector(),
                _buildStepIndicator(3, 'Biométrie'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Form(
              key: _formKey,
              child: _buildStepContent(),
            ),
          ),
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step <= _currentStep;
    final isCompleted = step < _currentStep;
    
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppTheme.primaryColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      height: 2,
      width: 20,
      color: Colors.grey[300],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildEmergencyContactsStep();
      case 2:
        return _buildMedicalInfoStep();
      case 3:
        return _buildBiometricStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations Personnelles',
            style: AppTheme.headingStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Ces informations sont essentielles en cas d\'urgence',
            style: AppTheme.captionStyle,
          ),
          const SizedBox(height: 24),
          
          CustomTextField(
            label: 'Numéro de téléphone *',
            hint: '+226 00 00 00 00',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le numéro de téléphone est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Adresse complète *',
            hint: 'Quartier, Ville',
            controller: _addressController,
            prefixIcon: const Icon(Icons.location_on),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'L\'adresse est requise';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Date of birth picker
          InkWell(
            onTap: _selectDateOfBirth,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date de naissance *',
                prefixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _selectedDateOfBirth != null
                    ? DateFormat('dd/MM/yyyy').format(_selectedDateOfBirth!)
                    : 'Sélectionner la date',
                style: TextStyle(
                  color: _selectedDateOfBirth != null
                      ? AppTheme.textColor
                      : AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Blood type dropdown
          DropdownButtonFormField<String>(
            value: _bloodTypeController.text.isEmpty ? null : _bloodTypeController.text,
            decoration: InputDecoration(
              labelText: 'Groupe sanguin *',
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le groupe sanguin est requis';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contacts d\'Urgence',
            style: AppTheme.headingStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez jusqu\'à 3 contacts qui seront notifiés en cas d\'accident',
            style: AppTheme.captionStyle,
          ),
          const SizedBox(height: 24),
          
          for (int i = 0; i < 3; i++) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact ${i + 1} ${i == 0 ? "(Principal)" : i == 1 ? "(Secondaire)" : "(Tertiaire)"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Nom complet ${i == 0 ? "*" : ""}',
                      hint: 'Jean Dupont',
                      controller: _contactControllers[i]['name']!,
                      prefixIcon: const Icon(Icons.person),
                      validator: i == 0
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Au moins un contact est requis';
                              }
                              return null;
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    
                    CustomTextField(
                      label: 'Numéro de téléphone ${i == 0 ? "*" : ""}',
                      hint: '+226 00 00 00 00',
                      controller: _contactControllers[i]['phone']!,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone),
                      validator: i == 0
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Le numéro est requis';
                              }
                              return null;
                            }
                          : null,
                    ),
                    const SizedBox(height: 12),
                    
                    DropdownButtonFormField<String>(
                      value: _contactControllers[i]['relationship']!.text.isEmpty 
                          ? null 
                          : _contactControllers[i]['relationship']!.text,
                      decoration: InputDecoration(
                        labelText: 'Relation ${i == 0 ? "*" : ""}',
                        prefixIcon: const Icon(Icons.people),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _relationships.map((rel) {
                        return DropdownMenuItem(
                          value: rel,
                          child: Text(rel),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _contactControllers[i]['relationship']!.text = value ?? '';
                        });
                      },
                      validator: i == 0
                          ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'La relation est requise';
                              }
                              return null;
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            if (i < 2) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations Médicales',
            style: AppTheme.headingStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Ces informations peuvent sauver votre vie en cas d\'urgence',
            style: AppTheme.captionStyle,
          ),
          const SizedBox(height: 24),
          
          CustomTextField(
            label: 'Allergies',
            hint: 'Ex: Pénicilline, Arachides, etc.',
            controller: _allergiesController,
            prefixIcon: const Icon(Icons.warning),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Médicaments actuels',
            hint: 'Listez vos médicaments réguliers',
            controller: _medicationsController,
            prefixIcon: const Icon(Icons.medication),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          CustomTextField(
            label: 'Conditions médicales',
            hint: 'Ex: Diabète, Hypertension, etc.',
            controller: _conditionsController,
            prefixIcon: const Icon(Icons.medical_services),
            maxLines: 2,
          ),
          
          const SizedBox(height: 24),
          
          Card(
            color: AppTheme.infoColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info, color: AppTheme.infoColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Ces informations sont confidentielles et ne seront partagées qu\'avec les services d\'urgence.',
                      style: AppTheme.captionStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Enregistrement Biométrique',
            style: AppTheme.headingStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Votre empreinte digitale permettra une identification rapide',
            style: AppTheme.captionStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          // Fingerprint icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: _currentProfile?.hasFingerprint == true
                  ? AppTheme.successColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fingerprint,
              size: 80,
              color: _currentProfile?.hasFingerprint == true
                  ? AppTheme.successColor
                  : AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          
          if (_currentProfile?.hasFingerprint == true) ...[
            const Icon(Icons.check_circle, color: AppTheme.successColor, size: 32),
            const SizedBox(height: 8),
            Text(
              'Empreinte enregistrée',
              style: TextStyle(
                color: AppTheme.successColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            CustomButton(
              text: 'Enregistrer l\'empreinte',
              onPressed: _captureFingerprint,
              icon: Icons.fingerprint,
              type: ButtonType.primary,
            ),
          ],
          
          const SizedBox(height: 40),
          
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
                      'L\'empreinte digitale est obligatoire pour compléter votre profil.',
                      style: AppTheme.captionStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: CustomButton(
                text: 'Précédent',
                onPressed: () {
                  setState(() {
                    _currentStep--;
                  });
                },
                type: ButtonType.outline,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: _currentStep == 3 ? 'Terminer' : 'Suivant',
              onPressed: _handleNext,
              isLoading: _isLoading,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _captureFingerprint() async {
    // TODO: Implement actual fingerprint capture
    // For now, simulate fingerprint capture
    setState(() => _isLoading = true);
    
    await Future.delayed(const Duration(seconds: 2));
    
    // Save fake fingerprint data
    await _profileService.updateFingerprintData('fake_fingerprint_data');
    
    // Reload profile
    await _loadProfile();
    
    setState(() => _isLoading = false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Empreinte enregistrée avec succès'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep < 3) {
      // Validate current step
      if (_currentStep == 0 && !_validatePersonalInfo()) return;
      if (_currentStep == 1 && !_validateEmergencyContacts()) return;
      
      // Save current step data
      await _saveCurrentStepData();
      
      setState(() {
        _currentStep++;
      });
    } else {
      // Final step - complete profile
      await _completeProfile();
    }
  }

  bool _validatePersonalInfo() {
    if (!_formKey.currentState!.validate()) return false;
    if (_selectedDateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner votre date de naissance'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateEmergencyContacts() {
    if (!_formKey.currentState!.validate()) return false;
    // At least one contact is required
    if (_contactControllers[0]['name']!.text.isEmpty ||
        _contactControllers[0]['phone']!.text.isEmpty ||
        _contactControllers[0]['relationship']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins un contact d\'urgence est requis'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _saveCurrentStepData() async {
    setState(() => _isLoading = true);
    
    try {
      switch (_currentStep) {
        case 0:
          // Save personal info
          await _profileService.updateProfile(
            phoneNumber: _phoneController.text,
            address: _addressController.text,
            dateOfBirth: _selectedDateOfBirth,
            bloodType: _bloodTypeController.text,
          );
          break;
          
        case 1:
          // Save emergency contacts
          final contacts = <ClientEmergencyContact>[];
          for (int i = 0; i < 3; i++) {
            if (_contactControllers[i]['name']!.text.isNotEmpty) {
              contacts.add(ClientEmergencyContact(
                name: _contactControllers[i]['name']!.text,
                phoneNumber: _contactControllers[i]['phone']!.text,
                relationship: _contactControllers[i]['relationship']!.text,
                priority: i + 1,
              ));
            }
          }
          await _profileService.updateEmergencyContacts(contacts);
          break;
          
        case 2:
          // Save medical info
          await _profileService.updateProfile(
            medicalInfo: {
              'allergies': _allergiesController.text,
              'medications': _medicationsController.text,
              'conditions': _conditionsController.text,
            },
          );
          break;
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

  Future<void> _completeProfile() async {
    // Check if fingerprint is registered
    if (_currentProfile?.hasFingerprint != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez enregistrer votre empreinte digitale'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Save any remaining data
      await _saveCurrentStepData();
      
      // Navigate to dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/client/dashboard',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
