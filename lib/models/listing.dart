import 'package:cloud_firestore/cloud_firestore.dart';

class Listing {
  final String id;
  final String sellerId;
  final String sellerName;
  final String sellerLocation;
  final String title;
  final String description;
  final String category;
  final double pricePerKg;
  final String priceUnit;
  final String currency;
  final double quantityKg;
  final String quantityUnit;
  final List<String> imageUrls;
  final String status;
  final DateTime createdAt;

  const Listing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerLocation,
    required this.title,
    required this.description,
    required this.category,
    required this.pricePerKg,
    this.priceUnit = 'kg',
    this.currency = 'INR',
    required this.quantityKg,
    this.quantityUnit = 'kg',
    this.imageUrls = const [],
    this.status = 'active',
    required this.createdAt,
  });

  factory Listing.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Listing(
      id:             doc.id,
      sellerId:       d['sellerId']       ?? '',
      sellerName:     d['sellerName']     ?? '',
      sellerLocation: d['sellerLocation'] ?? '',
      title:          d['title']          ?? '',
      description:    d['description']    ?? '',
      category:       d['category']       ?? 'Other',
      pricePerKg:     (d['pricePerKg']    as num?)?.toDouble() ?? 0.0,
      priceUnit:      d['priceUnit']      ?? 'kg',
      currency:       d['currency']       ?? 'INR',
      quantityKg:     (d['quantityKg']    as num?)?.toDouble() ?? 0.0,
      quantityUnit:   d['quantityUnit']   ?? 'kg',
      imageUrls:      List<String>.from(d['imageUrls'] ?? []),
      status:         d['status']         ?? 'active',
      createdAt:      (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'sellerId':       sellerId,
    'sellerName':     sellerName,
    'sellerLocation': sellerLocation,
    'title':          title,
    'description':    description,
    'category':       category,
    'pricePerKg':     pricePerKg,
    'priceUnit':      priceUnit,
    'currency':       currency,
    'quantityKg':     quantityKg,
    'quantityUnit':   quantityUnit,
    'imageUrls':      imageUrls,
    'status':         status,
    'createdAt':      Timestamp.fromDate(createdAt),
  };

  String get formattedPrice {
    final symbol = currency == 'INR' ? '₹' : currency;
    return '$symbol ${pricePerKg.toStringAsFixed(0)} / $priceUnit';
  }

  String get formattedQuantity =>
      '${quantityKg.toStringAsFixed(0)} $quantityUnit';
}