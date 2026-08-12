import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/language_provider.dart';
import 'package:mtc/utils/app_localizations.dart';
import 'package:mtc/utils/cart_provider.dart';
import 'package:mtc/utils/voice_provider/voice_provider.dart';
import 'package:mtc/utils/dashboard_tab_notifier.dart';
import 'package:mtc/screens/settings/theme_picker_screen.dart';
import 'package:mtc/screens/settings/account_settings_screen.dart';
import 'package:mtc/screens/settings/notifications_screen.dart';
import 'package:mtc/screens/settings/privacy_screen.dart';
import 'package:mtc/screens/settings/help_support_screen.dart';
import 'package:mtc/screens/settings/terms_screen.dart';
import 'package:mtc/screens/settings/about_screen.dart';
import 'package:mtc/screens/settings/language_screen.dart';
import 'package:mtc/screens/marketplace/marketplace_screen.dart';
import 'package:mtc/screens/marketplace/create_listing_screen.dart';
import 'package:mtc/screens/marketplace/secondhand_screen.dart';
import 'package:mtc/screens/marketplace/cart_screen.dart';
import 'package:mtc/screens/marketplace/my_listings_screen.dart';
import 'package:mtc/screens/chat/chat_list_screen.dart';
import 'package:mtc/screens/trackingg/tracking_screen.dart';
import 'package:mtc/screens/home/seasonal_calendar_screen.dart';

