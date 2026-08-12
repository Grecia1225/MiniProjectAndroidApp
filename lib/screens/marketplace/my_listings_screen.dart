import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/models/listing.dart';
import 'package:mtc/screens/marketplace/create_listing_screen.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  // ── Toggle active ↔ paused ───────────────────────────────────────────────
  Future<void> _toggleStatus(String docId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'paused' : 'active';
    await FirebaseFirestore.instance
        .collection('listings').doc(docId).update({'status': newStatus});
  }

  // ── Delete listing with confirmation ─────────────────────────────────────
  Future<void> _deleteListing(BuildContext context, String docId, AppTheme t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete listing?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('This cannot be undone.',
            style: TextStyle(color: Colors.white.withOpacity(0.5))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: t.primary))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('listings').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t   = Provider.of<ThemeProvider>(context).current;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.primary.withOpacity(0.25))),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 15))),
        title: const Text('My Listings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateListingScreen())),
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.add, color: Colors.black, size: 18),
                const SizedBox(width: 4),
                Text('New', style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.w700, fontSize: 13)),
              ]))),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('sellerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: t.primary));
          }
          var docs = snap.data?.docs ?? [];
          docs = List.from(docs)..sort((a, b) {
            final at = (a.data() as Map)['createdAt'];
            final bt = (b.data() as Map)['createdAt'];
            if (at == null || bt == null) return 0;
            return bt.compareTo(at);
          });

          if (docs.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.storefront_outlined, color: t.primary.withOpacity(0.3), size: 52),
              const SizedBox(height: 14),
              Text('No listings yet',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateListingScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Post your first listing',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)))),
            ]));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final data    = docs[i].data() as Map<String, dynamic>;
              final listing = Listing.fromDoc(docs[i]);
              final docId   = docs[i].id;
              final status  = listing.status; // 'active' | 'paused' | 'sold'

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.card, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: t.primary.withOpacity(0.12))),
                child: Row(children: [

                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: listing.imageUrls.isNotEmpty
                        ? Image.network(listing.imageUrls.first,
                            width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(t))
                        : _placeholder(t)),

                  const SizedBox(width: 14),

                  // Info
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(listing.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(listing.formattedPrice,
                      style: TextStyle(color: t.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(listing.formattedQuantity,
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                  ])),

                  // Action column
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [

                    // Status badge (tappable to toggle)
                    GestureDetector(
                      onTap: status == 'sold' ? null : () => _toggleStatus(docId, status),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(status.toUpperCase(),
                            style: TextStyle(color: _statusColor(status),
                                fontSize: 10, fontWeight: FontWeight.w700)),
                          if (status != 'sold') ...[
                            const SizedBox(width: 3),
                            Icon(Icons.swap_horiz_rounded,
                                color: _statusColor(status).withOpacity(0.7), size: 11),
                          ],
                        ]),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Edit + Delete row
                    Row(children: [
                      // Edit
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => CreateListingScreen(
                                existingListing: data, listingId: docId))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: t.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: t.primary.withOpacity(0.3))),
                          child: Text('Edit',
                              style: TextStyle(color: t.primary, fontSize: 11,
                                  fontWeight: FontWeight.w700)))),

                      const SizedBox(width: 6),

                      // Delete
                      GestureDetector(
                        onTap: () => _deleteListing(context, docId, t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.25))),
                          child: const Text('Del',
                              style: TextStyle(color: Colors.redAccent, fontSize: 11,
                                  fontWeight: FontWeight.w700)))),
                    ]),
                  ]),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'paused': return Colors.orange;
      case 'sold':   return Colors.grey;
      default:       return Colors.green;
    }
  }

  Widget _placeholder(AppTheme t) => Container(
    width: 60, height: 60, color: t.cardLight,
    child: Icon(Icons.storefront_outlined, color: t.primary.withOpacity(0.3), size: 24));
}