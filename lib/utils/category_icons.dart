// lib/utils/category_icons.dart
//
// Maps every category in AppConstants.categories to an icon and a
// translated display name, so low-literacy sellers can pick a category by
// recognising a picture instead of reading English text. Falls back to the
// raw English string if a translation is missing for a given language.
import 'package:flutter/material.dart';

class CategoryIcons {
  static IconData iconFor(String category) {
    switch (category) {
    // Seafood
      case 'Fresh Fish & Seafood':   return Icons.set_meal_outlined;
      case 'Frozen Seafood':         return Icons.ac_unit_outlined;
      case 'Dried & Processed Fish': return Icons.inventory_2_outlined;
      case 'Prawns & Shrimp':        return Icons.water;
      case 'Crabs & Lobster':        return Icons.catching_pokemon;
      case 'Squid & Octopus':        return Icons.water_outlined;
    // Agriculture
      case 'Grains & Cereals':       return Icons.grass_outlined;
      case 'Fruits & Vegetables':    return Icons.eco_outlined;
      case 'Edible Oils':            return Icons.opacity_outlined;
      case 'Dairy & Perishables':    return Icons.icecream_outlined;
    // Industrial
      case 'Crude Oil & Petroleum':  return Icons.local_gas_station_outlined;
      case 'Coal & Minerals':        return Icons.terrain_outlined;
      case 'Iron & Steel':           return Icons.construction_outlined;
      case 'Chemicals':              return Icons.science_outlined;
      case 'Fertilizers':            return Icons.grain_outlined;
      case 'Timber & Wood':          return Icons.park_outlined;
      case 'Cement & Construction':  return Icons.foundation_outlined;
    // Marine Equipment
      case 'Marine Equipment':       return Icons.anchor;
      case 'Fishing Gear':           return Icons.hardware_outlined;
      case 'Navigation Tools':       return Icons.explore_outlined;
      case 'Boats & Vessels':        return Icons.directions_boat_outlined;
      case 'Ship Parts & Engine':    return Icons.build_outlined;
      case 'Ropes & Nets':           return Icons.cable_outlined;
      case 'Safety Equipment':       return Icons.shield_outlined;
      case 'Fuel & Lubricants':      return Icons.oil_barrel_outlined;
    // Cargo
      case 'Containers':             return Icons.inventory_outlined;
      case 'Bulk Cargo':             return Icons.warehouse_outlined;
      case 'Electronics':            return Icons.devices_outlined;
      case 'Textiles & Garments':    return Icons.checkroom_outlined;
      case 'Pharmaceuticals':        return Icons.medication_outlined;
    // Other
      case 'Other':                  return Icons.more_horiz;
      default:                       return Icons.category_outlined;
    }
  }

  // Emoji fallback — renders identically on every device/font, useful
  // for the biggest, most recognisable tile visual (fish/prawn/crab etc).
  static String emojiFor(String category) {
    switch (category) {
      case 'Fresh Fish & Seafood':   return '🐟';
      case 'Frozen Seafood':         return '🧊';
      case 'Dried & Processed Fish': return '🍢';
      case 'Prawns & Shrimp':        return '🦐';
      case 'Crabs & Lobster':        return '🦀';
      case 'Squid & Octopus':        return '🦑';
      case 'Grains & Cereals':       return '🌾';
      case 'Fruits & Vegetables':    return '🥬';
      case 'Edible Oils':            return '🛢️';
      case 'Dairy & Perishables':    return '🥛';
      case 'Crude Oil & Petroleum':  return '⛽';
      case 'Coal & Minerals':        return '⛏️';
      case 'Iron & Steel':           return '🔩';
      case 'Chemicals':              return '🧪';
      case 'Fertilizers':            return '🌱';
      case 'Timber & Wood':          return '🪵';
      case 'Cement & Construction':  return '🧱';
      case 'Marine Equipment':       return '⚓';
      case 'Fishing Gear':           return '🎣';
      case 'Navigation Tools':       return '🧭';
      case 'Boats & Vessels':        return '🚤';
      case 'Ship Parts & Engine':    return '⚙️';
      case 'Ropes & Nets':           return '🕸️';
      case 'Safety Equipment':       return '🦺';
      case 'Fuel & Lubricants':      return '🛢️';
      case 'Containers':             return '📦';
      case 'Bulk Cargo':             return '🏗️';
      case 'Electronics':            return '🔌';
      case 'Textiles & Garments':    return '🧵';
      case 'Pharmaceuticals':        return '💊';
      case 'Other':                  return '❓';
      default:                       return '📦';
    }
  }

