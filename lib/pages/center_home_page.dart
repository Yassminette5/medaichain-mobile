import 'package:flutter/material.dart';
import '../models/prescription_model.dart';
import 'settings_page.dart';
import 'patients_list_page.dart';
import 'prescription_detail_page.dart';

class CenterHomePage extends StatefulWidget {
  const CenterHomePage({super.key});

  @override
  State<CenterHomePage> createState() => _CenterHomePageState();
}

class _CenterHomePageState extends State<CenterHomePage> {
  String _selectedFilter = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  final List<PrescriptionModel> _prescriptions = [
    PrescriptionModel(
      id: '1',
      requestNumber: 'REQ-8829',
      patientName: 'Jean Dupont',
      initials: 'JD',
      patientAge: 45,
      patientGender: 'Homme',
      timeAgo: 'Il y a 5 min',
      status: 'EN ATTENTE',
      tests: ['Bilan sanguin complet', 'Numération Formule Sanguine (NFS)', 'Glycémie à jeun', 'Bilan Lipidique'],
      avatarColor: Colors.blue,
      doctorName: 'Dr. Smith',
      doctorSpecialty: 'Cardiologie',
      clinicalContext: 'Symptômes de fatigue intense persistante depuis 3 semaines, suspicion d\'anémie ou carence en fer.',
    ),
    PrescriptionModel(
      id: '2',
      requestNumber: 'REQ-8830',
      patientName: 'Marie Curie',
      initials: 'MC',
      patientAge: 68,
      patientGender: 'Femme',
      timeAgo: 'Il y a 15 min',
      status: 'EN ATTENTE',
      tests: ['Test PCR', 'COVID-19'],
      avatarColor: Colors.orange,
      doctorName: 'Dr. Martin',
      doctorSpecialty: 'Médecine générale',
      clinicalContext: 'Dépistage COVID-19 suite à exposition récente.',
    ),
    PrescriptionModel(
      id: '3',
      requestNumber: 'REQ-8831',
      patientName: 'Pierre Martin',
      initials: 'PM',
      patientAge: 32,
      patientGender: 'Homme',
      timeAgo: 'Il y a 42 min',
      status: 'EN ATTENTE',
      tests: ['Analyse d\'urine'],
      avatarColor: Colors.green,
      doctorName: 'Dr. Dubois',
      doctorSpecialty: 'Néphrologie',
      clinicalContext: 'Contrôle de routine pour suivi rénal.',
    ),
  ];

  List<PrescriptionModel> get _filteredPrescriptions {
    var filtered = _prescriptions;

    if (_selectedFilter == 'Urgent') {
      // Filtrer les plus récentes (moins de 10 minutes)
      filtered = filtered.where((p) {
        final minutes = int.tryParse(p.timeAgo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return minutes < 10;
      }).toList();
    }

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((p) {
        return p.patientName.toLowerCase().contains(query) ||
            p.tests.any((test) => test.toLowerCase().contains(query));
      }).toList();
    }

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'URGENT':
        return Colors.amber[700]!;
      case 'ROUTINE':
        return Colors.grey[400]!;
      case 'PENDING':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.person, color: Colors.black87),
            onPressed: () {
              // Naviguer vers le profil
            },
          ),
        ),
        title: const Text(
          'Prescriptions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche et filtre
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Rechercher des patients ou types de tests...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // Filtres modernes avec style segmenté
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModernFilterChip('Tous', _selectedFilter == 'Tous'),
                      const SizedBox(width: 8),
                      _buildModernFilterChip('Urgent', _selectedFilter == 'Urgent'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Liste des prescriptions
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Soumissions récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ..._filteredPrescriptions.map((prescription) => _buildPrescriptionCard(prescription)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 1) {
            // Patients
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>  PatientsListPage(),
              ),
            );
          } else if (index == 2) {
            // Settings
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionModel prescription) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      prescription.initials,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Contenu principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prescription.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prescription.tests.first,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        prescription.timeAgo,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PrescriptionDetailPage(
                            prescription: prescription,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Consulter',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernFilterChip(String label, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFilter = label;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.blue[700] : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
