import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String   id;
  final List<String> participants;
  final String   lastMessage;
  final DateTime lastUpdated;
  final String   listingId;
  final String   listingTitle;
  // uid -> display name for every participant. Written by every chat
  // creation path now (buyer-seller in listing_detail_screen.dart,
  // buyer-agent/seller-agent in tracking_screen.dart's _ensureChat).
  // Lets any screen resolve "the other person's name" without caring
  // whether this is a buyer-seller, buyer-agent, or seller-agent chat.
  final Map<String, String> participantNames;

  const ChatModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastUpdated,
    this.listingId    = '',
    this.listingTitle = '',
    this.participantNames = const {},
  });

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final namesRaw = d['participantNames'] as Map<String, dynamic>?;
    return ChatModel(
      id:           doc.id,
      participants: List<String>.from(d['participants'] ?? []),
      lastMessage:  d['lastMessage']  ?? '',
      lastUpdated:  (d['lastUpdated'] as Timestamp?)?.toDate()
          ?? DateTime.now(),
      listingId:    d['listingId']    ?? '',
      listingTitle: d['listingTitle'] ?? '',
      participantNames: namesRaw == null
          ? const {}
          : namesRaw.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  /// Resolves the other participant's display name for [myUid], falling
  /// back gracefully if this chat predates participantNames.
  String otherName(String myUid, {String fallback = 'Trader'}) {
    final otherId = participants.firstWhere(
          (id) => id != myUid,
      orElse: () => '',
    );
    return participantNames[otherId] ?? fallback;
  }

  /// Resolves the other participant's uid for [myUid].
  String otherId(String myUid) => participants.firstWhere(
        (id) => id != myUid,
    orElse: () => '',
  );
}