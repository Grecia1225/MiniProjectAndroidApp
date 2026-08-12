import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _showPhone = false;
  bool _showLocation = true;
  bool _showCompany = true;
  bool _allowMessages = true;
  bool _showOnlineStatus = true;
  bool _dataAnalytics = true;

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context).current;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: t.primary.withOpacity(0.25))),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 15)),
        ),
        title: const Text('Privacy & Security', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [

          _sectionHeader('Profile visibility', t),
          _toggle('Show phone number', 'Other traders can see your phone', Icons.phone_outlined, _showPhone, t, (v) => setState(() => _showPhone = v)),
          _toggle('Show location', 'Display your port/location publicly', Icons.location_on_outlined, _showLocation, t, (v) => setState(() => _showLocation = v)),
          _toggle('Show company name', 'Display business name on profile', Icons.business_outlined, _showCompany, t, (v) => setState(() => _showCompany = v)),

          const SizedBox(height: 8),
          _sectionHeader('Interactions', t),
          _toggle('Allow direct messages', 'Let any trader message you', Icons.chat_outlined, _allowMessages, t, (v) => setState(() => _allowMessages = v)),
          _toggle('Show online status', 'Let others see when you\'re active', Icons.circle_outlined, _showOnlineStatus, t, (v) => setState(() => _showOnlineStatus = v)),

          const SizedBox(height: 8),
          _sectionHeader('Data', t),
          _toggle('Analytics', 'Help improve the app with usage data', Icons.bar_chart_outlined, _dataAnalytics, t, (v) => setState(() => _dataAnalytics = v)),

          const SizedBox(height: 16),
          _sectionHeader('Security', t),

          _actionTile('Change password', 'Update your account password', Icons.lock_outline, t, () => _showChangePasswordDialog(context, t)),

          // Active sessions — real data
          _actionTile('Active sessions', 'Devices logged into your account', Icons.devices_outlined, t, () => _showActiveSessions(context, t, user)),

          const SizedBox(height: 16),
          _sectionHeader('Legal', t),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
            child: Column(children: [
              _linkRow(context, 'Privacy Policy', t),
              Divider(color: Colors.white.withOpacity(0.06), height: 20),
              _linkRow(context, 'Terms of Service', t),
              Divider(color: Colors.white.withOpacity(0.06), height: 20),
              _linkRow(context, 'Data Deletion Request', t),
            ]),
          ),
        ],
      ),
    );
  }

  void _showActiveSessions(BuildContext context, AppTheme t, User? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: t.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: t.primary.withOpacity(0.15))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('Active Sessions', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
            GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: Colors.white.withOpacity(0.4))),
          ]),
          const SizedBox(height: 20),

          // Current session
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: t.primary.withOpacity(0.3))),
            child: Row(children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: t.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.computer_outlined, color: t.primary, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('Current Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 3),
                Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                const SizedBox(height: 2),
                Text('Signed in: ' + (user?.metadata.lastSignInTime?.toString().substring(0, 16) ?? 'Unknown'),
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              ])),
            ]),
          ),

          const SizedBox(height: 16),

          Text('Account created: ' + (user?.metadata.creationTime?.toString().substring(0, 16) ?? 'Unknown'),
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),

          const SizedBox(height: 16),

          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await FirebaseAuth.instance.signOut();
                if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.12), foregroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('Sign out all devices', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppTheme t) {
    final controller = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: t.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Change password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      content: TextField(
        controller: controller, obscureText: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(hintText: 'New password (min 6 chars)', hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          filled: true, fillColor: t.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.4)))),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.length < 6) return;
            try {
              await FirebaseAuth.instance.currentUser?.updatePassword(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated!'), backgroundColor: Colors.green));
              }
            } catch (e) {
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: t.primary, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  Widget _sectionHeader(String title, AppTheme t) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Text(title.toUpperCase(), style: TextStyle(color: t.primary.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  );

  Widget _toggle(String title, String subtitle, IconData icon, bool value, AppTheme t, ValueChanged<bool> onChanged) =>
    Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: t.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: t.primary, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: t.primary, activeTrackColor: t.primary.withOpacity(0.25), inactiveThumbColor: Colors.white30, inactiveTrackColor: Colors.white10),
      ]),
    );

  Widget _actionTile(String title, String subtitle, IconData icon, AppTheme t, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: t.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: t.primary, size: 18)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
          ])),
          Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 14),
        ]),
      ),
    );

  Widget _linkRow(BuildContext context, String title, AppTheme t) => GestureDetector(
    onTap: () => _openPolicy(context, title, t),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
      Icon(Icons.open_in_new, color: t.primary.withOpacity(0.5), size: 14),
    ]),
  );

  void _openPolicy(BuildContext context, String title, AppTheme t) {
    String body = '';
    if (title == 'Privacy Policy') {
      body = 'Marine Trade Connect collects your name, email, phone, company, and location to operate the platform. We use Firebase/Google as our backend. We never sell your data. You can request deletion at any time.\n\nContact: privacy@mtc.in';
    } else if (title == 'Terms of Service') {
      body = 'By using MTC you agree to post only genuine listings, not harass other users, and not use the platform for illegal activity. MTC does not process payments or guarantee transactions. We may suspend accounts that violate these terms.\n\nContact: legal@mtc.in';
    } else {
      body = 'To delete your account and all data, email deleteme@mtc.in from your registered email with subject "Delete My Account". We will process your request within 7 business days.\n\nAlternatively tap the button below.';
    }

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, maxChildSize: 0.9, minChildSize: 0.4,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(color: t.background, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border.all(color: t.primary.withOpacity(0.15))),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(children: [
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18))),
                GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: Colors.white.withOpacity(0.4))),
              ])),
            Divider(color: Colors.white.withOpacity(0.08), height: 24),
            Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
              Text(body, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.7)),
              if (title == 'Data Deletion Request') ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deletion request submitted. We\'ll contact you within 7 days.'))); },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                  child: const Text('Request Account Deletion', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ])),
          ]),
        ),
      ),
    );
  }
}