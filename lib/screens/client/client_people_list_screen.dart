import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/core/constants/app_constants.dart';
import 'package:accident_management4/models/person_model.dart';
import 'package:accident_management4/widgets/custom_text_field.dart';

class ClientPeopleListScreen extends StatefulWidget {
  const ClientPeopleListScreen({Key? key}) : super(key: key);

  @override
  State<ClientPeopleListScreen> createState() => _ClientPeopleListScreenState();
}

class _ClientPeopleListScreenState extends State<ClientPeopleListScreen> {
  final _searchController = TextEditingController();
  List<PersonModel> _allPeople = [];
  List<PersonModel> _filteredPeople = [];
  bool _isLoading = true;
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _loadPeople();
    _searchController.addListener(_filterPeople);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    // TODO: Charger les personnes depuis Firebase
    await Future.delayed(const Duration(seconds: 1)); // Simulation
    
    // Données de test
    setState(() {
      _allPeople = [
        PersonModel(
          personId: '1',
          firstName: 'Marie',
          lastName: 'Tchuente',
          registeredBy: 'user-id',
          registeredAt: DateTime.now().subtract(const Duration(days: 2)),
          emergencyContacts: List.generate(3, (index) => EmergencyContact(
            contactId: 'c$index',
            name: 'Contact ${index + 1}',
            phoneNumber: '+237690000000',
            relationship: 'Parent',
            priority: index + 1,
          )),
        ),
        PersonModel(
          personId: '2',
          firstName: 'Paul',
          lastName: 'Kamga',
          registeredBy: 'user-id',
          registeredAt: DateTime.now().subtract(const Duration(days: 5)),
          emergencyContacts: List.generate(3, (index) => EmergencyContact(
            contactId: 'c$index',
            name: 'Contact ${index + 1}',
            phoneNumber: '+237677000000',
            relationship: 'Ami',
            priority: index + 1,
          )),
        ),
        PersonModel(
          personId: '3',
          firstName: 'Anne',
          lastName: 'Ngono',
          registeredBy: 'user-id',
          registeredAt: DateTime.now().subtract(const Duration(days: 10)),
          emergencyContacts: List.generate(3, (index) => EmergencyContact(
            contactId: 'c$index',
            name: 'Contact ${index + 1}',
            phoneNumber: '+237655000000',
            relationship: 'Famille',
            priority: index + 1,
          )),
        ),
      ];
      _filteredPeople = List.from(_allPeople);
      _isLoading = false;
    });
  }

  void _filterPeople() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPeople = _allPeople.where((person) {
        final fullName = '${person.firstName} ${person.lastName}'.toLowerCase();
        return fullName.contains(query);
      }).toList();
    });
  }

  void _sortPeople(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      switch (sortBy) {
        case 'name':
          _filteredPeople.sort((a, b) => a.fullName.compareTo(b.fullName));
          break;
        case 'date':
          _filteredPeople.sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Liste des personnes'),
        backgroundColor: AppTheme.clientModuleColor,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: _sortPeople,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'name' 
                          ? AppTheme.clientModuleColor 
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Par nom'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: _sortBy == 'date' 
                          ? AppTheme.clientModuleColor 
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Par date'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Exporter en CSV
              _showExportDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: CustomTextField(
              label: '',
              hint: 'Rechercher par nom...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
          // Results count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredPeople.length} personne${_filteredPeople.length > 1 ? 's' : ''}',
                  style: AppTheme.captionStyle,
                ),
                if (_filteredPeople.length != _allPeople.length)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                    },
                    child: const Text('Effacer le filtre'),
                  ),
              ],
            ),
          ),
          // People list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPeople.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadPeople,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredPeople.length,
                          itemBuilder: (context, index) {
                            final person = _filteredPeople[index];
                            return _buildPersonCard(person);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Aucune personne enregistrée'
                : 'Aucun résultat trouvé',
            style: AppTheme.subheadingStyle.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Commencez par enregistrer une personne'
                : 'Essayez avec un autre terme de recherche',
            style: AppTheme.captionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonCard(PersonModel person) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.clientModuleColor,
          child: Text(
            '${person.firstName[0]}${person.lastName[0]}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          person.fullName,
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Enregistré le ${_formatDate(person.registeredAt)}',
              style: AppTheme.captionStyle,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 14,
                  color: AppTheme.textSecondaryColor,
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
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handlePersonAction(value, person),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('Voir les détails'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppTheme.errorColor),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: AppTheme.errorColor)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          _showPersonDetails(person);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return "aujourd'hui";
    } else if (difference.inDays == 1) {
      return "hier";
    } else if (difference.inDays < 7) {
      return "il y a ${difference.inDays} jours";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  void _handlePersonAction(String action, PersonModel person) {
    switch (action) {
      case 'view':
        _showPersonDetails(person);
        break;
      case 'edit':
        // TODO: Naviguer vers l'écran de modification
        break;
      case 'delete':
        _showDeleteConfirmation(person);
        break;
    }
  }

  void _showPersonDetails(PersonModel person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.clientModuleColor,
                          child: Text(
                            '${person.firstName[0]}${person.lastName[0]}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
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
                    // Contacts d'urgence
                    Text(
                      'Contacts d\'urgence',
                      style: AppTheme.subheadingStyle,
                    ),
                    const SizedBox(height: 16),
                    ...person.emergencyContacts.map((contact) => Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.clientModuleColor.withOpacity(0.1),
                          child: Text(
                            '${contact.priority}',
                            style: TextStyle(
                              color: AppTheme.clientModuleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(contact.name),
                        subtitle: Text('${contact.relationship} • ${contact.phoneNumber}'),
                      ),
                    )).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(PersonModel person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ${person.fullName} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Supprimer de Firebase
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Personne supprimée'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
              _loadPeople();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les données'),
        content: const Text(
          'Les données seront exportées au format CSV. Voulez-vous continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implémenter l'export CSV
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export en cours...'),
                  backgroundColor: AppTheme.infoColor,
                ),
              );
            },
            child: const Text('Exporter'),
          ),
        ],
      ),
    );
  }
}
