import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/voice_provider/voice_provider.dart';
import 'package:mtc/utils/language_provider.dart';
import 'package:mtc/screens/chat/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool showSettingsToggles;
  const NotificationsScreen({super.key, this.showSettingsToggles = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _newListings     = true;
  bool _messages        = true;
  bool _priceAlerts     = false;
  bool _shipmentUpdates = true;
  bool _promotions      = false;
  bool _appSounds       = true;

  String _userRole   = '';
  String _uid        = '';
  bool   _roleLoaded = false;
  String? _speakingId; // which notification's speaker is currently active

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _roleLoaded = true);
      return;
    }
    _uid = user.uid;
    try {
      DocumentSnapshot doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection('users').doc(user.uid)
            .get(const GetOptions(source: Source.cache));
      } catch (_) {
        doc = await FirebaseFirestore.instance
            .collection('users').doc(user.uid)
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

  Future<void> _markAllRead() async {
    if (_uid.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('notifications')
          .where('toUid', isEqualTo: _uid)
          .where('read', isEqualTo: false)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    }
  }

  // Notification types where tapping should open a chat with the person
  // who triggered it (buyer for cart_add/new_order/product_request),
  // instead of just marking the notification read. shipment_update and
  // shipment_assigned are informational (about an order's status), not
  // a "someone wants to talk to you" trigger, so they're deliberately
  // left out of this set — tapping them just marks them read.
  static const _chatOpeningTypes = {'cart_add', 'new_order', 'product_request', 'secondhand_interest', 'new_message'};

  /// Opens (creating if needed) a chat between the current user and the
  /// buyer named in the notification's fromUid/fromName fields. Mirrors
  /// the chat-doc shape ListingDetailScreen._openChat already writes, so
  /// both entry points land on the same chat thread.
  Future<void> _openChatFromNotification(
      BuildContext context, Map<String, dynamic> data) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final otherId   = (data['fromUid'] ?? '') as String;
    final otherName = (data['fromName'] ?? 'Buyer') as String;
    if (otherId.isEmpty) return; // nothing to open a chat with

    final listingId    = (data['listingId'] ?? '') as String;
    final listingTitle = (data['listingTitle'] ?? '') as String;
    final chatId = ([currentUser.uid, otherId]..sort()).join('_');

    await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
      'participants':    [currentUser.uid, otherId],
      'listingId':       listingId,
      'listingTitle':    listingTitle,
      'lastMessage':     '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastUpdated':     FieldValue.serverTimestamp(),
      'buyerId':         otherId,
      'sellerId':        currentUser.uid,
      'sellerName':      currentUser.displayName ?? 'Seller',
      'buyerName':       otherName,
      'participantNames': {
        currentUser.uid: currentUser.displayName ?? 'Seller',
        otherId:         otherName,
      },
    }, SetOptions(merge: true));

    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId:       chatId,
            otherName:    otherName,
            otherId:      otherId,
            listingTitle: listingTitle,
          )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context).current;
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.primary.withOpacity(0.25))),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 15)),
        ),
        title: Text(
            widget.showSettingsToggles ? 'Notification Settings' : 'Notifications',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17)),
        actions: [
          if (!widget.showSettingsToggles)
            TextButton(
                onPressed: _markAllRead,
                child: Text('Mark all read',
                    style: TextStyle(color: t.primary.withOpacity(0.8), fontSize: 12))),
        ],
      ),
      body: !_roleLoaded
          ? Center(child: CircularProgressIndicator(color: t.primary, strokeWidth: 2))
          : widget.showSettingsToggles
          ? _buildSettingsView(t)
          : _buildBellView(t),
    );
  }

  Widget _buildBellView(AppTheme t) {
    if (_uid.isEmpty) return _emptyState(t, 'Sign in to see notifications');

    // Reads from the top-level `notifications` collection, filtered by
    // toUid — same collection every notification write (cart, orders,
    // shipping, product requests) and the dashboard bell badge use.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('toUid', isEqualTo: _uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.notifications_none_rounded, color: t.primary.withOpacity(0.3), size: 48),
            const SizedBox(height: 12),
            Text('No notifications yet',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15)),
            const SizedBox(height: 4),
            Text("You're all caught up!",
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
          ]));
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: t.primary, strokeWidth: 2));
        }

        final docs = List<QueryDocumentSnapshot>.from(snap.data?.docs ?? [])
          ..sort((a, b) {
            final aTs = (a.data() as Map)['createdAt'] as Timestamp?;
            final bTs = (b.data() as Map)['createdAt'] as Timestamp?;
            if (aTs == null && bTs == null) return 0;
            if (aTs == null) return 1;
            if (bTs == null) return -1;
            return bTs.compareTo(aTs);
          });

        if (docs.isEmpty) return _emptyState(t, _emptyMessage());

        final unread = docs.where((d) => (d.data() as Map)['read'] == false).length;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            child: Row(children: [
              Text('${docs.length} notification${docs.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
              const Spacer(),
              if (unread > 0) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: t.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('$unread unread',
                      style: TextStyle(color: t.primary, fontSize: 10, fontWeight: FontWeight.w700))),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final data    = docs[i].data() as Map<String, dynamic>;
                final isUnread = data['read'] == false;
                final type    = data['type'] as String? ?? '';
                final title   = data['title'] as String? ?? 'Notification';
                final body    = data['body']  as String? ?? '';
                final ts      = data['createdAt'] as Timestamp?;
                final time    = ts != null ? _formatTime(ts.toDate()) : '';
                final opensChat = _chatOpeningTypes.contains(type) &&
                    (data['fromUid'] ?? '').toString().isNotEmpty;

                return GestureDetector(
                  onTap: () {
                    docs[i].reference.update({'read': true});
                    if (opensChat) _openChatFromNotification(context, data);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: isUnread ? t.primary.withOpacity(0.07) : t.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isUnread ? t.primary.withOpacity(0.30) : Colors.white.withOpacity(0.06))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(width: 42, height: 42,
                          decoration: BoxDecoration(
                              color: _typeColor(type, t).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(_typeIcon(type), color: _typeColor(type, t), size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text(title,
                              style: TextStyle(color: Colors.white, fontSize: 13,
                                  fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600))),
                          if (time.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(time, style: TextStyle(color: Colors.white.withOpacity(0.30), fontSize: 10)),
                          ],
                        ]),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(body,
                              style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12, height: 1.4),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color: _typeColor(type, t).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(5)),
                              child: Text(_typeLabel(type),
                                  style: TextStyle(color: _typeColor(type, t), fontSize: 9,
                                      fontWeight: FontWeight.w800, letterSpacing: 0.6))),
                          if (opensChat) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.chat_bubble_outline,
                                color: t.primary.withOpacity(0.5), size: 11),
                          ],
                        ]),
                      ])),
                      const SizedBox(width: 6),
                      _NotificationSpeaker(
                        docId: docs[i].id,
                        data: data,
                        speakingId: _speakingId,
                        onToggle: (id) => setState(() => _speakingId = id),
                        t: t,
                      ),
                      if (isUnread) Container(
                          width: 7, height: 7, margin: const EdgeInsets.only(top: 4, left: 2),
                          decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle)),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildSettingsView(AppTheme t) {
    return ListView(padding: const EdgeInsets.all(24), children: [
      _sectionHeader('Activity', t),
      _toggle('New listings nearby', 'Get notified about new marine listings',
          Icons.storefront_outlined, _newListings, t, (v) => setState(() => _newListings = v)),
      _toggle('Messages', 'New messages from traders',
          Icons.chat_bubble_outline, _messages, t, (v) => setState(() => _messages = v)),
      _toggle('Shipment updates', 'Track your shipments in real-time',
          Icons.directions_boat_outlined, _shipmentUpdates, t, (v) => setState(() => _shipmentUpdates = v)),
      const SizedBox(height: 8),
      _sectionHeader('Market', t),
      _toggle('Price alerts', 'Get alerts when prices drop or spike',
          Icons.show_chart, _priceAlerts, t, (v) => setState(() => _priceAlerts = v)),
      _toggle('Promotions', 'Deals and offers from sellers',
          Icons.local_offer_outlined, _promotions, t, (v) => setState(() => _promotions = v)),
      const SizedBox(height: 8),
      _sectionHeader('Preferences', t),
      _toggle('App sounds', 'Play sounds for notifications',
          Icons.volume_up_outlined, _appSounds, t, (v) => setState(() => _appSounds = v)),
      const SizedBox(height: 32),
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.primary.withOpacity(0.15))),
          child: Row(children: [
            Icon(Icons.info_outline, color: t.primary, size: 18),
            const SizedBox(width: 12),
            Expanded(child: Text('Push notifications require device permissions to be enabled.',
                style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 12))),
          ])),
    ]);
  }

  String _emptyMessage() {
    switch (_userRole) {
      case 'seller': return 'No orders yet';
      case 'agent':  return 'No shipping requests yet';
      default:       return 'No new notifications';
    }
  }

  Widget _emptyState(AppTheme t, String msg) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 70, height: 70,
          decoration: BoxDecoration(color: t.primary.withOpacity(0.10), shape: BoxShape.circle),
          child: Icon(Icons.notifications_none_rounded, color: t.primary.withOpacity(0.45), size: 32)),
      const SizedBox(height: 16),
      Text(msg, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text("You're all caught up!", style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13)),
    ]),
  );

  Color _typeColor(String type, AppTheme t) {
    switch (type) {
      case 'new_order':          return const Color(0xFF4CAF50);
      case 'cart_add':           return const Color(0xFFFFCA28);
      case 'order_confirmed':    return const Color(0xFF26C6DA);
      case 'shipping_request':   return const Color(0xFF7C4DFF);
      case 'agent_applied':      return const Color(0xFF7C4DFF);
      case 'agent_confirmed':    return const Color(0xFF4FC3F7);
      case 'agent_accepted':     return const Color(0xFF4FC3F7);
    // Buyer-facing order lifecycle notifications — a distinct blue so
    // they read clearly as "your order", separate from seller/agent
    // colors above.
      case 'shipment_update':    return const Color(0xFF42A5F5);
      case 'shipment_assigned':  return const Color(0xFF42A5F5);
      case 'order_delivered':    return Colors.green;
      case 'product_request':    return const Color(0xFFAB47BC);
      case 'secondhand_interest': return const Color(0xFF4CAF50);
      default:                   return t.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'new_order':          return Icons.receipt_long_rounded;
      case 'cart_add':           return Icons.shopping_cart_rounded;
      case 'order_confirmed':    return Icons.check_circle_rounded;
      case 'shipping_request':   return Icons.local_shipping_rounded;
      case 'agent_applied':      return Icons.person_add_alt_1_rounded;
      case 'agent_confirmed':    return Icons.handshake_rounded;
      case 'agent_accepted':     return Icons.handshake_rounded;
      case 'shipment_update':    return Icons.directions_boat_rounded;
      case 'shipment_assigned':  return Icons.local_shipping_rounded;
      case 'order_delivered':    return Icons.inventory_rounded;
      case 'product_request':    return Icons.storefront_rounded;
      case 'secondhand_interest': return Icons.recycling_rounded;
      default:                   return Icons.notifications_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'new_order':          return 'NEW ORDER';
      case 'cart_add':           return 'CART ADD';
      case 'order_confirmed':    return 'CONFIRMED';
      case 'shipping_request':   return 'SHIP REQUEST';
      case 'agent_applied':      return 'AGENT APPLIED';
      case 'agent_confirmed':    return 'AGENT CONFIRMED';
      case 'agent_accepted':     return 'AGENT ACCEPTED';
      case 'shipment_update':    return 'ORDER UPDATE';
      case 'shipment_assigned':  return 'AGENT ASSIGNED';
      case 'order_delivered':    return 'DELIVERED';
      case 'product_request':    return 'REQUEST';
      case 'secondhand_interest': return 'INTERESTED BUYER';
      default:                   return 'NOTIFICATION';
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _sectionHeader(String title, AppTheme t) => Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(title.toUpperCase(),
          style: TextStyle(color: t.primary.withOpacity(0.7), fontSize: 11,
              fontWeight: FontWeight.w700, letterSpacing: 1.5)));

  Widget _toggle(String title, String subtitle, IconData icon, bool value,
      AppTheme t, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: t.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: t.primary, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
        ])),
        Switch(value: value, onChanged: onChanged,
            activeColor: t.primary, activeTrackColor: t.primary.withOpacity(0.25),
            inactiveThumbColor: Colors.white30, inactiveTrackColor: Colors.white10),
      ]),
    );
  }
}

