import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});
  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
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
        setState(() =>
        _userRole = (doc.data() as Map?)?['role']?.toString() ?? '');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t       = Provider.of<ThemeProvider>(context).current;
    final user    = FirebaseAuth.instance.currentUser;
    final isAgent = _userRole == 'agent';

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Header ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Shipments',
                  style: TextStyle(color: Colors.white,
                      fontSize: 22, fontWeight: FontWeight.w800)),
              Text(
                  isAgent
                      ? 'Open shipment requests — apply to deliver'
                      : 'All your orders & deliveries',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 12)),
            ]),
          ),

          if (isAgent) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                      color: t.primary,
                      borderRadius: BorderRadius.circular(10)),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white.withOpacity(0.45),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Open Requests'),
                    Tab(text: 'My Shipments'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _OpenRequestsFeed(t: t, user: user),
                  _MyShipmentsTab(t: t, user: user, userRole: _userRole),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Expanded(
              child: _MyShipmentsTab(t: t, user: user, userRole: _userRole),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─── OPEN REQUESTS FEED (agent tab 1) ────────────────────────────────────────
// Shows ALL open shipment_requests as a live feed — Rapido-style
class _OpenRequestsFeed extends StatelessWidget {
  final AppTheme t;
  final User? user;
  const _OpenRequestsFeed({required this.t, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shipment_requests')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: t.primary, strokeWidth: 2));
        }

        var docs = List<QueryDocumentSnapshot>.from(
            snap.data?.docs ?? []);

        docs.sort((a, b) {
          final at = (a.data() as Map)['createdAt'] as Timestamp?;
          final bt = (b.data() as Map)['createdAt'] as Timestamp?;
          if (at == null || bt == null) return 0;
          return bt.compareTo(at);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_boat_outlined,
                      color: t.primary.withOpacity(0.2), size: 56),
                  const SizedBox(height: 14),
                  Text('No open requests right now',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Check back soon — sellers post new ones often',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 12)),
                ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _RouteRequestCard(
              data: data,
              requestId: docs[i].id,
              agentId: user?.uid ?? '',
              t: t,
            );
          },
        );
      },
    );
  }
}

// ─── ROUTE REQUEST CARD ───────────────────────────────────────────────────────
class _RouteRequestCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String requestId;
  final String agentId;
  final AppTheme t;
  const _RouteRequestCard({
    required this.data,
    required this.requestId,
    required this.agentId,
    required this.t,
  });
  @override
  State<_RouteRequestCard> createState() => _RouteRequestCardState();
}

class _RouteRequestCardState extends State<_RouteRequestCard> {
  bool _applying = false;

