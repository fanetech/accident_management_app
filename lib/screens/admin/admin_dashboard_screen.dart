import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _totalScans = 0;
  int _successfulScans = 0;
  int _todayScans = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // TODO: Charger les données depuis Firebase
    await Future.delayed(const Duration(seconds: 1)); // Simulation
    
    setState(() {
      _totalScans = 156;
      _successfulScans = 142;
      _todayScans = 8;
      _isLoading = false;
    });
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
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Afficher les notifications
            },
          ),
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
                    // Message d'urgence
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
                                    'Mode Urgence',
                                    style: AppTheme.subheadingStyle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Prêt pour l\'identification d\'urgence',
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
                    // Statistiques du jour
                    Text(
                      'Statistiques du jour',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Scans aujourd\'hui',
                            _todayScans.toString(),
                            Icons.fingerprint,
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Taux de réussite',
                            '${((_successfulScans / _totalScans) * 100).toStringAsFixed(1)}%',
                            Icons.check_circle,
                            AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Actions rapides
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
                    // Dernières identifications
                    Text(
                      'Dernières identifications',
                      style: AppTheme.subheadingStyle,
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                Text(
                  value,
                  style: AppTheme.headingStyle.copyWith(
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
    // TODO: Récupérer les vraies données depuis Firebase
    final recentScans = [
      {
        'name': 'Marie Tchuente',
        'time': 'Il y a 30 minutes',
        'status': 'success',
        'contacts': 3,
      },
      {
        'name': 'Paul Kamga',
        'time': 'Il y a 1 heure',
        'status': 'success',
        'contacts': 2,
      },
      {
        'name': 'Inconnu',
        'time': 'Il y a 2 heures',
        'status': 'failed',
        'contacts': 0,
      },
    ];

    return Column(
      children: recentScans.map((scan) {
        final isSuccess = scan['status'] == 'success';
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
              ),
            ),
            title: Text(scan['name'] as String),
            subtitle: Text(scan['time'] as String),
            trailing: isSuccess
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${scan['contacts']} contacts',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : null,
            onTap: isSuccess
                ? () {
                    // TODO: Naviguer vers les détails
                  }
                : null,
          ),
        );
      }).toList(),
    );
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
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.loginRoute,
                (route) => false,
              );
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
