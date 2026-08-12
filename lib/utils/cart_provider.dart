import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mtc/models/listing.dart';

class CartItem {
  final Listing listing;
  double quantity;
  CartItem({required this.listing, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => _items;

  bool _loaded = false; // guards against loading the same user's cart twice

  int    get count => _items.length;
  double get total => _items.fold(0, (sum, i) => sum + (i.listing.pricePerKg * i.quantity));

  /// Persists the current cart (just listingId + quantity, cheap to store)
  /// to Firestore under carts/{uid}, so it survives an app restart.
  Future<void> _persist() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('carts').doc(uid).set({
        'items': _items.map((i) => {
          'listingId': i.listing.id,
          'quantity':  i.quantity,
        }).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Cart persist error: $e');
    }
  }

  /// Loads this user's saved cart from Firestore (called once after login /
  /// on app start — see main.dart). Re-fetches each listing by id so the
  /// cart always shows current price/availability, not stale cached data.
  /// Silently drops any listingId that no longer exists (e.g. deleted or
  /// sold-out listings a user had sitting in their cart).
  Future<void> loadCart(String uid) async {
    if (_loaded) return; // don't reload/duplicate on every rebuild
    _loaded = true;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('carts').doc(uid).get();
      if (!doc.exists) return;
      final rawItems = (doc.data()?['items'] ?? []) as List;
      if (rawItems.isEmpty) return;

      final loaded = <CartItem>[];
      for (final raw in rawItems) {
        final listingId = raw['listingId'] as String?;
        final quantity  = (raw['quantity'] as num?)?.toDouble() ?? 1;
        if (listingId == null) continue;
        try {
          final listingDoc = await FirebaseFirestore.instance
              .collection('listings').doc(listingId).get();
          if (listingDoc.exists) {
            loaded.add(CartItem(
              listing: Listing.fromDoc(listingDoc),
              quantity: quantity,
            ));
          }
        } catch (_) {
          // listing gone or unreachable — skip it, don't block the rest
        }
      }
      _items
        ..clear()
        ..addAll(loaded);
      notifyListeners();
    } catch (e) {
      debugPrint('Cart load error: $e');
    }
  }

  /// Resets the loaded flag so the next loadCart() call (e.g. after a
  /// sign-out/sign-in as a different user) actually reloads instead of
  /// being skipped by the _loaded guard.
  void resetLoadGuard() => _loaded = false;

  /// Add item and notify the seller via Firestore
  Future<void> add(Listing listing) async {
    final idx = _items.indexWhere((i) => i.listing.id == listing.id);
    if (idx >= 0) {
      _items[idx].quantity += 1;
    } else {
      _items.add(CartItem(listing: listing));
    }
    notifyListeners();
    unawaited(_persist());

    // 🔔 Notify seller that buyer added their listing to cart
    try {
      final buyer = FirebaseAuth.instance.currentUser;
      if (buyer == null) return;
      final buyerDoc = await FirebaseFirestore.instance
          .collection('users').doc(buyer.uid).get();
      final buyerName = buyerDoc.data()?['name'] ?? 'A buyer';

      await FirebaseFirestore.instance.collection('notifications').add({
        'toUid':     listing.sellerId,
        'fromUid':   buyer.uid,
        'fromName':  buyerName,
        'type':      'cart_add',           // seller sees this
        'title':     'New Cart Add 🛒',
        'body':      '$buyerName added ${listing.title} to their cart',
        'listingId': listing.id,
        'listingTitle': listing.title,
        'read':      false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Cart notification error: $e');
    }
  }

  void remove(String listingId) {
    _items.removeWhere((i) => i.listing.id == listingId);
    notifyListeners();
    unawaited(_persist());
  }

  void updateQty(String listingId, double qty) {
    final idx = _items.indexWhere((i) => i.listing.id == listingId);
    if (idx >= 0) {
      _items[idx].quantity = qty;
      notifyListeners();
      unawaited(_persist());
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    unawaited(_persist());
  }
}

// Small local helper so we don't need to import dart:async just for this.
void unawaited(Future<void> future) {}