  Future<String> _getAgentName() async {
    if (widget.agentId.isEmpty) return 'Agent';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(widget.agentId).get();
      return (doc.data() as Map?)?['name']?.toString() ?? 'Agent';
    } catch (_) {
      return 'Agent';
    }
  }

  Future<void> _applyForJob(BuildContext context) async {
    final applicants = (widget.data['applicants'] ?? []) as List;
    final alreadyApplied =
    applicants.any((a) => a['agentId'] == widget.agentId);

    if (alreadyApplied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('You already applied for this request.'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.t.card,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apply for this shipment?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          '${widget.data['pickupPort'] ?? 'Origin'} → '
              '${widget.data['dropoffPort'] ?? 'Destination'}\n\n'
              'The seller will review your application and confirm you.',
          style: TextStyle(
              color: Colors.white.withOpacity(0.55), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style:
                TextStyle(color: Colors.white.withOpacity(0.4))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: widget.t.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Apply',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _applying = true);
    try {
      final agentName = await _getAgentName();

      await FirebaseFirestore.instance
          .collection('shipment_requests')
          .doc(widget.requestId)
          .update({
        'applicants': FieldValue.arrayUnion([{
          'agentId':   widget.agentId,
          'agentName': agentName,
          'appliedAt': DateTime.now().toIso8601String(),
        }]),
      });

      // Notify the seller — writes to the top-level `notifications`
      // collection with `toUid`, same as every other notification type,
      // so it actually shows up in NotificationsScreen's query.
      final sellerId = widget.data['sellerId'] ?? '';
      if (sellerId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('notifications')
            .add({
          'toUid':        sellerId,
          'type':         'agent_applied',
          'title':        'Agent Applied for Your Shipment',
          'message':      '$agentName wants to deliver: '
              '${widget.data['listingTitle'] ?? 'your order'}',
          'listingTitle': widget.data['listingTitle'] ?? '',
          'requestId':    widget.requestId,
          'agentId':      widget.agentId,
          'agentName':    agentName,
          'createdAt':    FieldValue.serverTimestamp(),
          'read':         false,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text(
              'Application sent! Waiting for seller to confirm.'),
          backgroundColor: widget.t.primary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
          duration: const Duration(seconds: 2),
        ));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t          = widget.t;
    final data       = widget.data;
    final pickup     = data['pickupPort']   ?? 'Not specified';
    final dropoff    = data['dropoffPort']  ?? 'Not specified';
    final title      = data['listingTitle'] ?? 'Shipment';
    final qty        = data['quantityKg']   ?? 0;
    final price      = data['totalPrice']   ?? 0;
    final sellerName = data['sellerName']   ?? 'Seller';
    final applicants = (data['applicants']  ?? []) as List;
    final alreadyApplied =
    applicants.any((a) => a['agentId'] == widget.agentId);
    final ts      = data['createdAt'] as Timestamp?;
    final timeAgo = ts != null ? _fmt(ts.toDate()) : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: alreadyApplied
                ? t.primary.withOpacity(0.50)
                : t.primary.withOpacity(0.18)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Title row ──────────────────────────────────────────────────
        Row(children: [
          Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11)),
              child: Icon(Icons.anchor_rounded, color: t.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700, fontSize: 14),
                overflow: TextOverflow.ellipsis),
            Text('By $sellerName'
                '${timeAgo.isNotEmpty ? "  ·  $timeAgo" : ""}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.30), fontSize: 11)),
          ])),
          if (alreadyApplied)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(7)),
              child: Text('APPLIED',
                  style: TextStyle(color: t.primary,
                      fontSize: 9, fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
            ),
        ]),

        const SizedBox(height: 14),

        // ── Route ──────────────────────────────────────────────────────
        Row(children: [
          Expanded(child: _portBox(
              Icons.circle, 'PICKUP', pickup, t, t.primary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded,
                color: t.primary.withOpacity(0.6), size: 18),
          ),
          Expanded(child: _portBox(
              Icons.location_on_rounded, 'DROPOFF', dropoff, t,
              Colors.green)),
        ]),

        const SizedBox(height: 12),

        // ── Chips ──────────────────────────────────────────────────────
        Row(children: [
          _chip(Icons.scale_outlined, '$qty kg', t),
          const SizedBox(width: 8),
          _chip(Icons.currency_rupee, '₹$price', t),
          const SizedBox(width: 8),
          _chip(Icons.people_outline_rounded,
              '${applicants.length} applied', t),
        ]),

        const SizedBox(height: 14),

        // ── Apply button ───────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_applying || alreadyApplied)
                ? null
                : () => _applyForJob(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: alreadyApplied
                  ? t.primary.withOpacity(0.10)
                  : t.primary,
              foregroundColor:
              alreadyApplied ? t.primary : Colors.black,
              disabledBackgroundColor: t.primary.withOpacity(0.10),
              disabledForegroundColor: t.primary,
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _applying
                ? SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    color: t.primary, strokeWidth: 2))
                : Text(
                alreadyApplied
                    ? '✓ Application Sent'
                    : 'Apply for This Shipment',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ]),
    );
  }

  Widget _portBox(IconData icon, String label,
      String value, AppTheme t, Color color) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.15))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(color: color.withOpacity(0.7),
                  fontSize: 9, fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 3),
          Row(children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Expanded(child: Text(value,
                style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w600),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ]),
      );

  Widget _chip(IconData icon, String label, AppTheme t) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: t.primary, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      );

  String _fmt(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours   < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ─── MY SHIPMENTS TAB (all roles) ─────────────────────────────────────────────
class _MyShipmentsTab extends StatelessWidget {
  final AppTheme t;
  final User? user;
  final String userRole;
  const _MyShipmentsTab(
      {required this.t, required this.user, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final uid = user?.uid ?? '';
    Stream<QuerySnapshot> stream;

    if (userRole == 'seller') {
      stream = FirebaseFirestore.instance
          .collection('shipments')
          .where('sellerId', isEqualTo: uid)
          .snapshots();
    } else if (userRole == 'agent') {
      stream = FirebaseFirestore.instance
          .collection('shipments')
          .where('agentId', isEqualTo: uid)
          .snapshots();
    } else {
      stream = FirebaseFirestore.instance
          .collection('shipments')
          .where('buyerId', isEqualTo: uid)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
              child: Text('Error loading shipments',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4))));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(
                  color: t.primary, strokeWidth: 2));
        }

        final docs =
        List<QueryDocumentSnapshot>.from(snap.data?.docs ?? [])
          ..sort((a, b) {
            final at =
            (a.data() as Map)['createdAt'] as Timestamp?;
            final bt =
            (b.data() as Map)['createdAt'] as Timestamp?;
            if (at == null || bt == null) return 0;
            return bt.compareTo(at);
          });

        if (userRole == 'seller') {
          return _SellerShipmentsView(docs: docs, uid: uid, t: t);
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_boat_outlined,
                      color: t.primary.withOpacity(0.2), size: 56),
                  const SizedBox(height: 14),
                  Text('No shipments yet',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                      userRole == 'agent'
                          ? 'Apply for a request from Open Requests tab'
                          : 'Orders you place appear here',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 12)),
                ]),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return _ShipmentCard(
              data: data,
              docId: docs[i].id,
              isBuyer: data['buyerId'] == uid,
              isSeller: data['sellerId'] == uid,
              isAgent: data['agentId'] == uid,
              t: t,
            );
          },
        );
      },
    );
  }
}

