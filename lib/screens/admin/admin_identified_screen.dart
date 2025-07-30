import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/models/person_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminIdentifiedScreen extends StatefulWidget {
  const AdminIdentifiedScreen({Key? key}) : super(key: key);

  @override
  State<AdminIdentifiedScreen> createState() => _AdminIdentifiedScreenState();
}

class _AdminIdentifiedScreenState extends State<AdminIdentifiedScreen> {
  PersonModel? _person;
  bool _isLoading = true;
  final List<bool> _callingStates = [false, false, false];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPersonData();
  }

  Future<void> _loadPersonData() async {
    // TODO: Charger les données de la personne depuis Firebase
    await Future.delayed(const Duration(seconds: 1)); // Simulation
    
    // Données de test
    setState(() {
      _person = PersonModel(
        personId: 'test-id',
        firstName: 'Marie',
        lastName: 'Tchuente',
        registeredBy: 'admin-id',
        registeredAt: DateTime.now().subtract(const Duration(days: 30)),
        emergencyContacts: [
          EmergencyContact(
            contactId: '1',
            name: 'Jean Tchuente',
            phoneNumber: '+237690123456',
            relationship: 'Époux',
            priority: 1,
          ),
          EmergencyContact(
            contactId: '2',
            name: 'Anne Kamga',
            phoneNumber: '+237677890123',
            relationship: 'Sœur',
            priority: 2,
          ),
          EmergencyContact(
            contactId: '3',
            name: 'Paul Ngono',
            phoneNumber: '+237655443322',
            relationship: 'Ami',
            priority: 3,
          ),
        ],
      );
      _isLoading = false;
    });
  }

  Future<void> _makeCall(int contactIndex) async {
    if (_callingStates[contactIndex]) return;

    setState(() {
      _callingStates[contactIndex] = true;
    });

    final contact = _person!.emergencyContacts[contactIndex];
    final phoneNumber = contact.phoneNumber;
    final uri = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        
        // Log l'appel
        _logEmergencyCall(contact);
        
        // Naviguer vers l'écran d'appel
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppConstants.adminCallingRoute,
            arguments: {
              'person': _person,
              'contact': contact,
            },
          );
        }
      } else {
        _showErrorSnackBar('Impossible de passer l\'appel');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'appel');
    } finally {
      if (mounted) {
        setState(() {
          _callingStates[contactIndex] = false;
        });
      }
    }
  }

  void _logEmergencyCall(EmergencyContact contact) {
    // TODO: Enregistrer l'appel dans Firebase
    HapticFeedback.lightImpact();
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Identification'),
          backgroundColor: AppTheme.adminModuleColor,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_person == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: AppTheme.adminModuleColor,
        ),
        body: const Center(
          child: Text('Impossible de charger les données'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Personne identifiée'),
        backgroundColor: AppTheme.adminModuleColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Success banner
              _buildSuccessBanner(),
              const SizedBox(height: 24),
              // Person info card
              _buildPersonInfoCard(),
              const SizedBox(height: 24),
              // Emergency contacts section
              _buildEmergencyContactsSection(),
              const SizedBox(height: 24),
              // Additional info
              _buildAdditionalInfo(),
              const SizedBox(height: 24),
              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Card(
      color: AppTheme.successColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identification réussie',
                    style: AppTheme.subheadingStyle.copyWith(
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vous pouvez maintenant contacter les proches',
                    style: AppTheme.captionStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.adminModuleColor,
                  child: Text(
                    '${_person!.firstName[0]}${_person!.lastName[0]}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _person!.fullName,
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${_person!.personId}',
                        style: AppTheme.captionStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInfoRow(
              Icons.calendar_today,
              'Enregistré le',
              '${_person!.registeredAt.day}/${_person!.registeredAt.month}/${_person!.registeredAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Contacts d\'urgence',
          style: AppTheme.subheadingStyle,
        ),
        const SizedBox(height: 8),
        Text(
          'Appuyez sur un contact pour appeler',
          style: AppTheme.captionStyle,
        ),
        const SizedBox(height: 16),
        ..._person!.emergencyContacts.asMap().entries.map((entry) {
          final index = entry.key;
          final contact = entry.value;
          return _buildEmergencyContactCard(index, contact);
        }).toList(),
      ],
    );
  }

  Widget _buildEmergencyContactCard(int index, EmergencyContact contact) {
    final isLoading = _callingStates[index];
    final priorityColors = [
      AppTheme.errorColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isLoading ? null : () => _makeCall(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: priorityColors[index].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: priorityColors[index],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
                    Text(
                      contact.relationship,
                      style: AppTheme.captionStyle,
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.adminModuleColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.phone,
                        color: Colors.white,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Card(
      color: AppTheme.infoColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: AppTheme.infoColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Localisation actuelle',
                    style: AppTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yaoundé, Cameroun', // TODO: Obtenir la vraie localisation
                    style: AppTheme.captionStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        CustomButton(
          text: 'Ajouter des notes',
          onPressed: () {
            // TODO: Implémenter l'ajout de notes
          },
          type: ButtonType.outline,
          icon: Icons.note_add,
        ),
        const SizedBox(height: 12),
        CustomButton(
          text: 'Terminer l\'intervention',
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppConstants.adminDashboardRoute,
              (route) => false,
            );
          },
          type: ButtonType.success,
          icon: Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: AppTheme.captionStyle,
        ),
        Text(
          value,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
