import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';

class AdminScannerScreen extends StatefulWidget {
  const AdminScannerScreen({Key? key}) : super(key: key);

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  
  bool _isScanning = false;
  bool _scanComplete = false;
  String _scanStatus = 'ready';
  double _scanProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _animationController.addListener(() {
      if (_isScanning) {
        setState(() {
          _scanProgress = _scanAnimation.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _scanComplete = false;
      _scanStatus = 'scanning';
      _scanProgress = 0.0;
    });

    _animationController.forward();

    // Simulation du scan
    await Future.delayed(const Duration(seconds: 2));

    // Simulation du résultat (succès ou échec)
    final success = DateTime.now().second % 3 != 0; // 66% de succès

    HapticFeedback.mediumImpact();

    if (success) {
      setState(() {
        _scanStatus = 'success';
        _scanComplete = true;
      });

      // Naviguer vers l'écran de personne identifiée
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushNamed(
          context,
          AppConstants.adminIdentifiedRoute,
          arguments: {
            'personId': 'test-person-id',
            'scanTime': DateTime.now(),
          },
        );
      }
    } else {
      setState(() {
        _scanStatus = 'failed';
        _scanComplete = true;
      });
    }

    setState(() {
      _isScanning = false;
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Scanner d\'empreinte'),
        backgroundColor: AppTheme.adminModuleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.adminHistoryRoute);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
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
              const SizedBox(height: 24),
              // Emergency info
              _buildEmergencyInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    String instructionText;
    IconData instructionIcon;
    Color instructionColor;

    switch (_scanStatus) {
      case 'scanning':
        instructionText = 'Scan en cours...';
        instructionIcon = Icons.fingerprint;
        instructionColor = AppTheme.adminModuleColor;
        break;
      case 'success':
        instructionText = 'Personne identifiée !';
        instructionIcon = Icons.check_circle;
        instructionColor = AppTheme.successColor;
        break;
      case 'failed':
        instructionText = 'Aucune correspondance trouvée';
        instructionIcon = Icons.error;
        instructionColor = AppTheme.errorColor;
        break;
      default:
        instructionText = 'Placez le doigt sur le capteur';
        instructionIcon = Icons.touch_app;
        instructionColor = AppTheme.adminModuleColor;
    }

    return Card(
      color: instructionColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              instructionIcon,
              color: instructionColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instructionText,
                    style: AppTheme.subheadingStyle,
                  ),
                  if (_scanStatus == 'ready')
                    Text(
                      'Le scan prend environ 2 secondes',
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

  Widget _buildScannerArea() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Scanner frame
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getScannerBorderColor(),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: _getScannerBorderColor().withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Fingerprint icon
        Icon(
          Icons.fingerprint,
          size: 150,
          color: _getScannerIconColor(),
        ),
        // Scan line animation
        if (_isScanning)
          Positioned(
            top: 40,
            child: Container(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _scanAnimation,
                builder: (context, child) {
                  return Container(
                    margin: EdgeInsets.only(top: _scanProgress * 160),
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.adminModuleColor,
                          AppTheme.adminModuleColor,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.2, 0.8, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.adminModuleColor.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        // Status indicator
        if (_scanComplete)
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _scanStatus == 'success'
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _scanStatus == 'success' ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _scanStatus == 'success' ? 'Succès' : 'Échec',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getScannerBorderColor() {
    switch (_scanStatus) {
      case 'scanning':
        return AppTheme.adminModuleColor;
      case 'success':
        return AppTheme.successColor;
      case 'failed':
        return AppTheme.errorColor;
      default:
        return Colors.grey[300]!;
    }
  }

  Color _getScannerIconColor() {
    switch (_scanStatus) {
      case 'scanning':
        return AppTheme.adminModuleColor.withOpacity(0.3);
      case 'success':
        return AppTheme.successColor.withOpacity(0.3);
      case 'failed':
        return AppTheme.errorColor.withOpacity(0.3);
      default:
        return Colors.grey[300]!;
    }
  }

  Widget _buildActionButton() {
    if (_isScanning) {
      return CustomButton(
        text: 'Scan en cours...',
        onPressed: null,
        isLoading: true,
      );
    }

    if (_scanStatus == 'failed') {
      return Column(
        children: [
          CustomButton(
            text: 'Réessayer',
            onPressed: _startScan,
            icon: Icons.refresh,
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Aide d\'urgence',
            onPressed: () {
              // TODO: Implémenter l'aide d'urgence
            },
            type: ButtonType.danger,
            icon: Icons.emergency,
          ),
        ],
      );
    }

    return CustomButton(
      text: 'Démarrer le scan',
      onPressed: _startScan,
      icon: Icons.fingerprint,
    );
  }

  Widget _buildEmergencyInfo() {
    return Card(
      color: AppTheme.warningColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: AppTheme.warningColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'En cas d\'urgence sans identification, utilisez le bouton d\'aide',
                style: AppTheme.captionStyle.copyWith(
                  color: AppTheme.warningColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