// Per-item speaker — reads a single notification aloud, reconstructed in
// the app's current language from its structured data (see
// VoiceProvider.buildNotificationSpeech), not the stored English
// title/body/message. Tapping while it's already speaking that same
// notification stops it; tapping a different one switches to it.
class _NotificationSpeaker extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String? speakingId;
  final ValueChanged<String?> onToggle;
  final AppTheme t;
  const _NotificationSpeaker({
    required this.docId,
    required this.data,
    required this.speakingId,
    required this.onToggle,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final voice    = Provider.of<VoiceProvider>(context);
    final langProv = Provider.of<LanguageProvider>(context, listen: false);
    final isThisSpeaking = voice.isSpeaking && speakingId == docId;

    return GestureDetector(
      onTap: () {
        if (isThisSpeaking) {
          voice.stop();
          onToggle(null);
        } else {
          voice.speakNotification(data, langProv);
          onToggle(docId);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isThisSpeaking
              ? t.primary.withOpacity(0.25)
              : t.primary.withOpacity(0.08),
          shape: BoxShape.circle,
          border: isThisSpeaking
              ? Border.all(color: t.primary, width: 1.2)
              : null,
        ),
        child: Icon(
          isThisSpeaking
              ? Icons.stop_circle_outlined
              : Icons.volume_up_rounded,
          color: t.primary,
          size: 14,
        ),
      ),
    );
  }
}