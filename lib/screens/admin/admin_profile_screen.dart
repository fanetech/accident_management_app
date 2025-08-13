import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/services/auth_service.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Ajout de cet import
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _departmentController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _emergencyContactPhoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditing = false;
  File? _imageFile;
  String? _photoUrl;
  Map<String, dynamic>? _adminData;
  DateTime? _joinedDate;
  int? _sessionRemainingHours;
  
  @override
  void initState() {
    super.initState();
    _initializeLocale(); // Initialisation de la locale
    _loadAdminProfile();
    _checkSessionTime();
  }

  // Nouvelle méthode pour initialiser la locale française
  Future<void> _initializeLocale() async {
    try {
      await initializeDateFormatting('fr_FR', null);
    } catch (e) {
      print('Erreur lors de l\'initialisation de la locale: $e');
      // Fallback: utiliser la locale par défaut si l'initialisation échoue
    }
  }

  Future<void> _checkSessionTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLoginTime = prefs.getInt('last_login_time');
      
      if (lastLoginTime != null) {
        final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
        final now = DateTime.now();
        final difference = now.difference(lastLogin);
        final remainingHours = 24 - difference.inHours;
        
        setState(() {
          _sessionRemainingHours = remainingHours > 0 ? remainingHours : 0;
        });
      }
    } catch (e) {
      print('Error checking session: $e');
    }
  }

  Future<void> _loadAdminProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Load user data from Firestore
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final data = userDoc.data()!;
          setState(() {
            _adminData = data;
            _displayNameController.text = data['displayName'] ?? '';
            _emailController.text = data['email'] ?? user.email ?? '';
            _phoneController.text = data['phoneNumber'] ?? '';
            _addressController.text = data['address'] ?? '';
            _departmentController.text = data['department'] ?? 'Services d\'urgence';
            _employeeIdController.text = data['employeeId'] ?? '';
            _emergencyContactNameController.text = data['emergencyContactName'] ?? '';
            _emergencyContactPhoneController.text = data['emergencyContactPhone'] ?? '';
            _photoUrl = data['photoUrl'];
            
            if (data['createdAt'] != null) {
              _joinedDate = (data['createdAt'] as Timestamp).toDate();
            }
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement du profil: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Méthode pour formater la date de manière sécurisée
  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      // Fallback vers le format par défaut si la locale française n'est pas disponible
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Prepare update data
        final updateData = {
          'displayName': _displayNameController.text,
          'phoneNumber': _phoneController.text,
          'address': _addressController.text,
          'department': _departmentController.text,
          'employeeId': _employeeIdController.text,
          'emergencyContactName': _emergencyContactNameController.text,
          'emergencyContactPhone': _emergencyContactPhoneController.text,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        // Update Firestore
        await _firestore.collection('users').doc(user.uid).update(updateData);
        
        // Update Firebase Auth display name if changed
        if (user.displayName != _displayNameController.text) {
          await user.updateDisplayName(_displayNameController.text);
        }
        
        _showSuccessSnackBar('Profil mis à jour avec succès');
        setState(() => _isEditing = false);
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la mise à jour: $e');
    } finally {
      setState(() => _isLoading = false);
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

  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                _showErrorSnackBar('Les mots de passe ne correspondent pas');
                return;
              }
              
              try {
                final user = _auth.currentUser;
                if (user != null && user.email != null) {
                  // Re-authenticate user
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: currentPasswordController.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  
                  // Update password
                  await user.updatePassword(newPasswordController.text);
                  
                  Navigator.pop(context);
                  _showSuccessSnackBar('Mot de passe modifié avec succès');
                }
              } catch (e) {
                _showErrorSnackBar('Erreur: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.adminModuleColor,
            ),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _departmentController.dispose();
    _employeeIdController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: AppTheme.adminModuleColor,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditing = true);
              },
            )
          else
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _isEditing = false);
                    _loadAdminProfile(); // Reload original data
                  },
                  child: const Text(
                    'Annuler',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                TextButton(
                  onPressed: _saveProfile,
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: AppTheme.adminModuleColor,
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : _photoUrl != null
                                        ? NetworkImage(_photoUrl!) as ImageProvider
                                        : null,
                                child: _imageFile == null && _photoUrl == null
                                    ? Text(
                                        _displayNameController.text.isNotEmpty
                                            ? _displayNameController.text[0].toUpperCase()
                                            : 'A',
                                        style: const TextStyle(
                                          fontSize: 40,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: CircleAvatar(
                                    backgroundColor: AppTheme.adminModuleColor,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _displayNameController.text,
                            style: AppTheme.headingStyle,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.adminModuleColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Administrateur',
                              style: TextStyle(
                                color: AppTheme.adminModuleColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Session Info Card
                    if (_sessionRemainingHours != null)
                      Card(
                        color: _sessionRemainingHours! < 2
                            ? AppTheme.warningColor.withOpacity(0.1)
                            : AppTheme.successColor.withOpacity(0.1),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer,
                                color: _sessionRemainingHours! < 2
                                    ? AppTheme.warningColor
                                    : AppTheme.successColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Session active',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Expire dans $_sessionRemainingHours heures',
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
                    
                    // Personal Information Section
                    Text(
                      'Informations Personnelles',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Nom complet',
                      controller: _displayNameController,
                      enabled: _isEditing,
                      prefixIcon: const Icon(Icons.person),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: false, // Email cannot be changed
                      prefixIcon: const Icon(Icons.email),
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Téléphone',
                      controller: _phoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Adresse',
                      controller: _addressController,
                      enabled: _isEditing,
                      prefixIcon: const Icon(Icons.location_on),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                    
                    // Professional Information Section
                    Text(
                      'Informations Professionnelles',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Département',
                      controller: _departmentController,
                      enabled: _isEditing,
                      prefixIcon: const Icon(Icons.business),
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Numéro d\'employé',
                      controller: _employeeIdController,
                      enabled: _isEditing,
                      prefixIcon: const Icon(Icons.badge),
                    ),
                    const SizedBox(height: 16),
                    
                    if (_joinedDate != null)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Date d\'inscription'),
                          subtitle: Text(_formatDate(_joinedDate!)), // Utilisation de la méthode sécurisée
                        ),
                      ),
                    const SizedBox(height: 32),
                    
                    // Emergency Contact Section
                    Text(
                      'Contact d\'Urgence',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Nom du contact',
                      controller: _emergencyContactNameController,
                      enabled: _isEditing,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                    
                    CustomTextField(
                      label: 'Téléphone du contact',
                      controller: _emergencyContactPhoneController,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_in_talk),
                    ),
                    const SizedBox(height: 32),
                    
                    // Security Section
                    Text(
                      'Sécurité',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Mot de passe'),
                        subtitle: const Text('••••••••'),
                        trailing: TextButton(
                          onPressed: _changePassword,
                          child: const Text('Changer'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Action Buttons
                    if (!_isEditing) ...[
                      CustomButton(
                        text: 'Modifier le profil',
                        onPressed: () {
                          setState(() => _isEditing = true);
                        },
                        icon: Icons.edit,
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Se déconnecter',
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Déconnexion'),
                              content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await _authService.signOut();
                                    if (mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        AppConstants.loginRoute,
                                        (route) => false,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                  child: const Text('Déconnexion'),
                                ),
                              ],
                            ),
                          );
                        },
                        type: ButtonType.danger,
                        icon: Icons.logout,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}