// ─── SELLER SHIPMENTS VIEW ────────────────────────────────────────────────────
class _SellerShipmentsView extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  final String uid;
  final AppTheme t;
  const _SellerShipmentsView(
      {required this.docs, required this.uid, required this.t});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shipment_requests')
          .where('sellerId', isEqualTo: uid)
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, reqSnap) {
        final requests =
        List<QueryDocumentSnapshot>.from(
            reqSnap.data?.docs ?? [])
          ..sort((a, b) {
            final at =
            (a.data() as Map)['createdAt'] as Timestamp?;
            final bt =
            (b.data() as Map)['createdAt'] as Timestamp?;
            if (at == null || bt == null) return 0;
            return bt.compareTo(at);
          });

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [

            if (requests.isNotEmpty) ...[
              _sectionHeader('Awaiting Agent', t),
              const SizedBox(height: 10),
              ...requests.map((req) {
                final data = req.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ShipmentRequestCard(
                      data: data,
                      requestId: req.id,
                      sellerId: uid,
                      t: t),
                );
              }),
              const SizedBox(height: 8),
            ],

            if (docs.isNotEmpty) ...[
              _sectionHeader('Your Shipments', t),
              const SizedBox(height: 10),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ShipmentCard(
                    data: data,
                    docId: doc.id,
                    isBuyer: false,
                    isSeller: true,
                    isAgent: false,
                    t: t,
                  ),
                );
              }),
            ],

            if (requests.isEmpty && docs.isEmpty)
              Center(
                child: Column(children: [
                  const SizedBox(height: 60),
                  Icon(Icons.directions_boat_outlined,
                      color: t.primary.withOpacity(0.2), size: 56),
                  const SizedBox(height: 14),
                  Text('No shipments yet',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Post a listing to get shipment requests',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 12)),
                ]),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title, AppTheme t) => Text(title,
      style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700));
}