// Small shared helper so both the home header badge and the profile tab
// show the same translated role text instead of the raw Firestore value.
String roleLabel(String role, AppLocalizations l) {
  switch (role) {
    case 'seller': return l.roleSeller;
    case 'agent':  return l.roleAgent;
    default:       return l.roleBuyer;
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int    _currentIndex = 0;
  String _userName     = '';
  String _userRole     = '';
  bool   _greeted      = false;

  // Captured via didChangeDependencies so dispose() can safely stop speech
  // without touching a possibly-torn-down BuildContext.
  VoiceProvider? _voiceRef;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    DashboardTabNotifier.requestedIndex.addListener(_onTabRequested);
  }

  void _onTabRequested() {
    final requested = DashboardTabNotifier.requestedIndex.value;
    if (requested != null && mounted) {
      setState(() => _currentIndex = requested);
      // Reset so the same request doesn't re-fire the next time this
      // screen happens to rebuild for an unrelated reason.
      DashboardTabNotifier.requestedIndex.value = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voiceRef = context.read<VoiceProvider>();
  }

  @override
  void dispose() {
    DashboardTabNotifier.requestedIndex.removeListener(_onTabRequested);
    _voiceRef?.stop();
    super.dispose();
  }

  void _applyUserDoc(DocumentSnapshot doc, User user) {
    if (!doc.exists || !mounted) return;
    final d = doc.data() as Map<String, dynamic>;
    setState(() {
      _userName = d['name'] ?? user.displayName ?? 'Trader';
      _userRole = d['role'] ?? 'buyer';
    });
    if (!_greeted && _userName.isNotEmpty) {
      _greeted = true;
      Future.delayed(const Duration(milliseconds: 800), _speakGreeting);
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      final cached = await ref.get(const GetOptions(source: Source.cache));
      _applyUserDoc(cached, user);
    } catch (_) {}
    try {
      final fresh = await ref.get(const GetOptions(source: Source.server));
      _applyUserDoc(fresh, user);
    } catch (_) {}
  }

  /// Builds the greeting text and speaks it in the app's current language,
  /// via the shared VoiceProvider (so it matches whatever language the
  /// screen is actually showing, instead of being hardcoded to English).
  Future<void> _speakGreeting() async {
    if (!mounted) return;
    final voice     = context.read<VoiceProvider>();
    final langProv  = context.read<LanguageProvider>();
    final firstName = _userName.split(' ').first;

    await voice.speakGreeting(firstName, langProv);
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final t = Provider.of<ThemeProvider>(ctx, listen: false).current;
        final l = AppLocalizations.of(ctx);
        return AlertDialog(
          backgroundColor: t.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l.signOutConfirmTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          content: Text(l.signOutConfirmBody,
              style: TextStyle(color: Colors.white.withOpacity(0.5))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel,
                    style: TextStyle(
                        color: Provider.of<ThemeProvider>(ctx, listen: false).current.primary))),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l.signOut,
                    style: const TextStyle(color: Colors.redAccent))),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await context.read<VoiceProvider>().stop();
    await FirebaseAuth.instance.signOut();
    // Was: Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false)
    // — that predicate removes EVERY route including _AuthGate itself
    // (this app's `home`), permanently killing its authStateChanges()
    // listener for the rest of the session. Next login would succeed with
    // no error, but nothing was left to react and navigate anywhere —
    // exactly the "spinner clears, stuck on login screen" symptom.
    //
    // _AuthGate is already listening for sign-out and will swap itself to
    // LoginScreen on its own the moment signOut() completes — same
    // reactive pattern login_screen.dart now relies on. All that's needed
    // here is to pop back to it (in case logout was triggered from a
    // pushed sub-screen) without destroying it.
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final t = themeProvider.current;
        return WillPopScope(
          onWillPop: () async {
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
              return false;
            }
            return true;
          },
          child: Scaffold(
            backgroundColor: t.background,
            body: SafeArea(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  Builder(builder: (ctx) => _HomeTab(
                    userName: _userName,
                    userRole: _userRole,
                    navContext: ctx,
                    onTabChange: (i) => setState(() => _currentIndex = i),
                  )),
                  const MarketplaceScreen(),
                  const ChatListScreen(),
                  const TrackingScreen(),
                  _ProfileTab(
                    userName: _userName,
                    userRole: _userRole,
                    onLogout: _handleLogout,
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _BottomNav(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              t: t,
            ),
          ),
        );
      },
    );
  }
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final AppTheme t;
  const _BottomNav(
      {required this.currentIndex, required this.onTap, required this.t});

  @override
  Widget build(BuildContext context) {
    final l     = AppLocalizations.of(context);
    final items = [
      {'icon': Icons.home_rounded,            'label': l.home},
      {'icon': Icons.storefront_rounded,      'label': l.market},
      {'icon': Icons.chat_bubble_rounded,     'label': l.chat},
      {'icon': Icons.directions_boat_rounded, 'label': l.tracking},
      {'icon': Icons.person_rounded,          'label': l.profile},
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 18),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(top: BorderSide(color: t.primary.withOpacity(0.10))),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30),
            blurRadius: 16, offset: const Offset(0, -3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = currentIndex == i;
          return Flexible(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? t.primary.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(items[i]['icon'] as IconData,
                      color: selected ? t.primary : Colors.white.withOpacity(0.30),
                      size: 22),
                  if (selected) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        items[i]['label'] as String,
                        style: TextStyle(color: t.primary, fontSize: 11,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Small standalone translator for "My Listings" — added here rather than
// in the .arb files so this works immediately without touching the
// localization pipeline. If you later add a proper `myListings` key to
// app_en.arb/app_hi.arb/etc., swap this call for `l.myListings`.
String _myListingsLabel(BuildContext context) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'hi': return 'मेरी लिस्टिंग';
    case 'ta': return 'எனது பட்டியல்கள்';
    case 'ar': return 'قوائمي';
    case 'fr': return 'Mes annonces';
    default:   return 'My Listings';
  }
}

// ─── HOME TAB ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String userName, userRole;
  final BuildContext navContext;
  final void Function(int) onTabChange;

  const _HomeTab({
    required this.userName,
    required this.userRole,
    required this.navContext,
    required this.onTabChange,
  });

  void _push(Widget screen) =>
      Navigator.push(navContext, MaterialPageRoute(builder: (_) => screen));

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    return hour < 12 ? l.goodMorning : hour < 17 ? l.goodAfternoon : l.goodEvening;
  }

  String _greetSubtitle(AppLocalizations l, bool isWeekend) {
    final hour = DateTime.now().hour;
    if (userRole == 'seller') {
      if (hour < 9)  return l.greetSellerEarly;
      if (isWeekend) return l.greetSellerWeekend;
      return l.greetSellerDefault;
    }
    if (userRole == 'agent') return l.greetAgentDefault;
    if (hour < 9)  return l.greetBuyerEarly;
    if (isWeekend) return l.greetBuyerWeekend;
    return l.greetBuyerDefault;
  }

  @override
  Widget build(BuildContext context) {
    final t         = Provider.of<ThemeProvider>(context).current;
    final l         = AppLocalizations.of(context);
    final cart      = Provider.of<CartProvider>(context);
    final voice     = Provider.of<VoiceProvider>(context);
    final langProv  = Provider.of<LanguageProvider>(context, listen: false);
    final uid       = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isSeller  = userRole == 'seller';
    final isAgent   = userRole == 'agent';
    final isWeekend = DateTime.now().weekday >= 6;
    final firstName   = userName.split(' ').first;
    final displayName = firstName.isNotEmpty ? firstName : 'there';

    return Stack(children: [
      // ── Background ────────────────────────────────────────────────────────
      Positioned.fill(
        child: Image.asset(t.backgroundImage, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: t.background)),
      ),
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                t.background.withOpacity(0.82),
                t.background.withOpacity(0.45),
                t.background.withOpacity(0.70),
              ],
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
        ),
      ),

      SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── HEADER ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Name row + bell
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_greeting(l)} 👋',
                        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 26,
                            fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Text(_greetSubtitle(l, isWeekend),
                        style: TextStyle(color: Colors.white.withOpacity(0.52),
                            fontSize: 12, height: 1.4)),
                  ]),
                ),
                const SizedBox(width: 12),
                // 🔔 Bell icon with unread badge
                _NotificationBell(t: t, navContext: navContext),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: t.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: t.primary.withOpacity(0.50)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_roleIcon(userRole), color: t.primary, size: 12),
                    const SizedBox(width: 5),
                    Text(roleLabel(userRole, l),
                        style: TextStyle(color: t.primary, fontSize: 10,
                            fontWeight: FontWeight.w700, letterSpacing: 1.1)),
                  ]),
                ),
                const Spacer(),
                // 🎤 Voice button — instant torch-style toggle via VoiceProvider.
                GestureDetector(
                  onTap: () {
                    if (voice.isSpeaking) {
                      voice.stop();
                    } else {
                      voice.speakGreeting(firstName, langProv);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: voice.isSpeaking
                          ? t.primary.withOpacity(0.25)
                          : t.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: voice.isSpeaking
                              ? t.primary
                              : t.primary.withOpacity(0.30),
                          width: voice.isSpeaking ? 1.5 : 1),
                    ),
                    child: Icon(
                      voice.isSpeaking
                          ? Icons.stop_circle_outlined
                          : Icons.volume_up_rounded,
                      color: t.primary,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Marine Trade Connect',
                    style: TextStyle(color: Colors.white.withOpacity(0.20), fontSize: 10)),
              ]),
            ]),
          ),

          // ── STAT CARDS ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: _DashboardGrid(
              t: t,
              tiles: isSeller
                  ? [
                // Row 1: In Transit, My Listings
                _TileDef(l.inTransit, Icons.directions_boat_rounded,
                        () => onTabChange(3),
                    stream: FirebaseFirestore.instance
                        .collection('shipments')
                        .where('sellerId', isEqualTo: uid)
                        .where('status', isEqualTo: 'in_transit')
                        .snapshots()),
                _TileDef(_myListingsLabel(context), Icons.list_alt_rounded,
                        () => _push(const MyListingsScreen()),
                    stream: FirebaseFirestore.instance
                        .collection('listings')
                        .where('sellerId', isEqualTo: uid)
                        .snapshots()),
                // Row 2: Chats, Post Listing
                _TileDef(l.chats, Icons.chat_bubble_rounded,
                        () => onTabChange(2),
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: uid)
                        .snapshots()),
                _TileDef(l.postListing, Icons.add_circle_rounded,
                        () => _push(CreateListingScreen())),
              ]
                  : isAgent
                  ? [
                // AGENT — Row 1: Available Jobs, My Deliveries
                //
                // Available Jobs was previously querying
                // shipments/status==pending, which is a
                // different collection than what the "Open
                // Requests" tab actually shows (shipment_requests
                // /status==open) — that mismatch is why this
                // tile and In Transit could show the same
                // number by coincidence. Now matches the real
                // Open Requests feed exactly.
                _TileDef(l.availableJobs, Icons.local_shipping_rounded,
                        () => onTabChange(3),
                    stream: FirebaseFirestore.instance
                        .collection('shipment_requests')
                        .where('status', isEqualTo: 'open')
                        .snapshots()),
                _TileDef(l.myDeliveries, Icons.directions_boat_rounded,
                        () => onTabChange(3),
                    stream: FirebaseFirestore.instance
                        .collection('shipments')
                        .where('agentId', isEqualTo: uid)
                        .snapshots()),
                // Row 2: Chats, In Transit
                _TileDef(l.chats, Icons.chat_bubble_rounded,
                        () => onTabChange(2),
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: uid)
                        .snapshots()),
                // Broadened from strictly 'in_transit' to any
                // status the agent is actively handling —
                // confirmed (just assigned) through picked_up
                // and in_transit — per request: "keep the
                // confirmed ones in In Transit box".
                _TileDef(l.inTransit, Icons.directions_boat_rounded,
                        () => onTabChange(3),
                    stream: FirebaseFirestore.instance
                        .collection('shipments')
                        .where('agentId', isEqualTo: uid)
                        .where('status', whereIn: [
                      'confirmed', 'picked_up', 'in_transit'
                    ])
                        .snapshots()),
              ]
                  : [
                // BUYER — Row 1: Chats, Market
                _TileDef(l.chats, Icons.chat_bubble_rounded,
                        () => onTabChange(2),
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: uid)
                        .snapshots()),
                _TileDef(l.market, Icons.storefront_rounded,
                        () => onTabChange(1)), // no count — thousands of items
                // Row 2: In Transit, My Cart
                _TileDef(l.inTransit, Icons.directions_boat_rounded,
                        () => onTabChange(3),
                    stream: FirebaseFirestore.instance
                        .collection('shipments')
                        .where('buyerId', isEqualTo: uid)
                        .where('status', isEqualTo: 'in_transit')
                        .snapshots()),
                _TileDef(l.myCart, Icons.shopping_cart_rounded,
                        () => Navigator.push(navContext,
                        MaterialPageRoute(builder: (_) => const CartScreen())),
                    staticCount: cart.count),
              ],
            ),
          ),


          // ── AI MARINE NEWS ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: _MarineNewsSection(t: t),
          ),

          // ── QUICK ACTIONS ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.quickActions,
                  style: const TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              if (isSeller) ...[
                // SELLER — remaining quick actions (My Listings, In Transit,
                // Chats, and Post Listing now live in the grid above).
                Row(children: [
                  _quickAction('♻️ ${l.secondHand}', l.listUsedItems,
                      Icons.recycling_rounded, const Color(0xFF4CAF50),
                          () => _push(const SecondHandScreen()), t),
                  const SizedBox(width: 10),
                  _quickAction('🐟 ${l.fishCalendar}', l.bestCatchesByMonth,
                      Icons.calendar_month_rounded, const Color(0xFF4FC3F7),
                          () => _push(const SeasonalCalendarScreen()), t),
                ]),

              ] else if (isAgent) ...[
                // AGENT — remaining quick action (Available Jobs, My
                // Deliveries, and Chats now live in the grid above).
                Row(children: [
                  _quickAction('🐟 ${l.fishCalendar}', l.bestCatchesByMonth,
                      Icons.calendar_month_rounded, const Color(0xFF26C6DA),
                          () => _push(const SeasonalCalendarScreen()), t),
                ]),

              ] else ...[
                // BUYER — remaining quick actions (Market + Cart now live
                // in the grid above).
                Row(children: [
                  _quickAction('♻️ ${l.secondHand}', l.buyUsedItems,
                      Icons.recycling_rounded, const Color(0xFF4CAF50),
                          () => _push(const SecondHandScreen()), t),
                  const SizedBox(width: 10),
                  _quickAction('🐟 ${l.fishCalendar}', l.bestCatchesByMonth,
                      Icons.calendar_month_rounded, const Color(0xFF4FC3F7),
                          () => _push(const SeasonalCalendarScreen()), t),
                ]),
              ],
            ]),
          ),

          // ── RECENT ACTIVITY ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 30),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(l.recentActivity,
                    style: const TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => onTabChange(3),
                  child: Text(l.viewAll,
                      style: TextStyle(color: t.primary.withOpacity(0.75), fontSize: 13)),
                ),
              ]),
              const SizedBox(height: 12),
              _RecentActivity(uid: uid, userRole: userRole, t: t),
            ]),
          ),
        ]),
      ),
    ]);
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'seller': return Icons.storefront_outlined;
      case 'agent':  return Icons.handshake_outlined;
      default:       return Icons.shopping_bag_outlined;
    }
  }

  Widget _quickAction(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap, AppTheme t) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.30))),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 10),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10)),
        ]),
      ),
    ));
  }

}

