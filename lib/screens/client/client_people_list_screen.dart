import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/models/person_model.dart';
import 'package:accident_management4/services/person_service.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';

class ClientPeopleListScreen extends StatefulWidget {
  const ClientPeopleListScreen({Key? key}) : super(key: key);

  @override
  State<ClientPeopleListScreen> createState() => _ClientPeopleListScreenState();
}

class _ClientPeopleListScreenState extends State<ClientPeopleListScreen> {
  final PersonService _personService = PersonService();
  final TextEditingController _searchController = TextEditingController();
  
  List<PersonModel> _allPersons = [];
  List<PersonModel> _filteredPersons = [];
  bool _isLoading = true;
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _loadPersons();
    _searchController.addListener(_filterPersons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPersons() {
    setState(() {
      _isLoading = true;
    });
  }

  void _filterPersons() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPersons = List.from(_allPersons);
      } else {
        _filteredPersons = _allPersons.where((person) {
          return person.firstName.toLowerCase().contains(query) ||
                 person.lastName.toLowerCase().contains(query) ||
                 person.fullName.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _sortPersons(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'name':
          _filteredPersons.sort((a, b) => a.fullName.compareTo(b.fullName));
          break;
        case 'recent':
        default:
          _filteredPersons.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
          break;
      }
    });
  }

  Future<void> _confirmDelete(PersonModel person) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${person.fullName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _personService.deletePerson(person.personId);
        _showSuccessSnackBar('Personne supprimée avec succès');
      } catch (e) {
        _showErrorSnackBar('Erreur lors de la suppression');
      }
    }
  }

  void _showPersonDetails(PersonModel person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PersonDetailsSheet(person: person),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Personnes enregistrées'),
        backgroundColor: AppTheme.clientModuleColor,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: _sortPersons,
            icon: const Icon(Icons.sort),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recent',
                child: Text('Plus récent'),
              ),
              const PopupMenuItem(
                value: 'name',
                child: Text('Par nom'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppTheme.clientModuleColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: CustomTextField(
              controller: _searchController,
              hint: 'Rechercher par nom...',
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              fillColor: Colors.white.withOpacity(0.1),
              textStyle: const TextStyle(color: Colors.white),
              hintStyle: const TextStyle(color: Colors.white70),
            ),
          ),
          // Statistics bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStatChip(
                  Icons.people,
                  '${_allPersons.length}',
                  'Total',
                  AppTheme.primaryColor,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  Icons.search,
                  '${_filteredPersons.length}',
                  'Résultats',
                  AppTheme.clientModuleColor,
                ),
              ],
            ),
          ),
          // List content
          Expanded(
            child: StreamBuilder<List<PersonModel>>(
              stream: _personService.getMyRegisteredPersons(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Erreur de chargement',
                          style: AppTheme.headingStyle,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: AppTheme.captionStyle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadPersons,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.clientModuleColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune personne enregistrée',
                          style: AppTheme.headingStyle.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez par enregistrer une nouvelle personne',
                          style: AppTheme.captionStyle,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppConstants.clientRegisterRoute,
                            );
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Nouvel enregistrement'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.clientModuleColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Update local lists
                _allPersons = snapshot.data!;
                if (_isLoading) {
                  _filteredPersons = List.from(_allPersons);
                  _isLoading = false;
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadPersons();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPersons.length,
                    itemBuilder: (context, index) {
                      final person = _filteredPersons[index];
                      return _PersonCard(
                        person: person,
                        onTap: () => _showPersonDetails(person),
                        onDelete: () => _confirmDelete(person),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
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

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final PersonModel person;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PersonCard({
    required this.person,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.clientModuleColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    person.firstName[0].toUpperCase() + 
                    person.lastName[0].toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.clientModuleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.fullName,
                      style: AppTheme.subheadingStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(person.registeredAt),
                          style: AppTheme.captionStyle,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${person.emergencyContacts.length} contacts',
                          style: AppTheme.captionStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Supprimer'),
                      ],
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _PersonDetailsSheet extends StatelessWidget {
  final PersonModel person;

  const _PersonDetailsSheet({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Person header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.clientModuleColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          person.firstName[0].toUpperCase() +
                          person.lastName[0].toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.clientModuleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.fullName,
                            style: AppTheme.headingStyle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${person.personId}',
                            style: AppTheme.captionStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Registration info
                _buildSection(
                  'Informations d\'enregistrement',
                  Icons.info_outline,
                  [
                    _buildDetailRow('Date', _formatDateTime(person.registeredAt)),
                    if (person.lastModified != null)
                      _buildDetailRow('Dernière modification', _formatDateTime(person.lastModified!)),
                    _buildDetailRow('Statut', person.status == 'active' ? 'Actif' : 'Inactif'),
                  ],
                ),
                const SizedBox(height: 24),
                // Emergency contacts
                _buildSection(
                  'Contacts d\'urgence',
                  Icons.emergency,
                  person.emergencyContacts.map((contact) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.clientModuleColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${contact.priority}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: AppTheme.bodyStyle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${contact.phoneNumber} • ${contact.relationship}',
                                  style: AppTheme.captionStyle,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Biometric status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.fingerprint,
                        color: AppTheme.successColor,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Empreintes digitales',
                              style: AppTheme.subheadingStyle.copyWith(
                                color: AppTheme.successColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '✓ Pouce gauche et auriculaire droit enregistrés',
                              style: AppTheme.captionStyle.copyWith(
                                color: AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.clientModuleColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.subheadingStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTheme.captionStyle,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
