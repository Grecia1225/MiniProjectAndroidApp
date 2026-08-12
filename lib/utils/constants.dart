import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Marine Trade Connect';
  static const String appTagline = "India's Maritime Marketplace";

  static const String usersCollection = 'users';
  static const String listingsCollection = 'listings';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String shipmentCollection = 'shipments';

  static const String roleBuyer  = 'buyer';
  static const String roleSeller = 'seller';
  static const String roleAgent  = 'agent';

  static const List<String> categories = [
    // Seafood
    'Fresh Fish & Seafood',
    'Frozen Seafood',
    'Dried & Processed Fish',
    'Prawns & Shrimp',
    'Crabs & Lobster',
    'Squid & Octopus',
    // Agriculture
    'Grains & Cereals',
    'Fruits & Vegetables',
    'Edible Oils',
    'Dairy & Perishables',
    // Industrial
    'Crude Oil & Petroleum',
    'Coal & Minerals',
    'Iron & Steel',
    'Chemicals',
    'Fertilizers',
    'Timber & Wood',
    'Cement & Construction',
    // Marine Equipment
    'Marine Equipment',
    'Fishing Gear',
    'Navigation Tools',
    'Boats & Vessels',
    'Ship Parts & Engine',
    'Ropes & Nets',
    'Safety Equipment',
    'Fuel & Lubricants',
    // Cargo
    'Containers',
    'Bulk Cargo',
    'Electronics',
    'Textiles & Garments',
    'Pharmaceuticals',
    // Other
    'Other',
  ];

  static const List<String> currencies = ['INR', 'USD', 'EUR', 'AED', 'GBP', 'SGD'];
  static const List<String> units = ['kg', 'ton', 'MT', 'piece', 'box', 'container', 'lot', 'vessel', 'litre', 'barrel'];

  static const double pagePadding   = 24.0;
  static const double cardRadius    = 16.0;
  static const double buttonRadius  = 14.0;

  static const Duration fast   = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
}