// ─── NOTIFICATION BELL ────────────────────────────────────────────────────────
class _NotificationBell extends StatelessWidget {
  final AppTheme t;
  final BuildContext navContext;
  const _NotificationBell({required this.t, required this.navContext});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('toUid', isEqualTo: uid)
          .where('read', isEqualTo: false)
          .snapshots(),
      builder: (context, snap) {
        final unread = snap.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(
            navContext,
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: t.card,
                shape: BoxShape.circle,
                border: Border.all(color: t.primary.withOpacity(0.25)),
              ),
              child: Icon(
                unread > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                color: unread > 0 ? t.primary : Colors.white54,
                size: 20,
              ),
            ),
            if (unread > 0)
              Positioned(
                top: -3, right: -3,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }
}

// ─── AI MARINE NEWS ───────────────────────────────────────────────────────────
class _MarineNewsSection extends StatefulWidget {
  final AppTheme t;
  const _MarineNewsSection({required this.t});
  @override
  State<_MarineNewsSection> createState() => _MarineNewsSectionState();
}

class _MarineNewsSectionState extends State<_MarineNewsSection> {
  // TODO: replace with your deployed Cloud Function URL — see the setup
  // instructions at the top of functions/index.js. Until this is a real
  // URL, this section will keep failing over to the static _fallback list
  // below (same as it does with the old direct api.anthropic.com call).
  static const _newsFunctionUrl =
      'https://us-central1-YOUR-PROJECT-ID.cloudfunctions.net/marineNews';

