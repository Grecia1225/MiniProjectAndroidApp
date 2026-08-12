import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/app_localizations.dart';
import 'package:mtc/models/listing.dart';
import 'package:mtc/screens/marketplace/listing_detail_screen.dart';
import 'package:mtc/screens/marketplace/create_listing_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = 'All';
  final _searchController  = TextEditingController();
  String _searchQuery      = '';
  String _userRole         = '';
  bool   _roleLoaded       = false;

  // Each label is what shows on the chip.
  // filterKey is what we match against Firestore's 'category' field (contains).
  final List<Map<String, dynamic>> _categories = [
    {'label': 'All',              'filterKey': '',                    'icon': Icons.apps},
    {'label': 'Fresh Fish',       'filterKey': 'fresh fish',          'icon': Icons.set_meal_outlined},
    {'label': 'Prawns & Shrimp',  'filterKey': 'prawn',               'icon': Icons.water},
    {'label': 'Crabs & Lobster',  'filterKey': 'crab',                'icon': Icons.catching_pokemon},
    {'label': 'Squid & Octopus',  'filterKey': 'squid',               'icon': Icons.water_outlined},
    {'label': 'Dried Seafood',    'filterKey': 'dried',               'icon': Icons.inventory_2_outlined},
    {'label': 'Marine Equipment', 'filterKey': 'marine equipment',    'icon': Icons.anchor},
    {'label': 'Boats & Vessels',  'filterKey': 'boat',                'icon': Icons.directions_boat_outlined},
    {'label': 'Fishing Gear',     'filterKey': 'fishing gear',        'icon': Icons.hardware_outlined},
    {'label': 'Ship Parts',       'filterKey': 'ship part',           'icon': Icons.build_outlined},
    {'label': 'Navigation Tools', 'filterKey': 'navigation',          'icon': Icons.explore_outlined},
    {'label': 'Safety Equipment', 'filterKey': 'safety',              'icon': Icons.shield_outlined},
    {'label': 'Ropes & Nets',     'filterKey': 'rope',                'icon': Icons.cable_outlined},
    {'label': 'Other',            'filterKey': 'other',               'icon': Icons.more_horiz},
  ];

  // Returns the filterKey for the currently selected label
  String get _activeFilterKey {
    final match = _categories.firstWhere(
          (c) => c['label'] == _selectedCategory,
      orElse: () => {'filterKey': ''},
    );
    return (match['filterKey'] as String).toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _roleLoaded = true);
      return;
    }
    try {
      DocumentSnapshot doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {
        doc = await FirebaseFirestore.instance
            .collection('users').doc(uid)
            .get(const GetOptions(source: Source.server));
      }
      if (mounted) {
        setState(() {
          _userRole   = (doc.data() as Map?)?['role']?.toString() ?? '';
          _roleLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _roleLoaded = true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRequestDialog(BuildContext context, AppTheme t) {
    final titleCtrl  = TextEditingController();
    final detailCtrl = TextEditingController();
    final messenger  = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Request a Product',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Can't find what you need? Let sellers know!",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: titleCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Product name (e.g. Fresh Tuna)',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: detailCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Quantity, location, any other details...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)))),
          TextButton(
            onPressed: () async {
              final title   = titleCtrl.text.trim();
              if (title.isEmpty) return;
              final uid     = FirebaseAuth.instance.currentUser?.uid;
              final details = detailCtrl.text.trim();

              Navigator.pop(ctx);

              messenger
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                  content: const Row(children: [
                    SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Sending request...'),
                  ]),
                  backgroundColor: Colors.grey[800],
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 80),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 10),
                ));

              bool saved = false;
              try {
                await FirebaseFirestore.instance
                    .collection('product_requests')
                    .add({
                  'buyerId':   uid,
                  'title':     title,
                  'details':   details,
                  'status':    'open',
                  'createdAt': FieldValue.serverTimestamp(),
                });
                saved = true;
              } catch (e) {
                debugPrint('Save request error: $e');
              }

              if (!saved) {
                messenger
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(
                    content: const Row(children: [
                      Icon(Icons.error_outline, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Expanded(child: Text('Failed to send. Check your connection.')),
                    ]),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.only(
                        left: 16, right: 16, bottom: 80),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    duration: const Duration(seconds: 3),
                  ));
                return;
              }

              messenger
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                  content: const Row(children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Request submitted! Sellers will be notified.')),
                  ]),
                  backgroundColor: const Color(0xFF1D9E75),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(
                      left: 16, right: 16, bottom: 80),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                ));

              _notifySellers(title, uid).catchError(
                      (e) => debugPrint('Seller notify error: $e'));
            },
            child: Text('Submit',
                style: TextStyle(
                    color: t.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _notifySellers(String productTitle, String? buyerUid) async {
    final sellers = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'seller')
        .get();
    final batch = FirebaseFirestore.instance.batch();
    for (final seller in sellers.docs) {
      // Write to top-level notifications collection (matches NotificationsScreen)
      final ref = FirebaseFirestore.instance
          .collection('notifications')
          .doc();
      batch.set(ref, {
        'toUid':        seller.id,
        'fromUid':      buyerUid ?? '',
        'type':         'product_request',
        'title':        'New Product Request 🛍️',
        'body':         '$productTitle — a buyer is looking for this!',
        'productTitle': productTitle,
        'createdAt':    FieldValue.serverTimestamp(),
        'read':         false,
      });
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final t        = Provider.of<ThemeProvider>(context).current;
    final l        = AppLocalizations.of(context);
    final isBuyer  = _userRole == 'buyer';
    final isSeller = _userRole == 'seller';

    // NOTE: intentionally NOT wrapping this in its own Scaffold.
    // MarketplaceScreen is rendered as one of several children inside
    // dashboard_screen.dart's IndexedStack, which already provides a
    // single outer Scaffold for the whole tab area. IndexedStack keeps
    // every tab's widget tree alive (just hidden) instead of disposing it
    // on tab switch, so a second, nested Scaffold here stayed alive
    // permanently in the background. That made ScaffoldMessenger.of(context)
    // calls elsewhere (e.g. the "added to cart" SnackBar in
    // listing_detail_screen.dart) resolve inconsistently once you navigated
    // away and back — the SnackBar could end up anchored to a Scaffold that
    // wasn't the one currently visible, so its auto-dismiss timer fired on
    // the wrong screen and the banner appeared stuck until app restart.
    // Only the dashboard's outer Scaffold should exist for this tab area.
    return Container(
      color: t.background,
      child: SafeArea(
        child: Column(children: [

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.marketplace,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  Text('Marine goods & equipment',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 12)),
                ]),
                if (!_roleLoaded)
                  SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: t.primary.withOpacity(0.4)))
                else if (isBuyer)
                  GestureDetector(
                    onTap: () => _showRequestDialog(context, t),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: t.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t.primary.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Icon(Icons.add_circle_outline,
                            color: t.primary, size: 16),
                        const SizedBox(width: 5),
                        Text('Request',
                            style: TextStyle(color: t.primary,
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  )
                else if (isSeller)
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => CreateListingScreen())),
                      child: Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                            color: t.primary,
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add,
                            color: Colors.black, size: 22),
                      ),
                    ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Search ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: l.search,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                prefixIcon: Icon(Icons.search,
                    color: Colors.white.withOpacity(0.3), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.close,
                        color: Colors.white.withOpacity(0.4), size: 18))
                    : null,
                filled: true,
                fillColor: t.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Category chips ───────────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat      = _categories[i];
                final label    = cat['label'] as String;
                final icon     = cat['icon'] as IconData;
                final selected = _selectedCategory == label;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: selected
                            ? t.primary
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? t.primary
                                : Colors.white.withOpacity(0.06))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon,
                          size: 13,
                          color: selected
                              ? Colors.black
                              : Colors.white.withOpacity(0.25)),
                      const SizedBox(width: 5),
                      Text(label,
                          style: TextStyle(
                              color: selected
                                  ? Colors.black
                                  : Colors.white.withOpacity(0.30),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // ── Listings grid ────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: t.primary));
                }

                var docs = snapshot.data?.docs ?? [];

                // Sort newest first (client-side, avoids composite index)
                docs = List.from(docs)
                  ..sort((a, b) {
                    final aTime = (a.data() as Map)['createdAt'];
                    final bTime = (b.data() as Map)['createdAt'];
                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime);
                  });

                // ── CATEGORY FILTER (contains — handles "Fresh Fish & Seafood" etc.) ──
                if (_selectedCategory != 'All') {
                  final key = _activeFilterKey; // e.g. "fresh fish"
                  docs = docs.where((d) {
                    final cat = ((d.data() as Map)['category'] ?? '')
                        .toString()
                        .toLowerCase();
                    return cat.contains(key);
                  }).toList();
                }

                // ── SEARCH FILTER ────────────────────────────────────────────
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['title'] ?? '')
                        .toString().toLowerCase().contains(_searchQuery) ||
                        (data['sellerLocation'] ?? '')
                            .toString().toLowerCase().contains(_searchQuery) ||
                        (data['category'] ?? '')
                            .toString().toLowerCase().contains(_searchQuery) ||
                        (data['description'] ?? '')
                            .toString().toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.storefront_outlined,
                            color: t.primary.withOpacity(0.3), size: 52),
                        const SizedBox(height: 12),
                        Text(l.noListings,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Try a different search or category',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 12)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: docs.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.56), // taller — fixes overflow on 2-line titles
                  itemBuilder: (_, i) {
                    final listing = Listing.fromDoc(docs[i]);
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ListingDetailScreen(listing: listing))),
                      child: Container(
                        decoration: BoxDecoration(
                            color: t.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: t.primary.withOpacity(0.15))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Image ──────────────────────────────────────
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: listing.imageUrls.isNotEmpty
                                  ? Image.network(
                                  listing.imageUrls.first,
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _placeholder(t, listing.category))
                                  : _placeholder(t, listing.category),
                            ),
                            // ── Text content ───────────────────────────────
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Category chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: t.primary.withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(6)),
                                      child: Text(listing.category,
                                          style: TextStyle(
                                              color: t.primary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    const SizedBox(height: 5),
                                    // Title
                                    Text(listing.title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const Spacer(),
                                    // Price
                                    Text(listing.formattedPrice,
                                        style: TextStyle(
                                            color: t.primary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    const SizedBox(height: 2),
                                    // Quantity
                                    Text(listing.formattedQuantity,
                                        style: TextStyle(
                                            color: Colors.white.withOpacity(0.35),
                                            fontSize: 11)),
                                    const SizedBox(height: 4),
                                    // Location
                                    Row(children: [
                                      Icon(Icons.location_on_outlined,
                                          color: Colors.white.withOpacity(0.3),
                                          size: 11),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          listing.sellerLocation.isNotEmpty
                                              ? listing.sellerLocation
                                              : '—',
                                          style: TextStyle(
                                              color: Colors.white.withOpacity(0.3),
                                              fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ]),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder(AppTheme t, String category) {
    IconData icon = Icons.storefront_outlined;
    final c = category.toLowerCase();
    if (c.contains('fish'))                        icon = Icons.set_meal_outlined;
    else if (c.contains('boat') || c.contains('vessel')) icon = Icons.directions_boat_outlined;
    else if (c.contains('equip') || c.contains('part'))  icon = Icons.build_outlined;
    else if (c.contains('prawn') || c.contains('crab'))  icon = Icons.water;
    return Container(
        height: 110,
        color: t.cardLight,
        child: Icon(icon, color: t.primary.withOpacity(0.3), size: 28));
  }
}