import 'package:flutter/material.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/models/listing.dart';

class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final AppTheme t;
  final bool compact;

  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    required this.t,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(compact ? 10 : 12),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.primary.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: listing.imageUrls.isNotEmpty
                ? Image.network(
                    listing.imageUrls.first,
                    width: compact ? 60 : 72,
                    height: compact ? 60 : 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(t, compact),
                  )
                : _placeholder(t, compact),
          ),

          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: t.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    listing.category,
                    style: TextStyle(
                        color: t.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 5),

                // Title
                Text(
                  listing.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Price
                Text(
                  listing.formattedPrice,
                  style: TextStyle(
                      color: t.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),

                // Location + Quantity
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 11,
                      color: Colors.white.withOpacity(0.3)),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      listing.sellerLocation,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    listing.formattedQuantity,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35),
                        fontSize: 11),
                  ),
                ]),
              ],
            ),
          ),

          const SizedBox(width: 6),
          Icon(Icons.chevron_right,
              color: Colors.white.withOpacity(0.2), size: 18),
        ]),
      ),
    );
  }

  Widget _placeholder(AppTheme t, bool compact) => Container(
        width: compact ? 60 : 72,
        height: compact ? 60 : 72,
        decoration: BoxDecoration(
          color: t.cardLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.image_outlined,
            color: t.primary.withOpacity(0.25),
            size: compact ? 22 : 28),
      );
}