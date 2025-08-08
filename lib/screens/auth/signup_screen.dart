import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  String _selectedRole = AppConstants.clientRole; // Default role

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptTerms) {
      _showErrorSnackBar('Veuillez accepter les conditions d\'utilisation');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );
      
      if (userCredential != null && mounted) {
        _showSuccessSnackBar('Compte créé avec succès! Veuillez vous connecter.');
        // Navigate to login page after successful signup
        Navigator.pushReplacementNamed(
          context,
          AppConstants.loginRoute,
        );
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_add,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Titre
              Text(
                'Créer un compte',
                style: AppTheme.headingStyle,
              ),
              const SizedBox(height: 8),
              Text(
                'Inscrivez-vous pour commencer',
                style: AppTheme.captionStyle,
              ),
              const SizedBox(height: 32),
              // Formulaire
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nom complet
                    CustomTextField(
                      label: 'Nom complet',
                      hint: 'Jean Dupont',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le nom est requis';
                        }
                        if (value.length < 3) {
                          return 'Le nom doit contenir au moins 3 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Email
                    CustomTextField(
                      label: 'Email',
                      hint: 'exemple@email.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
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
                    // Téléphone (optionnel)
                    CustomTextField(
                      label: 'Téléphone (optionnel)',
                      hint: '+226 00 00 00 00',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s]')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Mot de passe
                    CustomTextField(
                      label: 'Mot de passe',
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le mot de passe est requis';
                        }
                        if (value.length < 6) {
                          return 'Le mot de passe doit contenir au moins 6 caractères';
                        }
                        if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*[0-9])').hasMatch(value)) {
                          return 'Le mot de passe doit contenir des lettres et des chiffres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Confirmer le mot de passe
                    CustomTextField(
                      label: 'Confirmer le mot de passe',
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez confirmer le mot de passe';
                        }
                        if (value != _passwordController.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Conditions d'utilisation
              Row(
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptTerms = !_acceptTerms;
                        });
                      },
                      child: RichText(
                        text: TextSpan(
                          text: 'J\'accepte les ',
                          style: TextStyle(
                            color: AppTheme.textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: 'conditions d\'utilisation',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Bouton d'inscription
              CustomButton(
                text: 'S\'inscrire',
                onPressed: _handleSignup,
                isLoading: _isLoading,
                icon: Icons.person_add,
              ),
              const SizedBox(height: 24),
              // Lien vers la connexion
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Vous avez déjà un compte? ',
                    style: TextStyle(
                      color: AppTheme.textColor.withOpacity(0.7),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: Text(
                      'Se connecter',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
