import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/services/biometric_scan_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminScannerScreen extends StatefulWidget {
  const AdminScannerScreen({Key? key}) : super(key: key);

  @override
  State<AdminScannerScreen> createState() => _AdminScannerScreenState();
}

class _AdminScannerScreenState extends State<AdminScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  
  final BiometricScanService _biometricService = BiometricScanService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isScanning = false;
  bool _scanComplete = false;
  String _scanStatus = 'ready';
  double _scanProgress = 0.0;
  Map<String, dynamic>? _identifiedPerson;

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
      _identifiedPerson = null;
    });

    _animationController.forward();

    // Simulation du scan (durée de 2 secondes)
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Generate mock fingerprint template for testing
      // In production, this would come from the actual fingerprint sensor
      final mockTemplate = _biometricService.generateMockFingerprintTemplate();
      
      // Get current user info for logging
      final currentUser = _auth.currentUser;
      final scannedBy = currentUser?.uid;
      
      // Try to identify the person
      final result = await _biometricService.identifyPersonByFingerprint(
        scannedTemplate: mockTemplate,
        scannerLocation: 'Mobile Device',
        scannedBy: scannedBy,
      );

      HapticFeedback.mediumImpact();

      if (result != null) {
        setState(() {
          _scanStatus = 'success';
          _scanComplete = true;
          _identifiedPerson = result;
        });

        // Navigate to identified person screen after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppConstants.adminIdentifiedRoute,
            arguments: {
              'personData': result,
              'scanTime': DateTime.now(),
            },
          );
        }
      } else {
        setState(() {
          _scanStatus = 'failed';
          _scanComplete = true;
        });
        
        _showErrorDialog();
      }
    } catch (e) {
      setState(() {
        _scanStatus = 'error';
        _scanComplete = true;
      });
      
      _showErrorSnackBar('Erreur: ${e.toString()}');
    }

    setState(() {
      _isScanning = false;
    });
    _animationController.reset();
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: AppTheme.errorColor, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Aucune correspondance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'L\'empreinte digitale n\'a pas été trouvée dans notre base de données.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Que souhaitez-vous faire ?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.only(bottom: 8, right: 8),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _startScan(); // Retry scan
              },
              child: const Text('Réessayer'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to manual search or emergency help
                _showEmergencyOptions();
              },
              child: Text(
                'Aide d\'urgence',
                style: TextStyle(color: AppTheme.errorColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.emergency,
                    color: AppTheme.errorColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Options d\'urgence',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.call, color: AppTheme.errorColor),
                ),
                title: const Text('Appeler les urgences'),
                subtitle: const Text('Composer le 112'),
                onTap: () {
                  // TODO: Implement emergency call
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_hospital, color: AppTheme.warningColor),
                ),
                title: const Text('Premiers secours'),
                subtitle: const Text('Guide de premiers secours'),
                onTap: () {
                  // TODO: Navigate to first aid guide
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.infoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.search, color: AppTheme.infoColor),
                ),
                title: const Text('Recherche manuelle'),
                subtitle: const Text('Rechercher par nom'),
                onTap: () {
                  // TODO: Navigate to manual search
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
            tooltip: 'Historique des scans',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () async {
              // Show statistics
              final stats = await _biometricService.getScanStatistics();
              _showStatisticsDialog(stats);
            },
            tooltip: 'Statistiques',
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
      case 'error':
        instructionText = 'Erreur lors du scan';
        instructionIcon = Icons.warning;
        instructionColor = AppTheme.warningColor;
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
                  if (_identifiedPerson != null && _scanStatus == 'success')
                    Text(
                      '${_identifiedPerson!['fullName']}',
                      style: AppTheme.captionStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
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
      case 'error':
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
      case 'error':
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

    if (_scanStatus == 'failed' || _scanStatus == 'error') {
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
            onPressed: _showEmergencyOptions,
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

  void _showStatisticsDialog(Map<String, dynamic> stats) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Statistiques des scans'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow('Total des scans', stats['total'].toString()),
              _buildStatRow('Scans réussis', stats['successful'].toString()),
              _buildStatRow('Scans échoués', stats['failed'].toString()),
              _buildStatRow('Aujourd\'hui', stats['today'].toString()),
              _buildStatRow('Cette semaine', stats['thisWeek'].toString()),
              _buildStatRow('Ce mois', stats['thisMonth'].toString()),
              const Divider(),
              _buildStatRow('Taux de succès', '${stats['successRate']}%'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