  // Translated category names. Missing entries fall back to the raw
  // English string automatically via translatedName() below.
  static const Map<String, Map<String, String>> _names = {
    'Fresh Fish & Seafood': {
      'en': 'Fresh Fish & Seafood', 'hi': 'ताज़ी मछली और समुद्री भोजन',
      'ta': 'புதிய மீன் மற்றும் கடல் உணவு', 'te': 'తాజా చేప మరియు సముద్ర ఆహారం',
      'ar': 'سمك طازج ومأكولات بحرية', 'fr': 'Poisson frais et fruits de mer',
    },
    'Frozen Seafood': {
      'en': 'Frozen Seafood', 'hi': 'जमी हुई समुद्री भोजन',
      'ta': 'உறைந்த கடல் உணவு', 'te': 'ఘనీభవించిన సముద్ర ఆహారం',
      'ar': 'مأكولات بحرية مجمدة', 'fr': 'Fruits de mer congelés',
    },
    'Dried & Processed Fish': {
      'en': 'Dried & Processed Fish', 'hi': 'सूखी मछली',
      'ta': 'உலர்ந்த மீன்', 'te': 'ఎండిన చేప',
      'ar': 'سمك مجفف ومصنع', 'fr': 'Poisson séché',
    },
    'Prawns & Shrimp': {
      'en': 'Prawns & Shrimp', 'hi': 'झींगा',
      'ta': 'இறால்', 'te': 'రొయ్యలు',
      'ar': 'الجمبري والروبيان', 'fr': 'Crevettes',
    },
    'Crabs & Lobster': {
      'en': 'Crabs & Lobster', 'hi': 'केकड़ा और झींगा मछली',
      'ta': 'நண்டு மற்றும் இரால்', 'te': 'పీత మరియు లాబ్‌స్టర్',
      'ar': 'سلطعون وجراد البحر', 'fr': 'Crabes et homards',
    },
    'Squid & Octopus': {
      'en': 'Squid & Octopus', 'hi': 'स्क्विड और ऑक्टोपस',
      'ta': 'கணவாய் மற்றும் ஆக்டோபஸ்', 'te': 'స్క్విడ్ మరియు ఆక్టోపస్',
      'ar': 'الحبار والأخطبوط', 'fr': 'Calamars et poulpes',
    },
    'Grains & Cereals': {
      'en': 'Grains & Cereals', 'hi': 'अनाज',
      'ta': 'தானியங்கள்', 'te': 'ధాన్యాలు',
      'ar': 'الحبوب', 'fr': 'Céréales',
    },
    'Fruits & Vegetables': {
      'en': 'Fruits & Vegetables', 'hi': 'फल और सब्जियां',
      'ta': 'பழங்கள் மற்றும் காய்கறிகள்', 'te': 'పండ్లు మరియు కూరగాయలు',
      'ar': 'الفواكه والخضروات', 'fr': 'Fruits et légumes',
    },
    'Edible Oils': {
      'en': 'Edible Oils', 'hi': 'खाद्य तेल',
      'ta': 'சமையல் எண்ணெய்', 'te': 'వంట నూనెలు',
      'ar': 'الزيوت الصالحة للأكل', 'fr': 'Huiles alimentaires',
    },
    'Dairy & Perishables': {
      'en': 'Dairy & Perishables', 'hi': 'डेयरी उत्पाद',
      'ta': 'பால் பொருட்கள்', 'te': 'పాల ఉత్పత్తులు',
      'ar': 'منتجات الألبان', 'fr': 'Produits laitiers',
    },
    'Crude Oil & Petroleum': {
      'en': 'Crude Oil & Petroleum', 'hi': 'कच्चा तेल',
      'ta': 'கச்சா எண்ணெய்', 'te': 'ముడి చమురు',
      'ar': 'النفط الخام', 'fr': 'Pétrole brut',
    },
    'Coal & Minerals': {
      'en': 'Coal & Minerals', 'hi': 'कोयला और खनिज',
      'ta': 'நிலக்கரி மற்றும் தாதுக்கள்', 'te': 'బొగ్గు మరియు ఖనిజాలు',
      'ar': 'الفحم والمعادن', 'fr': 'Charbon et minéraux',
    },
    'Iron & Steel': {
      'en': 'Iron & Steel', 'hi': 'लोहा और इस्पात',
      'ta': 'இரும்பு மற்றும் எஃகு', 'te': 'ఇనుము మరియు ఉక్కు',
      'ar': 'الحديد والصلب', 'fr': 'Fer et acier',
    },
    'Chemicals': {
      'en': 'Chemicals', 'hi': 'रसायन',
      'ta': 'இரசாயனங்கள்', 'te': 'రసాయనాలు',
      'ar': 'المواد الكيميائية', 'fr': 'Produits chimiques',
    },
    'Fertilizers': {
      'en': 'Fertilizers', 'hi': 'उर्वरक',
      'ta': 'உரங்கள்', 'te': 'ఎరువులు',
      'ar': 'الأسمدة', 'fr': 'Engrais',
    },
    'Timber & Wood': {
      'en': 'Timber & Wood', 'hi': 'लकड़ी',
      'ta': 'மரம்', 'te': 'కలప',
      'ar': 'الأخشاب', 'fr': 'Bois',
    },
    'Cement & Construction': {
      'en': 'Cement & Construction', 'hi': 'सीमेंट और निर्माण',
      'ta': 'சிமெண்ட் மற்றும் கட்டுமானம்', 'te': 'సిమెంట్ మరియు నిర్మాణం',
      'ar': 'الأسمنت والبناء', 'fr': 'Ciment et construction',
    },
    'Marine Equipment': {
      'en': 'Marine Equipment', 'hi': 'समुद्री उपकरण',
      'ta': 'கடல்சார் உபகரணங்கள்', 'te': 'సముద్ర పరికరాలు',
      'ar': 'المعدات البحرية', 'fr': 'Équipement marin',
    },
    'Fishing Gear': {
      'en': 'Fishing Gear', 'hi': 'मछली पकड़ने का सामान',
      'ta': 'மீன்பிடி உபகரணங்கள்', 'te': 'చేపలు పట్టే పరికరాలు',
      'ar': 'معدات الصيد', 'fr': 'Matériel de pêche',
    },
    'Navigation Tools': {
      'en': 'Navigation Tools', 'hi': 'नेविगेशन उपकरण',
      'ta': 'வழிசெலுத்தல் கருவிகள்', 'te': 'నావిగేషన్ పరికరాలు',
      'ar': 'أدوات الملاحة', 'fr': 'Outils de navigation',
    },
    'Boats & Vessels': {
      'en': 'Boats & Vessels', 'hi': 'नाव और जहाज',
      'ta': 'படகுகள் மற்றும் கப்பல்கள்', 'te': 'పడవలు మరియు నౌకలు',
      'ar': 'القوارب والسفن', 'fr': 'Bateaux et navires',
    },
    'Ship Parts & Engine': {
      'en': 'Ship Parts & Engine', 'hi': 'जहाज के पुर्जे और इंजन',
      'ta': 'கப்பல் பாகங்கள் மற்றும் இயந்திரம்', 'te': 'నౌక భాగాలు మరియు ఇంజిన్',
      'ar': 'قطع غيار السفن والمحرك', 'fr': 'Pièces de navire et moteur',
    },
    'Ropes & Nets': {
      'en': 'Ropes & Nets', 'hi': 'रस्सी और जाल',
      'ta': 'கயிறு மற்றும் வலை', 'te': 'తాడు మరియు వల',
      'ar': 'الحبال والشباك', 'fr': 'Cordes et filets',
    },
    'Safety Equipment': {
      'en': 'Safety Equipment', 'hi': 'सुरक्षा उपकरण',
      'ta': 'பாதுகாப்பு உபகரணங்கள்', 'te': 'భద్రతా పరికరాలు',
      'ar': 'معدات السلامة', 'fr': 'Équipement de sécurité',
    },
    'Fuel & Lubricants': {
      'en': 'Fuel & Lubricants', 'hi': 'ईंधन और स्नेहक',
      'ta': 'எரிபொருள் மற்றும் உயவுப்பொருள்', 'te': 'ఇంధనం మరియు కందెనలు',
      'ar': 'الوقود ومواد التشحيم', 'fr': 'Carburant et lubrifiants',
    },
    'Containers': {
      'en': 'Containers', 'hi': 'कंटेनर',
      'ta': 'கொள்கலன்கள்', 'te': 'కంటైనర్లు',
      'ar': 'الحاويات', 'fr': 'Conteneurs',
    },
    'Bulk Cargo': {
      'en': 'Bulk Cargo', 'hi': 'थोक माल',
      'ta': 'மொத்த சரக்கு', 'te': 'బల్క్ కార్గో',
      'ar': 'البضائع السائبة', 'fr': 'Cargaison en vrac',
    },
    'Electronics': {
      'en': 'Electronics', 'hi': 'इलेक्ट्रॉनिक्स',
      'ta': 'மின்னணுவியல்', 'te': 'ఎలక్ట్రానిక్స్',
      'ar': 'الإلكترونيات', 'fr': 'Électronique',
    },
    'Textiles & Garments': {
      'en': 'Textiles & Garments', 'hi': 'वस्त्र और परिधान',
      'ta': 'ஆடை மற்றும் துணி', 'te': 'వస్త్రాలు మరియు దుస్తులు',
      'ar': 'المنسوجات والملابس', 'fr': 'Textiles et vêtements',
    },
    'Pharmaceuticals': {
      'en': 'Pharmaceuticals', 'hi': 'दवाइयां',
      'ta': 'மருந்துகள்', 'te': 'ఔషధాలు',
      'ar': 'الأدوية', 'fr': 'Produits pharmaceutiques',
    },
    'Other': {
      'en': 'Other', 'hi': 'अन्य',
      'ta': 'மற்றவை', 'te': 'ఇతరాలు',
      'ar': 'أخرى', 'fr': 'Autre',
    },
  };

  /// Returns the category name translated into [langCode].
  /// Falls back to the raw English category string if no translation
  /// exists for that language.
  static String translatedName(String category, String langCode) {
    return _names[category]?[langCode] ?? category;
  }
}