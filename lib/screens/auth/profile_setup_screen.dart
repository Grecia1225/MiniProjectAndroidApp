import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetup extends StatefulWidget {
  const ProfileSetup({super.key});
  @override
  State<ProfileSetup> createState() => _ProfileSetupState();
}

class _ProfileSetupState extends State<ProfileSetup> {
  final _formKey = GlobalKey<FormState>();

  final _phoneController    = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController      = TextEditingController();
  final _companyController  = TextEditingController(); // seller + agent only

  final _phoneFocus    = FocusNode();
  final _companyFocus  = FocusNode();
  final _locationFocus = FocusNode();
  final _bioFocus      = FocusNode();

  bool _isLoading      = false;
  bool _isFetchingRole = true;
  bool _roleResolved   = false;
  String _role = '';

  static const _gold = Color(0xFFF4A532);
  static const _navy = Color(0xFF060F1E);

  bool get _isBuyer   => _role == 'buyer';
  bool get _isSeller  => _role == 'seller';
  bool get _isAgent   => _role == 'agent';
  bool get _hasCompany => _isSeller || _isAgent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_roleResolved) return;
    _roleResolved = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final argRole = args != null ? args.toString().toLowerCase().trim() : '';

    if (argRole.isNotEmpty) {
      setState(() {
        _role = argRole;
        _isFetchingRole = false;
      });
      _prefillFields();
    } else {
      _loadRoleFromFirestore();
    }
  }

  Future<void> _loadRoleFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _isFetchingRole = false);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted) return;
      final data = doc.data() ?? {};
      _role = (data['role'] ?? '').toString().toLowerCase().trim();
      _phoneController.text    = data['phone']    ?? '';
      _locationController.text = data['location'] ?? '';
      _bioController.text      = data['bio']      ?? '';
      if (_hasCompany) _companyController.text = data['company'] ?? '';
      setState(() => _isFetchingRole = false);
    } catch (e) {
      if (mounted) setState(() => _isFetchingRole = false);
    }
  }

  Future<void> _prefillFields() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!mounted || !doc.exists) return;
      final data = doc.data() ?? {};
      _phoneController.text    = data['phone']    ?? '';
      _locationController.text = data['location'] ?? '';
      _bioController.text      = data['bio']      ?? '';
      if (_hasCompany) _companyController.text = data['company'] ?? '';
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _companyController.dispose();
    _phoneFocus.dispose();
    _companyFocus.dispose();
    _locationFocus.dispose();
    _bioFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final Map<String, dynamic> data = {
        'phone':           _phoneController.text.trim(),
        'location':        _locationController.text.trim(),
        'bio':             _bioController.text.trim(),
        'profileComplete': true,
        if (_role.isNotEmpty) 'role': _role,
        if (_hasCompany) 'company': _companyController.text.trim(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _subtitle {
    if (_isBuyer)  return "Tell sellers where you're based";
    if (_isAgent)  return "Tell us about your agency";
    if (_isSeller) return "Let buyers know who you are";
    return "Complete your profile";
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingRole) {
      return const Scaffold(
        backgroundColor: _navy,
        body: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }

    return Scaffold(
      body: Stack(children: [
        SizedBox.expand(
          child: Image.network(
            'https://images.unsplash.com/photo-1520870028842-5f06cb876136?w=800',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: _navy),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _navy.withOpacity(0.8),
                _navy.withOpacity(0.96),
                _navy,
              ],
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 3,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _gold, Colors.transparent],
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step indicator
                  Row(
                    children: List.generate(3, (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i <= 1 ? _gold : Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    )),
                  ),

                  const SizedBox(height: 32),

                  const Text('Your profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(_subtitle,
                      style: TextStyle(
                          color: _gold.withOpacity(0.6), fontSize: 13)),

                  const SizedBox(height: 24),

                  // Avatar placeholder
                  Center(
                    child: Stack(children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _gold.withOpacity(0.5), width: 2),
                          color: _gold.withOpacity(0.08),
                        ),
                        child: const Icon(Icons.person_outline,
                            color: Colors.white38, size: 38),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _gold,
                            shape: BoxShape.circle,
                            border: Border.all(color: _navy, width: 2),
                          ),
                          child: const Icon(Icons.add,
                              color: Color(0xFF060F1E), size: 16),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 28),

                  // Phone — shared
                  _label('Phone number'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inp('+91 98765 43210'),
                    onFieldSubmitted: (_) => FocusScope.of(context)
                        .requestFocus(_hasCompany ? _companyFocus : _locationFocus),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Phone required';
                      final digits = v.trim().replaceAll(RegExp(r'\D'), '');
                      if (digits.length < 10) return 'Enter a valid 10-digit phone number';
                      return null;
                    },
                  ),

                  const SizedBox(height: 18),

                  // Company — seller + agent only
                  if (_hasCompany) ...[
                    _label(_isAgent
                        ? 'Agency / Company name'
                        : 'Company / Business name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _companyController,
                      focusNode: _companyFocus,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inp(_isAgent
                          ? 'e.g. BlueWave Marine Agents'
                          : 'e.g. Coastal Exports Pvt Ltd'),
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_locationFocus),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? '${_isAgent ? 'Agency' : 'Company'} name required'
                          : null,
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Location — shared
                  _label('Port / Location'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    focusNode: _locationFocus,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inp('e.g. Mumbai Port, Maharashtra'),
                    onFieldSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_bioFocus),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Location required'
                        : null,
                  ),

                  const SizedBox(height: 18),

                  // Bio — shared
                  _label('Short bio (optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _bioController,
                    focusNode: _bioFocus,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    maxLength: 160,
                    onFieldSubmitted: (_) => _handleSave(),
                    decoration: _inp(
                      _isBuyer
                          ? 'e.g. Restaurant owner, need fresh daily catch...'
                          : _isAgent
                          ? 'e.g. 15+ years in marine trade facilitation...'
                          : 'e.g. 10+ years in marine cargo trading...',
                    ).copyWith(
                      counterStyle: TextStyle(
                          color: Colors.white.withOpacity(0.25), fontSize: 11),
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _navy,
                        disabledBackgroundColor: _gold.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : const Text('Complete setup',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF060F1E))),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/dashboard'),
                      child: Text('Skip for now',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(
          color: Colors.white.withOpacity(0.65),
          fontSize: 13,
          fontWeight: FontWeight.w500));

  InputDecoration _inp(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
    filled: true,
    fillColor: Colors.white.withOpacity(0.06),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF4A532), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: Colors.redAccent, width: 1.5)),
    errorStyle: const TextStyle(color: Colors.redAccent),
  );
}