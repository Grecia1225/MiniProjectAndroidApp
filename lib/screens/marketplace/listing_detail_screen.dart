import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/cart_provider.dart';
import 'package:mtc/utils/language_provider.dart';
import 'package:mtc/utils/voice_provider/voice_provider.dart';
import 'package:mtc/utils/app_localizations.dart';
import 'package:mtc/models/listing.dart';
import 'package:mtc/screens/chat/chat_screen.dart';
import 'package:mtc/screens/marketplace/cart_screen.dart';
import 'package:mtc/screens/marketplace/create_listing_screen.dart';

class ListingDetailScreen extends StatelessWidget {
  final Listing listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;
        final isOwner     = currentUser != null && currentUser.uid == listing.sellerId;
        final t           = Provider.of<ThemeProvider>(context).current;
        final cart        = Provider.of<CartProvider>(context);
        final voice       = Provider.of<VoiceProvider>(context);
        final langProv    = Provider.of<LanguageProvider>(context, listen: false);
        final loc         = AppLocalizations.of(context);
        final inCart      = cart.items.any((i) => i.listing.id == listing.id);
        final isSold      = listing.status == 'sold';

        return Directionality(
          textDirection: langProv.isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: t.background,
            body: CustomScrollView(
              slivers: [

                // ── App bar with hero image ──────────────────────────────────
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: t.background,
                  elevation: 0,
                  leading: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 15),
                    ),
                  ),
                  actions: [
                    // 🔊 Voice button — instant toggle, like a torch switch.
                    // Tapping while speaking calls stop() immediately;
                    // VoiceProvider updates isSpeaking synchronously so the
                    // icon flips right away instead of waiting on the engine.
                    // Reads name, price, quantity, and description only —
                    // built by VoiceProvider.speakListing, which already
                    // translates the currency word and unit (kg/piece/etc)
                    // into the current app language.
                    GestureDetector(
                      onTap: () {
                        if (voice.isSpeaking) {
                          voice.stop();
                        } else {
                          voice.speakListing(listing, langProv);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: voice.isSpeaking
                              ? t.primary.withOpacity(0.25)
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(10),
                          border: voice.isSpeaking
                              ? Border.all(color: t.primary, width: 1.5)
                              : null,
                        ),
                        child: Icon(
                          voice.isSpeaking
                              ? Icons.stop_circle_outlined
                              : Icons.volume_up_outlined,
                          color: voice.isSpeaking ? t.primary : Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                    // Cart icon (buyers only)
                    if (!isOwner)
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CartScreen())),
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(children: [
                            Icon(Icons.shopping_cart_outlined,
                                color: t.primary, size: 18),
                            if (cart.count > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                width: 18, height: 18,
                                decoration: BoxDecoration(
                                    color: t.primary, shape: BoxShape.circle),
                                child: Center(
                                  child: Text('${cart.count}',
                                      style: const TextStyle(color: Colors.black,
                                          fontSize: 10, fontWeight: FontWeight.w800)),
                                ),
                              ),
                            ],
                          ]),
                        ),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(children: [
                      Positioned.fill(
                        child: listing.imageUrls.isNotEmpty
                            ? PageView.builder(
                          itemCount: listing.imageUrls.length,
                          itemBuilder: (_, i) => Image.network(
                            listing.imageUrls[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: t.card,
                              child: Icon(Icons.image_outlined,
                                  color: t.primary.withOpacity(0.3), size: 60),
                            ),
                          ),
                        )
                            : Container(
                            color: t.card,
                            child: Icon(Icons.storefront_outlined,
                                color: t.primary.withOpacity(0.3), size: 60)),
                      ),
                      if (listing.imageUrls.length > 1)
                        Positioned(
                          bottom: 90, left: 0, right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              listing.imageUrls.length,
                                  (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: 6, height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        left: 0, right: 0, bottom: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [t.background, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                      if (isSold)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(loc.sold.toUpperCase(),
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 28, fontWeight: FontWeight.w900,
                                        letterSpacing: 4)),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),

                // ── Content ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Badges row
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          _badge(listing.category, t.primary, t),
                          _statusBadge(isSold, loc),
                          if (isOwner)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: t.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: t.primary.withOpacity(0.25))),
                              child: Text(loc.yourListing,
                                  style: TextStyle(color: t.primary.withOpacity(0.8),
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                            ),
                        ]),

                        const SizedBox(height: 14),

