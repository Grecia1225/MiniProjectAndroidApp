import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mtc/firebase_options.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/cart_provider.dart';
import 'package:mtc/utils/language_provider.dart';
import 'package:mtc/utils/app_localizations.dart';
import 'package:mtc/utils/voice_provider/voice_provider.dart';
import 'package:mtc/screens/auth/login_screen.dart';
import 'package:mtc/screens/auth/signup_screen.dart';
import 'package:mtc/screens/auth/role_selection_screen.dart';
import 'package:mtc/screens/auth/profile_setup_screen.dart';
import 'package:mtc/screens/home/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  final themeProvider    = ThemeProvider();
  final languageProvider = LanguageProvider();

  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await Future.wait([
      themeProvider.loadThemeFromFirestore(),
      languageProvider.loadFromFirestore(),
    ]);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider.value(value: languageProvider),
        // VoiceProvider registered here — available app-wide
        ChangeNotifierProvider(create: (_) => VoiceProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider    = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final appTheme         = themeProvider.current;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: languageProvider.locale,
      supportedLocales: const [
        Locale('en'), Locale('hi'), Locale('ta'),
        Locale('te'), Locale('ar'), Locale('fr'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (_, supportedLocales) {
        for (final s in supportedLocales) {
          if (s.languageCode == languageProvider.locale.languageCode) return s;
        }
        return const Locale('en');
      },
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.dark(
          primary: appTheme.primary,
          surface: appTheme.background,
        ),
      ),
      home: _AuthGate(appTheme: appTheme),
      routes: {
        '/login':          (_) => const LoginScreen(),
        '/signup':         (_) => const SignupScreen(),
        '/role-selection': (_) => const RoleSelectionScreen(),
        '/profile-setup':  (_) => const ProfileSetup(),
        '/dashboard':      (_) => const DashboardScreen(),
      },
    );
  }
}

// ── Auth gate ─────────────────────────────────────────────────────────────────
class _AuthGate extends StatelessWidget {
  final AppTheme appTheme;
  const _AuthGate({required this.appTheme});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: appTheme.background,
            body: Center(
                child: CircularProgressIndicator(color: appTheme.primary)),
          );
        }
        if (!snap.hasData || snap.data == null) return const LoginScreen();

        return _UserRouter(
          key: ValueKey(snap.data!.uid),
          user: snap.data!,
          appTheme: appTheme,
        );
      },
    );
  }
}

// ── User router ───────────────────────────────────────────────────────────────
class _UserRouter extends StatefulWidget {
  final User user;
  final AppTheme appTheme;
  const _UserRouter({super.key, required this.user, required this.appTheme});

  @override
  State<_UserRouter> createState() => _UserRouterState();
}

class _UserRouterState extends State<_UserRouter> {
  Widget? _dest;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _load();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_done) _setDest(const DashboardScreen());
    });
  }

  void _setDest(Widget w) {
    if (_done) return;
    _done = true;
    if (mounted) setState(() => _dest = w);
  }

  Future<void> _load() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('users').doc(widget.user.uid);

      DocumentSnapshot? snap;

      try {
        snap = await ref.get(const GetOptions(source: Source.cache));
      } catch (_) {}

      if (snap == null || !snap.exists) {
        try {
          snap = await ref
              .get(const GetOptions(source: Source.server))
              .timeout(const Duration(seconds: 3));
        } catch (_) {}
      }

      if (!mounted) return;

      if (snap == null || !snap.exists) {
        await ref.set({
          'uid':             widget.user.uid,
          'name':            widget.user.displayName ?? '',
          'email':           widget.user.email ?? '',
          'role':            '',
          'profileComplete': false,
          'theme':           'navy_gold',
          'createdAt':       FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        _setDest(const RoleSelectionScreen());
        return;
      }

      final data      = snap.data() as Map<String, dynamic>;
      final role      = (data['role'] ?? '').toString().trim();
      final ok        = data['profileComplete'] == true;
      final langCode  = data['language'] as String?;
      final themeCode = data['theme'] as String?;

      final lp = context.read<LanguageProvider>();
      final tp = context.read<ThemeProvider>();
      if (langCode != null && langCode.isNotEmpty) lp.setLanguage(langCode);
      if (themeCode != null && themeCode.isNotEmpty) tp.setThemeLocal(themeCode);
      context.read<CartProvider>().loadCart(widget.user.uid);

      if (!mounted) return;

      if (role.isEmpty)  { _setDest(const RoleSelectionScreen()); return; }
      if (!ok)           { _setDest(const ProfileSetup());         return; }
      _setDest(const DashboardScreen());
    } catch (e) {
      debugPrint('UserRouter error: $e');
      if (mounted && !_done) _setDest(const DashboardScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dest == null) {
      return Scaffold(
        backgroundColor: widget.appTheme.background,
        body: Center(
            child: CircularProgressIndicator(color: widget.appTheme.primary)),
      );
    }
    return _dest!;
  }
}