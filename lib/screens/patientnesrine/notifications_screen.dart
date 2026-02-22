import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Notifications", style: GoogleFonts.poppins(color: AppColors.textDark, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: () {},
              child: Text("Mark all read", style: GoogleFonts.poppins(color: AppColors.primary)),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildNotificationItem(
            context,
            title: "MediCare Pharmacy responded!",
            message: "We have 'Amoxicillin 500mg' in stock. You can reserve it now.",
            time: "2 mins ago",
            icon: Icons.local_pharmacy,
            iconColor: Colors.green,
            isUnread: true,
            onTap: () {
              // Navigate to detail or map
            },
          ),
          _buildNotificationItem(
            context,
            title: "Appointment Reminder",
            message: "Upcoming consultation with Dr. Jennifer tomorrow at 10:30 AM.",
            time: "1 hour ago",
            icon: Icons.calendar_today,
            iconColor: AppColors.primary,
            isUnread: true,
            onTap: () {},
          ),
          _buildNotificationItem(
            context,
            title: "Lab Results Ready",
            message: "Your blood test analysis is ready to view.",
            time: "1 day ago",
            icon: Icons.analytics,
            iconColor: Colors.blue,
            isUnread: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, {required String title, required String message, required String time, required IconData icon, required Color iconColor, required bool isUnread, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: isUnread ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade400,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}