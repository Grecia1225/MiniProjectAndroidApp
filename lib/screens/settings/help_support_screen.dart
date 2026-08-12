import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedIndex;
  final _reportController = TextEditingController();

  final List<Map<String, String>> _faqs = [
    {'q': 'How do I post a listing?', 'a': 'Go to the Marketplace tab and tap the + button. Fill in your product details, price per kg, and quantity. Your listing will be live instantly.'},
    {'q': 'How does shipment tracking work?', 'a': 'Once a seller confirms your order, you can track it in real-time from the Tracking tab. The status updates from Pending → Confirmed → Picked Up → In Transit → Delivered.'},
    {'q': 'How do I contact a seller?', 'a': 'Tap any listing and press the chat button. This opens a direct chat where you can negotiate and confirm the deal.'},
    {'q': 'How do I place an order?', 'a': 'Tap a listing → Add to Cart → adjust quantity → Place Order. You\'ll get a confirmation and can track it in the Shipments tab.'},
    {'q': 'What payment methods are supported?', 'a': 'Payments are handled directly between buyers and sellers. MTC does not process payments — we recommend UPI, bank transfer, or cash on delivery.'},
    {'q': 'How do I change my role?', 'a': 'Contact our support team via the Live Chat option or email support@mtc.in. Role changes are reviewed within 24 hours.'},
    {'q': 'Can I delete my account?', 'a': 'Yes. Go to Privacy & Security → Data Deletion Request. Your data will be permanently removed within 7 business days.'},
  ];

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _submitReport(AppTheme t) async {
    final text = _reportController.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user?.uid ?? 'anonymous',
        'email': user?.email ?? '',
        'message': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _reportController.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Report submitted! We\'ll get back to you within 24 hours.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context).current;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background, elevation: 0,
        leading: GestureDetector(onTap: () => Navigator.pop(context),
          child: Container(margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.primary.withOpacity(0.25))),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 15))),
        title: const Text('Help & Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [

          // Contact cards
          Row(children: [
            _contactCard(Icons.chat_bubble_outline, 'Live Chat', 'Tap to start', t, () => _showLiveChat(context, t)),
            const SizedBox(width: 12),
            _contactCard(Icons.email_outlined, 'Email Us', 'support@mtc.in', t, () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email: support@mtc.in'), behavior: SnackBarBehavior.floating));
            }),
          ]),

          const SizedBox(height: 28),

          Text('FAQs', style: TextStyle(color: t.primary.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 12),

          ...List.generate(_faqs.length, (i) {
            final isOpen = _expandedIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _expandedIndex = isOpen ? null : i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isOpen ? t.primary.withOpacity(0.4) : Colors.white.withOpacity(0.06))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(_faqs[i]['q']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
                    Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white38, size: 20),
                  ]),
                  if (isOpen) ...[
                    const SizedBox(height: 10),
                    Text(_faqs[i]['a']!, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
                  ],
                ]),
              ),
            );
          }),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () => _showReportDialog(context, t),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.redAccent.withOpacity(0.2))),
              child: const Row(children: [
                Icon(Icons.flag_outlined, color: Colors.redAccent, size: 18),
                SizedBox(width: 12),
                Text('Report a problem', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                Spacer(),
                Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 13),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showLiveChat(BuildContext context, AppTheme t) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) {
        final ctrl = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: t.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: t.primary.withOpacity(0.15))),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: t.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(Icons.support_agent, color: t.primary, size: 20)),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('MTC Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('Usually replies in 5 minutes', style: TextStyle(color: Colors.green, fontSize: 11)),
                ])),
                GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: Colors.white.withOpacity(0.4))),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(12)),
                child: Text('Hi! How can we help you today? Describe your issue and we\'ll get back to you shortly.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.5)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                  filled: true, fillColor: t.card,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (ctrl.text.trim().isEmpty) return;
                    final user = FirebaseAuth.instance.currentUser;
                    await FirebaseFirestore.instance.collection('support_chats').add({
                      'userId': user?.uid, 'email': user?.email,
                      'message': ctrl.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Message sent! We\'ll reply to your email shortly.'), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: t.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, minimumSize: const Size(double.infinity, 48)),
                  child: const Text('Send Message', style: TextStyle(fontWeight: FontWeight.w800)),
                )),
            ]),
          ),
        );
      },
    );
  }

  Widget _contactCard(IconData icon, String title, String sub, AppTheme t, VoidCallback onTap) =>
    Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: t.primary.withOpacity(0.2))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: t.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: t.primary, size: 18)),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
        ]),
      ),
    ));

  void _showReportDialog(BuildContext context, AppTheme t) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: t.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Report a problem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      content: TextField(
        controller: _reportController, maxLines: 4,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: 'Describe the issue...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          filled: true, fillColor: t.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.4)))),
        ElevatedButton(
          onPressed: () => _submitReport(t),
          style: ElevatedButton.styleFrom(backgroundColor: t.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Submit', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}