  List<_NewsItem> _items = [];
  bool _loading = true;
  bool _isAI    = false;
  DateTime? _lastRefreshed;

  static const _fallback = [
    _NewsItem(title: 'Bay of Bengal — Fishing Advisory',
        summary: 'Potential fishing zones active 60–90 km off Chennai. Moderate seas expected.',
        category: 'PFZ'),
    _NewsItem(title: 'Kerala Coast — Sea State Update',
        summary: 'South-west swell 2–3 m. Small craft caution advised until Thursday.',
        category: 'ALERT'),
    _NewsItem(title: 'Tuna Season Outlook',
        summary: 'Good yellowfin tuna activity reported in Lakshadweep waters this week.',
        category: 'FISH'),
    _NewsItem(title: 'Cyclone Watch — Arabian Sea',
        summary: 'Low pressure area likely to intensify. Karnataka & Goa fishers advised caution.',
        category: 'CYCLONE'),
  ];

  @override
  void initState() {
    super.initState();
    _items = List.from(_fallback);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAINews());
  }

  Future<void> _fetchAINews() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final now      = DateTime.now();
    final month    = _monthName(now.month);
    final season   = _fishingSeason(now.month);
    final langCode = Localizations.localeOf(context).languageCode;
    // Prompt is now built server-side in functions/index.js — the app only
    // sends the ingredients (month/year/season/langCode), never the API key.
    try {
      final res = await http.post(
        Uri.parse(_newsFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'month':    month,
          'year':     now.year,
          'season':   season,
          'langCode': langCode,
        }),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body  = jsonDecode(res.body);
        final text  = (body['content'] as List)
            .where((b) => b['type'] == 'text')
            .map((b) => b['text'] as String).join('');
        final clean = text
            .replaceAll(RegExp(r'```json\s*'), '')
            .replaceAll(RegExp(r'```\s*'), '').trim();
        final List<dynamic> parsed = jsonDecode(clean);
        final items = parsed.map((e) => _NewsItem(
          title:    (e['title']    ?? '').toString(),
          summary:  (e['summary']  ?? '').toString(),
          category: (e['category'] ?? 'NEWS').toString().toUpperCase(),
        )).toList();
        if (items.isNotEmpty && mounted) {
          setState(() {
            _items = items;
            _loading = false;
            _isAI = true;
            _lastRefreshed = DateTime.now();
          });
          return;
        }
      }
    } catch (e) { debugPrint('Marine news: $e'); }
    if (mounted) setState(() { _loading = false; _lastRefreshed = DateTime.now(); });
  }

  String _monthName(int m) =>
      ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  String _fishingSeason(int m) {
    if (m >= 6 && m <= 7)   return 'Fishing ban season along most Indian coasts';
    if (m >= 8 && m <= 9)   return 'Post-ban — good mackerel and sardine activity';
    if (m >= 10 && m <= 11) return 'Peak season — pomfret, hilsa, and prawn in demand';
    if (m == 12 || m <= 2)  return 'Winter fishing — good rohu, catla, and surmai';
    return 'Pre-ban season — tuna and prawn activity';
  }

  Color _catColor(String c) {
    switch (c) {
      case 'ALERT':      return const Color(0xFFE57373);
      case 'CYCLONE':    return const Color(0xFFFF7043);
      case 'PFZ':        return const Color(0xFF4CAF50);
      case 'FISH':       return const Color(0xFF26C6DA);
      case 'FORECAST':   return const Color(0xFF4FC3F7);
      case 'MARKET':     return const Color(0xFFFFCA28);
      case 'REGULATION': return const Color(0xFFBA68C8);
      default:           return widget.t.primary;
    }
  }

  IconData _catIcon(String c) {
    switch (c) {
      case 'ALERT':      return Icons.warning_amber_rounded;
      case 'CYCLONE':    return Icons.cyclone_rounded;
      case 'PFZ':        return Icons.set_meal_rounded;
      case 'FISH':       return Icons.phishing_rounded;
      case 'FORECAST':   return Icons.waves_rounded;
      case 'MARKET':     return Icons.trending_up_rounded;
      case 'REGULATION': return Icons.gavel_rounded;
      default:           return Icons.info_outline_rounded;
    }
  }

  String _timeAgo() {
    if (_lastRefreshed == null) return '';
    final diff = DateTime.now().difference(_lastRefreshed!);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final t      = widget.t;
    final l      = AppLocalizations.of(context);
    final voice  = Provider.of<VoiceProvider>(context);
    final langProv = Provider.of<LanguageProvider>(context, listen: false);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        // Wrapped in Expanded so this side never claims more room than is
        // actually left after the "INCOIS ↗" link on the right — without
        // this, longer translations of "Marine News" (e.g. French
        // "Actualités Marines") push the row past the screen edge.
        Expanded(
          child: Row(children: [
            Flexible(
              child: Text(l.marineNews,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            // 🔊 Reads every visible headline + summary aloud, in the app's
            // current language, via the shared VoiceProvider — same
            // torch-style instant toggle used elsewhere in the app.
            GestureDetector(
              onTap: () {
                if (voice.isSpeaking) {
                  voice.stop();
                } else if (_items.isNotEmpty) {
                  final combined = _items
                      .map((item) => '${item.title}. ${item.summary}')
                      .join(' ... ');
                  voice.speakInAppLanguage(combined, langProv);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: voice.isSpeaking
                      ? t.primary.withOpacity(0.25)
                      : t.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                  border: voice.isSpeaking
                      ? Border.all(color: t.primary, width: 1)
                      : null,
                ),
                child: Icon(
                  voice.isSpeaking
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_rounded,
                  color: t.primary,
                  size: 13,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _fetchAINews,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (_isAI ? const Color(0xFF7C4DFF) : const Color(0xFFE57373)).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                      color: (_isAI ? const Color(0xFF7C4DFF) : const Color(0xFFE57373)).withOpacity(0.40)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_isAI ? 'AI' : 'LIVE', style: TextStyle(
                      color: _isAI ? const Color(0xFF7C4DFF) : const Color(0xFFE57373),
                      fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(width: 4),
                  Icon(_loading ? Icons.hourglass_top_rounded : Icons.refresh_rounded,
                      color: _isAI ? const Color(0xFF7C4DFF) : const Color(0xFFE57373), size: 10),
                ]),
              ),
            ),
            if (_lastRefreshed != null && !_loading) ...[
              const SizedBox(width: 6),
              Text(_timeAgo(),
                  style: TextStyle(color: Colors.white.withOpacity(0.30), fontSize: 9)),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('https://incois.gov.in'),
              mode: LaunchMode.externalApplication),
          child: Text('INCOIS ↗',
              style: TextStyle(color: t.primary.withOpacity(0.70), fontSize: 12)),
        ),
      ]),
      const SizedBox(height: 10),
      SizedBox(
        height: 140,
        child: _items.isEmpty
            ? Center(child: CircularProgressIndicator(color: t.primary, strokeWidth: 2))
            : ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) {
            final item  = _items[i];
            final color = _catColor(item.category);
            return Container(
              width: 210, padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.42),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.28)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(7)),
                    child: Icon(_catIcon(item.category), color: color, size: 13),
                  ),
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(item.category, style: TextStyle(color: color,
                        fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                  ),
                  if (_loading) ...[const Spacer(), _PulseDot(color: color)],
                ]),
                const SizedBox(height: 8),
                Text(item.title, style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w700, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item.summary, style: TextStyle(color: Colors.white.withOpacity(0.48),
                    fontSize: 9, height: 1.4),
                    maxLines: 3, overflow: TextOverflow.ellipsis),
              ]),
            );
          },
        ),
      ),
      if (_isAI)
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(l.aiGeneratedDisclaimer,
              style: TextStyle(color: Colors.white.withOpacity(0.20), fontSize: 9)),
        ),
    ]);
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(width: 6, height: 6,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
  );
}

