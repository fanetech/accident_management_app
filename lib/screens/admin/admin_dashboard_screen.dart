import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';
import 'package:accident_management4/services/auth_service.dart';
import 'package:accident_management4/services/biometric_scan_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AuthService _authService = AuthService();
  final BiometricScanService _biometricService = BiometricScanService();
  
  Map<String, dynamic> _statistics = {
    'total': 0,
    'successful': 0,
    'failed': 0,
    'today': 0,
    'successRate': '0.0',
  };
  
  bool _isLoading = true;
  String _adminName = 'Administrateur';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current admin name
      final user = _authService.currentUser;
      if (user != null) {
        final userDoc = await _authService.getUserDocument(user.uid);
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _adminName = userData['displayName'] ?? user.displayName ?? 'Administrateur';
          });
        }
      }
      
      // Load real statistics from Firebase
      final stats = await _biometricService.getScanStatistics();
      
      setState(() {
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Espace Admin'),
        backgroundColor: AppTheme.adminModuleColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.profileRoute);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome message
                    Card(
                      color: AppTheme.adminModuleColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.emergency,
                              color: AppTheme.adminModuleColor,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bonjour, $_adminName',
                                    style: AppTheme.subheadingStyle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Système d\'identification d\'urgence actif',
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
                    // Statistics
                    Text(
                      'Statistiques',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildStatCard(
                          'Aujourd\'hui',
                          _statistics['today'].toString(),
                          Icons.today,
                          AppTheme.primaryColor,
                        ),
                        _buildStatCard(
                          'Taux de succès',
                          '${_statistics['successRate']}%',
                          Icons.check_circle,
                          AppTheme.successColor,
                        ),
                        _buildStatCard(
                          'Total scans',
                          _statistics['total'].toString(),
                          Icons.fingerprint,
                          AppTheme.infoColor,
                        ),
                        _buildStatCard(
                          'Cette semaine',
                          _statistics['thisWeek']?.toString() ?? '0',
                          Icons.calendar_view_week,
                          AppTheme.warningColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Quick actions
                    Text(
                      'Actions rapides',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    _buildQuickActionButton(
                      'Scanner une empreinte',
                      'Identifier une personne en urgence',
                      Icons.fingerprint,
                      AppTheme.adminModuleColor,
                      () {
                        Navigator.pushNamed(
                          context,
                          AppConstants.adminScannerRoute,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionButton(
                      'Historique des scans',
                      'Consulter les identifications passées',
                      Icons.history,
                      AppTheme.primaryColor,
                      () {
                        Navigator.pushNamed(
                          context,
                          AppConstants.adminHistoryRoute,
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    // Recent identifications
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dernières identifications',
                          style: AppTheme.subheadingStyle,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.adminHistoryRoute,
                            );
                          },
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecentScansList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppConstants.adminScannerRoute);
        },
        backgroundColor: AppTheme.adminModuleColor,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scanner'),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: AppTheme.captionStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTheme.captionStyle,
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }

  Widget _buildRecentScansList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _biometricService.getRecentScanLogs(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Erreur de chargement',
                    style: AppTheme.captionStyle,
                  ),
                ],
              ),
            ),
          );
        }

        final logs = snapshot.data ?? [];

        if (logs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.fingerprint,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune identification récente',
                      style: AppTheme.captionStyle,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Get only successful scans with person info
        final successfulScans = logs.where((log) => 
          log['status'] == 'success' && 
          log['personId'] != null
        ).take(5).toList();

        if (successfulScans.isEmpty) {
          // Show all scans if no successful ones
          return Column(
            children: logs.take(3).map((log) {
              final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
              final status = log['status'] ?? 'unknown';
              final isSuccess = status == 'success';
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSuccess
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    child: Icon(
                      isSuccess ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    isSuccess ? 'Identification réussie' : 'Échec du scan',
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    timestamp != null 
                        ? _getTimeAgo(timestamp)
                        : 'Date inconnue',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppConstants.adminHistoryRoute,
                    );
                  },
                ),
              );
            }).toList(),
          );
        }

        // Show successful scans with person data
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadPersonDetails(successfulScans),
          builder: (context, personSnapshot) {
            if (!personSnapshot.hasData) {
              return Column(
                children: successfulScans.map((log) {
                  final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.successColor,
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Chargement...',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        timestamp != null 
                            ? _getTimeAgo(timestamp)
                            : 'Date inconnue',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              );
            }

            final personsData = personSnapshot.data!;
            
            return Column(
              children: personsData.map((data) {
                final timestamp = data['timestamp'] as DateTime?;
                final personName = data['personName'] ?? 'Personne inconnue';
                final contactsCount = data['contactsCount'] ?? 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.successColor,
                      child: Text(
                        personName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      personName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      timestamp != null 
                          ? _getTimeAgo(timestamp)
                          : 'Date inconnue',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$contactsCount contacts',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    onTap: () {
                      // Navigate to history for details
                      Navigator.pushNamed(
                        context,
                        AppConstants.adminHistoryRoute,
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadPersonDetails(List<Map<String, dynamic>> logs) async {
    List<Map<String, dynamic>> results = [];
    
    for (var log in logs) {
      try {
        final personId = log['personId'] as String?;
        if (personId == null) continue;
        
        // Try to get person details from persons collection
        final personDoc = await FirebaseFirestore.instance
            .collection('persons')
            .doc(personId)
            .get();
        
        if (personDoc.exists) {
          final personData = personDoc.data()!;
          results.add({
            'personName': '${personData['firstName']} ${personData['lastName']}',
            'contactsCount': (personData['emergencyContacts'] as List?)?.length ?? 0,
            'timestamp': (log['timestamp'] as Timestamp?)?.toDate(),
          });
        } else {
          // Try client_profiles collection
          final profileDoc = await FirebaseFirestore.instance
              .collection('client_profiles')
              .doc(personId)
              .get();
          
          if (profileDoc.exists) {
            final profileData = profileDoc.data()!;
            results.add({
              'personName': profileData['displayName'] ?? 'Utilisateur',
              'contactsCount': (profileData['emergencyContacts'] as List?)?.length ?? 0,
              'timestamp': (log['timestamp'] as Timestamp?)?.toDate(),
            });
          }
        }
      } catch (e) {
        print('Error loading person details: $e');
      }
    }
    
    return results;
  }

  void _showLogoutDialog() {
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
              Navigator.pop(context); // Close dialog
              
              // Sign out
              await _authService.signOut();
              
              // Navigate to login and clear navigation stack
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
  }
}
