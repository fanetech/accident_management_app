import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/models/client_profile_model.dart';
import 'package:accident_management4/services/client_profile_service.dart';
import 'package:accident_management4/services/auth_service.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({Key? key}) : super(key: key);

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final ClientProfileService _profileService = ClientProfileService();
  final AuthService _authService = AuthService();
  
  ClientProfile? _profile;
  bool _isLoading = true;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _profileService.getCurrentUserProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du profil: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Prendre une photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 512,
                  maxHeight: 512,
                );
                if (photo != null) {
                  setState(() {
                    _imageFile = File(photo.path);
                  });
                  // TODO: Upload to Firebase Storage
                  _showPhotoUploadSuccess();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choisir de la galerie'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 512,
                  maxHeight: 512,
                );
                if (photo != null) {
                  setState(() {
                    _imageFile = File(photo.path);
                  });
                  // TODO: Upload to Firebase Storage
                  _showPhotoUploadSuccess();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoUploadSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo mise à jour avec succès'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mon Profil'),
          backgroundColor: AppTheme.primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Profil non trouvé'),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Créer mon profil',
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context,
                    '/client/profile-completion',
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Profile Photo
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Profile Photo
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white,
                            child: _imageFile != null
                                ? ClipOval(
                                    child: Image.file(
                                      _imageFile!,
                                      width: 116,
                                      height: 116,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _profile!.photoUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          _profile!.photoUrl!,
                                          width: 116,
                                          height: 116,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppTheme.primaryColor,
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 20),
                                color: Colors.white,
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name and Email
                      Text(
                        _profile!.displayName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile!.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Profile Completion Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _profile!.isProfileComplete
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _profile!.isProfileComplete
                              ? '✓ Profil Complet'
                              : '⚠ Profil Incomplet',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final result = await Navigator.pushNamed(
                    context,
                    '/client/profile-completion',
                  );
                  if (result == true) {
                    _loadProfile();
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.qr_code),
                onPressed: _showQRCode,
              ),
            ],
          ),
          
          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  Row(
                    children: [
                      _buildStatCard(
                        'Contacts',
                        '${_profile!.emergencyContacts.length}',
                        Icons.contact_phone,
                        AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Empreinte',
                        _profile!.hasFingerprint ? 'OUI' : 'NON',
                        Icons.fingerprint,
                        _profile!.hasFingerprint
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Personal Information Section
                  _buildSectionHeader(
                    'Informations Personnelles',
                    Icons.person,
                    onEdit: () => _editSection('personal'),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _InfoItem('Téléphone', _profile!.phoneNumber ?? 'Non défini'),
                    _InfoItem('Adresse', _profile!.address ?? 'Non définie'),
                    _InfoItem(
                      'Date de naissance',
                      _profile!.dateOfBirth != null
                          ? DateFormat('dd MMMM yyyy').format(_profile!.dateOfBirth!)
                          : 'Non définie',
                    ),
                    _InfoItem('Groupe sanguin', _profile!.bloodType ?? 'Non défini'),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Emergency Contacts Section
                  _buildSectionHeader(
                    'Contacts d\'Urgence',
                    Icons.contact_phone,
                    onEdit: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/client/emergency-contacts',
                      );
                      if (result == true) {
                        _loadProfile();
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_profile!.emergencyContacts.isEmpty)
                    _buildEmptyCard('Aucun contact d\'urgence défini')
                  else
                    ..._profile!.emergencyContacts.map((contact) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildContactCard(contact),
                    )),
                  
                  const SizedBox(height: 24),
                  
                  // Medical Information Section
                  _buildSectionHeader(
                    'Informations Médicales',
                    Icons.medical_services,
                    onEdit: () => _editSection('medical'),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _InfoItem(
                      'Allergies',
                      _profile!.medicalInfo?['allergies']?.toString().isNotEmpty == true
                          ? _profile!.medicalInfo!['allergies']
                          : 'Aucune',
                    ),
                    _InfoItem(
                      'Médicaments',
                      _profile!.medicalInfo?['medications']?.toString().isNotEmpty == true
                          ? _profile!.medicalInfo!['medications']
                          : 'Aucun',
                    ),
                    _InfoItem(
                      'Conditions médicales',
                      _profile!.medicalInfo?['conditions']?.toString().isNotEmpty == true
                          ? _profile!.medicalInfo!['conditions']
                          : 'Aucune',
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // Biometric Section
                  _buildSectionHeader(
                    'Données Biométriques',
                    Icons.fingerprint,
                    onEdit: () => _editSection('biometric'),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.fingerprint,
                        color: _profile!.hasFingerprint
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                      title: Text(
                        _profile!.hasFingerprint
                            ? 'Empreinte enregistrée'
                            : 'Empreinte non enregistrée',
                      ),
                      subtitle: _profile!.hasFingerprint
                          ? Text(
                              'Dernière mise à jour: ${_profile!.lastUpdated != null ? DateFormat('dd/MM/yyyy').format(_profile!.lastUpdated!) : "N/A"}',
                            )
                          : null,
                      trailing: _profile!.hasFingerprint
                          ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                          : TextButton(
                              onPressed: () => _editSection('biometric'),
                              child: const Text('Configurer'),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Account Information
                  _buildSectionHeader(
                    'Informations du Compte',
                    Icons.info_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _InfoItem('ID Utilisateur', _profile!.uid.substring(0, 8) + '...'),
                    _InfoItem(
                      'Compte créé',
                      DateFormat('dd MMMM yyyy').format(_profile!.createdAt),
                    ),
                    _InfoItem(
                      'Dernière mise à jour',
                      _profile!.lastUpdated != null
                          ? DateFormat('dd MMMM yyyy').format(_profile!.lastUpdated!)
                          : 'Jamais',
                    ),
                  ]),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  CustomButton(
                    text: 'Exporter mes données',
                    onPressed: _exportData,
                    type: ButtonType.outline,
                    icon: Icons.download,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Supprimer mon compte',
                    onPressed: _confirmDeleteAccount,
                    type: ButtonType.outline,
                    icon: Icons.delete_forever,
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: AppTheme.captionStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {VoidCallback? onEdit}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.subheadingStyle,
            ),
          ],
        ),
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Modifier'),
          ),
      ],
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildContactCard(ClientEmergencyContact contact) {
    final priorityColors = {
      1: AppTheme.primaryColor,
      2: AppTheme.clientModuleColor,
      3: AppTheme.textSecondaryColor,
    };
    
    final priorityLabels = {
      1: 'Principal',
      2: 'Secondaire',
      3: 'Tertiaire',
    };
    
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: priorityColors[contact.priority]?.withOpacity(0.1),
          child: Icon(
            Icons.person,
            color: priorityColors[contact.priority],
          ),
        ),
        title: Text(contact.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phoneNumber),
            Text(
              '${contact.relationship} • ${priorityLabels[contact.priority]}',
              style: TextStyle(
                fontSize: 12,
                color: priorityColors[contact.priority],
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () {
            // TODO: Implement call functionality
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Appel vers ${contact.name}...'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editSection(String section) async {
    switch (section) {
      case 'personal':
      case 'medical':
      case 'biometric':
        final result = await Navigator.pushNamed(
          context,
          '/client/profile-completion',
        );
        if (result == true) {
          _loadProfile();
        }
        break;
    }
  }

  void _showQRCode() {
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
                // TODO: Generate actual QR code
                child: Icon(
                  Icons.qr_code_2,
                  size: 150,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ID: ${_profile!.uid.substring(0, 8)}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Présentez ce code aux services d\'urgence',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Implement share functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonction de partage à venir'),
                ),
              );
            },
            child: const Text('Partager'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // TODO: Implement data export
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter mes données'),
        content: const Text(
          'Vos données seront exportées au format PDF et envoyées à votre adresse email.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export en cours... Vous recevrez un email bientôt.'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Exporter'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Supprimer le compte'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir supprimer votre compte?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Cette action est irréversible et entraînera:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text('• La suppression de toutes vos données'),
            Text('• La perte de vos contacts d\'urgence'),
            Text('• L\'impossibilité d\'être identifié en cas d\'urgence'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement account deletion
              await _authService.deleteUserAccount();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  _InfoItem(this.label, this.value);
}
