import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/services/emergency_call_service.dart';
import 'package:intl/intl.dart';

class AdminIdentifiedScreen extends StatefulWidget {
  const AdminIdentifiedScreen({Key? key}) : super(key: key);

  @override
  State<AdminIdentifiedScreen> createState() => _AdminIdentifiedScreenState();
}

class _AdminIdentifiedScreenState extends State<AdminIdentifiedScreen> {
  final EmergencyCallService _callService = EmergencyCallService();
  
  Map<String, dynamic>? _personData;
  DateTime? _scanTime;
  bool _isLoading = false;
  final List<bool> _callingStates = [false, false, false];
  final List<bool> _calledContacts = [false, false, false];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPersonData();
  }

  void _loadPersonData() {
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (arguments != null) {
      setState(() {
        _personData = arguments['personData'] as Map<String, dynamic>?;
        _scanTime = arguments['scanTime'] as DateTime?;
      });
    }
  }

  Future<void> _makeCall(int contactIndex) async {
    if (_callingStates[contactIndex]) return;
    
    final contacts = _personData!['emergencyContacts'] as List<dynamic>;
    if (contactIndex >= contacts.length) return;
    
    final contact = contacts[contactIndex];

    setState(() {
      _callingStates[contactIndex] = true;
    });

    try {
      final success = await _callService.makeEmergencyCall(
        phoneNumber: contact['phoneNumber'] ?? '',
        personId: _personData!['personId'] ?? '',
        personName: _personData!['fullName'] ?? '',
        contactName: contact['name'] ?? '',
        relationship: contact['relationship'] ?? '',
        priority: contact['priority'] ?? (contactIndex + 1),
        location: 'Yaoundé, Cameroun', // TODO: Get real location
      );

      if (success) {
        setState(() {
          _calledContacts[contactIndex] = true;
        });
        
        _showSuccessSnackBar('Appel initié vers ${contact['name']}');
        
        // Log the successful call
        HapticFeedback.mediumImpact();
      } else {
        _showErrorSnackBar('Impossible d\'appeler ${contact['name']}');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _callingStates[contactIndex] = false;
        });
      }
    }
  }

  Future<void> _sendBatchSMS() async {
    final contacts = _personData!['emergencyContacts'] as List<dynamic>;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final message = '''
URGENCE MÉDICALE

${_personData!['fullName']} a été identifié(e) suite à un accident.

Date: ${DateFormat('dd/MM/yyyy HH:mm').format(_scanTime ?? DateTime.now())}

Veuillez rappeler ce numéro pour plus d'informations.
      ''';

      final results = await _callService.sendBatchEmergencySMS(
        contacts: contacts.map((c) => c as Map<String, dynamic>).toList(),
        personId: _personData!['personId'] ?? '',
        personName: _personData!['fullName'] ?? '',
        message: message,
        location: 'Yaoundé, Cameroun',
      );

      int successCount = results.values.where((v) => v).length;
      
      _showSuccessSnackBar('SMS envoyé à $successCount contact(s)');
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'envoi des SMS');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showMedicalInfo() {
    final medicalInfo = _personData!['medicalInfo'] as Map<String, dynamic>?;
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations médicales',
                style: AppTheme.headingStyle,
              ),
              const SizedBox(height: 20),
              if (_personData!['bloodType'] != null)
                _buildMedicalInfoRow(
                  'Groupe sanguin',
                  _personData!['bloodType'],
                  Icons.bloodtype,
                ),
              if (medicalInfo?['allergies'] != null)
                _buildMedicalInfoRow(
                  'Allergies',
                  medicalInfo!['allergies'],
                  Icons.warning_amber,
                ),
              if (medicalInfo?['conditions'] != null)
                _buildMedicalInfoRow(
                  'Conditions médicales',
                  medicalInfo!['conditions'],
                  Icons.medical_information,
                ),
              if (medicalInfo?['medications'] != null)
                _buildMedicalInfoRow(
                  'Médicaments',
                  medicalInfo!['medications'],
                  Icons.medication,
                ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Fermer',
                onPressed: () => Navigator.pop(context),
                type: ButtonType.outline,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMedicalInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.adminModuleColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.captionStyle,
                ),
                Text(
                  value,
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_personData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: AppTheme.adminModuleColor,
        ),
        body: const Center(
          child: Text('Aucune donnée de personne disponible'),
        ),
      );
    }

    final emergencyContacts = _personData!['emergencyContacts'] as List<dynamic>? ?? [];
    final identificationMethod = _personData!['identificationMethod'] ?? 'unknown';
    final personType = _personData!['type'] ?? 'unknown';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Personne identifiée'),
        backgroundColor: AppTheme.adminModuleColor,
        actions: [
          if (_personData!['medicalInfo'] != null)
            IconButton(
              icon: const Icon(Icons.medical_information),
              onPressed: _showMedicalInfo,
              tooltip: 'Informations médicales',
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Success banner
                  _buildSuccessBanner(),
                  const SizedBox(height: 24),
                  // Person info card
                  _buildPersonInfoCard(personType, identificationMethod),
                  const SizedBox(height: 24),
                  // Emergency contacts section
                  if (emergencyContacts.isNotEmpty)
                    _buildEmergencyContactsSection(emergencyContacts)
                  else
                    _buildNoContactsWarning(),
                  const SizedBox(height: 24),
                  // Additional info
                  _buildAdditionalInfo(),
                  const SizedBox(height: 24),
                  // Action buttons
                  _buildActionButtons(emergencyContacts),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_scanTime != null)
                    Text(
                      'Scanné à ${DateFormat('HH:mm').format(_scanTime!)}',
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

  Widget _buildPersonInfoCard(String personType, String identificationMethod) {
    final firstName = _personData!['firstName'] ?? '';
    final lastName = _personData!['lastName'] ?? '';
    final fullName = _personData!['fullName'] ?? '$firstName $lastName';
    
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
                  backgroundImage: _personData!['photoUrl'] != null
                      ? NetworkImage(_personData!['photoUrl'])
                      : null,
                  child: _personData!['photoUrl'] == null
                      ? Text(
                          '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: AppTheme.headingStyle,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: personType == 'app_user'
                              ? AppTheme.infoColor.withOpacity(0.1)
                              : AppTheme.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          personType == 'app_user'
                              ? 'Utilisateur de l\'app'
                              : 'Personne enregistrée',
                          style: TextStyle(
                            fontSize: 12,
                            color: personType == 'app_user'
                                ? AppTheme.infoColor
                                : AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (_personData!['phoneNumber'] != null)
              _buildInfoRow(
                Icons.phone,
                'Téléphone',
                _personData!['phoneNumber'],
              ),
            if (_personData!['email'] != null)
              _buildInfoRow(
                Icons.email,
                'Email',
                _personData!['email'],
              ),
            if (_personData!['bloodType'] != null)
              _buildInfoRow(
                Icons.bloodtype,
                'Groupe sanguin',
                _personData!['bloodType'],
              ),
            if (_personData!['address'] != null)
              _buildInfoRow(
                Icons.location_on,
                'Adresse',
                _personData!['address'],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactsSection(List<dynamic> contacts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Contacts d\'urgence',
              style: AppTheme.subheadingStyle,
            ),
            Text(
              '${contacts.length} contact(s)',
              style: AppTheme.captionStyle,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Appuyez sur un contact pour appeler',
          style: AppTheme.captionStyle,
        ),
        const SizedBox(height: 16),
        ...contacts.asMap().entries.map((entry) {
          final index = entry.key;
          final contact = entry.value;
          return _buildEmergencyContactCard(index, contact);
        }).toList(),
      ],
    );
  }

  Widget _buildEmergencyContactCard(int index, dynamic contact) {
    final isLoading = _callingStates[index];
    final wasCalled = _calledContacts[index];
    final priorityColors = [
      AppTheme.errorColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
    ];

    final color = index < priorityColors.length 
        ? priorityColors[index] 
        : AppTheme.infoColor;

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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: wasCalled
                      ? Icon(Icons.check, color: AppTheme.successColor)
                      : Text(
                          '${contact['priority'] ?? (index + 1)}',
                          style: TextStyle(
                            color: color,
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
                      contact['name'] ?? 'Contact ${index + 1}',
                      style: AppTheme.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          contact['relationship'] ?? 'Relation non spécifiée',
                          style: AppTheme.captionStyle,
                        ),
                        if (wasCalled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Appelé',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.successColor,
                              ),
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildNoContactsWarning() {
    return Card(
      color: AppTheme.warningColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber,
              size: 48,
              color: AppTheme.warningColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun contact d\'urgence',
              style: AppTheme.subheadingStyle.copyWith(
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Cette personne n\'a pas de contacts d\'urgence enregistrés',
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Card(
      color: AppTheme.infoColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
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
            if (_scanTime != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: AppTheme.infoColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heure d\'identification',
                          style: AppTheme.bodyStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy à HH:mm').format(_scanTime!),
                          style: AppTheme.captionStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(List<dynamic> emergencyContacts) {
    return Column(
      children: [
        if (emergencyContacts.isNotEmpty) ...[
          CustomButton(
            text: 'Envoyer SMS à tous',
            onPressed: _isLoading ? null : _sendBatchSMS,
            type: ButtonType.outline,
            icon: Icons.sms,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 12),
        ],
        CustomButton(
          text: 'Ajouter des notes',
          onPressed: () {
            // TODO: Implémenter l'ajout de notes
            _showNotesDialog();
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: AppTheme.captionStyle,
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog() {
    final notesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter des notes'),
          content: TextField(
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Entrez vos notes ici...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Save notes to Firebase
                Navigator.pop(context);
                _showSuccessSnackBar('Notes ajoutées avec succès');
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}
