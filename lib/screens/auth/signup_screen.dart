import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  // Focus nodes — Enter jumps to next field
  final _nameFocus     = FocusNode();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus  = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;

  static const _gold = Color(0xFFF4A532);
  static const _navy = Color(0xFF060F1E);

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose();
    _passwordController.dispose(); _confirmController.dispose();
    _nameFocus.dispose(); _emailFocus.dispose();
    _passwordFocus.dispose(); _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Create the account
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update display name
      await credential.user?.updateDisplayName(_nameController.text.trim());

      // Create Firestore user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': '',
        'phone': '',
        'company': '',
        'location': '',
        'bio': '',
        'theme': 'navy_gold',
        'profileComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/role-selection');
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_errorMessage(e.code)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _errorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':   return 'Account already exists. Please sign in instead.';
      case 'invalid-email':          return 'Invalid email address.';
      case 'weak-password':          return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':  return 'Email signup is not enabled. Contact support.';
      case 'network-request-failed': return 'No internet connection.';
      default:                       return 'Signup failed ($code). Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.network(
              'https://images.unsplash.com/photo-1494587351196-bbf5f29cff42?w=800',
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) =>
              progress == null ? child : Container(color: _navy),
              errorBuilder: (_, __, ___) => Container(color: _navy),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [_navy.withOpacity(0.78), _navy.withOpacity(0.93), _navy],
              ),
            ),
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 3, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Colors.transparent, _gold, Colors.transparent]),
            )),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold.withOpacity(0.25)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text('Join the network', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Connect with marine traders worldwide', style: TextStyle(color: _gold.withOpacity(0.6), fontSize: 13, letterSpacing: 0.3)),

                    const SizedBox(height: 36),

                    // Full name → email on Enter
                    _label('Full name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle('e.g. Arjun Mehta'),
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocus),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Name required' : null,
                    ),

                    const SizedBox(height: 18),

                    // Email → password on Enter
                    _label('Email address'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle('trader@marine.com'),
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Email required';
                        if (!val.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Password → confirm on Enter
                    _label('Password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle('Min. 6 characters').copyWith(
                        suffixIcon: _eyeIcon(_obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
                      ),
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmFocus),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Password required';
                        if (val.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Confirm → submits on Enter
                    _label('Confirm password'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmController,
                      focusNode: _confirmFocus,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputStyle('Re-enter password').copyWith(
                        suffixIcon: _eyeIcon(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                      ),
                      onFieldSubmitted: (_) => _handleSignup(),
                      validator: (val) => val != _passwordController.text ? 'Passwords do not match' : null,
                    ),

                    const SizedBox(height: 36),

                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold, foregroundColor: _navy,
                          disabledBackgroundColor: _gold.withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF060F1E))),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Already have an account? ', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Sign in', style: TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                    ])),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13, fontWeight: FontWeight.w500));

  Widget _eyeIcon(bool obscure, VoidCallback onTap) => IconButton(
    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20),
    onPressed: onTap,
  );

  InputDecoration _inputStyle(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
    filled: true, fillColor: Colors.white.withOpacity(0.06),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFF4A532), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
    errorStyle: const TextStyle(color: Colors.redAccent),
  );
}