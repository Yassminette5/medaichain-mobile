import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../utils/app_images.dart';

class DoctorPlanningScreen extends StatefulWidget {
  const DoctorPlanningScreen({super.key});

  @override
  State<DoctorPlanningScreen> createState() => _DoctorPlanningScreenState();
}

enum DoctorStatus { available, busy, absent }

class Doctor {
  final String name;
  final String specialty;
  final String imageUrl;
  DoctorStatus status;

  Doctor({
    required this.name, 
    required this.specialty, 
    required this.imageUrl,
    this.status = DoctorStatus.available
  });
}

class _DoctorPlanningScreenState extends State<DoctorPlanningScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<Doctor> _doctors = [
    Doctor(name: "Dr. House", specialty: "Diagnosticien", status: DoctorStatus.busy, imageUrl: "https://i.pravatar.cc/150?img=11"),
    Doctor(name: "Dr. Watson", specialty: "Chirurgie", status: DoctorStatus.available, imageUrl: "https://i.pravatar.cc/150?img=33"),
    Doctor(name: "Dr. Strange", specialty: "Neurochirurgie", status: DoctorStatus.absent, imageUrl: "https://i.pravatar.cc/150?img=12"),
    Doctor(name: "Dr. Grey", specialty: "Généraliste", status: DoctorStatus.available, imageUrl: "https://i.pravatar.cc/150?img=24"),
  ];

  late Doctor _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedDoctor = _doctors[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: AppImages.provider(AppImages.doctor, AppImages.doctorUrl),
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Planning Médecins",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Gérez les disponibilités et rendez-vous",
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 14,
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

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Personnel Disponible",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkNavy,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDoctorSelector(),
        const SizedBox(height: 24),
        Container(
          color: AppTheme.background,
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            children: [
               _buildCalendar(),
              const SizedBox(height: 24),
              _buildTimeSlots(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorSelector() {
    return SizedBox(
      height: 120, // Increased height for better spacing
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5), // Added vertical padding
        scrollDirection: Axis.horizontal,
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          final isSelected = doctor == _selectedDoctor;
          return GestureDetector(
            onTap: () => setState(() => _selectedDoctor = doctor),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 16),
              width: 85, // Slightly wider
              decoration: isSelected 
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50), // Pill shape when selected
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  )
                : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 32, // Larger avatar
                          backgroundImage: NetworkImage(doctor.imageUrl),
                          onBackgroundImageError: (_, __) {
                            // Silent fallback handled by widget if needed, 
                            // but NetworkImage doesn't support fallback builder directly here easily without complex widgets. 
                            // We rely on valid URLs or existing code robustness.
                          },
                        ),
                      ),
                      _buildStatusDot(doctor.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryBlue : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusDot(DoctorStatus status) {
    Color color;
    switch (status) {
      case DoctorStatus.available: color = AppTheme.success; break;
      case DoctorStatus.busy: color = AppTheme.warning; break;
      case DoctorStatus.absent: color = Colors.grey; break;
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2), // White border for clearer visibility
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onFormatChanged: (format) {
          if (_calendarFormat != format) {
            setState(() {
              _calendarFormat = format;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: AppTheme.darkNavy,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppTheme.darkNavy),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppTheme.darkNavy),
        ),
      ),
    );
  }

  Widget _buildTimeSlots() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Agenda du ${_selectedDay?.day}/${_selectedDay?.month}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkNavy,
                ),
              ),
              _buildStatusChip(_selectedDoctor.status),
            ],
          ),
          const SizedBox(height: 24),
          _buildTimeSlotItem("09:00", "Consultation Initiale", true),
          _buildTimeSlotItem("10:00", "Suivi Post-op", false),
          _buildTimeSlotItem("11:30", "Urgence", true),
          _buildTimeSlotItem("14:00", "Disponible", false, isAvailable: true),
          _buildTimeSlotItem("15:00", "Disponible", false, isAvailable: true),
        ],
      ),
    );
  }

  Widget _buildStatusChip(DoctorStatus status) {
    String label;
    Color color;
    Color bgColor;
    switch (status) {
      case DoctorStatus.available:
        label = "Disponible";
        color = AppTheme.success;
        bgColor = AppTheme.success.withValues(alpha: 0.1);
        break;
      case DoctorStatus.busy:
        label = "Occupé";
        color = AppTheme.warning;
        bgColor = AppTheme.warning.withValues(alpha: 0.1);
        break;
      case DoctorStatus.absent:
        label = "Absent";
        color = Colors.grey;
        bgColor = Colors.grey.withValues(alpha: 0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color, 
          fontWeight: FontWeight.bold, 
          fontSize: 12
        ),
      ),
    );
  }

  Widget _buildTimeSlotItem(String time, String title, bool isBusy, {bool isAvailable = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAvailable ? AppTheme.primaryBlue.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAvailable ? AppTheme.primaryBlue.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: isAvailable ? [] : [
           BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              time,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold, 
                fontSize: 14,
                color: AppTheme.darkNavy,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: isAvailable ? FontWeight.bold : FontWeight.w600,
                    color: isAvailable ? AppTheme.primaryBlue : AppTheme.darkNavy,
                  ),
                ),
                if (isAvailable)
                  Text(
                    "Réserver ce créneau",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isAvailable ? AppTheme.primaryBlue : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAvailable ? Icons.add : Icons.lock_outline,
              size: 20,
              color: isAvailable ? Colors.white : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
