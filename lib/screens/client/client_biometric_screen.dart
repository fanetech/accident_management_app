import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';

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

    if (_captureQuality >= AppConstants.biometricQualityThreshold) {
      HapticFeedback.mediumImpact();
      _onCaptureSuccess();
    } else {
      _onCaptureFailed();
    }
  }

  void _onCaptureSuccess() {
    if (_currentFinger == 'left_thumb') {
      setState(() {
        _leftThumbCaptured = true;
        _isCapturing = false;
        _currentFinger = 'right_pinky';
      });
      
      _showSuccessSnackBar('Pouce gauche capturé avec succès !');
    } else {
      setState(() {
        _rightPinkyCaptured = true;
        _isCapturing = false;
      });
      
      _showSuccessSnackBar('Auriculaire droit capturé avec succès !');
      
      // Si les deux empreintes sont capturées, naviguer vers la confirmation
      if (_leftThumbCaptured && _rightPinkyCaptured) {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacementNamed(
            context,
            AppConstants.clientConfirmationRoute,
            arguments: _personData,
          );
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
      ),
    );
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
        title: const Text('Capture des empreintes'),
        backgroundColor: AppTheme.clientModuleColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
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
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: Column(
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
                ),
              ),
              if (_leftThumbCaptured)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 20,
                ),
            ],
          ),
        ),
        Container(
          width: 40,
          height: 2,
          color: _leftThumbCaptured ? AppTheme.successColor : Colors.grey[300],
        ),
        Expanded(
          child: Column(
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
                ),
              ),
              if (_rightPinkyCaptured)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 20,
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
      color: AppTheme.clientModuleColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.clientModuleColor,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              'Placez $fingerText sur le capteur',
              style: AppTheme.subheadingStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
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
        text: 'Terminer',
        onPressed: () {
          Navigator.pushReplacementNamed(
            context,
            AppConstants.clientConfirmationRoute,
            arguments: _personData,
          );
        },
        type: ButtonType.success,
        icon: Icons.check,
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
