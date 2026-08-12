import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mtc/utils/theme_provider.dart';

/// A live-updating stat card that streams a Firestore count.
///
/// Usage:
/// ```dart
/// StatCardWidget(
///   label: 'Listings',
///   icon: Icons.list_alt_rounded,
///   stream: FirebaseFirestore.instance
///       .collection('listings')
///       .where('sellerId', isEqualTo: uid)
///       .snapshots(),
///   onTap: () => onTabChange(1),
///   t: t,
/// )
/// ```
class StatCardWidget extends StatelessWidget {
  final String                  label;
  final IconData                icon;
  final Stream<QuerySnapshot>   stream;
  final VoidCallback            onTap;
  final AppTheme                t;

  const StatCardWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.stream,
    required this.onTap,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (_, snap) {
        final count = snap.data?.docs.length ?? 0;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.primary.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: t.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, color: t.primary, size: 16),
                    ),
                    Icon(Icons.north_east_rounded,
                        color: t.primary.withOpacity(0.35), size: 13),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A row of 3 stat cards — pass your own definitions.
class StatCardsRow extends StatelessWidget {
  final List<StatCardDef> defs;
  final AppTheme t;

  const StatCardsRow({super.key, required this.defs, required this.t});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(defs.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
            child: StatCardWidget(
              label:  defs[i].label,
              icon:   defs[i].icon,
              stream: defs[i].stream,
              onTap:  defs[i].onTap,
              t:      t,
            ),
          ),
        );
      }),
    );
  }
}

/// Data class for a single stat card definition.
class StatCardDef {
  final String                label;
  final IconData              icon;
  final Stream<QuerySnapshot> stream;
  final VoidCallback          onTap;

  const StatCardDef({
    required this.label,
    required this.icon,
    required this.stream,
    required this.onTap,
  });
}