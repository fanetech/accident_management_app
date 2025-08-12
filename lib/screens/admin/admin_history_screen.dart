import 'package:flutter/material.dart';
import 'package:accident_management4/core/theme/app_theme.dart';
import 'package:accident_management4/services/biometric_scan_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminHistoryScreen extends StatefulWidget {
  const AdminHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends State<AdminHistoryScreen> 
    with SingleTickerProviderStateMixin {
  final BiometricScanService _biometricService = BiometricScanService();
  late TabController _tabController;
  
  String _selectedFilter = 'all';
  DateTime? _selectedDate;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return AppTheme.successColor;
      case 'failed':
        return AppTheme.errorColor;
      case 'initiated':
      case 'attempting':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'failed':
        return Icons.cancel;
      case 'initiated':
      case 'attempting':
        return Icons.pending;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return 'Réussi';
      case 'failed':
        return 'Échoué';
      case 'initiated':
        return 'Initié';
      case 'attempting':
        return 'En cours';
      default:
        return status;
    }
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Tous'),
            selected: _selectedFilter == 'all',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'all';
              });
            },
            selectedColor: AppTheme.adminModuleColor.withOpacity(0.2),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Réussis'),
            selected: _selectedFilter == 'success',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'success';
              });
            },
            selectedColor: AppTheme.successColor.withOpacity(0.2),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Échoués'),
            selected: _selectedFilter == 'failed',
            onSelected: (selected) {
              setState(() {
                _selectedFilter = 'failed';
              });
            },
            selectedColor: AppTheme.errorColor.withOpacity(0.2),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(_selectedDate != null 
                    ? DateFormat('dd/MM').format(_selectedDate!)
                    : 'Date'),
              ],
            ),
            selected: _selectedDate != null,
            onSelected: (selected) async {
              if (selected) {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                setState(() {
                  _selectedDate = picked;
                });
              } else {
                setState(() {
                  _selectedDate = null;
                });
              }
            },
            selectedColor: AppTheme.infoColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: AppTheme.adminModuleColor,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Scans', icon: Icon(Icons.fingerprint)),
            Tab(text: 'Appels', icon: Icon(Icons.phone)),
            Tab(text: 'SMS', icon: Icon(Icons.sms)),
          ],
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildScansTab(),
          _buildCallsTab(),
          _buildSMSTab(),
        ],
      ),
    );
  }

  Widget _buildScansTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildFilterChips(),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _biometricService.getRecentScanLogs(limit: 100),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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
                        style: AppTheme.subheadingStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        style: AppTheme.captionStyle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                );
              }

              final logs = snapshot.data ?? [];
              
              // Apply filters
              final filteredLogs = logs.where((log) {
                if (_selectedFilter != 'all' && log['status'] != _selectedFilter) {
                  return false;
                }
                if (_selectedDate != null) {
                  final logDate = (log['timestamp'] as Timestamp?)?.toDate();
                  if (logDate != null) {
                    return logDate.year == _selectedDate!.year &&
                           logDate.month == _selectedDate!.month &&
                           logDate.day == _selectedDate!.day;
                  }
                }
                return true;
              }).toList();

              if (filteredLogs.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.fingerprint,
                  title: 'Aucun scan trouvé',
                  subtitle: _selectedFilter != 'all' || _selectedDate != null
                      ? 'Essayez de modifier vos filtres'
                      : 'Les scans d\'empreintes apparaîtront ici',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredLogs.length,
                itemBuilder: (context, index) {
                  final log = filteredLogs[index];
                  return _buildScanLogCard(log);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCallsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_call_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final logs = snapshot.data?.docs ?? [];

        if (logs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.phone,
            title: 'Aucun appel',
            subtitle: 'Les appels d\'urgence apparaîtront ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            return _buildCallLogCard(log);
          },
        );
      },
    );
  }

  Widget _buildSMSTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('emergency_sms_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Erreur: ${snapshot.error}'),
          );
        }

        final logs = snapshot.data?.docs ?? [];

        if (logs.isEmpty) {
          return _buildEmptyState(
            icon: Icons.sms,
            title: 'Aucun SMS',
            subtitle: 'Les SMS d\'urgence apparaîtront ici',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index].data() as Map<String, dynamic>;
            return _buildSMSLogCard(log);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.adminModuleColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppTheme.adminModuleColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: AppTheme.headingStyle.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.captionStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScanLogCard(Map<String, dynamic> log) {
    final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
    final status = log['status'] ?? 'unknown';
    final location = log['location'] ?? 'Non spécifié';
    final method = log['identificationMethod'] ?? '';
    final personId = log['personId'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                status == 'success' && personId.isNotEmpty
                    ? 'Personne identifiée'
                    : 'Scan ${_getStatusText(status).toLowerCase()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (timestamp != null)
              Text(
                DateFormat('HH:mm').format(timestamp),
                style: AppTheme.captionStyle,
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (personId.isNotEmpty)
              Text('ID: ${personId.substring(0, 8)}...'),
            Text('Lieu: $location'),
            if (method.isNotEmpty)
              Text('Méthode: ${_formatMethod(method)}'),
            if (timestamp != null)
              Text(
                DateFormat('dd/MM/yyyy').format(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondaryColor,
        ),
        onTap: () {
          _showScanDetails(log);
        },
      ),
    );
  }

  Widget _buildCallLogCard(Map<String, dynamic> log) {
    final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
    final personName = log['personName'] ?? 'Inconnu';
    final contactName = log['contactName'] ?? 'Contact';
    final relationship = log['relationship'] ?? '';
    final status = log['status'] ?? 'unknown';
    final callerName = log['callerName'] ?? 'Agent';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.phone_in_talk,
            color: AppTheme.successColor,
          ),
        ),
        title: Text(
          '$contactName ($relationship)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pour: $personName'),
            Text('Par: $callerName'),
            if (timestamp != null)
              Text(
                DateFormat('dd/MM/yyyy à HH:mm').format(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(status),
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSMSLogCard(Map<String, dynamic> log) {
    final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
    final personName = log['personName'] ?? 'Inconnu';
    final phoneNumber = log['phoneNumber'] ?? '';
    final message = log['message'] ?? '';
    final senderName = log['senderName'] ?? 'Agent';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.sms,
            color: AppTheme.infoColor,
          ),
        ),
        title: Text(
          'SMS à ${_maskPhoneNumber(phoneNumber)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pour: $personName'),
            Text(
              message.length > 50 
                  ? '${message.substring(0, 50)}...'
                  : message,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            Text('Par: $senderName'),
            if (timestamp != null)
              Text(
                DateFormat('dd/MM/yyyy à HH:mm').format(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
          ],
        ),
        onTap: () {
          _showSMSDetails(log);
        },
      ),
    );
  }

  String _formatMethod(String method) {
    switch (method) {
      case 'person_biometrics':
      case 'biometric_match':
        return 'Empreinte enregistrée';
      case 'client_profile':
        return 'Profil client';
      default:
        return method;
    }
  }

  String _maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 4) return phoneNumber;
    final lastFour = phoneNumber.substring(phoneNumber.length - 4);
    return '****$lastFour';
  }

  void _showScanDetails(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
        final status = log['status'] ?? 'unknown';
        
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Détails du scan',
                    style: AppTheme.headingStyle,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Statut', _getStatusText(status)),
              _buildDetailRow('Lieu', log['location'] ?? 'Non spécifié'),
              if (log['personId'] != null)
                _buildDetailRow('ID Personne', log['personId']),
              if (log['identificationMethod'] != null)
                _buildDetailRow('Méthode', _formatMethod(log['identificationMethod'])),
              if (log['scannedBy'] != null && log['scannedBy'] != 'anonymous')
                _buildDetailRow('Scanné par', log['scannedBy']),
              if (log['reason'] != null)
                _buildDetailRow('Raison', log['reason']),
              if (timestamp != null)
                _buildDetailRow(
                  'Date et heure',
                  DateFormat('dd/MM/yyyy à HH:mm:ss').format(timestamp),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminModuleColor,
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSMSDetails(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final timestamp = (log['timestamp'] as Timestamp?)?.toDate();
        
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sms,
                    color: AppTheme.infoColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Détails du SMS',
                    style: AppTheme.headingStyle,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Destinataire', _maskPhoneNumber(log['phoneNumber'] ?? '')),
              _buildDetailRow('Pour', log['personName'] ?? 'Inconnu'),
              _buildDetailRow('Envoyé par', log['senderName'] ?? 'Agent'),
              if (log['location'] != null)
                _buildDetailRow('Lieu', log['location']),
              if (timestamp != null)
                _buildDetailRow(
                  'Date et heure',
                  DateFormat('dd/MM/yyyy à HH:mm:ss').format(timestamp),
                ),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log['message'] ?? '',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.adminModuleColor,
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.captionStyle,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
