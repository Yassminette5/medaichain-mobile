import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medaichainmobile/clinique/theme/app_theme.dart';
import 'package:medaichainmobile/services/api_service.dart';
import 'package:intl/intl.dart';

class InvoicesView extends StatefulWidget {
  const InvoicesView({super.key});

  @override
  State<InvoicesView> createState() => _InvoicesViewState();
}

class _InvoicesViewState extends State<InvoicesView> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      setState(() => _isLoading = true);
      final invoices = await ApiService.getInvoices();
      if (mounted) {
        setState(() {
          _invoices = invoices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _filteredInvoices {
    if (_filterStatus == 'all') return _invoices;
    return _invoices.where((i) => i['paymentStatus'] == _filterStatus).toList();
  }

  double get _totalRevenue {
    double total = 0;
    for (var inv in _invoices) {
      if (inv['paymentStatus'] == 'paid') total += (inv['totalAmount'] ?? 0).toDouble();
    }
    return total;
  }

  double get _totalPending {
    double total = 0;
    for (var inv in _invoices) {
      if (inv['paymentStatus'] == 'pending') total += (inv['amountDue'] ?? 0).toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ======= FINANCE SUMMARY =======
        Row(
          children: [
            Expanded(child: _buildFinanceCard(
              'Revenus Totaux',
              '${_formatMoney(_totalRevenue)} DA',
              Icons.account_balance_wallet_rounded,
              AppTheme.success,
              const LinearGradient(colors: [Color(0xFF059669), Color(0xFF34D399)]),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildFinanceCard(
              'En Attente',
              '${_formatMoney(_totalPending)} DA',
              Icons.pending_actions_rounded,
              AppTheme.warning,
              const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildFinanceCard(
              'Factures',
              '${_invoices.length}',
              Icons.receipt_long_rounded,
              AppTheme.primaryMedical,
              AppTheme.primaryGradient,
            )),
          ],
        ),
        const SizedBox(height: 24),

        // ======= HEADER + ACTIONS =======
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.receipt_long_rounded, color: AppTheme.success, size: 18),
                ),
                const SizedBox(width: 12),
                Text('Factures', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.darkNavy)),
              ],
            ),
            Row(
              children: [
                // Filter chips
                _buildFilterChip('Toutes', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Payées', 'paid'),
                const SizedBox(width: 8),
                _buildFilterChip('En attente', 'pending'),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCreateInvoiceDialog(),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text('Nouvelle Facture', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ======= INVOICES LIST =======
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredInvoices.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredInvoices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _buildInvoiceCard(_filteredInvoices[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildFinanceCard(String label, String value, IconData icon, Color color, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    bool isActive = _filterStatus == status;
    return InkWell(
      onTap: () => setState(() => _filterStatus = status),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryMedical : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? AppTheme.primaryMedical : AppTheme.dividerLight),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(dynamic invoice) {
    final status = invoice['paymentStatus'] ?? 'pending';
    final statusInfo = _getPaymentStatusInfo(status);
    final items = (invoice['items'] as List?) ?? [];
    final date = invoice['date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice['date'])) : '-';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerLight.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8)],
      ),
      child: Row(
        children: [
          // Invoice icon with number
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusInfo['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_rounded, color: statusInfo['color'], size: 22),
          ),
          const SizedBox(width: 16),

          // Invoice info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      invoice['invoiceNumber'] ?? 'FAC-???',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppTheme.darkNavy, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text('• $date', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_rounded, size: 14, color: AppTheme.textSecondary.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      invoice['patientName'] ?? 'Patient',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        '${items.length} prestation(s)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_formatMoney((invoice['totalAmount'] ?? 0).toDouble())} DA',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusInfo['label'],
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: statusInfo['color']),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Actions
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.more_vert_rounded, color: AppTheme.darkNavy, size: 18),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) async {
              if (val == 'pay') {
                await ApiService.updateInvoice(invoice['_id'], {
                  'paymentStatus': 'paid',
                  'amountPaid': invoice['totalAmount'],
                  'amountDue': 0,
                  'paidAt': DateTime.now().toIso8601String(),
                });
                _loadInvoices();
              } else if (val == 'delete') {
                await ApiService.deleteInvoice(invoice['_id']);
                _loadInvoices();
              } else if (val == 'view') {
                _showInvoiceDetail(invoice);
              }
            },
            itemBuilder: (_) => [
              _popupItem('view', 'Voir détails', Icons.visibility_rounded, AppTheme.primaryMedical),
              if (status == 'pending')
                _popupItem('pay', 'Marquer payée', Icons.check_circle_rounded, AppTheme.success),
              _popupItem('delete', 'Supprimer', Icons.delete_rounded, AppTheme.error),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String value, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
        ],
      ),
    );
  }

  // ======= CREATE INVOICE DIALOG =======
  void _showCreateInvoiceDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    List<Map<String, dynamic>> items = [
      {'label': 'Consultation', 'quantity': 1, 'unitPrice': 2000},
    ];
    String paymentMethod = 'cash';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          double subtotal = 0;
          for (var item in items) {
            subtotal += (item['quantity'] ?? 1) * (item['unitPrice'] ?? 0);
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.receipt_long_rounded, color: AppTheme.success, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Nouvelle Facture', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.darkNavy)),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Patient', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.darkNavy)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _dialogField(nameCtrl, 'Nom du patient', Icons.person_rounded)),
                        const SizedBox(width: 12),
                        Expanded(child: _dialogField(phoneCtrl, 'Téléphone', Icons.phone_rounded)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Prestations', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.darkNavy)),
                        TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              items.add({'label': '', 'quantity': 1, 'unitPrice': 0});
                            });
                          },
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text('Ajouter', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(items.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                decoration: _fieldDecor('Prestation'),
                                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                controller: TextEditingController(text: items[i]['label']),
                                onChanged: (v) => items[i]['label'] = v,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 60,
                              child: TextField(
                                decoration: _fieldDecor('Qté'),
                                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(text: items[i]['quantity'].toString()),
                                onChanged: (v) {
                                  setDialogState(() {
                                    items[i]['quantity'] = int.tryParse(v) ?? 1;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: TextField(
                                decoration: _fieldDecor('Prix (DA)'),
                                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                                keyboardType: TextInputType.number,
                                controller: TextEditingController(text: items[i]['unitPrice'].toString()),
                                onChanged: (v) {
                                  setDialogState(() {
                                    items[i]['unitPrice'] = int.tryParse(v) ?? 0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (items.length > 1)
                              IconButton(
                                onPressed: () => setDialogState(() => items.removeAt(i)),
                                icon: Icon(Icons.close_rounded, size: 18, color: AppTheme.error.withOpacity(0.7)),
                                splashRadius: 16,
                              ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    // Payment method
                    Text('Moyen de paiement', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.darkNavy)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _paymentMethodChip('cash', 'Espèces', Icons.payments_rounded, paymentMethod, (v) => setDialogState(() => paymentMethod = v)),
                        const SizedBox(width: 8),
                        _paymentMethodChip('card', 'Carte', Icons.credit_card_rounded, paymentMethod, (v) => setDialogState(() => paymentMethod = v)),
                        const SizedBox(width: 8),
                        _paymentMethodChip('insurance', 'Assurance', Icons.shield_rounded, paymentMethod, (v) => setDialogState(() => paymentMethod = v)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.dividerLight),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                          Text(
                            '${_formatMoney(subtotal)} DA',
                            style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Annuler', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  try {
                    // Nettoyage strict des items pour éviter les problèmes de whitelisting du backend
                    final cleanItems = items.map((item) => {
                      'label': item['label'],
                      'quantity': item['quantity'],
                      'unitPrice': item['unitPrice'],
                    }).toList();

                    await ApiService.createInvoice(
                      patientId: ApiService.generateObjectId(),
                      patientName: nameCtrl.text,
                      items: cleanItems,
                      paymentMethod: paymentMethod,
                    );
                    Navigator.pop(ctx);
                    _loadInvoices();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e'), backgroundColor: AppTheme.error),
                    );
                  }
                },
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text('Créer Facture', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentMethodChip(String value, String label, IconData icon, String selected, ValueChanged<String> onTap) {
    bool isActive = selected == value;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryMedical.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isActive ? AppTheme.primaryMedical : AppTheme.dividerLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? AppTheme.primaryMedical : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? AppTheme.primaryMedical : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ======= INVOICE DETAIL =======
  void _showInvoiceDetail(dynamic invoice) {
    final items = (invoice['items'] as List?) ?? [];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0A1628), Color(0xFF1A4B8C)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('FACTURE', style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                        Text(invoice['invoiceNumber'] ?? '', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Patient', style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                            Text(invoice['patientName'] ?? '-', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Date', style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                            Text(
                              invoice['date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice['date'])) : '-',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Items table
              Container(
                decoration: BoxDecoration(border: Border.all(color: AppTheme.dividerLight), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text('Prestation', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary))),
                          Expanded(child: Text('Qté', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
                          Expanded(child: Text('P.U', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary), textAlign: TextAlign.right)),
                          Expanded(child: Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary), textAlign: TextAlign.right)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(item['label'] ?? '', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.darkNavy))),
                          Expanded(child: Text('${item['quantity'] ?? 1}', style: GoogleFonts.plusJakartaSans(fontSize: 13), textAlign: TextAlign.center)),
                          Expanded(child: Text('${_formatMoney((item['unitPrice'] ?? 0).toDouble())}', style: GoogleFonts.plusJakartaSans(fontSize: 13), textAlign: TextAlign.right)),
                          Expanded(child: Text('${_formatMoney((item['total'] ?? 0).toDouble())}', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Totals
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text('Sous-total: ', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                          Text('${_formatMoney((invoice['subtotal'] ?? 0).toDouble())} DA', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.darkNavy)),
                        ],
                      ),
                      if ((invoice['discount'] ?? 0) > 0)
                        Row(
                          children: [
                            Text('Remise: ', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
                            Text('-${_formatMoney((invoice['discount'] ?? 0).toDouble())} DA', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.error)),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text('Total: ', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
                            Text('${_formatMoney((invoice['totalAmount'] ?? 0).toDouble())} DA', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.success)),
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
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Fermer', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  InputDecoration _fieldDecor(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 12),
      filled: true,
      fillColor: AppTheme.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.dividerLight.withOpacity(0.5))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.dividerLight.withOpacity(0.5))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryMedical)),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.plusJakartaSans(fontSize: 13),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textSecondary),
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 13),
        filled: true,
        fillColor: AppTheme.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Map<String, dynamic> _getPaymentStatusInfo(String status) {
    switch (status) {
      case 'paid': return {'label': 'Payée', 'color': AppTheme.success};
      case 'pending': return {'label': 'En attente', 'color': AppTheme.warning};
      case 'partial': return {'label': 'Partiel', 'color': AppTheme.primaryMedical};
      case 'cancelled': return {'label': 'Annulée', 'color': AppTheme.error};
      default: return {'label': status, 'color': Colors.grey};
    }
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.06), shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_rounded, size: 48, color: AppTheme.success.withOpacity(0.4)),
          ),
          const SizedBox(height: 20),
          Text('Aucune facture', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.darkNavy)),
          const SizedBox(height: 8),
          Text('Créez votre première facture en cliquant sur le bouton ci-dessus', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
