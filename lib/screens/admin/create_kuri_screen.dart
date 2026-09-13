import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../widgets/shared_widgets.dart';
import '../../utils/app_helpers.dart';

class CreateKuriScreen extends ConsumerStatefulWidget {
  final String shopId;
  const CreateKuriScreen({super.key, required this.shopId});

  @override
  ConsumerState<CreateKuriScreen> createState() => _CreateKuriScreenState();
}

class _CreateKuriScreenState extends ConsumerState<CreateKuriScreen> {
  final titleCtrl   = TextEditingController();
  final amountCtrl  = TextEditingController();
  final membersCtrl = TextEditingController();
  final monthsCtrl  = TextEditingController();
  DateTime startDate = DateTime.now();
  bool isLoading = false;
  String error = '';

  static const Color _primaryBlue = Color(0xFF0F4CFF);
  static const Color _primaryTeal = Color(0xFF14D8C4);
  static const Color _darkNavy    = Color(0xFF0A1F44);

  @override
  void initState() {
    super.initState();
    amountCtrl.addListener(_refresh);
    membersCtrl.addListener(_refresh);
    monthsCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    amountCtrl.removeListener(_refresh);
    membersCtrl.removeListener(_refresh);
    monthsCtrl.removeListener(_refresh);
    titleCtrl.dispose();
    amountCtrl.dispose();
    membersCtrl.dispose();
    monthsCtrl.dispose();
    super.dispose();
  }

  double get _amount  => double.tryParse(amountCtrl.text)  ?? 0;
  int    get _members => int.tryParse(membersCtrl.text)    ?? 0;
  int    get _months  => int.tryParse(monthsCtrl.text)     ?? 0;
  double get _pool    => _amount * _members;

  Future<void> _create() async {
    if (titleCtrl.text.trim().isEmpty) {
      setState(() => error = 'Please enter kuri title.');
      return;
    }
    if (_amount <= 0) {
      setState(() => error = 'Please enter a valid monthly amount.');
      return;
    }
    if (_members <= 0) {
      setState(() => error = 'Please enter a valid number of members.');
      return;
    }
    if (_months <= 0) {
      setState(() => error = 'Please enter a valid number of months.');
      return;
    }

    setState(() { isLoading = true; error = ''; });

    final err = await ref.read(kuriServiceProvider).createKuri(
      shopId:        widget.shopId,
      title:         titleCtrl.text.trim(),
      monthlyAmount: _amount,
      totalMembers:  _members,
      totalMonths:   _months,
      startDate:     startDate,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (err != null) {
      setState(() => error = err);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('✅ Kuri pool created successfully!',
          style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: _primaryTeal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primaryBlue,
            onPrimary: Colors.white,
            onSurface: _darkNavy,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('Create New Kuri',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: _darkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Live Preview Card (shows once amount + members filled) ──
          if (_amount > 0 && _members > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primaryBlue, _primaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _previewItem('Monthly', AppHelpers.formatAmount(_amount)),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3)),
                    _previewItem('Total Pool', AppHelpers.formatAmount(_pool)),
                    Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3)),
                    _previewItem('Months', '$_months'),
                  ]),
            ),

          // ── Form Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: [

              // Kuri Title
              AppTextField(
                  controller: titleCtrl,
                  label: 'Kuri Title *',
                  icon: Icons.title),
              const SizedBox(height: 16),

              // Monthly Amount
              AppTextField(
                controller: amountCtrl,
                label: 'Monthly Amount (₹) *',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number,
                
              ),
              const SizedBox(height: 20),

              // ── Total Members & Total Months — full-width with clear labels ──
              _countField(
                controller: membersCtrl,
                icon: Icons.people_alt_outlined,
                label: 'Total Members',
                hint: 'e.g. 12',
                helper: 'How many people join this kuri',
              ),
              const SizedBox(height: 16),
              _countField(
                controller: monthsCtrl,
                icon: Icons.calendar_month_outlined,
                label: 'Total Months',
                hint: 'e.g. 12',
                helper: 'Usually equals Total Members',
              ),
              const SizedBox(height: 20),

              // Start Date
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.calendar_today,
                          color: _primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Start Date',
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(AppHelpers.formatDate(startDate),
                              style: const TextStyle(
                                  color: _darkNavy,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                        ]),
                    const Spacer(),
                    Icon(Icons.edit_calendar,
                        color: Colors.grey.shade400, size: 20),
                  ]),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Info Box ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryTeal.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline, color: _primaryTeal, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: 13,
                        color: _darkNavy.withOpacity(0.8),
                        height: 1.5),
                    children: const [
                      TextSpan(
                          text: 'Total Months = Total Members. ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(
                          text:
                              'Each member wins the pool exactly once over the duration of the kuri.'),
                    ],
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 32),

          LoadingButton(
            isLoading: isLoading,
            onPressed: _create,
            label: 'Create Kuri Pool',
            icon: Icons.add_circle_outline,
            color: _primaryBlue,
          ),

          if (error.isNotEmpty) ...[
            const SizedBox(height: 16),
            ErrorMessage(message: error),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  // ── Full-width count field with label + helper text ──
  Widget _countField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    required String helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _darkNavy)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            helperStyle:
                TextStyle(fontSize: 12, color: Colors.grey.shade500),
            prefixIcon: Icon(icon, color: _primaryBlue, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: _primaryBlue, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _previewItem(String label, String value) {
    return Column(children: [
      Text(label,
          style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
    ]);
  }
}