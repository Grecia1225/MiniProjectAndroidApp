import 'package:flutter/material.dart';
import 'package:mtc/utils/theme_provider.dart';

class ChatMessageTile extends StatelessWidget {
  final String otherName;
  final String listingTitle;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final bool hasUnread;
  final AppTheme t;
  final VoidCallback onTap;

  const ChatMessageTile({
    super.key,
    required this.otherName,
    required this.listingTitle,
    required this.lastMessage,
    required this.t,
    required this.onTap,
    this.lastMessageTime,
    this.hasUnread = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasUnread ? t.primary.withOpacity(0.06) : t.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasUnread
                ? t.primary.withOpacity(0.2)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.primary.withOpacity(0.15),
              border: Border.all(
                  color: t.primary.withOpacity(0.4), width: 1.5),
            ),
            child: Center(
              child: Text(
                otherName.isNotEmpty
                    ? otherName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    color: t.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(
                      otherName,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: hasUnread
                              ? FontWeight.w800
                              : FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                  if (lastMessageTime != null)
                    Text(
                      _timeAgo(lastMessageTime!),
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11),
                    ),
                ]),
                const SizedBox(height: 3),

                if (listingTitle.isNotEmpty)
                  Text(
                    'Re: $listingTitle',
                    style: TextStyle(
                        color: t.primary.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),

                Row(children: [
                  Expanded(
                    child: Text(
                      lastMessage.isEmpty
                          ? 'No messages yet'
                          : lastMessage,
                      style: TextStyle(
                          color: hasUnread
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.35),
                          fontSize: 12,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasUnread)
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: t.primary, shape: BoxShape.circle),
                    ),
                ]),
              ],
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

/// A single chat bubble — used inside ChatScreen
class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final AppTheme t;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.t,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72),
          decoration: BoxDecoration(
            color: isMe ? t.primary : t.card,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMe ? 14 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 14),
            ),
            border: isMe
                ? null
                : Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Text(
            text,
            style: TextStyle(
                color: isMe ? t.background : Colors.white,
                fontSize: 14,
                height: 1.4),
          ),
        ),
      ),
    );
  }
}