class _NewsItem {
  final String title, summary, category;
  const _NewsItem({required this.title, required this.summary, required this.category});
}

// ─── UNIFIED 2x2 DASHBOARD GRID (buyer, seller & agent) ───────────────────────
// Replaces the old split between the top numeric stat row and the separate
// "Quick Actions" row for these two roles — those overlapped (e.g. Market
// showed up in both), which is what made the dashboard feel messy. Now
// there's exactly one grid with the 4 things that matter most per role.
//
// A tile can show a live count in three ways:
//  - `stream`      : count comes from a Firestore query snapshot
//  - `staticCount` : count comes from a plain int (e.g. CartProvider.count)
//  - neither       : no number is shown at all (e.g. Market — thousands of
//                     items, a raw count is meaningless; or Post Listing —
//                     it's an action, not a metric)
class _TileDef {
  final String label;
  final IconData icon;
  final Stream<QuerySnapshot>? stream;
  final int? staticCount;
  final VoidCallback onTap;
  const _TileDef(this.label, this.icon, this.onTap,
      {this.stream, this.staticCount});
}

class _DashboardGrid extends StatelessWidget {
  final List<_TileDef> tiles; // exactly 4: [topLeft, topRight, bottomLeft, bottomRight]
  final AppTheme t;
  const _DashboardGrid({required this.tiles, required this.t});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _tile(tiles[0])),
          const SizedBox(width: 10),
          Expanded(child: _tile(tiles[1])),
        ]),
      ),
      const SizedBox(height: 10),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _tile(tiles[2])),
          const SizedBox(width: 10),
          Expanded(child: _tile(tiles[3])),
        ]),
      ),
    ]);
  }

  Widget _tile(_TileDef def) {
    Widget buildCard(int? count) => GestureDetector(
      onTap: def.onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.primary.withOpacity(0.20)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(width: 30, height: 30,
                decoration: BoxDecoration(color: t.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(9)),
                child: Icon(def.icon, color: t.primary, size: 15)),
            Icon(Icons.north_east_rounded,
                color: t.primary.withOpacity(0.45), size: 13),
          ]),
          const SizedBox(height: 8),
          if (count != null)
            Text('$count', style: const TextStyle(color: Colors.white,
                fontSize: 24, fontWeight: FontWeight.w800))
          else
            const SizedBox(height: 27), // keeps label baseline aligned across tiles
          const SizedBox(height: 2),
          Text(def.label,
              style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 10),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );

    if (def.stream != null) {
      return StreamBuilder<QuerySnapshot>(
        stream: def.stream,
        builder: (_, snap) => buildCard(snap.data?.docs.length ?? 0),
      );
    }
    return buildCard(def.staticCount);
  }
}

