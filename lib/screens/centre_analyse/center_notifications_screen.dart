import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../services/api_service.dart';

/// Écran des notifications pour le centre d'analyse (Mobile)
class CenterNotificationsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const CenterNotificationsScreen({super.key, this.onBack});

  @override
  State<CenterNotificationsScreen> createState() => _CenterNotificationsScreenState();
}

class _CenterNotificationsScreenState extends State<CenterNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appointments = await ApiService.getLabAppointments();
      
      // Transformer les appointments en notifications
      final notifications = appointments.map((apt) {
        final patientInfo = apt['patientInfo'] ?? apt['patientId'];
        String patientName = 'Patient Inconnu';
        String patientEmail = '';

        if (patientInfo != null && patientInfo is Map) {
          patientName =
              '${patientInfo['firstName'] ?? ''} ${patientInfo['lastName'] ?? ''}'.trim();
          patientEmail = patientInfo['email']?.toString() ?? '';
          if (patientName.isEmpty) {
            patientName = patientEmail.isNotEmpty
                ? patientEmail.split('@').first
                : 'Patient';
          }
        }

        final status = apt['status']?.toString().toLowerCase() ?? 'pending';
        final appointmentDate = apt['appointmentDate']?.toString() ?? '';
        final createdAt = apt['createdAt']?.toString() ?? DateTime.now().toIso8601String();
        
        return {
          'id': apt['_id']?.toString() ?? apt['id']?.toString() ?? '',
          'type': _getNotificationType(status),
          'title': _getNotificationTitle(status, patientName),
          'description': _getNotificationDescription(status, patientName, apt['analysisType']?.toString() ?? ''),
          'appointmentDate': appointmentDate,
          'createdAt': createdAt,
          'isRead': apt['isRead'] ?? false,
          'status': status,
          'patientName': patientName,
          'patientEmail': patientEmail,
        };
      }).toList();
      
      // Trier par date de création (plus récent en premier)
      notifications.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
        final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getNotificationType(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      case 'accepted':
        return 'accepted';
      default:
        return 'pending';
    }
  }

  String _getNotificationTitle(String status, String patientName) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Appointment with $patientName';
      case 'cancelled':
        return 'Appointment with $patientName';
      case 'accepted':
        return 'Appointment with $patientName';
      default:
        return 'Appointment with $patientName';
    }
  }

  String _getNotificationDescription(String status, String patientName, String analysisType) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Your Appointment has been completed with $patientName';
      case 'cancelled':
        return 'Your Appointment has been cancelled with $patientName';
      case 'accepted':
        return 'Appointment confirmed with $patientName';
      default:
        return 'New appointment request from $patientName';
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _notifications = _notifications.map((notif) {
        return {...notif, 'isRead': true};
      }).toList();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toutes les notifications ont été marquées comme lues'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les notifications'),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes les notifications ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _notifications = [];
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications ont été supprimées'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.done_all, color: AppColors.primary),
              title: const Text('Marquer comme lu'),
              onTap: () {
                Navigator.pop(context);
                _markAllAsRead();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Supprimer tous'),
              onTap: () {
                Navigator.pop(context);
                _deleteAll();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupNotificationsByDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (final notif in _notifications) {
      final createdAt = DateTime.tryParse(notif['createdAt'] ?? '') ?? DateTime.now();
      final createdDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
      
      String groupKey;
      if (createdDate == today) {
        groupKey = 'Aujourd\'hui';
      } else if (createdDate == yesterday) {
        groupKey = 'Hier';
      } else {
        final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
                       'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
        groupKey = '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
      }
      
      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(notif);
    }
    
    return grouped;
  }

  String _formatAppointmentDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final appointmentDay = DateTime(date.year, date.month, date.day);
      
      final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
                     'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
      
      String dayLabel;
      if (appointmentDay == today) {
        dayLabel = 'Aujourd\'hui';
      } else if (appointmentDay == today.add(const Duration(days: 1))) {
        dayLabel = 'Demain';
      } else if (appointmentDay == today.subtract(const Duration(days: 1))) {
        dayLabel = 'Hier';
      } else {
        dayLabel = '${date.day} ${months[date.month - 1]}';
      }
      
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final displayHour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      
      return '$dayLabel, ${date.day}${_getDaySuffix(date.day)} ${months[date.month - 1]} - $displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return dateString;
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'ème';
    switch (day % 10) {
      case 1: return 'er';
      case 2: return 'ème';
      case 3: return 'ème';
      default: return 'ème';
    }
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      final displayHour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return '';
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return const Color(0xFFFF9800);
      case 'accepted':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'accepted':
        return Icons.calendar_today;
      default:
        return Icons.calendar_today;
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedNotifications = _groupNotificationsByDate();
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorState()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      itemCount: groupedNotifications.length,
                      itemBuilder: (context, index) {
                        final groupKey = groupedNotifications.keys.elementAt(index);
                        final groupNotifications = groupedNotifications[groupKey]!;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                              child: Text(
                                groupKey,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            ...groupNotifications.asMap().entries.map((entry) {
                              final index = entry.key;
                              final notif = entry.value;
                              return _buildDismissibleNotification(notif, groupKey, index);
                            }),
                          ],
                        );
                      },
                    ),
    );
  }

  Future<void> _deleteNotification(Map<String, dynamic> notification) async {
    final notificationId = notification['id'] ?? '';
    
    setState(() {
      _notifications.removeWhere((n) => n['id'] == notificationId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification supprimée'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Annuler',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _notifications.add(notification);
              _notifications.sort((a, b) {
                final dateA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
                final dateB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
                return dateB.compareTo(dateA);
              });
            });
          },
        ),
      ),
    );
  }

  Widget _buildDismissibleNotification(Map<String, dynamic> notification, String groupKey, int index) {
    final notificationId = notification['id'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('notification_${notificationId}_$index'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
            size: 28,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Supprimer la notification'),
              content: const Text('Êtes-vous sûr de vouloir supprimer cette notification ?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (direction) {
          _deleteNotification(notification);
        },
        child: _buildNotificationCard(notification),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'pending';
    final color = _getNotificationColor(type);
    final icon = _getNotificationIcon(type);
    final title = notification['title'] ?? '';
    final description = notification['description'] ?? '';
    final appointmentDate = notification['appointmentDate'] ?? '';
    final createdAt = notification['createdAt'] ?? '';
    final isRead = notification['isRead'] ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône de notification
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (appointmentDate.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatAppointmentDate(appointmentDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Heure de réception
          Text(
            _formatTime(createdAt),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Une erreur est survenue',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
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
          Icon(Icons.notifications_none, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(fontSize: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas de notifications pour le moment',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
