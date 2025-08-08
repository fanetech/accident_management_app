import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/models/person_model.dart';
import 'package:accident_management4/services/person_service.dart';
import 'package:uuid/uuid.dart';

class ClientRegisterScreen extends StatefulWidget {
  const ClientRegisterScreen({Key? key}) : super(key: key);

  @override
  State<ClientRegisterScreen> createState() => _ClientRegisterScreenState();
}

class _ClientRegisterScreenState extends State<ClientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final PersonService _personService = PersonService();
  
  int _currentStep = 0;
  bool _isLoading = false;

  // Controllers pour les informations personnelles
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  // Controllers pour les contacts d'urgence
  final List<Map<String, TextEditingController>> _contactControllers = [
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'relationship': TextEditingController(),
    },
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'relationship': TextEditingController(),
    },
    {
      'name': TextEditingController(),
      'phone': TextEditingController(),
      'relationship': TextEditingController(),
    },
  ];

  final List<String> _relationships = [
    'Époux/Épouse',
    'Parent',
    'Enfant',
    'Frère/Sœur',
    'Ami(e)',
    'Autre',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    for (var contact in _contactControllers) {
      contact['name']!.dispose();
      contact['phone']!.dispose();
      contact['relationship']!.dispose();
    }
    super.dispose();
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      // Valider les informations personnelles
      if (_validatePersonalInfo()) {
        setState(() => _currentStep++);
      }
    } else if (_currentStep == 1) {
      // Valider les contacts d'urgence
      if (_validateEmergencyContacts()) {
        setState(() => _currentStep++);
        // Naviguer vers l'écran de capture biométrique
        Navigator.pushNamed(
          context,
          AppConstants.clientBiometricRoute,
          arguments: _preparePersonData(),
        );
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  bool _validatePersonalInfo() {
    if (_firstNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Le prénom est requis');
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Le nom est requis');
      return false;
    }
    if (_firstNameController.text.trim().length < 2) {
      _showErrorSnackBar('Le prénom doit contenir au moins 2 caractères');
      return false;
    }
    if (_lastNameController.text.trim().length < 2) {
      _showErrorSnackBar('Le nom doit contenir au moins 2 caractères');
      return false;
    }
    return true;
  }

  bool _validateEmergencyContacts() {
    for (int i = 0; i < 3; i++) {
      if (_contactControllers[i]['name']!.text.trim().isEmpty ||
          _contactControllers[i]['phone']!.text.trim().isEmpty ||
          _contactControllers[i]['relationship']!.text.trim().isEmpty) {
        _showErrorSnackBar('Veuillez remplir tous les contacts d\'urgence (Contact ${i + 1})');
        return false;
      }
      
      // Validate phone number format
      final phone = _contactControllers[i]['phone']!.text.trim();
      if (!_isValidPhoneNumber(phone)) {
        _showErrorSnackBar('Numéro de téléphone invalide (Contact ${i + 1})');
        return false;
      }
    }
    return true;
  }

  bool _isValidPhoneNumber(String phone) {
    // Remove spaces and check format
    final cleanPhone = phone.replaceAll(' ', '');
    // Accept formats: +226XXXXXXXXX or 6XXXXXXXX or 2XXXXXXXX
    final phoneRegex = RegExp(r'^(\226)?[2-9]\d{8}$');
    return phoneRegex.hasMatch(cleanPhone);
  }

  String _formatPhoneNumber(String phone) {
    // Clean and format phone number
    String cleanPhone = phone.replaceAll(' ', '').replaceAll('-', '');
    if (!cleanPhone.startsWith('+226') && !cleanPhone.startsWith('226')) {
      cleanPhone = '+226$cleanPhone';
    } else if (cleanPhone.startsWith('226')) {
      cleanPhone = '+$cleanPhone';
    }
    return cleanPhone;
  }

  Map<String, dynamic> _preparePersonData() {
    final uuid = const Uuid();
    List<EmergencyContact> contacts = [];
    
    for (int i = 0; i < 3; i++) {
      contacts.add(EmergencyContact(
        contactId: uuid.v4(),
        name: _contactControllers[i]['name']!.text.trim(),
        phoneNumber: _formatPhoneNumber(_contactControllers[i]['phone']!.text.trim()),
        relationship: _contactControllers[i]['relationship']!.text,
        priority: i + 1,
      ));
    }

    return {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'emergencyContacts': contacts,
      'service': _personService, // Pass the service for saving
    };
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nouvel enregistrement'),
        backgroundColor: AppTheme.clientModuleColor,
        elevation: 0,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.clientModuleColor,
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: details.onStepContinue,
                    icon: Icon(_currentStep == 1 ? Icons.fingerprint : Icons.arrow_forward),
                    label: Text(_currentStep == 1 ? 'Capturer les empreintes' : 'Continuer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.clientModuleColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(
                      _currentStep == 0 ? 'Annuler' : 'Retour',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Informations personnelles'),
              content: _buildPersonalInfoStep(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0
                  ? StepState.complete
                  : StepState.indexed,
            ),
            Step(
              title: const Text('Contacts d\'urgence'),
              subtitle: const Text('3 contacts requis'),
              content: _buildEmergencyContactsStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1
                  ? StepState.complete
                  : StepState.indexed,
            ),
            Step(
              title: const Text('Empreintes digitales'),
              subtitle: const Text('Pouce gauche et auriculaire droit'),
              content: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.fingerprint,
                      size: 80,
                      color: AppTheme.clientModuleColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Les empreintes seront capturées à l\'étape suivante',
                      style: AppTheme.bodyStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Préparez le pouce gauche et l\'auriculaire droit',
                      style: AppTheme.captionStyle,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Identité de la personne',
            style: AppTheme.subheadingStyle.copyWith(
              color: AppTheme.clientModuleColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          CustomTextField(
            label: 'Prénom *',
            hint: 'Entrez le prénom',
            controller: _firstNameController,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le prénom est requis';
              }
              if (value.trim().length < 2) {
                return 'Le prénom doit contenir au moins 2 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Nom *',
            hint: 'Entrez le nom',
            controller: _lastNameController,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom est requis';
              }
              if (value.trim().length < 2) {
                return 'Le nom doit contenir au moins 2 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Info card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.infoColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ces informations seront utilisées pour identifier la personne en cas d\'urgence',
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.infoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacts d\'urgence',
          style: AppTheme.subheadingStyle.copyWith(
            color: AppTheme.clientModuleColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ces personnes seront contactées en cas d\'accident',
          style: AppTheme.captionStyle,
        ),
        const SizedBox(height: 20),
        ...List.generate(3, (index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.clientModuleColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppTheme.clientModuleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Contact priorité ${index + 1}',
                        style: AppTheme.subheadingStyle.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Nom complet *',
                    hint: 'Nom du contact',
                    controller: _contactControllers[index]['name']!,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'Numéro de téléphone *',
                    hint: '+226 6XX XXX XXX',
                    controller: _contactControllers[index]['phone']!,
                    prefixIcon: const Icon(Icons.phone),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _contactControllers[index]['relationship']!.text.isEmpty
                        ? null
                        : _contactControllers[index]['relationship']!.text,
                    decoration: InputDecoration(
                      labelText: 'Relation *',
                      prefixIcon: const Icon(Icons.family_restroom),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: AppTheme.clientModuleColor, width: 2),
                      ),
                    ),
                    items: _relationships.map((String relation) {
                      return DropdownMenuItem(
                        value: relation,
                        child: Text(relation),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _contactControllers[index]['relationship']!.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez sélectionner une relation';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
