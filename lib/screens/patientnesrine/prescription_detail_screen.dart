import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../pharmacy/pharmacies_list_screen.dart';
import '../../services/api_service.dart';

class PrescriptionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> prescription;

  const PrescriptionDetailScreen({super.key, required this.prescription});

  String _formatDate(Map<String, dynamic> p) {
    final dateStr = p['prescriptionDate'] ?? p['createdAt'];
    if (dateStr == null) return '--';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = prescription['doctorId'];
    final doctorName = (doctor is Map) ? (doctor['fullName'] ?? doctor['email'] ?? 'Médecin') : (doctor?.toString() ?? 'Médecin');
    final meds = (prescription['medications'] as List?) ?? [];
    final rawUrl = prescription['prescriptionImageUrl']?.toString();
    String? imageUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      imageUrl = rawUrl.startsWith('http') ? rawUrl : '${ApiService.baseUrl}${rawUrl.startsWith('/') ? '' : '/'}$rawUrl';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Détails de l\'ordonnance', style: GoogleFonts.poppins(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctorName, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Row(children: [Icon(Icons.calendar_today, size: 14, color: AppColors.textGrey), const SizedBox(width: 6), Text(_formatDate(prescription), style: GoogleFonts.poppins(color: AppColors.textGrey))]),
                    const SizedBox(height: 12),
                    if (imageUrl != null) ...[
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: InteractiveViewer(child: Image.network(imageUrl!, fit: BoxFit.contain)),
                            ),
                          );
                        },
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.15))),
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(imageUrl!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (meds.isNotEmpty) ...[
                      Text('Médicaments', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      ...meds.map((m) {
                        final name = (m is Map) ? (m['name'] ?? '') : m.toString();
                        final dosage = (m is Map) ? (m['dosage'] ?? '') : '';
                        final qty = (m is Map) ? (m['quantity']?.toString() ?? '') : '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text('$name ${dosage ?? ''}', style: GoogleFonts.poppins())),
                              if (qty.isNotEmpty) Text(qty, style: GoogleFonts.poppins(color: AppColors.textGrey)),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const PharmaciesListScreen()));
                            },
                            icon: const Icon(Icons.local_pharmacy_outlined, size: 18),
                            label: const Text('Partager avec pharmacie', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.prescription, padding: const EdgeInsets.symmetric(horizontal: 4)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context), 
                            icon: const Icon(Icons.close, size: 18), 
                            label: const Text('Fermer', maxLines: 1, overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
