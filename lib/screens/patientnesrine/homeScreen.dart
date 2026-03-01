import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../patientnesrine/notifications_screen.dart';
import '../patientnesrine/doctor_detail_sheet.dart';
import '../../core/theme/app_colors.dart';
import '../patientnesrine/doctor.dart';
import '../patientnesrine/profile_screen.dart';
import '../patientnesrine/doctors_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unreadNotificationCount = 0;
  List<Map<String, dynamic>> _topDoctors = [];
  bool _topDoctorsLoading = true;
  List<Map<String, dynamic>> _prescriptions = [];
  bool _prescriptionsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadTopDoctors();
    _loadPrescriptions();
  }

  Future<void> _loadPrescriptions() async {
    setState(() => _prescriptionsLoading = true);
    try {
      final list = await ApiService.getMyPrescriptions();
      if (mounted) setState(() { _prescriptions = list; _prescriptionsLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _prescriptions = []; _prescriptionsLoading = false; });
    }
  }

  Future<void> _loadTopDoctors() async {
    setState(() => _topDoctorsLoading = true);
    try {
      final list = await ApiService.searchDoctors();
      if (mounted) setState(() { _topDoctors = list; _topDoctorsLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _topDoctors = []; _topDoctorsLoading = false; });
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final data = await ApiService.getUnreadNotificationsCount();
      final count = data['unreadCount'] is int ? data['unreadCount'] as int : 0;
      if (mounted) setState(() => _unreadNotificationCount = count);
    } catch (_) {
      if (mounted) setState(() => _unreadNotificationCount = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Gradient Background
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.colored(AppColors.primary),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Bonjour,", // French greeting
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9), // Changed withValues to withOpacity
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                final name = auth.user != null
                                    ? " ${auth.user!.fullName}"
                                    : "Patient";
                                return Text(
                                  name,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildNotificationButton(context),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Enhanced Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.small,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search for doctors, specialties...",
                    hintStyle: GoogleFonts.poppins(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.search, color: Colors.white, size: 20),
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Categories with Gradient Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryCard(
                    icon: Icons.psychology,
                    label: "Neuro",
                    gradient: const LinearGradient(colors: [Color(0xFFFF6B9D), Color(0xFFFF8E9E)]),
                  ),
                  _buildCategoryCard(
                    icon: Icons.favorite,
                    label: "Cardio",
                    gradient: const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
                  ),
                  _buildCategoryCard(
                    icon: Icons.accessibility_new,
                    label: "Ortho",
                    gradient: const LinearGradient(colors: [Color(0xFFFF9B71), Color(0xFFFFB88C)]),
                  ),
                  _buildCategoryCard(
                    icon: Icons.healing,
                    label: "Pulmo",
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8F89FF)]),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Upcoming Appointment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Upcoming Appointment",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    "See All",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Premium Appointment Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8F89FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: AppColors.colored(AppColors.primary),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: const CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.white,
                                  child: Icon(Icons.person, color: AppColors.primary, size: 28),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Dr. Jennifer Smith",
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Orthopedic Consultation",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Wed, 7 Sep 2024",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, color: Colors.white, size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      "10:30 AM",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
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
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Mes ordonnances
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Mes ordonnances",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _prescriptionsLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                    )
                  : _prescriptions.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppColors.prescription.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.prescription.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.description_outlined, color: AppColors.prescription.withOpacity(0.8), size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Aucune ordonnance pour le moment",
                                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textGrey),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: _prescriptions.take(5).map((p) => _buildPrescriptionCard(p)).toList(),
                        ),
              const SizedBox(height: 28),

              // Top Doctors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Top Doctors",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorsListScreen()));
                      _loadTopDoctors();
                    },
                    child: Text(
                      "Voir tout",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 200,
                child: _topDoctorsLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _topDoctors.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun médecin disponible',
                              style: GoogleFonts.poppins(color: AppColors.textGrey, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _topDoctors.length,
                            itemBuilder: (context, index) {
                              final d = _topDoctors[index];
                              final u = d['userId'];
                              final doctorId = u is Map ? u['_id']?.toString() : u?.toString();
                              final doctor = Doctor(
                                name: d['fullName'] ?? 'Médecin',
                                specialty: d['speciality'] ?? 'Médecine générale',
                                hospital: d['hospital'] ?? '',
                                rating: 4.5,
                                reviews: 0,
                                experience: (d['yearsOfExperience'] as num?)?.toInt() ?? 0,
                                about: '',
                                imagePath: '',
                              );
                              return Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: _buildDoctorCard(context, doctor, doctorId: doctorId),
                              );
                            },
                          ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> p) {
    final doctorId = p['doctorId'];
    String doctorName = 'Médecin';
    if (doctorId is Map && doctorId['email'] != null) {
      doctorName = doctorId['fullName'] ?? doctorId['email'] ?? 'Médecin';
    }
    final meds = p['medications'] as List? ?? [];
    final firstMed = meds.isNotEmpty && meds[0] is Map ? '${(meds[0] as Map)['name']} ${(meds[0] as Map)['dosage']}' : null;
    final status = p['status'] as String? ?? 'active';
    final date = p['prescriptionDate'] != null
        ? DateFormat('dd MMM yyyy', 'fr').format(DateTime.parse(p['prescriptionDate'].toString()))
        : (p['createdAt'] != null ? DateFormat('dd MMM yyyy', 'fr').format(DateTime.parse(p['createdAt'].toString())) : '--');
    final statusLabel = status == 'active' ? 'Active' : status == 'completed' ? 'Complétée' : 'Annulée';
    final statusColor = status == 'active' ? AppColors.prescription : status == 'completed' ? AppColors.success : AppColors.textGrey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        border: Border.all(color: AppColors.prescription.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.prescription.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded, color: AppColors.prescription, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
                if (firstMed != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      firstMed,
                      style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Text(date, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textGrey)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(statusLabel, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
        _loadUnreadCount();
        _loadPrescriptions();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
          ),
          if (_unreadNotificationCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
  }) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.medium,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor, {String? doctorId}) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DoctorDetailSheet(doctor: doctor, doctorId: doctorId),
        );
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(Icons.person, size: 32, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty,
                        style: GoogleFonts.poppins(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFB800), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${doctor.rating}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            " (${doctor.reviews})",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Book Appointment",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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