import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/models/client_profile_model.dart';
import 'package:accident_management4/services/client_profile_service.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';
import 'package:accident_management4/widgets/custom_button.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final ClientProfileService _profileService = ClientProfileService();
  final _formKey = GlobalKey<FormState>();
  
  final List<Map<String, TextEditingController>> _contactControllers = [];
  final List<String> _relationships = [
    'Époux/Épouse',
    'Parent',
    'Enfant', 
    'Frère/Sœur',
    'Ami(e)',
    'Collègue',
    'Voisin(e)',
    'Autre'
  ];
  
  bool _isLoading = false;
  ClientProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadContacts();
  }

  void _initializeControllers() {
    for (int i = 0; i < 3; i++) {
      _contactControllers.add({
        'name': TextEditingController(),
        'phone': TextEditingController(),
        'relationship': TextEditingController(),
      });
    }
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentProfile = profile;
          
          // Load existing contacts
          for (int i = 0; i < profile.emergencyContacts.length && i < 3; i++) {
            _contactControllers[i]['name']!.text = profile.emergencyContacts[i].name;
            _contactControllers[i]['phone']!.text = profile.emergencyContacts[i].phoneNumber;
            _contactControllers[i]['relationship']!.text = profile.emergencyContacts[i].relationship;
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
    for (var controllers in _contactControllers) {
      controllers.forEach((key, controller) => controller.dispose());
    }
    super.dispose();
  }

  Future<void> _saveContacts() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if at least one contact is provided
    bool hasAtLeastOneContact = false;
    for (var controller in _contactControllers) {
      if (controller['name']!.text.isNotEmpty &&
          controller['phone']!.text.isNotEmpty &&
          controller['relationship']!.text.isNotEmpty) {
        hasAtLeastOneContact = true;
        break;
      }
    }
    
    if (!hasAtLeastOneContact) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins un contact d\'urgence est requis'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      final contacts = <ClientEmergencyContact>[];
      
      for (int i = 0; i < 3; i++) {
        if (_contactControllers[i]['name']!.text.isNotEmpty &&
            _contactControllers[i]['phone']!.text.isNotEmpty &&
            _contactControllers[i]['relationship']!.text.isNotEmpty) {
          contacts.add(ClientEmergencyContact(
            name: _contactControllers[i]['name']!.text.trim(),
            phoneNumber: _contactControllers[i]['phone']!.text.trim(),
            relationship: _contactControllers[i]['relationship']!.text,
            priority: i + 1,
          ));
        }
      }
      
      await _profileService.updateEmergencyContacts(contacts);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contacts enregistrés avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes were made
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Contacts d\'Urgence'),
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
                                'Ces contacts seront notifiés en cas d\'accident ou d\'urgence médicale.',
                                style: AppTheme.captionStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    for (int i = 0; i < 3; i++) ...[
                      _buildContactCard(i),
                      if (i < 2) const SizedBox(height: 16),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    CustomButton(
                      text: 'Enregistrer les contacts',
                      onPressed: _saveContacts,
                      isLoading: _isLoading,
                      icon: Icons.save,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildContactCard(int index) {
    final priorityLabels = ['Principal', 'Secondaire', 'Tertiaire'];
    final priorityColors = [
      AppTheme.primaryColor,
      AppTheme.clientModuleColor,
      AppTheme.textSecondaryColor,
    ];
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColors[index].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Contact ${priorityLabels[index]}',
                    style: TextStyle(
                      color: priorityColors[index],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (_contactControllers[index]['name']!.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _contactControllers[index]['name']!.clear();
                        _contactControllers[index]['phone']!.clear();
                        _contactControllers[index]['relationship']!.clear();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            CustomTextField(
              label: 'Nom complet ${index == 0 ? "*" : ""}',
              hint: 'Jean Dupont',
              controller: _contactControllers[index]['name']!,
              prefixIcon: const Icon(Icons.person),
              validator: index == 0
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le contact principal est obligatoire';
                      }
                      return null;
                    }
                  : null,
            ),
            const SizedBox(height: 12),
            
            CustomTextField(
              label: 'Numéro de téléphone ${index == 0 ? "*" : ""}',
              hint: '+226 00 00 00 00',
              controller: _contactControllers[index]['phone']!,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone),
              validator: index == 0
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le numéro est requis';
                      }
                      if (value.length < 8) {
                        return 'Numéro invalide';
                      }
                      return null;
                    }
                  : (value) {
                      if (value != null && value.isNotEmpty && value.length < 8) {
                        return 'Numéro invalide';
                      }
                      return null;
                    },
            ),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _contactControllers[index]['relationship']!.text.isEmpty
                  ? null
                  : _contactControllers[index]['relationship']!.text,
              decoration: InputDecoration(
                labelText: 'Relation ${index == 0 ? "*" : ""}',
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
                  _contactControllers[index]['relationship']!.text = value ?? '';
                });
              },
              validator: index == 0
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
            const Text('À propos des contacts'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pourquoi des contacts d\'urgence?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '• Notification immédiate en cas d\'accident\n'
              '• Accès rapide aux proches en situation d\'urgence\n'
              '• Transmission d\'informations médicales vitales',
            ),
            SizedBox(height: 16),
            Text(
              'Ordre de priorité:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '1. Contact principal: Notifié en premier\n'
              '2. Contact secondaire: Si le principal est injoignable\n'
              '3. Contact tertiaire: Dernier recours',
            ),
          ],
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
