import 'package:flutter/material.dart';
import '../models/prescription_model.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class PrescriptionDetailPage extends StatefulWidget {
  final PrescriptionModel prescription;

  const PrescriptionDetailPage({
    super.key,
    required this.prescription,
  });

  @override
  State<PrescriptionDetailPage> createState() => _PrescriptionDetailPageState();
}

class _PrescriptionDetailPageState extends State<PrescriptionDetailPage> {
  bool _isAccepted = false;
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Détails de la demande',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                      // En-tête avec numéro de demande
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${widget.prescription.requestNumber} Détails de la demande',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 24),

                      // Informations patient
                      _buildSectionTitle('PATIENT'),
                      const SizedBox(height: 8),
                      Text(
                        widget.prescription.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.prescription.patientAge} ans, ${widget.prescription.patientGender}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Informations médecin
                      _buildSectionTitle('MÉDECIN'),
                      const SizedBox(height: 8),
                      Text(
                        widget.prescription.doctorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.prescription.doctorSpecialty,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Date et heure du rendez-vous
                      _buildSectionTitle('DATE ET HEURE DU RENDEZ-VOUS'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatDate(widget.prescription.appointmentDate)} à ${widget.prescription.appointmentTime}',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Analyses requises
                      _buildSectionTitle('ANALYSES REQUISES'),
                      const SizedBox(height: 12),
                      ...widget.prescription.tests.skip(1).map((test) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    test,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.black87,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 24),

                      // Allergies
                      _buildSectionTitle('ALLERGIES'),
                      const SizedBox(height: 8),
                      widget.prescription.allergies.isEmpty
                          ? Text(
                              'Aucune allergie déclarée',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.prescription.allergies.map((allergy) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning, size: 16, color: Colors.red[700]),
                                      const SizedBox(width: 6),
                                      Text(
                                        allergy,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                      const SizedBox(height: 32),

                      // Boutons d'action
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _handlePending();
                              },
                              icon: const Icon(Icons.schedule, size: 20),
                              label: const Text('En attente'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange[700],
                                side: BorderSide(color: Colors.orange[700]!),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _handleAccept();
                              },
                              icon: const Icon(Icons.check, size: 20),
                              label: const Text('Accepter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.more_vert, color: Colors.grey[700], size: 20),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onSelected: (value) {
                              if (value == 'date_unavailable') {
                                _handleDateUnavailable();
                              } else if (value == 'other') {
                                _handleOtherNotification();
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'date_unavailable',
                                child: Row(
                                  children: [
                                    Icon(Icons.event_busy, size: 20, color: Colors.red),
                                    SizedBox(width: 12),
                                    Text('Date occupée'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'other',
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 20, color: Colors.blue),
                                    SizedBox(width: 12),
                                    Text('Autre notification'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );


  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey[600],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildRequestCard(PrescriptionModel prescription, {required bool isSelected}) {
    final statusColor = prescription.status == 'NOUVEAU'
        ? Colors.blue
        : prescription.status == 'EN ATTENTE'
            ? Colors.orange
            : Colors.grey;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PrescriptionDetailPage(prescription: prescription),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: prescription.avatarColor.withOpacity(0.2),
                    child: Text(
                      prescription.initials,
                      style: TextStyle(
                        color: prescription.avatarColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        const SizedBox(height: 2),
                        Text(
                          prescription.tests.first,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      prescription.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Consulter',
                      style: TextStyle(
                        color: isSelected ? Colors.blue[700] : Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                prescription.timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _handleAccept() {
    // Envoyer une notification au patient
    _notificationService.addNotification(
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Rendez-vous accepté',
        message: 'Votre demande de rendez-vous (#${widget.prescription.requestNumber}) pour le ${_formatDate(widget.prescription.appointmentDate)} à ${widget.prescription.appointmentTime} a été acceptée. Veuillez respecter les informations fournies.',
        date: DateTime.now(),
        type: 'accepted',
        requestNumber: widget.prescription.requestNumber,
      ),
    );

    // Afficher la notification de succès
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rendez-vous accepté. Notification envoyée au patient.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.fixed,
      ),
    );

    // Retourner à la page précédente
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _handlePending() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mettre en attente'),
        content: const Text('Voulez-vous mettre cette demande en attente ? Le patient sera notifié qu\'il y a des procédures à suivre concernant son analyse.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Envoyer une notification au patient
              _notificationService.addNotification(
                NotificationModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Rendez-vous en attente',
                  message: 'Votre demande de rendez-vous (#${widget.prescription.requestNumber}) est en attente. Il y a des procédures à suivre concernant votre analyse. Nous vous contacterons bientôt.',
                  date: DateTime.now(),
                  type: 'pending',
                  requestNumber: widget.prescription.requestNumber,
                ),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Demande mise en attente. Notification envoyée au patient.'),
                    backgroundColor: Colors.orange[700],
                  ),
                );
                
                Future.delayed(const Duration(seconds: 1), () {
                  if (mounted) {
                    Navigator.pop(context, false);
                  }
                });
              }
            },
            child: const Text('Mettre en attente', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _handleDateUnavailable() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date occupée'),
        content: const Text('Voulez-vous envoyer une notification au patient pour l\'informer que la date est occupée et proposer des dates alternatives ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Générer des dates alternatives (exemple: +1, +2, +3 jours)
              final alternativeDates = [
                widget.prescription.appointmentDate.add(const Duration(days: 1)),
                widget.prescription.appointmentDate.add(const Duration(days: 2)),
                widget.prescription.appointmentDate.add(const Duration(days: 3)),
              ];

              // Envoyer une notification au patient avec dates alternatives
              _notificationService.addNotification(
                NotificationModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: 'Date de rendez-vous occupée',
                  message: 'Désolé, la date de votre rendez-vous (#${widget.prescription.requestNumber}) pour le ${_formatDate(widget.prescription.appointmentDate)} à ${widget.prescription.appointmentTime} est occupée. Voici d\'autres jours disponibles si vous souhaitez réserver.',
                  date: DateTime.now(),
                  type: 'date_unavailable',
                  requestNumber: widget.prescription.requestNumber,
                  alternativeDates: alternativeDates.map((d) => _formatDate(d)).toList(),
                ),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Notification envoyée au patient avec dates alternatives.'),
                    backgroundColor: Colors.blue[700],
                  ),
                );
              }
            },
            child: const Text('Envoyer', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _handleOtherNotification() {
    final messageController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autre notification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le message à envoyer au patient :'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (messageController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                
                // Envoyer une notification personnalisée au patient
                _notificationService.addNotification(
                  NotificationModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: 'Notification du centre',
                    message: messageController.text.trim(),
                    date: DateTime.now(),
                    type: 'other',
                    requestNumber: widget.prescription.requestNumber,
                  ),
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Notification envoyée au patient.'),
                      backgroundColor: Colors.blue[700],
                    ),
                  );
                }
              }
            },
            child: const Text('Envoyer', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}