// ─── SHIPMENT REQUEST CARD (seller side) ─────────────────────────────────────
class _ShipmentRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String requestId;
  final String sellerId;
  final AppTheme t;
  const _ShipmentRequestCard({
    required this.data,
    required this.requestId,
    required this.sellerId,
    required this.t,
  });

  /// Creates (or reuses, via merge) a 1:1 chat between any two people —
  /// same chatId scheme (sorted UIDs joined with '_') and document shape
  /// that listing_detail_screen.dart's _openChat() already uses for
  /// buyer-seller chats, so ChatListScreen/ChatScreen pick these up with
  /// no other changes needed. Called twice below: buyer↔agent and
  /// seller↔agent, the moment the seller confirms an agent.
  Future<void> _ensureChat({
    required String uidA,
    required String nameA,
    required String uidB,
    required String nameB,
    required String listingTitle,
  }) async {
    if (uidA.isEmpty || uidB.isEmpty) return;
    final chatId = ([uidA, uidB]..sort()).join('_');
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants':    [uidA, uidB],
      'listingTitle':    listingTitle,
      'lastMessage':     '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastUpdated':     FieldValue.serverTimestamp(),
      // Generic name lookup so ChatListScreen can resolve "the other
      // person's name" for ANY two-participant chat, not just the
      // sellerName/buyerName-specific shape the original listing chats
      // use (those two fields don't make sense for a buyer↔agent or
      // seller↔agent chat — there's no "seller" role in that pair).
      'participantNames': {uidA: nameA, uidB: nameB},
    }, SetOptions(merge: true));
  }

  Future<void> _confirmAgent(
      BuildContext context, Map<String, dynamic> applicant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm this agent?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          '${applicant['agentName']} will be assigned to deliver:\n'
              '"${data['listingTitle'] ?? 'Order'}"',
          style: TextStyle(
              color: Colors.white.withOpacity(0.55), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.4))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Confirm Agent',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final batch = FirebaseFirestore.instance.batch();

    batch.update(
        FirebaseFirestore.instance
            .collection('shipment_requests')
            .doc(requestId),
        {
          'status':         'filled',
          'confirmedAgent': applicant,
          'updatedAt':      FieldValue.serverTimestamp(),
        });

    final shipmentId = data['shipmentId'] as String?;
    if (shipmentId != null && shipmentId.isNotEmpty) {
      batch.update(
          FirebaseFirestore.instance
              .collection('shipments')
              .doc(shipmentId),
          {
            'agentId':   applicant['agentId'],
            'agentName': applicant['agentName'],
            'status':    'confirmed',
            'updatedAt': FieldValue.serverTimestamp(),
          });
    }

    await batch.commit();

    final agentId      = applicant['agentId'] as String? ?? '';
    final agentName    = applicant['agentName'] as String? ?? 'Agent';
    final buyerId      = data['buyerId'] as String? ?? '';
    final buyerName    = data['buyerName'] as String? ?? 'Buyer';
    final sellerName   = data['sellerName'] as String? ?? 'Seller';
    final listingTitle = data['listingTitle'] as String? ?? 'Order';

    // Auto-create the two delivery-logistics chats now that an agent is
    // assigned: seller↔agent (pickup details) and buyer↔agent (delivery
    // details). The buyer↔seller chat about the product itself already
    // exists separately from listing_detail_screen.dart — this doesn't
    // touch that one.
    await Future.wait([
      _ensureChat(
        uidA: sellerId, nameA: sellerName,
        uidB: agentId,  nameB: agentName,
        listingTitle: listingTitle,
      ),
      _ensureChat(
        uidA: buyerId, nameA: buyerName,
        uidB: agentId, nameB: agentName,
        listingTitle: listingTitle,
      ),
    ]);

    // Notify the agent — writes to the top-level `notifications`
    // collection with `toUid`, same as every other notification type,
    // so it actually shows up in NotificationsScreen's query.
    if (agentId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'toUid':        agentId,
        'type':         'agent_confirmed',
        'title':        'You\'ve been confirmed!',
        'message':      'Seller confirmed you for: '
            '$listingTitle. '
            'Check My Shipments.',
        'agentName':    agentName,
        'listingTitle': listingTitle,
        'createdAt':    FieldValue.serverTimestamp(),
        'read':         false,
      });
    }

    // 🔔 Also notify the buyer — a delivery agent has been assigned to
    // their order, and a buyer↔agent chat is now ready for them to use.
    if (buyerId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .add({
        'toUid':        buyerId,
        'type':         'shipment_assigned',
        'title':        'Agent Assigned to Your Order 🚚',
        'body':         '$agentName will deliver $listingTitle. '
            'You can message them in Chats.',
        'agentName':    agentName,
        'listingTitle': listingTitle,
        'createdAt':    FieldValue.serverTimestamp(),
        'read':         false,
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$agentName confirmed as agent! 🚢'),
        backgroundColor: t.primary,
        behavior: SnackBarBehavior.floating,
        margin:
        const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup     = data['pickupPort']   ?? '';
    final dropoff    = data['dropoffPort']  ?? '';
    final title      = data['listingTitle'] ?? 'Shipment';
    final applicants = (data['applicants']  ?? []) as List;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.30)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [
          Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.pending_actions_rounded,
                  color: Colors.orange, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                Text('$pickup  →  $dropoff',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.40),
                        fontSize: 11)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(7)),
            child: Text('${applicants.length} APPLIED',
                style: const TextStyle(color: Colors.orange,
                    fontSize: 9, fontWeight: FontWeight.w800,
                    letterSpacing: 0.8)),
          ),
        ]),

        if (applicants.isEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Icon(Icons.hourglass_top_rounded,
                  color: Colors.white.withOpacity(0.20), size: 24),
              const SizedBox(height: 6),
              Text('Waiting for agents to apply...',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.30),
                      fontSize: 12)),
            ]),
          ),
        ] else ...[
          const SizedBox(height: 14),
          Text('Agents who applied:',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...applicants.map((a) {
            final ap   = a as Map<String, dynamic>;
            final name = ap['agentName'] ?? 'Agent';
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                  color: t.primary.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: t.primary.withOpacity(0.18))),
              child: Row(children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: t.primary.withOpacity(0.15),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : 'A',
                        style: TextStyle(color: t.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('Going your route',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 11)),
                    ])),
                ElevatedButton(
                  onPressed: () => _confirmAgent(context, ap),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9)),
                    elevation: 0,
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ]),
            );
          }),
        ],
      ]),
    );
  }
}

