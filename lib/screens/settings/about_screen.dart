import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context).current;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(margin: const EdgeInsets.all(10), decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.primary.withOpacity(0.25))), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 15)),
        ),
        title: const Text('About MTC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Logo hero
          Center(
            child: Container(
              width: 90, height: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, color: t.primary.withOpacity(0.12), border: Border.all(color: t.primary.withOpacity(0.4), width: 2)),
              child: Icon(Icons.anchor, color: t.primary, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Marine Trade Connect', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
          const SizedBox(height: 4),
          Center(child: Text("The Ocean's Marketplace", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13))),
          const SizedBox(height: 4),
          Center(child: Text('Version 1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12))),
          const SizedBox(height: 32),

          _infoCard('Our Mission', 'MTC connects marine product sellers, buyers, and brokers across India\'s coastline — making trade faster, transparent, and accessible for everyone.', Icons.rocket_launch_outlined, t),
          const SizedBox(height: 12),
          _infoCard('Who We Serve', 'Fish traders, seafood exporters, marine equipment dealers, shipping brokers, and buyers from across the coast.', Icons.people_outline, t),
          const SizedBox(height: 12),
          _infoCard('Built With', 'Flutter · Firebase · Firestore · Cloud Storage', Icons.code_outlined, t),

          const SizedBox(height: 28),

          _linkRow(Icons.language_outlined, 'Website', 'www.mtc.in', t),
          _linkRow(Icons.email_outlined, 'Email', 'hello@mtc.in', t),
          _linkRow(Icons.phone_outlined, 'Support', '+91 80000 00000', t),

          const SizedBox(height: 28),
          Center(child: Text('© 2026 Marine Trade Connect. All rights reserved.', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String body, IconData icon, AppTheme t) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.primary.withOpacity(0.15))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 36, height: 36, decoration: BoxDecoration(color: t.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: t.primary, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 4),
        Text(body, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, height: 1.5)),
      ])),
    ]),
  );

  Widget _linkRow(IconData icon, String label, String value, AppTheme t) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
    child: Row(children: [
      Icon(icon, color: t.primary, size: 18),
      const SizedBox(width: 14),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(value, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
    ]),
  );
}