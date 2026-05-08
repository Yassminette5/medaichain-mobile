import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medaichainmobile/core/theme/app_colors.dart';
import 'package:medaichainmobile/services/api_service.dart';
import 'package:intl/intl.dart';

class CliniqueFinanceTab extends StatefulWidget {
  const CliniqueFinanceTab({super.key});

  @override
  State<CliniqueFinanceTab> createState() => _CliniqueFinanceTabState();
}

class _CliniqueFinanceTabState extends State<CliniqueFinanceTab> with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _invoicesFuture;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    
    _loadData();
  }

  void _loadData() {
    setState(() {
      _invoicesFuture = ApiService.getInvoices();
    });
    _invoicesFuture.then((_) {
      if (mounted) _fadeController.forward(from: 0);
    }).catchError((_) {
      if (mounted) _fadeController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  double _calculateTotal(List<dynamic> invoices, String? status) {
    double total = 0;
    for (var inv in invoices) {
      if (status == null || inv['paymentStatus'] == status) {
        if (status == 'pending') {
           total += (inv['amountDue'] ?? 0).toDouble();
        } else {
           total += (inv['totalAmount'] ?? 0).toDouble();
        }
      }
    }
    return total;
  }

  String _formatMoney(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            _loadData();
            await _invoicesFuture;
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                backgroundColor: AppColors.background,
                elevation: 0,
                pinned: true,
                title: Text(
                  'Facturation',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: false,
              ),
              
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: FutureBuilder<List<dynamic>>(
                    future: _invoicesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 50.0),
                            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                          )
                        );
                      }
                      
                      final invoices = snapshot.data ?? [];
                      final totalRevenue = _calculateTotal(invoices, 'paid');
                      final totalPending = _calculateTotal(invoices, 'pending');

                      // Filter
                      final filteredInvoices = invoices.where((i) {
                        if (_filterStatus == 'all') return true;
                        return i['paymentStatus'] == _filterStatus;
                      }).toList();

                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              // Finance Summary Cards
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSummaryCard(
                                      'Revenus Totaux',
                                      '${_formatMoney(totalRevenue)} DA',
                                      Icons.account_balance_wallet_rounded,
                                      const Color(0xFF1E3A8A), // Deep Blue
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _buildSummaryCard(
                                      'En Attente',
                                      '${_formatMoney(totalPending)} DA',
                                      Icons.pending_actions_rounded,
                                      const Color(0xFF3B82F6), // Blue
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 24),
                            
                            // Filters
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: Row(
                                children: [
                                  _buildFilterChip('Toutes', 'all'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Payées', 'paid'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('En attente', 'pending'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('Annulées', 'cancelled'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Invoices List
                            if (filteredInvoices.isEmpty)
                              _buildEmptyState()
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredInvoices.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (_, i) => _buildInvoiceCard(filteredInvoices[i]),
                              ),
                              
                            const SizedBox(height: 100),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    // Generate a sleek gradient based on the base color
    final gradientStart = color.withValues(alpha: 0.9);
    final gradientEnd = color.withValues(alpha: 0.7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.trending_up_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    bool isActive = _filterStatus == status;
    return InkWell(
      onTap: () => setState(() => _filterStatus = status),
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? const Color(0xFF1E3A8A) : AppColors.border.withValues(alpha: 0.5),
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getPaymentStatusInfo(String status) {
    switch (status) {
      case 'paid': return {'label': 'Payée', 'color': const Color(0xFF10B981)};
      case 'pending': return {'label': 'En attente', 'color': const Color(0xFFF59E0B)};
      case 'partial': return {'label': 'Partiel', 'color': const Color(0xFF6366F1)};
      case 'cancelled': return {'label': 'Annulée', 'color': const Color(0xFFEF4444)};
      default: return {'label': status, 'color': const Color(0xFF94A3B8)};
    }
  }

  Widget _buildInvoiceCard(dynamic invoice) {
    final status = invoice['paymentStatus'] ?? 'pending';
    final statusInfo = _getPaymentStatusInfo(status);
    final date = invoice['date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(invoice['date'])) : '-';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [(statusInfo['color'] as Color).withValues(alpha: 0.2), (statusInfo['color'] as Color).withValues(alpha: 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: (statusInfo['color'] as Color).withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.receipt_long_rounded, color: statusInfo['color'], size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          invoice['patientName'] ?? 'Patient Anonyme',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          date,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      invoice['invoiceNumber'] ?? 'FAC-???',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (statusInfo['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: (statusInfo['color'] as Color).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusInfo['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusInfo['label'],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: statusInfo['color'],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_formatMoney((invoice['totalAmount'] ?? 0).toDouble())} DA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E3A8A),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_rounded, size: 48, color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune facture',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucune facture ne correspond au filtre actuel.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
