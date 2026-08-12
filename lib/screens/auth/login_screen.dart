import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _loading    = false;
  bool _obscure    = true;  // true = password hidden
  String? _error;

  static const _gold = Color(0xFFF4A532);
  static const _navy = Color(0xFF060F1E);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // NOTE: this used to read the user's Firestore doc and manually call
  // Navigator.pushReplacementNamed(context, '/dashboard' | '/role-selection'
  // | '/profile-setup') after a successful sign-in.
  //
  // That was the actual cause of language/theme/cart getting "stuck" from
  // whichever account used the app first: main.dart's _AuthGate is this
  // app's `home` widget, and it's the ONLY place that calls
  // languageProvider.setLanguage(...) / themeProvider.setThemeLocal(...) /
  // cartProvider.loadCart(...) for whoever is currently signed in — it does
  // this reactively via a StreamBuilder listening to authStateChanges().
  //
  // Navigator.pushReplacementNamed(context, '/dashboard') REPLACES the
  // current route — and since _AuthGate *is* the current route (it's
  // `home`, not something reached via Navigator.push), that call was
  // destroying _AuthGate and its StreamBuilder entirely, dropping straight
  // onto a bare DashboardScreen() that never went through _UserRouter's
  // per-user loading logic. Every login after the first one in a session
  // just kept whatever language/theme/cart was already in memory.
  //
  // Fix: don't navigate manually at all. FirebaseAuth.signInWithEmailAndPassword
  // updates the auth state, authStateChanges() emits, and _AuthGate reacts
  // automatically — swapping itself for _UserRouter, which loads this
  // user's language/theme/cart AND routes to role-selection / profile-setup
  // / dashboard correctly. This screen's only job is to sign in and report
  // errors.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      // Nothing else to do here — _AuthGate picks up the auth state
      // change and handles routing + per-user data loading.
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _msg(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter your email address first.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Password reset email sent!'),
          behavior: SnackBarBehavior.floating));
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_msg(e.code)), behavior: SnackBarBehavior.floating));
    }
  }

  String _msg(String code) {
    switch (code) {
      case 'user-not-found':     return 'No account found with this email.';
      case 'wrong-password':     return 'Incorrect password.';
      case 'invalid-email':      return 'Please enter a valid email.';
      case 'invalid-credential': return 'Incorrect email or password.';
      case 'too-many-requests':  return 'Too many attempts. Try again later.';
      default:                   return 'Login failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        SizedBox.expand(child: Image.asset(
            'assets/images/theme_navy_gold.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: _navy))),
        Container(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_navy.withOpacity(0.7), _navy.withOpacity(0.95), _navy]))),
        Positioned(top: 0, left: 0, right: 0,
            child: Container(height: 3, decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.transparent, _gold, Colors.transparent])))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Container(width: 72, height: 72,
                      decoration: BoxDecoration(
                          color: _gold.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: _gold.withOpacity(0.4), width: 1.5)),
                      child: const Icon(Icons.anchor, color: _gold, size: 34)),

                  const SizedBox(height: 28),

                  const Text('Welcome back',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 28,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text('Sign in to Marine Trade Connect',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),

                  const SizedBox(height: 36),

                  Align(alignment: Alignment.centerLeft, child: _label('Email address')),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inp('you@example.com', Icons.email_outlined),
                      validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid email' : null),

                  const SizedBox(height: 18),

                  Align(alignment: Alignment.centerLeft, child: _label('Password')),
                  const SizedBox(height: 8),
                  TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,          // true = hidden ✓
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      style: const TextStyle(color: Colors.white),
                      decoration: _inp('Enter your password', Icons.lock_outline).copyWith(
                          suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscure = !_obscure),
                              child: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined  // hidden → show eye-off
                                      : Icons.visibility_outlined,     // visible → show eye
                                  color: Colors.white30, size: 20))),
                      validator: (v) =>
                      v == null || v.length < 6 ? 'Password must be 6+ characters' : null),

                  const SizedBox(height: 4),
                  Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                          onPressed: _forgotPassword,
                          child: Text('Forgot password?',
                              style: TextStyle(color: _gold.withOpacity(0.7), fontSize: 13)))),

                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                        ])),
                  ],

                  const SizedBox(height: 28),

                  SizedBox(width: double.infinity, height: 56,
                      child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _gold, foregroundColor: _navy,
                              disabledBackgroundColor: _gold.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0),
                          child: _loading
                              ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Text('Sign in',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w800)))),

                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text("Don't have an account? ",
                        style: TextStyle(color: Colors.white.withOpacity(0.4),
                            fontSize: 14)),
                    GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: const Text('Sign up',
                            style: TextStyle(color: _gold, fontWeight: FontWeight.w700,
                                fontSize: 14))),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _label(String t) => Text(t,
      style: TextStyle(color: Colors.white.withOpacity(0.65),
          fontSize: 13, fontWeight: FontWeight.w500));

  InputDecoration _inp(String hint, IconData icon) => InputDecoration(
      hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
      prefixIcon: Icon(icon, color: Colors.white30, size: 20),
      filled: true, fillColor: Colors.white.withOpacity(0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _gold, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)));
}