// ─── RECENT ACTIVITY ──────────────────────────────────────────────────────────
class _RecentActivity extends StatelessWidget {
  final String uid, userRole;
  final AppTheme t;
  const _RecentActivity({required this.uid, required this.userRole, required this.t});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final stream = userRole == 'seller'
        ? FirebaseFirestore.instance.collection('shipments')
        .where('sellerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true).limit(3).snapshots()
        : FirebaseFirestore.instance.collection('shipments')
        .where('buyerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true).limit(3).snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(children: [
              Container(width: 50, height: 50,
                  decoration: BoxDecoration(color: t.primary.withOpacity(0.12),
                      shape: BoxShape.circle),
                  child: Icon(Icons.anchor_rounded,
                      color: t.primary.withOpacity(0.45), size: 24)),
              const SizedBox(height: 10),
              Text(l.noActivity,
                  style: TextStyle(color: Colors.white.withOpacity(0.50),
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          );
        }
        return Column(children: docs.map((doc) {
          final data      = doc.data() as Map<String, dynamic>;
          final status    = (data['status'] ?? 'pending') as String;
          final label     = status[0].toUpperCase() + status.substring(1).replaceAll('_', ' ');
          final delivered = status == 'delivered';
          return Container(
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.38),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: delivered ? Colors.green.withOpacity(0.25) : Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: delivered ? Colors.green.withOpacity(0.12) : t.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(delivered ? Icons.check_circle_rounded : Icons.directions_boat_rounded,
                      color: delivered ? Colors.green : t.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['listingTitle'] ?? l.orderFallback,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(userRole == 'seller'
                    ? '${l.buyerPrefix}: ${data['buyerName'] ?? l.unknownUser}'
                    : '${l.sellerPrefix}: ${data['sellerName'] ?? l.unknownUser}',
                    style: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 11)),
              ])),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: delivered ? Colors.green.withOpacity(0.12) : t.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(label, style: TextStyle(
                      color: delivered ? Colors.green : t.primary,
                      fontSize: 10, fontWeight: FontWeight.w700))),
            ]),
          );
        }).toList());
      },
    );
  }
}

