import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// WORKAROUND SCREEN - For iOS Firebase Auth Bug
/// This creates users directly in Firestore without Firebase Auth
/// FOR DEVELOPMENT/TESTING ONLY!
class WorkaroundSignupScreen extends StatefulWidget {
  const WorkaroundSignupScreen({Key? key}) : super(key: key);

  @override
  State<WorkaroundSignupScreen> createState() => _WorkaroundSignupScreenState();
}

class _WorkaroundSignupScreenState extends State<WorkaroundSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  String _userType = 'user';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _createWorkaroundUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Generate a unique ID
      final String userId = 'workaround_${DateTime.now().millisecondsSinceEpoch}';
      
      // Check if email already exists
      final existingUsers = await FirebaseFirestore.instance
          .collection('workaround_users')
          .where('email', isEqualTo: _emailController.text.trim())
          .get();
      
      if (existingUsers.docs.isNotEmpty) {
        throw 'Cet email est déjà utilisé';
      }
      
      // Create user document in Firestore (not Firebase Auth)
      await FirebaseFirestore.instance
          .collection('workaround_users')
          .doc(userId)
          .set({
        'uid': userId,
        'email': _emailController.text.trim(),
        'passwordHash': _hashPassword(_passwordController.text),
        'displayName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'role': _userType,
        'userType': _userType,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
        'profileCompleted': false,
        'isWorkaroundUser': true, // Flag to identify workaround users
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilisateur créé avec succès! (Mode Workaround)'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show the credentials
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Compte créé'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${_emailController.text}'),
                Text('User ID: $userId'),
                SizedBox(height: 16),
                Text(
                  'Note: Ceci est un compte de contournement. '
                  'Firebase Auth est contourné à cause du bug iOS.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workaround Signup'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: Colors.orange.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 48),
                          SizedBox(height: 8),
                          Text(
                            'Mode Contournement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Crée des utilisateurs directement dans Firestore\n'
                            'sans passer par Firebase Auth (bug iOS)',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  CustomTextField(
                    label: 'Nom complet',
                    hint: 'John Doe',
                    controller: _nameController,
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
                    hint: 'test@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'L\'email est requis';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    label: 'Mot de passe',
                    hint: 'Au moins 6 caractères',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le mot de passe est requis';
                      }
                      if (value.length < 6) {
                        return 'Au moins 6 caractères';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  CustomTextField(
                    label: 'Téléphone (optionnel)',
                    hint: '+226 00 00 00 00',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // User type selection
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type d\'utilisateur:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        RadioListTile<String>(
                          title: const Text('Utilisateur'),
                          value: 'user',
                          groupValue: _userType,
                          onChanged: (value) {
                            setState(() {
                              _userType = value!;
                            });
                          },
                        ),
                        RadioListTile<String>(
                          title: const Text('Admin'),
                          value: 'admin',
                          groupValue: _userType,
                          onChanged: (value) {
                            setState(() {
                              _userType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  CustomButton(
                    text: 'Créer Compte (Workaround)',
                    onPressed: _createWorkaroundUser,
                    isLoading: _isLoading,
                    icon: Icons.person_add,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    '⚠️ Ce mode crée des comptes sans authentification Firebase.\n'
                    'Utilisé uniquement pour contourner le bug iOS temporairement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
