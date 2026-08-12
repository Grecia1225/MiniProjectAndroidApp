import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/cart_provider.dart';
import 'package:mtc/utils/dashboard_tab_notifier.dart';
import 'package:mtc/screens/marketplace/listing_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isPlacing = false;
  final _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(BuildContext context, AppTheme t, CartProvider cart) async {
    if (cart.items.isEmpty) return;

    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please enter a delivery address before placing your order.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    setState(() => _isPlacing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Buyer';

      final batch = FirebaseFirestore.instance.batch();
      final shipmentIds = <String>[];

      for (final item in cart.items) {
        final shipRef = FirebaseFirestore.instance.collection('shipments').doc();
        shipmentIds.add(shipRef.id);
        batch.set(shipRef, {
          'listingId':      item.listing.id,
          'listingTitle':   item.listing.title,
          'buyerId':        user.uid,
          'buyerName':      userName,
          'buyerAddress':   address, // ← delivery address, so a seller
          //    requesting a shipment agent
          //    always has a real dropoff to
          //    show — see tracking_screen.dart
          'sellerId':       item.listing.sellerId,
          'sellerName':     item.listing.sellerName,
          'sellerLocation': item.listing.sellerLocation,
          'quantityKg':     item.quantity,
          'pricePerKg':     item.listing.pricePerKg,
          'totalPrice':     item.listing.pricePerKg * item.quantity,
          'currency':       item.listing.currency,
          'status':         'pending',
          'shipperId':      null,
          'shipperName':    null,
          'createdAt':      FieldValue.serverTimestamp(),
          'updatedAt':      FieldValue.serverTimestamp(),
        });

        // 🔔 Notify seller about new order
        final notifRef = FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifRef, {
          'toUid':        item.listing.sellerId,
          'fromUid':      user.uid,
          'fromName':     userName,
          'type':         'new_order',
          'title':        'New Order Received! 📦',
          'body':         '$userName ordered ${item.quantity.toInt()} kg of ${item.listing.title}',
          'listingId':    item.listing.id,
          'listingTitle': item.listing.title,
          'quantityKg':   item.quantity,
          'shipmentId':   shipRef.id,
          'read':         false,
          'createdAt':    FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      cart.clear();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: t.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('Order Placed!',
                  style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Your order has been sent to the seller. Track it in the Shipments tab.',
                style: TextStyle(color: Colors.white.withOpacity(0.5),
                    fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Tell the dashboard to land on the "Tracking" tab
                  // (index 3) once we're back at its route, then pop
                  // everything on top of it (the dialog + this cart
                  // screen) in one go — more robust than a fixed count
                  // of Navigator.pop() calls, which broke if the cart
                  // was ever reached via a different navigation depth.
                  DashboardTabNotifier.requestedIndex.value = 3;
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Track Orders',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'),
                backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t    = Provider.of<ThemeProvider>(context).current;
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.primary.withOpacity(0.25)),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 15),
          ),
        ),
        title: const Text('Your Cart',
            style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => cart.clear(),
              child: Text('Clear',
                  style: TextStyle(color: Colors.redAccent.withOpacity(0.8))),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined,
                    color: t.primary.withOpacity(0.2), size: 60),
                const SizedBox(height: 14),
                Text('Your cart is empty',
                    style: TextStyle(color: Colors.white.withOpacity(0.5),
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Browse the marketplace to add items',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.25), fontSize: 12)),
              ]))
          : Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ...List.generate(cart.items.length, (i) {
                final item = cart.items[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: i == cart.items.length - 1 ? 0 : 12),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(listing: item.listing))),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: t.primary.withOpacity(0.12)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: t.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.set_meal_outlined,
                              color: t.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.listing.title,
                                    style: const TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 2),
                                Text(item.listing.formattedPrice,
                                    style: TextStyle(color: t.primary,
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (item.quantity > 1) {
                                        cart.updateQty(item.listing.id,
                                            item.quantity - 1);
                                      } else {
                                        cart.remove(item.listing.id);
                                      }
                                    },
                                    child: Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color: t.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.remove,
                                          color: t.primary, size: 16),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    child: Text('${item.quantity.toInt()} kg',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  GestureDetector(
                                    onTap: () => cart.updateQty(
                                        item.listing.id, item.quantity + 1),
                                    child: Container(
                                      width: 28, height: 28,
                                      decoration: BoxDecoration(
                                        color: t.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.add,
                                          color: t.primary, size: 16),
                                    ),
                                  ),
                                ]),
                              ]),
                        ),
                        Column(crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${(item.listing.pricePerKg * item.quantity).toStringAsFixed(0)}',
                                style: TextStyle(color: t.primary,
                                    fontWeight: FontWeight.w800, fontSize: 15),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => cart.remove(item.listing.id),
                                child: Icon(Icons.delete_outline,
                                    color: Colors.redAccent.withOpacity(0.6),
                                    size: 18),
                              ),
                            ]),
                      ]),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // ── Delivery address ─────────────────────────────────────
              // Required so a seller requesting a shipment agent always
              // has a real dropoff location to show — instead of the
              // blank "DROPOFF" box it was showing before, since nothing
              // ever asked the buyer where they wanted delivery.
              Text('Delivery Address',
                  style: TextStyle(color: Colors.white.withOpacity(0.7),
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Where should this be delivered? (e.g. street, area, city)',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                  filled: true,
                  fillColor: t.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.primary.withOpacity(0.15))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: t.primary.withOpacity(0.5))),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: t.background,
            border: Border(
                top: BorderSide(color: t.primary.withOpacity(0.1))),
          ),
          child: Column(children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${cart.count} item${cart.count > 1 ? "s" : ""}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 14)),
                  Text('Total: ₹${cart.total.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isPlacing
                    ? null
                    : () => _placeOrder(context, t, cart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.primary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: t.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isPlacing
                    ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Text('Place Order',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}