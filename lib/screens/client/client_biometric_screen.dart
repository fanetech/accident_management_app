import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/services/person_service.dart';
import 'package:accident_management4/models/person_model.dart';
import 'dart:convert';
import 'dart:math';

class ClientBiometricScreen extends StatefulWidget {
  const ClientBiometricScreen({Key? key}) : super(key: key);

  @override
  State<ClientBiometricScreen> createState() => _ClientBiometricScreenState();
}

class _ClientBiometricScreenState extends State<ClientBiometricScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  bool _isCapturing = false;
  bool _leftThumbCaptured = false;
  bool _rightPinkyCaptured = false;
  int _captureQuality = 0;
  String _currentFinger = 'left_thumb';
  Map<String, dynamic>? _personData;
  
  // Store biometric templates
  Map<String, dynamic> _leftThumbData = {};
  Map<String, dynamic> _rightPinkyData = {};
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer les données de la personne passées en argument
    _personData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Generate a mock biometric template (in real app, this would come from the sensor)
  String _generateBiometricTemplate() {
    final random = Random();
    final bytes = List<int>.generate(512, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  Future<void> _startCapture() async {
    setState(() {
      _isCapturing = true;
      _captureQuality = 0;
    });

    // Simulation de la capture biométrique
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() {
          _captureQuality = i;
        });
      }
    }

    // Check quality threshold
    if (_captureQuality >= AppConstants.biometricQualityThreshold) {
      HapticFeedback.mediumImpact();
      _onCaptureSuccess();
    } else {
      _onCaptureFailed();
    }
  }

  void _onCaptureSuccess() {
    final template = _generateBiometricTemplate();
    
    if (_currentFinger == 'left_thumb') {
      setState(() {
        _leftThumbCaptured = true;
        _isCapturing = false;
        _leftThumbData = {
          'template': template,
          'quality': _captureQuality,
        };
        _currentFinger = 'right_pinky';
      });
      
      _showSuccessSnackBar('Pouce gauche capturé avec succès !');
    } else {
      setState(() {
        _rightPinkyCaptured = true;
        _isCapturing = false;
        _rightPinkyData = {
          'template': template,
          'quality': _captureQuality,
        };
      });
      
      _showSuccessSnackBar('Auriculaire droit capturé avec succès !');
      
      // Si les deux empreintes sont capturées, sauvegarder automatiquement
      if (_leftThumbCaptured && _rightPinkyCaptured) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _saveToFirebase();
        });
      }
    }
  }

  void _onCaptureFailed() {
    setState(() {
      _isCapturing = false;
    });
    
    _showErrorSnackBar('Échec de la capture. Veuillez réessayer.');
  }

  Future<void> _saveToFirebase() async {
    if (_personData == null) {
      _showErrorSnackBar('Données de la personne manquantes');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final PersonService personService = _personData!['service'] ?? PersonService();
      final emergencyContacts = _personData!['emergencyContacts'] as List<EmergencyContact>;
      
      // Save person with biometrics to Firebase
      final personId = await personService.createPersonWithBiometrics(
        firstName: _personData!['firstName'],
        lastName: _personData!['lastName'],
        emergencyContacts: emergencyContacts,
        leftThumbData: _leftThumbData,
        rightPinkyData: _rightPinkyData,
      );

      if (mounted) {
        _showSuccessSnackBar('Enregistrement réussi !');
        
        // Navigate to confirmation screen
        Navigator.pushReplacementNamed(
          context,
          AppConstants.clientConfirmationRoute,
          arguments: {
            'personId': personId,
            'firstName': _personData!['firstName'],
            'lastName': _personData!['lastName'],
            'emergencyContacts': emergencyContacts,
          },
        );
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de l\'enregistrement: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    final personName = _personData != null 
        ? '${_personData!['firstName']} ${_personData!['lastName']}'
        : 'Personne';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Capture des empreintes'),
        backgroundColor: AppTheme.clientModuleColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Person info card
                  Card(
                    color: AppTheme.clientModuleColor.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: AppTheme.clientModuleColor.withOpacity(0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: AppTheme.clientModuleColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enregistrement pour:',
                                  style: AppTheme.captionStyle,
                                ),
                                Text(
                                  personName,
                                  style: AppTheme.subheadingStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Progress indicator
                  _buildProgressIndicator(),
                  const SizedBox(height: 32),
                  // Instructions
                  _buildInstructions(),
                  const SizedBox(height: 40),
                  // Scanner area
                  Expanded(
                    child: Center(
                      child: _buildScannerArea(),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Action button
                  _buildActionButton(),
                ],
              ),
            ),
            // Loading overlay
            if (_isSaving)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Enregistrement en cours...',
                            style: AppTheme.subheadingStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: _leftThumbCaptured
                        ? AppTheme.successColor
                        : (_currentFinger == 'left_thumb' && _isCapturing)
                            ? AppTheme.clientModuleColor
                            : Colors.grey,
                    size: 40,
                  ),
                  if (_leftThumbCaptured)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Pouce gauche',
                style: TextStyle(
                  color: _leftThumbCaptured
                      ? AppTheme.successColor
                      : AppTheme.textPrimaryColor,
                  fontWeight: _currentFinger == 'left_thumb'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 20),
            color: _leftThumbCaptured ? AppTheme.successColor : Colors.grey[300],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: _rightPinkyCaptured
                        ? AppTheme.successColor
                        : (_currentFinger == 'right_pinky' && _isCapturing)
                            ? AppTheme.clientModuleColor
                            : Colors.grey,
                    size: 40,
                  ),
                  if (_rightPinkyCaptured)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Auriculaire droit',
                style: TextStyle(
                  color: _rightPinkyCaptured
                      ? AppTheme.successColor
                      : AppTheme.textPrimaryColor,
                  fontWeight: _currentFinger == 'right_pinky'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
    final fingerText = _currentFinger == 'left_thumb'
        ? 'votre pouce gauche'
        : 'votre auriculaire droit';

    return Card(
      color: AppTheme.infoColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.infoColor,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              'Placez $fingerText sur le capteur',
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Maintenez votre doigt immobile pendant la capture',
              style: AppTheme.captionStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerArea() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Scanner background
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.clientModuleColor.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: _isCapturing 
                  ? AppTheme.clientModuleColor 
                  : Colors.grey[300]!,
              width: 2,
            ),
          ),
        ),
        // Animated fingerprint
        if (_isCapturing)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Icon(
                  Icons.fingerprint,
                  size: 120,
                  color: AppTheme.clientModuleColor.withOpacity(0.3),
                ),
              );
            },
          )
        else
          Icon(
            Icons.fingerprint,
            size: 120,
            color: Colors.grey[300],
          ),
        // Quality indicator
        if (_isCapturing)
          Positioned(
            bottom: 20,
            child: Column(
              children: [
                Text(
                  'Qualité: $_captureQuality%',
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _captureQuality >= AppConstants.biometricQualityThreshold
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: _captureQuality / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _captureQuality >= AppConstants.biometricQualityThreshold
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_leftThumbCaptured && _rightPinkyCaptured) {
      return CustomButton(
        text: 'Enregistrer',
        onPressed: _isSaving ? null : _saveToFirebase,
        type: ButtonType.success,
        icon: Icons.save,
        isLoading: _isSaving,
      );
    }

    return CustomButton(
      text: _isCapturing ? 'Capture en cours...' : 'Capturer',
      onPressed: _isCapturing ? null : _startCapture,
      isLoading: _isCapturing,
      icon: Icons.fingerprint,
    );
  }
}