// ─── SHIPMENT PROGRESS CARD ───────────────────────────────────────────────────
class _ShipmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isBuyer, isSeller, isAgent;
  final AppTheme t;
  const _ShipmentCard({
    required this.data,
    required this.docId,
    required this.isBuyer,
    required this.isSeller,
    required this.isAgent,
    required this.t,
  });

  static const _steps  = [
    'pending', 'confirmed', 'picked_up', 'in_transit', 'delivered'
  ];
  static const _labels = [
    'Pending', 'Confirmed', 'Picked Up', 'In Transit', 'Delivered'
  ];
  static const _icons  = [
    Icons.hourglass_empty,
    Icons.check_circle_outline,
    Icons.inventory_2_outlined,
    Icons.directions_boat_outlined,
    Icons.where_to_vote_outlined,
  ];

  Future<void> _advance(BuildContext context, int nextIndex) async {
    await FirebaseFirestore.instance
        .collection('shipments')
        .doc(docId)
        .update({
      'status':    _steps[nextIndex],
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 🔔 Notify the buyer — this was the missing piece: nothing in the
    // app previously ever wrote a notification with toUid == buyerId,
    // so buyers' notification screens were always empty no matter what
    // happened to their order.
    final buyerId = data['buyerId'] as String? ?? '';
    if (buyerId.isNotEmpty) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid':        buyerId,
        'type':         'shipment_update',
        'title':        'Order Update 🚢',
        'body':         '${data['listingTitle'] ?? 'Your order'} is now '
            '${_labels[nextIndex]}',
        'listingTitle': data['listingTitle'] ?? '',
        'status':       _steps[nextIndex],
        'statusLabel':  _labels[nextIndex],
        'shipmentId':   docId,
        'createdAt':    FieldValue.serverTimestamp(),
        'read':         false,
      });
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status updated to ${_labels[nextIndex]}'),
        backgroundColor: t.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _requestShipment(BuildContext context) async {
    final pickupCtrl = TextEditingController();
    final t = this.t;
    // Buyer's delivery address, captured at checkout in cart_screen.dart.
    // Shown read-only here instead of another blank text field — the
    // seller has no way to know where the buyer wants delivery, so this
    // was showing up empty on the request card before (see the DROPOFF
    // box with no text underneath it).
    final dropoffAddress = (data['buyerAddress'] as String?)?.trim() ?? '';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: t.background,
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: t.primary.withOpacity(0.18)),
          ),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 38, height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Request a Shipment Agent',
                    style: TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('Agents travelling this route will apply',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.40),
                        fontSize: 12)),
                const SizedBox(height: 20),
                _portField(pickupCtrl, '📍 Pickup Port',
                    'e.g. Chennai Port', t),
                const SizedBox(height: 12),
                // Read-only — pulled from what the buyer entered at
                // checkout, never typed blind by the seller.
                Text('🏁 Dropoff Port',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: dropoffAddress.isEmpty
                        ? Colors.redAccent.withOpacity(0.08)
                        : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(11),
                    border: dropoffAddress.isEmpty
                        ? Border.all(color: Colors.redAccent.withOpacity(0.3))
                        : null,
                  ),
                  child: Text(
                    dropoffAddress.isEmpty
                        ? 'No delivery address on file for this order'
                        : dropoffAddress,
                    style: TextStyle(
                        color: dropoffAddress.isEmpty
                            ? Colors.redAccent.withOpacity(0.85)
                            : Colors.white,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: dropoffAddress.isEmpty
                        ? null
                        : () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.primary,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: t.primary.withOpacity(0.2),
                      minimumSize:
                      const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13)),
                      elevation: 0,
                    ),
                    child: const Text('Post Request',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                  ),
                ),
              ]),
        ),
      ),
    );
    if (confirmed != true) return;
    if (pickupCtrl.text.trim().isEmpty || dropoffAddress.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('shipment_requests')
        .add({
      'shipmentId':   docId,
      'sellerId':     data['sellerId'],
      'sellerName':   data['sellerName'],
      'buyerId':      data['buyerId'],
      'buyerName':    data['buyerName'],
      'listingTitle': data['listingTitle'],
      'quantityKg':   data['quantityKg'],
      'totalPrice':   data['totalPrice'],
      'pickupPort':   pickupCtrl.text.trim(),
      'dropoffPort':  dropoffAddress,
      'status':       'open',
      'applicants':   [],
      'createdAt':    FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Shipment request posted! Agents can now apply. 🚢'),
        backgroundColor: t.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  static Widget _portField(TextEditingController ctrl,
      String label, String hint, AppTheme t) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.20)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.06),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none),
          ),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    final status      = data['status'] ?? 'pending';
    final stepIndex   =
    _steps.indexOf(status).clamp(0, _steps.length - 1);
    final isDelivered = status == 'delivered';
    final totalPrice  = data['totalPrice'] ?? 0;
    final qty         = data['quantityKg'] ?? 0;
    final hasAgent    =
        (data['agentId'] ?? '').toString().isNotEmpty;

    final canAdvance = !isDelivered &&
        stepIndex < _steps.length - 1 &&
        (isAgent && stepIndex >= 1 && stepIndex <= 3);
    final sellerCanRequest =
        isSeller && !hasAgent && status == 'pending';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDelivered
                ? Colors.green.withOpacity(0.3)
                : t.primary.withOpacity(0.15)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(children: [
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['listingTitle'] ?? 'Order',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  isBuyer
                      ? 'Seller: ${data['sellerName'] ?? ''}'
                      : isAgent
                      ? 'From: ${data['sellerName'] ?? ''} → '
                      '${data['buyerName'] ?? ''}'
                      : 'Buyer: ${data['buyerName'] ?? ''}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 12),
                ),
                if (qty != 0 || totalPrice != 0) ...[
                  const SizedBox(height: 3),
                  Text('$qty kg  •  ₹$totalPrice',
                      style: TextStyle(
                          color: t.primary.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
                if (hasAgent && data['agentName'] != null) ...[
                  const SizedBox(height: 3),
                  Text('Agent: ${data['agentName']}',
                      style: TextStyle(
                          color: Colors.purple.withOpacity(0.8),
                          fontSize: 11)),
                ],
              ])),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDelivered
                  ? Colors.green.withOpacity(0.12)
                  : t.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_labels[stepIndex],
                style: TextStyle(
                    color: isDelivered ? Colors.green : t.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ]),

        const SizedBox(height: 20),

        // ── Progress stepper ───────────────────────────────────────────
        Row(
          children: List.generate(_steps.length, (i) {
            final done   = i <= stepIndex;
            final active = i == stepIndex;
            return Expanded(
              child: Row(children: [
                Column(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? (isDelivered
                          ? Colors.green
                          : t.primary)
                          : t.background,
                      border: Border.all(
                        color: done
                            ? (isDelivered
                            ? Colors.green
                            : t.primary)
                            : Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(_icons[i],
                        size: 13,
                        color: done
                            ? Colors.black
                            : Colors.white.withOpacity(0.25)),
                  ),
                  const SizedBox(height: 4),
                  Text(_labels[i],
                      style: TextStyle(
                          color: done
                              ? Colors.white
                              : Colors.white.withOpacity(0.25),
                          fontSize: 8,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.normal),
                      textAlign: TextAlign.center),
                ]),
                if (i < _steps.length - 1)
                  Expanded(
                    child: Container(
                        height: 1.5,
                        color: i < stepIndex
                            ? (isDelivered
                            ? Colors.green
                            : t.primary)
                            : Colors.white.withOpacity(0.10)),
                  ),
              ]),
            );
          }),
        ),

        if (sellerCanRequest) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _requestShipment(context),
              icon: const Icon(Icons.local_shipping_outlined,
                  size: 17),
              label: const Text('Request Shipment Agent',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.black,
                minimumSize:
                const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],

        if (canAdvance) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _advance(context, stepIndex + 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.primary.withOpacity(0.15),
                foregroundColor: t.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                  'Mark as ${_labels[stepIndex + 1]}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],

        const SizedBox(height: 10),

        Row(children: [
          _roleBadge(),
          if (hasAgent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('AGENT ASSIGNED',
                  style: TextStyle(
                      color: Colors.purple,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _roleBadge() {
    final label = isBuyer
        ? 'YOUR ORDER'
        : isAgent
        ? 'YOUR DELIVERY'
        : 'YOUR SALE';
    final color = isBuyer
        ? Colors.blue
        : isAgent
        ? Colors.purple
        : Colors.green;
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1)),
    );
  }
}