import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController      = TextEditingController();
  final _companyController  = TextEditingController();

  String _role      = '';
  bool   _isLoading = false;
  bool   _isFetching = true;

  bool get _isSeller   => _role == 'seller';
  bool get _isAgent    => _role == 'agent';
  bool get _hasCompany => _isSeller || _isAgent;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ── Apply document data to controllers ────────────────────────────────────
  void _applyData(Map<String, dynamic> d) {
    _role = (d['role'] ?? '').toString().toLowerCase().trim();
    _nameController.text     = d['name']         ?? '';
    _phoneController.text    = d['phone']         ?? '';
    // ── field is stored as 'portLocation' in Firestore ───────────────────
    _locationController.text = d['portLocation']  ?? d['location'] ?? '';
    _bioController.text      = d['bio']            ?? '';
    _companyController.text  = d['companyName']    ?? d['company']  ?? '';
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isFetching = false);
      return;
    }

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    // ── 1. Cache first — instant, works fully offline ─────────────────────
    try {
      final cached = await ref.get(const GetOptions(source: Source.cache));
      if (cached.exists && mounted) {
        _applyData(cached.data() as Map<String, dynamic>);
        setState(() => _isFetching = false); // show UI immediately
      }
    } catch (_) {}

    // ── 2. Server refresh in background — silent if offline ───────────────
    try {
      final fresh = await ref.get(const GetOptions(source: Source.server));
      if (fresh.exists && mounted) {
        setState(() {
          _applyData(fresh.data() as Map<String, dynamic>);
          _isFetching = false;
        });
      }
    } catch (_) {
      // Offline — cache already shown, nothing to do
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Name cannot be empty'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final Map<String, dynamic> data = {
        'name':        name,
        'phone':       _phoneController.text.trim(),
        'portLocation': _locationController.text.trim(), // consistent field name
        'bio':         _bioController.text.trim(),
        if (_hasCompany) 'companyName': _companyController.text.trim(),
      };

      // Firestore queues this write even when offline — syncs when back online
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Profile updated!'),
          ]),
          backgroundColor: const Color(0xFF1D9E75),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _companyController.dispose();
    super.dispose();
  }

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
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.primary.withOpacity(0.25)),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 15),
          ),
        ),
        title: const Text('Account Settings',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
      ),
      body: _isFetching
          ? Center(child: CircularProgressIndicator(color: t.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Avatar ────────────────────────────────────────────
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.primary.withOpacity(0.15),
                  border: Border.all(
                      color: t.primary.withOpacity(0.5), width: 2),
                ),
                child: Center(
                  child: Text(
                    _nameController.text.isNotEmpty
                        ? _nameController.text[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                        color: t.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            _field('Full Name', _nameController, t,
                hint: 'e.g. Ravi Kumar'),
            _field('Phone Number', _phoneController, t,
                hint: '+91 98765 43210',
                keyboard: TextInputType.phone),

            if (_hasCompany)
              _field(
                _isAgent ? 'Company / Agency' : 'Company / Business',
                _companyController, t,
                hint: _isAgent
                    ? 'e.g. BlueWave Marine Agents'
                    : 'e.g. Coastal Exports Pvt Ltd',
              ),

            _field('Port / Location', _locationController, t,
                hint: 'e.g. Kochi, Kerala'),
            _field('Bio', _bioController, t,
                hint: 'Tell traders about yourself...',
                maxLines: 3),

            const SizedBox(height: 32),

            // ── Save button ───────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: t.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),

            const SizedBox(height: 24),

            // ── Danger zone ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: Colors.redAccent.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Danger Zone',
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (_) => false);
                      }
                    },
                    child: const Row(children: [
                      Icon(Icons.logout,
                          color: Colors.redAccent, size: 16),
                      SizedBox(width: 8),
                      Text('Sign out of account',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController controller,
      AppTheme t, {
        String hint = '',
        TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
            filled: true,
            fillColor: t.card,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.08))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                BorderSide(color: Colors.white.withOpacity(0.08))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}