                        // Title + voice hint
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(listing.title,
                                  style: const TextStyle(color: Colors.white,
                                      fontSize: 22, fontWeight: FontWeight.w800)),
                            ),
                            // Subtle "tap 🔊 to hear" hint — first time feel
                            if (!voice.isSpeaking)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, left: 8),
                                child: Text('🔊',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.25))),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(children: [
                          Text(listing.formattedPrice,
                              style: TextStyle(color: t.primary,
                                  fontSize: 22, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 12),
                          Text('• ${listing.formattedQuantity} ${loc.available.toLowerCase()}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13)),
                        ]),

                        const SizedBox(height: 20),

                        // Seller card
                        _sellerCard(t, loc),

                        // Description
                        if (listing.description.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(loc.description,
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: t.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.06))),
                            child: Text(listing.description,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 13, height: 1.6)),
                          ),
                        ],

                        // Details grid
                        const SizedBox(height: 20),
                        Text(loc.details,
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _chip(Icons.scale_outlined,
                              loc.quantity, listing.formattedQuantity, t)),
                          const SizedBox(width: 10),
                          Expanded(child: _chip(Icons.currency_exchange,
                              loc.currency, listing.currency, t)),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _chip(Icons.category_outlined,
                              loc.category, listing.category, t)),
                          const SizedBox(width: 10),
                          Expanded(child: _chip(Icons.access_time_outlined,
                              loc.posted, _timeAgo(listing.createdAt, loc), t)),
                        ]),

                        // Sold notice
                        if (isSold && !isOwner) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.3))),
                            child: Row(children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.redAccent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                loc.itemSoldNotice,
                                style: TextStyle(
                                    color: Colors.redAccent.withOpacity(0.85),
                                    fontSize: 13),
                              )),
                            ]),
                          ),
                        ],

                        // Owner controls
                        if (isOwner && !isSold) ...[
                          const SizedBox(height: 20),
                          _ownerAction(
                            icon: Icons.sell_outlined,
                            label: loc.markAsSold,
                            color: Colors.orange,
                            onTap: () => _markAsSold(context, t, loc),
                          ),
                        ],
                        if (isOwner && isSold) ...[
                          const SizedBox(height: 20),
                          _ownerAction(
                            icon: Icons.refresh_rounded,
                            label: loc.markAvailableAgain,
                            color: Colors.green,
                            onTap: () => _markAsAvailable(context, loc),
                          ),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Bottom action bar ──────────────────────────────────────────
            bottomNavigationBar: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: t.background,
                border: Border(top: BorderSide(color: t.primary.withOpacity(0.1))),
              ),
              child: isOwner
                  ? Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editListing(context),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    label: Text(loc.editListing,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _deleteListing(context, t, loc),
                  child: Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.redAccent.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 22),
                  ),
                ),
              ])
                  : isSold
                  ? SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(
                      Icons.remove_shopping_cart_outlined, size: 17),
                  label: Text(loc.itemSold,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: Colors.white12,
                    disabledForegroundColor: Colors.white38,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              )
                  : Row(children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (inCart) {
                        Navigator.push(context, MaterialPageRoute(
                            builder: (_) => const CartScreen()));
                      } else {
                        cart.add(listing);
                        // Capture the messenger reference before showing —
                        // safe to use even if this widget gets disposed
                        // before the delayed callback below runs.
                        final messenger = ScaffoldMessenger.of(context);
                        messenger
                          ..clearSnackBars()
                          ..showSnackBar(SnackBar(
                            content: Text('${listing.title} ${loc.addedToCartSuffix}'),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: loc.viewCart,
                              textColor: Colors.white,
                              onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(
                                      builder: (_) => const CartScreen())),
                            ),
                          ));
                        // Belt-and-suspenders manual dismiss. In a tabbed
                        // IndexedStack layout it's possible for a SnackBar's
                        // own duration timer to end up anchored to a
                        // Scaffold that isn't the one currently on screen
                        // (see marketplace_screen.dart notes) — this
                        // guarantees the banner disappears after 2s no
                        // matter what.
                        Future.delayed(const Duration(seconds: 2), () {
                          messenger.hideCurrentSnackBar();
                        });
                      }
                    },
                    icon: Icon(
                        inCart
                            ? Icons.shopping_cart
                            : Icons.add_shopping_cart,
                        size: 18),
                    label: Text(inCart ? loc.viewCart : loc.addToCart,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: t.primary,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _openChat(context),
                  child: Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: t.primary.withOpacity(0.25)),
                    ),
                    child: Icon(Icons.chat_bubble_outline,
                        color: t.primary, size: 22),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _badge(String label, Color color, AppTheme t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
    child: Text(label,
        style: TextStyle(color: color,
            fontSize: 11, fontWeight: FontWeight.w700)),
  );

  Widget _statusBadge(bool isSold, AppLocalizations loc) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: isSold
            ? Colors.redAccent.withOpacity(0.12)
            : Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        isSold
            ? Icons.remove_shopping_cart_outlined
            : Icons.check_circle_outline,
        color: isSold ? Colors.redAccent : Colors.green,
        size: 12,
      ),
      const SizedBox(width: 4),
      Text(isSold ? loc.sold : loc.available,
          style: TextStyle(
              color: isSold ? Colors.redAccent : Colors.green,
              fontSize: 11, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _sellerCard(AppTheme t, AppLocalizations loc) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.primary.withOpacity(0.15))),
    child: Row(children: [
      Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t.primary.withOpacity(0.15),
          border: Border.all(color: t.primary.withOpacity(0.4), width: 1.5),
        ),
        child: Center(
          child: Text(
            listing.sellerName.isNotEmpty
                ? listing.sellerName[0].toUpperCase()
                : 'S',
            style: TextStyle(color: t.primary,
                fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(listing.sellerName,
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 3),
          Row(children: [
            Icon(Icons.location_on_outlined,
                color: Colors.white.withOpacity(0.35), size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                listing.sellerLocation.isNotEmpty
                    ? listing.sellerLocation
                    : loc.locationNotSpecified,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: t.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: t.primary.withOpacity(0.3))),
        child: Text(loc.seller.toUpperCase(),
            style: TextStyle(color: t.primary,
                fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
    ]),
  );

  Widget _ownerAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(color: color,
                fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    ),
  );

  Widget _chip(IconData icon, String label, String value, AppTheme t) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.06))),
        child: Row(children: [
          Icon(icon, color: t.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.35), fontSize: 10)),
                  const SizedBox(height: 2),
                  Text(value,
                      overflow: TextOverflow.ellipsis, maxLines: 1,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
          ),
        ]),
      );

  // ── Actions ───────────────────────────────────────────────────────────────

  void _editListing(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CreateListingScreen(
        existingListing: {
          'title':          listing.title,
          'description':    listing.description,
          'category':       listing.category,
          'pricePerKg':     listing.pricePerKg,
          'priceUnit':      listing.priceUnit,
          'quantityKg':     listing.quantityKg,
          'quantityUnit':   listing.quantityUnit,
          'currency':       listing.currency,
          'imageUrls':      listing.imageUrls,
          'status':         listing.status,
          'sellerId':       listing.sellerId,
          'sellerName':     listing.sellerName,
          'sellerLocation': listing.sellerLocation,
        },
        listingId: listing.id,
      ),
    ));
  }

  Future<void> _markAsSold(
      BuildContext context, AppTheme t, AppLocalizations loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.markSoldConfirmTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          loc.markSoldConfirmBody,
          style: TextStyle(color: Colors.white.withOpacity(0.5)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel,
                  style: TextStyle(color: Colors.white.withOpacity(0.4)))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text(loc.markAsSold)),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('listings').doc(listing.id)
          .update({'status': 'sold'});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(loc.listingMarkedSold),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _markAsAvailable(BuildContext context, AppLocalizations loc) async {
    await FirebaseFirestore.instance
        .collection('listings').doc(listing.id)
        .update({'status': 'active'});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.listingMarkedAvailable),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    }
  }

  Future<void> _deleteListing(
      BuildContext context, AppTheme t, AppLocalizations loc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(loc.deleteListingTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(loc.deleteListingBody,
            style: TextStyle(color: Colors.white.withOpacity(0.5))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel,
                  style: TextStyle(color: Colors.white.withOpacity(0.4)))),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text(loc.delete)),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('listings').doc(listing.id).delete();
      if (context.mounted) Navigator.pop(context);
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final chatId = ([currentUser.uid, listing.sellerId]..sort()).join('_');
    final buyerName = currentUser.displayName ?? 'Buyer';
    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants':    [currentUser.uid, listing.sellerId],
      'listingId':       listing.id,
      'listingTitle':    listing.title,
      'lastMessage':     '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastUpdated':     FieldValue.serverTimestamp(),
      'buyerId':         currentUser.uid,
      'sellerId':        listing.sellerId,
      'sellerName':      listing.sellerName,
      'buyerName':       buyerName,
      // Same generic uid->name map used by every chat now (see
      // tracking_screen.dart's _ensureChat for buyer-agent/seller-agent
      // chats) — keeps ChatListScreen's name lookup consistent across
      // every chat type instead of relying on chat-type-specific fields.
      'participantNames': {
        currentUser.uid:  buyerName,
        listing.sellerId: listing.sellerName,
      },
    }, SetOptions(merge: true));
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId:       chatId,
            otherName:    listing.sellerName,
            otherId:      listing.sellerId,
            listingTitle: listing.title,
          )));
    }
  }

  String _timeAgo(DateTime dt, AppLocalizations loc) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return loc.daysAgo(diff.inDays);
    if (diff.inHours > 0) return loc.hoursAgo(diff.inHours);
    return loc.minsAgo(diff.inMinutes);
  }
}