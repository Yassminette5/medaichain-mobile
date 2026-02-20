import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

class DocumentListScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;

  const DocumentListScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradient.colors.first.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(icon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.description, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "8 Documents",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.cloud_done, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "All Synced",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Document List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: 8,
                itemBuilder: (context, index) {
                  return _buildDocumentCard(context, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard(BuildContext context, int index) {
    final List<Map<String, dynamic>> documents = [
      {
        "name": "Blood Test Results",
        "date": "Dec 15, 2024",
        "size": "2.4 MB",
        "type": "PDF",
        "status": "Verified",
        "color": const Color(0xFFFF6B9D),
      },
      {
        "name": "X-Ray Chest",
        "date": "Dec 10, 2024",
        "size": "5.1 MB",
        "type": "IMAGE",
        "status": "Pending",
        "color": const Color(0xFF6C63FF),
      },
      {
        "name": "Medical Certificate",
        "date": "Dec 5, 2024",
        "size": "1.2 MB",
        "type": "PDF",
        "status": "Verified",
        "color": const Color(0xFF4ECDC4),
      },
      {
        "name": "Prescription - Amoxicillin",
        "date": "Nov 28, 2024",
        "size": "0.8 MB",
        "type": "PDF",
        "status": "Active",
        "color": const Color(0xFFFF9B71),
      },
      {
        "name": "ECG Report",
        "date": "Nov 20, 2024",
        "size": "3.2 MB",
        "type": "PDF",
        "status": "Verified",
        "color": const Color(0xFFB4A5FF),
      },
      {
        "name": "Vaccination Record",
        "date": "Nov 15, 2024",
        "size": "1.5 MB",
        "type": "PDF",
        "status": "Verified",
        "color": const Color(0xFF44A08D),
      },
      {
        "name": "Allergy Test",
        "date": "Nov 10, 2024",
        "size": "2.1 MB",
        "type": "PDF",
        "status": "Pending",
        "color": const Color(0xFFFF8E9E),
      },
      {
        "name": "Annual Checkup",
        "date": "Oct 30, 2024",
        "size": "4.3 MB",
        "type": "PDF",
        "status": "Verified",
        "color": const Color(0xFF8F89FF),
      },
    ];

    final doc = documents[index % documents.length];
    final bool isVerified = doc["status"] == "Verified";
    final bool isActive = doc["status"] == "Active";

    return GestureDetector(
      onTap: () {
        // Open document viewer
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (doc["color"] as Color).withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Gradient accent on the left
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        doc["color"] as Color,
                        (doc["color"] as Color).withOpacity(0.5),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Document Icon with gradient background
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (doc["color"] as Color).withOpacity(0.2),
                            (doc["color"] as Color).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          doc["type"] == "PDF" ? Icons.picture_as_pdf : Icons.image,
                          color: doc["color"] as Color,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Document Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doc["name"],
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isVerified
                                      ? const Color(0xFF4ECDC4).withOpacity(0.15)
                                      : isActive
                                      ? const Color(0xFFFF9B71).withOpacity(0.15)
                                      : const Color(0xFFFFB88C).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isVerified
                                          ? Icons.verified
                                          : isActive
                                          ? Icons.access_time
                                          : Icons.pending,
                                      size: 12,
                                      color: isVerified
                                          ? const Color(0xFF4ECDC4)
                                          : isActive
                                          ? const Color(0xFFFF9B71)
                                          : const Color(0xFFFFB88C),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      doc["status"],
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isVerified
                                            ? const Color(0xFF4ECDC4)
                                            : isActive
                                            ? const Color(0xFFFF9B71)
                                            : const Color(0xFFFFB88C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Date and Size
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 13, color: AppColors.textGrey),
                              const SizedBox(width: 6),
                              Text(
                                doc["date"],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.textGrey.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Icon(Icons.storage, size: 13, color: AppColors.textGrey),
                              const SizedBox(width: 6),
                              Text(
                                doc["size"],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Action Buttons
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Share document
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (doc["color"] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.share_outlined,
                              color: doc["color"] as Color,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            _showDocumentOptions(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.more_horiz,
                              color: AppColors.textMedium,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            _buildOptionTile(Icons.visibility_outlined, "View Document", AppColors.primary),
            _buildOptionTile(Icons.download_outlined, "Download", const Color(0xFF4ECDC4)),
            _buildOptionTile(Icons.edit_outlined, "Rename", const Color(0xFFFF9B71)),
            _buildOptionTile(Icons.delete_outline, "Delete", const Color(0xFFFF6B9D)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}