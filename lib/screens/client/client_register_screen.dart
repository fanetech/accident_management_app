import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/models/person_model.dart';
import 'package:uuid/uuid.dart';

class ClientRegisterScreen extends StatefulWidget {
  const ClientRegisterScreen({Key? key}) : super(key: key);

  @override
  State<ClientRegisterScreen> createState() => _ClientRegisterScreenState();
}

class _ClientRegisterScreenState extends State<ClientRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (_firstNameController.text.isEmpty) {
      _showErrorSnackBar('Le prénom est requis');
      return false;
    }
    if (_lastNameController.text.isEmpty) {
      _showErrorSnackBar('Le nom est requis');
      return false;
    }
    return true;
  }

  bool _validateEmergencyContacts() {
    for (int i = 0; i < 3; i++) {
      if (_contactControllers[i]['name']!.text.isEmpty ||
          _contactControllers[i]['phone']!.text.isEmpty ||
          _contactControllers[i]['relationship']!.text.isEmpty) {
        _showErrorSnackBar('Veuillez remplir tous les contacts d\'urgence');
        return false;
      }
    }
    return true;
  }

  Map<String, dynamic> _preparePersonData() {
    final uuid = const Uuid();
    List<EmergencyContact> contacts = [];
    
    for (int i = 0; i < 3; i++) {
      contacts.add(EmergencyContact(
        contactId: uuid.v4(),
        name: _contactControllers[i]['name']!.text,
        phoneNumber: _contactControllers[i]['phone']!.text,
        relationship: _contactControllers[i]['relationship']!.text,
        priority: i + 1,
      ));
    }

    return {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'emergencyContacts': contacts,
    };
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Nouvel enregistrement'),
        backgroundColor: AppTheme.clientModuleColor,
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
            return Row(
              children: [
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep == 1 ? 'Suivant' : 'Continuer'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(_currentStep == 0 ? 'Annuler' : 'Retour'),
                ),
              ],
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
              content: _buildEmergencyContactsStep(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1
                  ? StepState.complete
                  : StepState.indexed,
            ),
            Step(
              title: const Text('Empreintes digitales'),
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
                      'Cliquez sur "Suivant" pour capturer les empreintes',
                      style: AppTheme.bodyStyle,
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
        children: [
          CustomTextField(
            label: 'Prénom',
            hint: 'Entrez le prénom',
            controller: _firstNameController,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le prénom est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Nom',
            hint: 'Entrez le nom',
            controller: _lastNameController,
            prefixIcon: const Icon(Icons.person_outline),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le nom est requis';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          // Option pour ajouter une photo
          Card(
            color: AppTheme.clientModuleColor.withOpacity(0.1),
            child: ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: AppTheme.clientModuleColor,
              ),
              title: const Text('Ajouter une photo'),
              subtitle: const Text('Optionnel'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Implémenter la capture de photo
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsStep() {
    return Column(
      children: List.generate(3, (index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact ${index + 1}',
                  style: AppTheme.subheadingStyle.copyWith(
                    color: AppTheme.clientModuleColor,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Nom complet',
                  hint: 'Nom du contact',
                  controller: _contactControllers[index]['name']!,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                const SizedBox(height: 12),
                PhoneNumberField(
                  label: 'Numéro de téléphone',
                  controller: _contactControllers[index]['phone']!,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _contactControllers[index]['relationship']!.text.isEmpty
                      ? null
                      : _contactControllers[index]['relationship']!.text,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    prefixIcon: const Icon(Icons.family_restroom),
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
    );
  }
}
