import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/cloudinary_uploader.dart';
import 'package:mtc/screens/chat/chat_screen.dart';

class SecondHandScreen extends StatefulWidget {
  const SecondHandScreen({super.key});
  @override
  State<SecondHandScreen> createState() => _SecondHandScreenState();
}

class _SecondHandScreenState extends State<SecondHandScreen> {
  final _searchController   = TextEditingController();
  String _searchQuery       = '';
  String _selectedCondition = 'All';
  final List<String> _conditions = ['All', 'Like New', 'Good', 'Fair', 'For Parts'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context).current;

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(children: [

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Text('♻️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 7),
                  const Text('Second Hand', style: TextStyle(color: Colors.white,
                      fontSize: 21, fontWeight: FontWeight.w800)),
                ]),
                Text('Buy & sell used marine goods',
                    style: TextStyle(color: Colors.white.withOpacity(0.32), fontSize: 12)),
              ]),
              // Single post button — in the header only
              GestureDetector(
                onTap: () => _showPostDialog(context, t),
                child: Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add, color: Colors.white, size: 22)),
              ),
            ]),
          ),

          const SizedBox(height: 10),

          // Eco banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.08),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.25)),
              ),
              child: Row(children: [
                const Text('♻️', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 9),
                Expanded(child: Text(
                    'Give marine equipment a second life. Reduce waste, save money.',
                    style: TextStyle(color: const Color(0xFF4CAF50).withOpacity(0.85),
                        fontSize: 11, height: 1.4))),
              ]),
            ),
          ),

          const SizedBox(height: 10),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search second hand items...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.22)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.28), size: 19),
                filled: true, fillColor: t.card,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Condition filter
          SizedBox(height: 34,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              scrollDirection: Axis.horizontal,
              itemCount: _conditions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (_, i) {
                final c        = _conditions[i];
                final selected = _selectedCondition == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCondition = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF4CAF50) : t.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected
                          ? const Color(0xFF4CAF50)
                          : Colors.white.withOpacity(0.07)),
                    ),
                    child: Text(c, style: TextStyle(
                        color: selected ? Colors.white : Colors.white.withOpacity(0.55),
                        fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('secondhand')
                  .where('status', isEqualTo: 'available')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50)));
                }
                var docs = snap.data?.docs ?? [];
                docs = List.from(docs)..sort((a, b) {
                  final at = (a.data() as Map)['createdAt'];
                  final bt = (b.data() as Map)['createdAt'];
                  if (at == null || bt == null) return 0;
                  return bt.compareTo(at);
                });
                if (_selectedCondition != 'All') {
                  docs = docs.where((d) =>
                  (d.data() as Map)['condition'] == _selectedCondition).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final m = d.data() as Map<String, dynamic>;
                    return (m['title'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
                        (m['description'] ?? '').toString().toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  // Empty state — no second post button here, header + has it
                  return Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('♻️', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 10),
                    Text('No second hand items yet',
                        style: TextStyle(color: Colors.white.withOpacity(0.45),
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Tap + above to list something!',
                        style: TextStyle(color: Colors.white.withOpacity(0.22), fontSize: 12)),
                  ]));
                }

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  itemCount: docs.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 10,
                      mainAxisSpacing: 10, childAspectRatio: 0.72),
                  itemBuilder: (_, i) {
                    final data      = docs[i].data() as Map<String, dynamic>;
                    final condition = data['condition'] ?? 'Good';
                    final condColor = condition == 'Like New' ? const Color(0xFF4CAF50)
                        : condition == 'Good'  ? const Color(0xFF42A5F5)
                        : condition == 'Fair'  ? Colors.orange
                        : Colors.grey;
                    return GestureDetector(
                      onTap: () => _showItemDetail(context, t, data, docs[i].id),
                      child: Container(
                        decoration: BoxDecoration(color: t.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFF4CAF50).withOpacity(0.13))),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(14)),
                                child: data['imageUrl'] != null &&
                                    (data['imageUrl'] as String).isNotEmpty
                                    ? Image.network(data['imageUrl'],
                                    height: 105, width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _placeholder())
                                    : _placeholder(),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(9),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: condColor.withOpacity(0.13),
                                                borderRadius: BorderRadius.circular(5)),
                                            child: Text(condition, style: TextStyle(
                                                color: condColor, fontSize: 8,
                                                fontWeight: FontWeight.w700))),
                                        const SizedBox(width: 4),
                                        const Text('♻️', style: TextStyle(fontSize: 9)),
                                      ]),
                                      const SizedBox(height: 5),
                                      Text(data['title'] ?? '',
                                          style: const TextStyle(color: Colors.white,
                                              fontWeight: FontWeight.w700, fontSize: 12),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Text('₹${data['price'] ?? 0}',
                                            style: const TextStyle(
                                                color: Color(0xFF4CAF50),
                                                fontWeight: FontWeight.w800, fontSize: 13)),
                                        if (data['originalPrice'] != null) ...[
                                          const SizedBox(width: 5),
                                          Text('₹${data['originalPrice']}',
                                              style: TextStyle(
                                                  color: Colors.white.withOpacity(0.28),
                                                  fontSize: 10,
                                                  decoration: TextDecoration.lineThrough)),
                                        ],
                                      ]),
                                      const SizedBox(height: 3),
                                      Row(children: [
                                        Icon(Icons.location_on_outlined,
                                            color: Colors.white.withOpacity(0.28), size: 10),
                                        const SizedBox(width: 2),
                                        Expanded(child: Text(data['location'] ?? '',
                                            style: TextStyle(
                                                color: Colors.white.withOpacity(0.28),
                                                fontSize: 9),
                                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ]),
                                    ]),
                              ),
                            ]),
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

  Widget _placeholder() => Container(height: 105,
      color: const Color(0xFF4CAF50).withOpacity(0.07),
      child: const Center(child: Text('♻️', style: TextStyle(fontSize: 30))));

  // ── Item detail bottom sheet ───────────────────────────────────────────────
  void _showItemDetail(BuildContext context, AppTheme t,
      Map<String, dynamic> data, String docId) {
    final uid     = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = data['sellerId'] == uid;
    debugPrint('DEBUG isOwner check → currentUser uid: $uid | listing sellerId: ${data['sellerId']} | isOwner: $isOwner');

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, ctrl) => Container(
          decoration: BoxDecoration(color: t.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.18))),
          child: ListView(controller: ctrl,
              padding: const EdgeInsets.all(22), children: [
                Center(child: Container(width: 38, height: 4,
                    decoration: BoxDecoration(color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 14),
                if (data['imageUrl'] != null && (data['imageUrl'] as String).isNotEmpty)
                  ClipRRect(borderRadius: BorderRadius.circular(14),
                      child: Image.network(data['imageUrl'], height: 190,
                          width: double.infinity, fit: BoxFit.cover)),
                const SizedBox(height: 14),
                Row(children: [
                  const Text('♻️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 7),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.13),
                          borderRadius: BorderRadius.circular(7)),
                      child: Text(data['condition'] ?? 'Good',
                          style: const TextStyle(color: Color(0xFF4CAF50),
                              fontSize: 11, fontWeight: FontWeight.w700))),
                ]),
                const SizedBox(height: 7),
                Text(data['title'] ?? '', style: const TextStyle(color: Colors.white,
                    fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 7),
                Row(children: [
                  Text('₹${data['price'] ?? 0}',
                      style: const TextStyle(color: Color(0xFF4CAF50),
                          fontSize: 22, fontWeight: FontWeight.w800)),
                  if (data['originalPrice'] != null) ...[
                    const SizedBox(width: 10),
                    Text('MRP ₹${data['originalPrice']}',
                        style: TextStyle(color: Colors.white.withOpacity(0.28),
                            fontSize: 13, decoration: TextDecoration.lineThrough)),
                  ],
                ]),
                const SizedBox(height: 10),
                Text(data['description'] ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.55),
                        fontSize: 13, height: 1.6)),
                const SizedBox(height: 12),
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      color: Colors.white.withOpacity(0.38), size: 13),
                  const SizedBox(width: 5),
                  Text(data['location'] ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.38), fontSize: 12)),
                ]),
                const SizedBox(height: 22),
                if (isOwner)
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (dCtx) => AlertDialog(
                          backgroundColor: t.card,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          title: const Text('Mark as sold?',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700)),
                          content: Text(
                            'This will remove "${data['title'] ?? 'this item'}" '
                                'from the marketplace permanently.',
                            style: TextStyle(color: Colors.white.withOpacity(0.55)),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(dCtx, false),
                                child: Text('Cancel',
                                    style: TextStyle(color: Colors.white.withOpacity(0.4)))),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(dCtx, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10))),
                                child: const Text('Mark as Sold')),
                          ],
                        ),
                      );
                      if (confirm != true) return;

                      // Deletes the listing outright instead of just
                      // setting status: 'sold' — a sold second-hand item
                      // has no further purpose in this app (no order/
                      // shipment lifecycle like the main marketplace has),
                      // so there's nothing worth keeping it around for.
                      await FirebaseFirestore.instance
                          .collection('secondhand').doc(docId)
                          .delete();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Marked as sold and removed ♻️'),
                            backgroundColor: Color(0xFF4CAF50),
                            behavior: SnackBarBehavior.floating));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                        elevation: 0),
                    child: const Text('Mark as Sold',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  )
                else
                  Column(children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final currentUser = FirebaseAuth.instance.currentUser;
                        if (currentUser == null) return;
                        final sellerId = data['sellerId'] ?? '';
                        if (sellerId.isEmpty) return;
                        final sellerName = data['sellerName'] ?? 'Seller';
                        final itemTitle  = data['title'] ?? 'Second hand item';

                        // Buyer's own name, needed both for the chat's
                        // participantNames map and for the notification
                        // we now send the seller.
                        String buyerName = currentUser.displayName ?? 'Buyer';
                        try {
                          final buyerDoc = await FirebaseFirestore.instance
                              .collection('users').doc(currentUser.uid).get();
                          buyerName = (buyerDoc.data()?['name'] as String?) ?? buyerName;
                        } catch (_) {}

                        final chatId = ([currentUser.uid, sellerId]..sort()).join('_');
                        await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
                          'participants':    [currentUser.uid, sellerId],
                          'listingId':       docId,
                          'listingTitle':    itemTitle,
                          'lastMessage':     '',
                          'lastMessageTime': FieldValue.serverTimestamp(),
                          'lastUpdated':     FieldValue.serverTimestamp(),
                          'buyerId':         currentUser.uid,
                          'sellerId':        sellerId,
                          'sellerName':      sellerName,
                          'buyerName':       buyerName,
                          // Same generic uid->name map every other chat in
                          // the app now writes (see listing_detail_screen.dart
                          // and tracking_screen.dart's _ensureChat) — keeps
                          // ChatListScreen's name lookup consistent.
                          'participantNames': {
                            currentUser.uid: buyerName,
                            sellerId:        sellerName,
                          },
                        }, SetOptions(merge: true));

                        // 🔔 This was the actual gap: nothing told the seller
                        // someone was interested. Unlike the main marketplace
                        // (which fires a cart_add notification), second-hand
                        // has no cart — "Contact Seller" is the ONLY signal a
                        // seller gets, so it needs to notify them directly.
                        await FirebaseFirestore.instance
                            .collection('notifications').add({
                          'toUid':        sellerId,
                          'fromUid':      currentUser.uid,
                          'fromName':     buyerName,
                          'type':         'secondhand_interest',
                          'title':        'Someone\'s Interested! ♻️',
                          'body':         '$buyerName wants to buy your $itemTitle',
                          'listingId':    docId,
                          'listingTitle': itemTitle,
                          'read':         false,
                          'createdAt':    FieldValue.serverTimestamp(),
                        });

                        if (context.mounted) {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId:       chatId,
                                otherName:    sellerName,
                                otherId:      sellerId,
                                listingTitle: itemTitle,
                              )));
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline, size: 17),
                      label: const Text('Contact Seller',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13)),
                          elevation: 0),
                    ),
                    const SizedBox(height: 10),
                    // Buyer-side equivalent of the seller's "Mark as Sold" —
                    // deletes the listing the same way, but is triggered by
                    // whoever bought the item instead of the seller having
                    // to remember to come back and remove it themselves.
                    // No payment verification happens here (this app has no
                    // escrow/payment tracking for second-hand — same trust
                    // model as "Contact Seller" already has), it's purely a
                    // confirmation the item has changed hands.
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dCtx) => AlertDialog(
                            backgroundColor: t.card,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            title: const Text('Mark as purchased?',
                                style: TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w700)),
                            content: Text(
                              'This confirms you bought "${data['title'] ?? 'this item'}" '
                                  'and removes it from the marketplace for everyone.',
                              style: TextStyle(color: Colors.white.withOpacity(0.55)),
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(dCtx, false),
                                  child: Text('Cancel',
                                      style: TextStyle(color: Colors.white.withOpacity(0.4)))),
                              ElevatedButton(
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4CAF50),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10))),
                                  child: const Text('Confirm Purchase')),
                            ],
                          ),
                        );
                        if (confirm != true) return;

                        final buyer    = FirebaseAuth.instance.currentUser;
                        final sellerId = data['sellerId'] ?? '';

                        // Delete the listing — same as the seller's own
                        // "Mark as Sold", so it disappears from the grid
                        // immediately either way it happens.
                        await FirebaseFirestore.instance
                            .collection('secondhand').doc(docId)
                            .delete();

                        // Let the seller know it was the buyer who closed
                        // the deal, not them — otherwise they'd have no
                        // idea it sold.
                        if (buyer != null && sellerId.isNotEmpty) {
                          String buyerName = buyer.displayName ?? 'A buyer';
                          try {
                            final buyerDoc = await FirebaseFirestore.instance
                                .collection('users').doc(buyer.uid).get();
                            buyerName = (buyerDoc.data()?['name'] as String?) ?? buyerName;
                          } catch (_) {}

                          await FirebaseFirestore.instance.collection('notifications').add({
                            'toUid':        sellerId,
                            'fromUid':      buyer.uid,
                            'fromName':     buyerName,
                            'type':         'secondhand_sold',
                            'title':        'Item Sold! ♻️',
                            'body':         '$buyerName marked "${data['title'] ?? 'your item'}" as purchased',
                            'listingTitle': data['title'] ?? '',
                            'read':         false,
                            'createdAt':    FieldValue.serverTimestamp(),
                          });
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('Marked as purchased ♻️'),
                              backgroundColor: Color(0xFF4CAF50),
                              behavior: SnackBarBehavior.floating));
                        }
                      },
                      icon: const Icon(Icons.check_circle_outline, size: 17),
                      label: const Text('Mark as Purchased',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4CAF50),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13))),
                    ),
                  ]),
              ]),
        ),
      ),
    );
  }

  // ── Post dialog ───────────────────────────────────────────────────────────
  //
  // Key fix: capture ScaffoldMessenger from the SCREEN's BuildContext BEFORE
  // opening the bottom sheet. Inside the sheet, `ctx` is a different subtree
  // and ScaffoldMessenger.of(ctx) can't find the Scaffold, causing posts to
  // appear to succeed but snackbars/errors to silently fail.
  //
  // Second fix (this pass): image uploads now go through Cloudinary
  // (CloudinaryUploader) instead of Firebase Storage — Storage requires the
  // paid Blaze plan even for tiny usage, which caused every upload to fail
  // with object-not-found on the free Spark plan. If the Cloudinary upload
  // fails for any reason, the listing still posts (without a photo) instead
  // of failing outright.
  //
  void _showPostDialog(BuildContext context, AppTheme t) {
    // Capture messenger from the screen context — this is the fix.
    final messenger = ScaffoldMessenger.of(context);

    final titleCtrl    = TextEditingController();
    final descCtrl     = TextEditingController();
    final priceCtrl    = TextEditingController();
    final origCtrl     = TextEditingController();
    final locationCtrl = TextEditingController();
    String condition   = 'Good';
    File?  pickedImage;
    bool   isPosting   = false;
    final picker       = ImagePicker();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: t.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.18))),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, children: [
                    Center(child: Container(width: 38, height: 4,
                        decoration: BoxDecoration(color: Colors.white24,
                            borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 14),
                    const Row(children: [
                      Text('♻️', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 7),
                      Text('List a second hand item', style: TextStyle(
                          color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 18),

                    // Photo picker
                    GestureDetector(
                      onTap: () async {
                        final src = await showModalBottomSheet<ImageSource>(
                          context: ctx,
                          backgroundColor: t.card,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                          builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
                            ListTile(
                                leading: const Icon(Icons.camera_alt_rounded,
                                    color: Color(0xFF4CAF50)),
                                title: const Text('Camera',
                                    style: TextStyle(color: Colors.white)),
                                onTap: () => Navigator.pop(ctx, ImageSource.camera)),
                            ListTile(
                                leading: const Icon(Icons.photo_library_rounded,
                                    color: Color(0xFF4CAF50)),
                                title: const Text('Gallery',
                                    style: TextStyle(color: Colors.white)),
                                onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
                          ]),
                        );
                        if (src == null) return;
                        final x = await picker.pickImage(source: src, imageQuality: 75);
                        if (x != null) setModal(() => pickedImage = File(x.path));
                      },
                      child: Container(
                        height: 110, width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.30)),
                        ),
                        child: pickedImage != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(11),
                            child: Image.file(pickedImage!, fit: BoxFit.cover,
                                width: double.infinity))
                            : Column(mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined,
                                  color: Color(0xFF4CAF50), size: 32),
                              const SizedBox(height: 6),
                              Text('Add photo', style: TextStyle(
                                  color: const Color(0xFF4CAF50).withOpacity(0.7),
                                  fontSize: 13)),
                            ]),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _modalField(titleCtrl, 'Title *', 'e.g. Fishing net — used 3 months', t),
                    _modalField(descCtrl, 'Description', 'Condition, reason for selling...', t, maxLines: 3),

                    // Condition selector
                    Text('Condition', style: TextStyle(color: Colors.white.withOpacity(0.55),
                        fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 7),
                    Wrap(spacing: 7, children: ['Like New', 'Good', 'Fair', 'For Parts']
                        .map((c) => GestureDetector(
                      onTap: () => setModal(() => condition = c),
                      child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                              color: condition == c
                                  ? const Color(0xFF4CAF50).withOpacity(0.18) : t.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: condition == c
                                  ? const Color(0xFF4CAF50) : Colors.white.withOpacity(0.07))),
                          child: Text(c, style: TextStyle(
                              color: condition == c ? const Color(0xFF4CAF50)
                                  : Colors.white.withOpacity(0.55),
                              fontSize: 11, fontWeight: FontWeight.w600))),
                    )).toList()),
                    const SizedBox(height: 14),

                    Row(children: [
                      Expanded(child: _modalField(priceCtrl, 'Your price (₹) *',
                          '500', t, keyboard: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: _modalField(origCtrl, 'Original price (₹)',
                          '2000', t, keyboard: TextInputType.number)),
                    ]),
                    _modalField(locationCtrl, 'Location *', 'e.g. Chennai Port', t),
                    const SizedBox(height: 6),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isPosting ? null : () async {
                          if (titleCtrl.text.trim().isEmpty ||
                              priceCtrl.text.trim().isEmpty ||
                              locationCtrl.text.trim().isEmpty) {
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Fill in all required fields'),
                                behavior: SnackBarBehavior.floating));
                            return;
                          }
                          setModal(() => isPosting = true);
                          try {
                            final user    = FirebaseAuth.instance.currentUser;
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users').doc(user?.uid).get();

                            String imageUrl = '';
                            if (pickedImage != null) {
                              final url = await CloudinaryUploader.uploadImage(
                                  pickedImage!, folder: 'secondhand');
                              if (url != null) {
                                imageUrl = url;
                              } else {
                                debugPrint('Second-hand image upload failed '
                                    '(check CloudinaryUploader cloudName/uploadPreset)');
                                // Fall through and post the listing without
                                // a photo rather than losing the whole post.
                              }
                            }

                            await FirebaseFirestore.instance.collection('secondhand').add({
                              'title':         titleCtrl.text.trim(),
                              'description':   descCtrl.text.trim(),
                              'price':         double.tryParse(priceCtrl.text) ?? 0,
                              'originalPrice': double.tryParse(origCtrl.text),
                              'condition':     condition,
                              'location':      locationCtrl.text.trim(),
                              'imageUrl':      imageUrl,
                              'sellerId':      user?.uid,
                              'sellerName':    userDoc.data()?['name'] ?? 'Seller',
                              'status':        'available',
                              'createdAt':     FieldValue.serverTimestamp(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            // Use the pre-captured messenger — always works even
                            // after the bottom sheet's BuildContext is gone.
                            messenger.showSnackBar(SnackBar(
                                content: Text(pickedImage != null && imageUrl.isEmpty
                                    ? 'Listed successfully (photo upload failed, posted without it) ♻️'
                                    : 'Listed successfully! ♻️'),
                                backgroundColor: const Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating));
                          } catch (e) {
                            setModal(() => isPosting = false);
                            messenger.showSnackBar(
                                SnackBar(content: Text('Error: $e'),
                                    behavior: SnackBarBehavior.floating));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13)),
                            elevation: 0),
                        child: isPosting
                            ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                            : const Text('List Item ♻️',
                            style: TextStyle(fontWeight: FontWeight.w700,
                                fontSize: 15)),
                      ),
                    ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modalField(TextEditingController ctrl, String label, String hint,
      AppTheme t, {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.55),
          fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 5),
      TextField(controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.18)),
            filled: true, fillColor: t.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.4)),
          )),
      const SizedBox(height: 12),
    ]);
  }
}