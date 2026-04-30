import 'package:flutter/material.dart';
import 'package:medaichainmobile/core/theme/app_colors.dart';
import 'package:medaichainmobile/services/prescriptions_service.dart';

/// Screen for doctor to view their prescriptions and transfer ownership to patient
class DoctorPrescriptionsScreen extends StatefulWidget {
  const DoctorPrescriptionsScreen({super.key});

  @override
  State<DoctorPrescriptionsScreen> createState() => _DoctorPrescriptionsScreenState();
}

class _DoctorPrescriptionsScreenState extends State<DoctorPrescriptionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await PrescriptionsService.getMyPrescriptions();
      setState(() {
        _prescriptions = list;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _transfer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Transférer à patient'),
        content: const Text('Confirmer le transfert on-chain de cette ordonnance au patient ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirmer')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isLoading = true);
      await PrescriptionsService.transferToPatient(prescriptionId: id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transfert effectué')));
        await _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes ordonnances'), backgroundColor: AppColors.primary),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _prescriptions.isEmpty
                  ? ListView(children: [Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('Aucune ordonnance')))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _prescriptions.length,
                      itemBuilder: (context, i) {
                        final p = _prescriptions[i];
                        final id = p['_id']?.toString() ?? p['id']?.toString() ?? '';
                        final patient = p['patientId'] ?? p['patient'] ?? {};
                        final patientName = (patient is Map) ? (patient['fullName'] ?? patient['name'] ?? '--') : '--';
                        final status = p['status'] ?? '--';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text('ID: $id', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(status.toString()),
                              ]),
                              const SizedBox(height: 8),
                              Text('Patient: $patientName'),
                              const SizedBox(height: 12),
                              Row(children: [
                                ElevatedButton(
                                  onPressed: () => _transfer(id),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                  child: const Text('Transférer au patient'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(onPressed: () {}, child: const Text('Voir')),
                              ])
                            ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
