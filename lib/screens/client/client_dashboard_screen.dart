import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/widgets/custom_button.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _totalRegistrations = 0;
  int _todayRegistrations = 0;
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
      _totalRegistrations = 42;
      _todayRegistrations = 5;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Espace Client'),
        backgroundColor: AppTheme.clientModuleColor,
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
                    // Message de bienvenue
                    Card(
                      color: AppTheme.clientModuleColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.waving_hand,
                              color: AppTheme.clientModuleColor,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bienvenue !',
                                    style: AppTheme.subheadingStyle,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Prêt à enregistrer de nouvelles personnes ?',
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
                    // Statistiques
                    Text(
                      'Statistiques',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total enregistré',
                            _totalRegistrations.toString(),
                            Icons.people,
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Aujourd\'hui',
                            _todayRegistrations.toString(),
                            Icons.today,
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
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildActionCard(
                          'Nouvel enregistrement',
                          Icons.person_add,
                          AppTheme.clientModuleColor,
                          () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.clientRegisterRoute,
                            );
                          },
                        ),
                        _buildActionCard(
                          'Liste des personnes',
                          Icons.list_alt,
                          AppTheme.primaryColor,
                          () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.clientPeopleListRoute,
                            );
                          },
                        ),
                        _buildActionCard(
                          'Paramètres',
                          Icons.settings,
                          AppTheme.textSecondaryColor,
                          () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.settingsRoute,
                            );
                          },
                        ),
                        _buildActionCard(
                          'Aide',
                          Icons.help_outline,
                          AppTheme.infoColor,
                          () {
                            // TODO: Afficher l'aide
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Derniers enregistrements
                    Text(
                      'Derniers enregistrements',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    // TODO: Implémenter la liste des derniers enregistrements
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.clientModuleColor,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: const Text('Jean Dupont'),
                        subtitle: const Text('Enregistré il y a 2 heures'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Naviguer vers les détails
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppConstants.clientRegisterRoute);
        },
        backgroundColor: AppTheme.clientModuleColor,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouveau'),
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

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
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