// ─── PROFILE TAB ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final String userName, userRole;
  final VoidCallback onLogout;
  const _ProfileTab({required this.userName, required this.userRole, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final t    = Provider.of<ThemeProvider>(context).current;
    final l    = AppLocalizations.of(context);
    final lp   = Provider.of<LanguageProvider>(context);
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft,
                end: Alignment.bottomRight, colors: [t.card, t.background]),
          ),
          child: Column(children: [
            Container(width: 76, height: 76,
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.80), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: t.primary.withOpacity(0.30),
                      blurRadius: 20, offset: const Offset(0, 6))],
                ),
                child: Center(child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.black,
                      fontSize: 30, fontWeight: FontWeight.w800),
                ))),
            const SizedBox(height: 12),
            Text(userName.isEmpty ? l.userFallback : userName,
                style: const TextStyle(color: Colors.white,
                    fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(user?.email ?? '',
                style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 12)),
            const SizedBox(height: 9),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: t.primary.withOpacity(0.35)),
                ),
                child: Text(roleLabel(userRole, l),
                    style: TextStyle(color: t.primary, fontSize: 10,
                        fontWeight: FontWeight.w700, letterSpacing: 1.4))),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(children: [
            _section(context, l.personalisation, [
              _MenuItem(Icons.palette_rounded, l.appTheme, l.chooseColourScheme, t,
                      () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const ThemePickerScreen()))),
              _MenuItem(Icons.language_rounded, l.language,
                  '${lp.currentFlag} ${lp.currentLanguageName}', t,
                      () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const LanguageScreen()))),
              _MenuItem(Icons.person_rounded, l.editProfile, l.updateYourDetails, t,
                      () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const AccountSettingsScreen()))),
            ], t),
            const SizedBox(height: 14),
            _section(context, l.preferences, [
              _MenuItem(Icons.notifications_rounded, l.notifications, l.manageAlerts, t,
                      () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(showSettingsToggles: true)))),
              _MenuItem(Icons.shield_rounded, l.privacy, l.controlYourData, t,
                      () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const PrivacyScreen()))),
            ], t),
            const SizedBox(height: 14),
            _section(context, l.support, [
              _MenuItem(Icons.help_rounded, l.help, l.faqsAndLiveChat, t,
                      () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen()))),
              _MenuItem(Icons.description_rounded, l.terms, l.legalInformation, t,
                      () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const TermsScreen()))),
              _MenuItem(Icons.info_rounded, l.about, l.versionAndCompanyInfo, t,
                      () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const AboutScreen()))),
            ], t),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.22)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 17),
                  const SizedBox(width: 7),
                  Text(l.signOut, style: const TextStyle(color: Colors.redAccent,
                      fontWeight: FontWeight.w700, fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ]),
    );
  }

  Widget _section(BuildContext context, String title, List<_MenuItem> items, AppTheme t) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 3, bottom: 7),
        child: Text(title, style: TextStyle(color: t.primary.withOpacity(0.55),
            fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
      ),
      Container(
        decoration: BoxDecoration(color: t.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Column(children: List.generate(items.length, (i) {
          final item   = items[i];
          final isLast = i == items.length - 1;
          return Column(children: [
            GestureDetector(
              onTap: item.onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Container(width: 34, height: 34,
                      decoration: BoxDecoration(color: t.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(9)),
                      child: Icon(item.icon, color: t.primary, size: 17)),
                  const SizedBox(width: 13),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.label, style: const TextStyle(color: Colors.white,
                        fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(item.subtitle, style: TextStyle(
                        color: Colors.white.withOpacity(0.32), fontSize: 11)),
                  ])),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.13), size: 12),
                ]),
              ),
            ),
            if (!isLast) Divider(color: Colors.white.withOpacity(0.04), height: 1, indent: 63),
          ]);
        })),
      ),
    ]);
  }
}

class _MenuItem {
  final IconData icon;
  final String label, subtitle;
  final AppTheme t;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.subtitle, this.t, this.onTap);
}