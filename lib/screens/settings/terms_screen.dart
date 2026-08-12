import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context).current;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.primary.withOpacity(0.25))),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 15))),
        title: const Text('Terms & Conditions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Last updated: May 2026', style: TextStyle(color: t.primary.withOpacity(0.6), fontSize: 12)),
          const SizedBox(height: 16),
          _section('1. Acceptance of Terms', 'By downloading, registering, or using the Marine Trade Connect (MTC) application, you agree to be legally bound by these Terms and Conditions. If you disagree with any part of these terms, you must not use the application.', t),
          _section('2. Eligibility & User Accounts', 'You must be at least 18 years of age to register and use MTC. By creating an account, you confirm that all information provided is accurate, current, and complete. You are solely responsible for maintaining the confidentiality of your login credentials.', t),
          _section('3. User Roles', 'MTC offers three roles — Buyer, Seller, and Agent. Buyers may browse and purchase listed goods. Sellers may post listings and manage orders. Agents may facilitate deals between buyers and sellers.', t),
          _section('4. Marketplace Listings', 'All listings posted on MTC must be genuine, accurately described, and legally permitted for trade. MTC reserves the right to remove any listing that is misleading, fraudulent, or violates applicable laws without prior notice.', t),
          _section('5. Transactions & Payments', 'MTC is a marketplace platform and does not process, hold, or guarantee any payments. All financial transactions occur directly between the buyer and seller. MTC is not a party to any transaction.', t),
          _section('6. Shipments & Tracking', 'Shipment tracking features on MTC are provided for informational purposes only. MTC does not operate, own, or guarantee any logistics or delivery services.', t),
          _section('7. Prohibited Conduct', 'Users must not post false or fraudulent listings, impersonate other users, engage in harassment, use the platform to trade in illegal goods, or attempt to reverse-engineer or exploit the platform.', t),
          _section('8. Intellectual Property', 'All content, design, branding, logos, and technology on the MTC platform are the exclusive intellectual property of Marine Trade Connect.', t),
          _section('9. Privacy', 'Your use of MTC is also governed by our Privacy Policy. By using MTC, you consent to the collection and use of your information as described in the Privacy Policy.', t),
          _section('10. Limitation of Liability', 'MTC is provided on an "as is" basis without warranties of any kind. To the fullest extent permitted by law, MTC shall not be liable for any indirect or consequential damages arising from your use of the platform.', t),
          _section('11. Governing Law', 'These Terms shall be governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of courts in Mumbai, Maharashtra, India.', t),
          _section('12. Contact', 'Email: legal@mtc.in\nPhone: +91 80000 00000\nAddress: Marine Trade Connect Pvt Ltd, Mumbai Port Area, Maharashtra - 400001', t),
        ],
      ),
    );
  }

  Widget _section(String title, String body, AppTheme t) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: t.primary, fontWeight: FontWeight.w700, fontSize: 13)),
      const SizedBox(height: 8),
      Text(body, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.7)),
    ]),
  );
}