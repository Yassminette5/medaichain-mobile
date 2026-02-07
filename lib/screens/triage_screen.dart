import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/patient_queue_item.dart';
import '../theme/app_theme.dart';

class TriageScreen extends StatefulWidget {
  const TriageScreen({super.key});

  @override
  State<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends State<TriageScreen> {
  // Mock List
  final List<PatientQueueItem> _queue = [
    PatientQueueItem(
      id: '1',
      name: 'Jean Dupont',
      symptom: 'Douleur thoracique aiguë',
      severityScore: 9,
      arrivalTime: DateTime.now().subtract(const Duration(minutes: 5)),
      estimatedWaitMinutes: 0,
    ),
    PatientQueueItem(
      id: '2',
      name: 'Marie Currie',
      symptom: 'Fièvre modérée',
      severityScore: 4,
      arrivalTime: DateTime.now().subtract(const Duration(minutes: 20)),
      estimatedWaitMinutes: 45,
    ),
    PatientQueueItem(
      id: '3',
      name: 'Paul Durand',
      symptom: 'Fracture ouverte',
      severityScore: 8,
      arrivalTime: DateTime.now().subtract(const Duration(minutes: 10)),
      estimatedWaitMinutes: 5,
    ),
    PatientQueueItem(
      id: '4',
      name: 'Alice Leroi',
      symptom: 'Migraine',
      severityScore: 2,
      arrivalTime: DateTime.now().subtract(const Duration(minutes: 30)),
      estimatedWaitMinutes: 60,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Sort by severity (descending) -> AI Logic Simulation
    _queue.sort((a, b) => b.severityScore.compareTo(a.severityScore));
  }

  Color _getPriorityColor(int score) {
    if (score >= 8) return AppTheme.error; // Red
    if (score >= 5) return AppTheme.warning; // Amber
    return AppTheme.success; // Green
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'File d\'Attente Intelligente',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.tune_rounded, size: 20, color: AppTheme.darkNavy),
            ),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _queue.length,
              separatorBuilder: (c, i) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final patient = _queue[index];
                return _buildPatientCard(patient);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem("Urgence Haute", "2", AppTheme.error),
          Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.1)),
          _buildStatItem("Moyenne", "1", AppTheme.warning),
          Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.1)),
          _buildStatItem("Stable", "1", AppTheme.success),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(PatientQueueItem patient) {
    final color = _getPriorityColor(patient.severityScore);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority Indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            patient.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkNavy,
                            ),
                          ),
                          _buildWaitTime(patient.estimatedWaitMinutes),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        patient.symptom,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Tags Row
                      Row(
                        children: [
                          _buildTag(
                            "Priorité ${patient.priorityLevel}", 
                            color, 
                            color.withValues(alpha: 0.1)
                          ),
                          const SizedBox(width: 10),
                          _buildTag(
                            "IA Score: ${patient.severityScore}/10", 
                            Colors.blueGrey, 
                            Colors.blueGrey.withValues(alpha: 0.05)
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
      ),
    );
  }

  Widget _buildWaitTime(int minutes) {
    bool isUrgent = minutes <= 10;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.red.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_filled_rounded, 
            size: 14, 
            color: isUrgent ? Colors.red : Colors.grey[600]
          ),
          const SizedBox(width: 6),
          Text(
            minutes == 0 ? "~ 0 min" : "~ $minutes min",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
