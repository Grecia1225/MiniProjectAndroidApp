import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/screens/chat/chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  /// Resolves "the other person in this chat"'s name + uid generically,
  /// so this works for ANY 2-person chat — not just buyer-seller ones.
  ///
  /// Priority:
  ///  1. `participants` array (always present on every chat) minus my own
  ///     uid gives the other person's uid, reliably, regardless of role.
  ///  2. `participantNames` map (uid -> name), written by every NEW chat
  ///     (buyer-seller via listing_detail_screen.dart, and buyer-agent /
  ///     seller-agent via tracking_screen.dart's _confirmAgent).
  ///  3. Falls back to the old buyerName/sellerName fields for any chat
  ///     created before participantNames existed, so nothing that was
  ///     already working breaks.
  static ({String name, String id}) _resolveOther(
      Map<String, dynamic> data, String myUid) {
    final participants = List<String>.from(data['participants'] ?? []);
    final otherId = participants.firstWhere(
          (id) => id != myUid,
      orElse: () => '',
    );

    final names = data['participantNames'] as Map<String, dynamic>?;
    if (names != null && otherId.isNotEmpty && names[otherId] != null) {
      return (name: names[otherId].toString(), id: otherId);
    }

    // Legacy buyer-seller chat shape (no participantNames field yet).
    final isBuyer = data['buyerId'] == myUid;
    final legacyName = isBuyer
        ? (data['sellerName'] ?? 'Seller')
        : (data['buyerName'] ?? 'Buyer');
    final legacyId = isBuyer
        ? (data['sellerId'] ?? otherId)
        : (data['buyerId'] ?? otherId);
    return (name: legacyName.toString(), id: legacyId.toString());
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context).current;
    final user = FirebaseAuth.instance.currentUser;
    final myUid = user?.uid ?? '';

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Messages', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              Text('Your trade conversations', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12)),
            ]),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants', arrayContains: myUid)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: t.primary));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chat_bubble_outline, color: t.primary.withOpacity(0.2), size: 52),
                    const SizedBox(height: 14),
                    Text('No conversations yet', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Contact a seller from the marketplace', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12)),
                  ]));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final other = _resolveOther(data, myUid);
                    final otherName = other.name.isEmpty ? 'Trader' : other.name;
                    final otherId = other.id;
                    final lastMsg = data['lastMessage'] ?? '';
                    final time = (data['lastMessageTime'] as Timestamp?)?.toDate();

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          chatId: docs[i].id,
                          otherName: otherName,
                          otherId: otherId,
                          listingTitle: data['listingTitle'] ?? '',
                        ),
                      )),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.06))),
                        child: Row(children: [
                          Container(width: 48, height: 48,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: t.primary.withOpacity(0.15), border: Border.all(color: t.primary.withOpacity(0.4), width: 1.5)),
                              child: Center(child: Text(otherName[0].toUpperCase(), style: TextStyle(color: t.primary, fontWeight: FontWeight.w800, fontSize: 18)))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(otherName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
                              if (time != null) Text(_timeAgo(time), style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                            ]),
                            const SizedBox(height: 3),
                            Text(data['listingTitle'] ?? '', style: TextStyle(color: t.primary.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(lastMsg.isEmpty ? 'No messages yet' : lastMsg, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ])),
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

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'now';
  }
}