import 'package:flutter/material.dart';
import '../models/center_model.dart';
import 'home_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late CenterModel _center;

  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _center = CenterModel();
    _nameController.text = _center.name;
    _categoryController.text = _center.category;
    _phoneController.text = _center.phone;
    _emailController.text = _center.email;
    _locationController.text = _center.location;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _center.name = _nameController.text;
      _center.category = _categoryController.text;
      _center.phone = _phoneController.text;
      _center.email = _emailController.text;
      _center.location = _locationController.text;

      // Naviguer vers la page d'accueil
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(centerName: _center.name),
        ),
      );
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer le centre'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer ce centre ? Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Ici vous pouvez ajouter la logique de suppression
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Centre supprimé')),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(String time) {
    if (time.isEmpty) return '';
    return time;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Profil du Centre'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Enregistrer',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Prise de rendez-vous en ligne
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Prise de rendez-vous en ligne',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Permettre aux patients de prendre rendez-vous via l\'application.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _center.onlineAppointmentEnabled,
                            onChanged: (value) {
                              setState(() {
                                _center.onlineAppointmentEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Section Informations Générales
              const Padding(
                padding: EdgeInsets.only(bottom: 12, top: 8),
                child: Text(
                  'INFORMATIONS GÉNÉRALES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom du centre',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le nom du centre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Catégorie',
                          suffixIcon: Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer la catégorie';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Section Coordonnées
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'COORDONNÉES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le numéro de téléphone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email professionnel',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer l\'email';
                          }
                          if (!value.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Localisation',
                          prefixIcon: Icon(Icons.location_on),
                          suffixIcon: Icon(Icons.map, color: Colors.blue),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer la localisation';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Section Horaires d'ouverture
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'HORAIRES D\'OUVERTURE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: _center.openingHours.entries.map((entry) {
                    final day = entry.key;
                    final schedule = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 20,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        day,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        schedule.isOpen
                                            ? '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}'
                                            : 'Fermé',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: schedule.isOpen,
                            onChanged: (value) {
                              setState(() {
                                schedule.isOpen = value;
                                if (value && schedule.startTime.isEmpty) {
                                  schedule.startTime = '08:00 AM';
                                  schedule.endTime = '06:30 PM';
                                } else if (!value) {
                                  schedule.startTime = '';
                                  schedule.endTime = '';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Bouton Supprimer le centre
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showDeleteDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Supprimer le centre',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
