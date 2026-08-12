// lib/utils/voice_provider/voice_provider.dart
import 'package:flutter/foundation.dart';
import 'package:mtc/utils/language_provider.dart';
import 'package:mtc/utils/voice_provider/voice_engine.dart';
import 'package:mtc/models/listing.dart';

class VoiceProvider extends ChangeNotifier {
  final VoiceEngine _engine = VoiceEngine();

  bool _isSpeaking = false;
  bool get isSpeaking => _isSpeaking;

  int _token = 0;

  static const _bcp47ByLangCode = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
    'te': 'te-IN',
    'ml': 'ml-IN',
    'kn': 'kn-IN',
    'ar': 'ar-SA',
    'fr': 'fr-FR',
  };

  // Unit words translated per language so the voice never reads a raw
  // English unit (e.g. "kg") inside an otherwise-translated sentence.
  // Falls back to whatever the seller typed if the unit isn't in this map.
  static const Map<String, Map<String, String>> _unitWords = {
    'kg':      {'hi': 'किलो',    'ta': 'கிலோ',    'te': 'కిలో',    'ar': 'كيلوغرام', 'fr': 'kilo',      'en': 'kg'},
    'g':       {'hi': 'ग्राम',   'ta': 'கிராம்',   'te': 'గ్రాము',  'ar': 'غرام',     'fr': 'gramme',    'en': 'g'},
    'ton':     {'hi': 'टन',      'ta': 'டன்',      'te': 'టన్ను',   'ar': 'طن',       'fr': 'tonne',     'en': 'ton'},
    'quintal': {'hi': 'क्विंटल', 'ta': 'குவிண்டல்', 'te': 'క్వింటాల్', 'ar': 'قنطار',  'fr': 'quintal',   'en': 'quintal'},
    'piece':   {'hi': 'नग',      'ta': 'துண்டு',    'te': 'ముక్క',    'ar': 'قطعة',    'fr': 'pièce',     'en': 'piece'},
    'dozen':   {'hi': 'दर्जन',   'ta': 'டசன்',      'te': 'డజను',    'ar': 'دستة',    'fr': 'douzaine',  'en': 'dozen'},
    'liter':   {'hi': 'लीटर',   'ta': 'லிட்டர்',   'te': 'లీటరు',   'ar': 'لتر',      'fr': 'litre',     'en': 'liter'},
    'litre':   {'hi': 'लीटर',   'ta': 'லிட்டர்',   'te': 'లీటరు',   'ar': 'لتر',      'fr': 'litre',     'en': 'litre'},
    'box':     {'hi': 'बॉक्स',   'ta': 'பெட்டி',    'te': 'పెట్టె',   'ar': 'صندوق',   'fr': 'boîte',     'en': 'box'},
    'bag':     {'hi': 'बैग',     'ta': 'பை',        'te': 'సంచి',    'ar': 'كيس',     'fr': 'sac',       'en': 'bag'},
  };

  /// Translates a raw unit string (as typed by the seller, e.g. "kg") into
  /// the equivalent word for [langCode]. Unknown units are returned as-is.
  static String translateUnit(String unit, String langCode) {
    final key = unit.toLowerCase().trim();
    return _unitWords[key]?[langCode] ?? unit;
  }

  static String _currencyWord(String langCode) {
    switch (langCode) {
      case 'hi': return 'रुपये';
      case 'ta': return 'ரூபாய்';
      case 'te': return 'రూపాయలు';
      case 'ar': return 'روبية';
      case 'fr': return 'roupies';
      default:   return 'rupees';
    }
  }

  Future<void> init() => _engine.init();

  /// Strips emojis and special characters before speaking
  static String _clean(String text) {
    return text
        .replaceAll(RegExp(
        r'[\u{1F600}-\u{1F64F}'
        r'\u{1F300}-\u{1F5FF}'
        r'\u{1F680}-\u{1F6FF}'
        r'\u{1F700}-\u{1F77F}'
        r'\u{1F780}-\u{1F7FF}'
        r'\u{1F800}-\u{1F8FF}'
        r'\u{1F900}-\u{1F9FF}'
        r'\u{1FA00}-\u{1FA6F}'
        r'\u{2600}-\u{26FF}'
        r'\u{2700}-\u{27BF}]',
        unicode: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Builds natural, simple speech for a listing — like a friend explaining it.
  static String buildListingSpeech(Listing listing, String langCode) {
    final name      = listing.title;
    final location  = listing.sellerLocation.isNotEmpty ? listing.sellerLocation : '';
    final price     = listing.pricePerKg.toStringAsFixed(0);
    final priceUnit = translateUnit(
        listing.priceUnit.isNotEmpty ? listing.priceUnit : 'kg', langCode);
    final qty       = listing.quantityKg.toStringAsFixed(0);
    final qtyUnit   = translateUnit(
        listing.quantityUnit.isNotEmpty ? listing.quantityUnit : 'kg', langCode);
    final desc      = listing.description;
    final currency  = listing.currency == 'INR'
        ? _currencyWord(langCode)
        : listing.currency;

    switch (langCode) {
      case 'hi':
        return _clean(
          '$name${location.isNotEmpty ? ", $location से" : ""} मिल रहा है। '
              '$price $currency प्रति $priceUnit। '
              'कुल $qty $qtyUnit उपलब्ध है। '
              '${desc.isNotEmpty ? desc : ""}',
        );
      case 'ta':
        return _clean(
          '$name${location.isNotEmpty ? ", $location இலிருந்து" : ""} கிடைக்கிறது. '
              'ஒரு $priceUnit க்கு $price $currency. '
              'மொத்தம் $qty $qtyUnit உள்ளது. '
              '${desc.isNotEmpty ? desc : ""}',
        );
      case 'te':
        return _clean(
          '$name${location.isNotEmpty ? ", $location నుండి" : ""} అందుబాటులో ఉంది. '
              'ఒక $priceUnit కు $price $currency. '
              'మొత్తం $qty $qtyUnit ఉంది. '
              '${desc.isNotEmpty ? desc : ""}',
        );
      case 'ar':
        return _clean(
          '$name${location.isNotEmpty ? ", من $location" : ""} متاح. '
              'السعر $price $currency لكل $priceUnit. '
              'الكمية المتاحة $qty $qtyUnit. '
              '${desc.isNotEmpty ? desc : ""}',
        );
      case 'fr':
        return _clean(
          '$name${location.isNotEmpty ? ", de $location" : ""} est disponible. '
              'Prix: $price $currency par $priceUnit. '
              'Quantité disponible: $qty $qtyUnit. '
              '${desc.isNotEmpty ? desc : ""}',
        );
      default: // English
        return _clean(
          '$name${location.isNotEmpty ? ", from $location" : ""}. '
              'Priced at $price $currency per $priceUnit, '
              'with $qty $qtyUnit available. '
              '${desc.isNotEmpty ? desc : ""}',
        );
    }
  }

  /// Builds natural greeting speech
  static String buildGreetingSpeech(
      String firstName, String langCode, int hour) {
    switch (langCode) {
      case 'hi':
        final g = hour < 12 ? 'सुप्रभात' : hour < 17 ? 'नमस्कार' : 'शुभ संध्या';
        return _clean('$g $firstName। मरीन ट्रेड कनेक्ट में आपका स्वागत है।');
      case 'ta':
        final g = hour < 12 ? 'காலை வணக்கம்' : hour < 17 ? 'மதிய வணக்கம்' : 'மாலை வணக்கம்';
        return _clean('$g $firstName. மரைன் டிரேட் கனெக்டில் உங்களை வரவேற்கிறோம்.');
      case 'te':
        final g = hour < 12 ? 'శుభోదయం' : hour < 17 ? 'నమస్కారం' : 'శుభ సాయంత్రం';
        return _clean('$g $firstName. మెరైన్ ట్రేడ్ కనెక్ట్ కి స్వాగతం.');
      case 'ar':
        final g = hour < 12 ? 'صباح الخير' : hour < 17 ? 'مساء الخير' : 'مساء النور';
        return _clean('$g $firstName. أهلاً بك في Marine Trade Connect.');
      case 'fr':
        final g = hour < 12 ? 'Bonjour' : hour < 17 ? 'Bon après-midi' : 'Bonsoir';
        return _clean('$g $firstName. Bienvenue sur Marine Trade Connect.');
      default:
        final g = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
        return _clean('$g $firstName. Welcome to Marine Trade Connect.');
    }
  }

  /// Builds a translated sentence for a notification from its structured
  /// Firestore fields, instead of reading the stored title/body/message —
  /// which is always written in English at creation time and never
  /// translates, no matter what BCP-47 tag is passed to the TTS engine.
  ///
  /// [data] is the raw notification document map (must include 'type' and
  /// whatever fields that type stores — see the field table added to each
  /// notification write in cart_screen.dart / marketplace_screen.dart /
  /// tracking_screen.dart).
  ///
  /// If a notification predates those field additions and is missing the
  /// data this needs, this falls back to reading the stored English
  /// body/message/title as-is — same behavior as before, not a regression.
  static String buildNotificationSpeech(
      String type, Map<String, dynamic> data, String langCode) {
    final fallback =
    (data['body'] ?? data['message'] ?? data['title'] ?? '') as String;

    switch (type) {
    // "{name} added {item} to their cart." — trailing "reach out to
    // them" / "contact them" line intentionally removed per product
    // request; keep this case to exactly one short sentence.
      case 'cart_add':
        final buyer   = data['fromName'] as String?;
        final listing = data['listingTitle'] as String?;
        if (buyer == null || listing == null) return _clean(fallback);
        switch (langCode) {
          case 'hi': return _clean('$buyer ने आपके $listing को कार्ट में जोड़ा।');
          case 'ta': return _clean('$buyer உங்கள் $listing-ஐ கார்ட்டில் சேர்த்தார்.');
          case 'te': return _clean('$buyer మీ $listing ని కార్ట్‌లో జోడించారు.');
          case 'ar': return _clean('أضاف $buyer $listing إلى سلة التسوق.');
          case 'fr': return _clean('$buyer a ajouté votre $listing au panier.');
          default:   return _clean('$buyer added $listing to their cart.');
        }

      case 'new_order':
        final buyer   = data['fromName'] as String?;
        final listing = data['listingTitle'] as String?;
        final qtyRaw  = data['quantityKg'];
        if (buyer == null || listing == null || qtyRaw == null) {
          return _clean(fallback);
        }
        final qty = (qtyRaw as num).toStringAsFixed(0);
        switch (langCode) {
          case 'hi': return _clean('$buyer ने $listing का $qty किलोग्राम ऑर्डर किया।');
          case 'ta': return _clean('$buyer $listing இன் $qty கிலோ ஆர்டர் செய்தார்.');
          case 'te': return _clean('$buyer $listing యొక్క $qty కిలోలు ఆర్డర్ చేశారు.');
          case 'ar': return _clean('طلب $buyer $qty كيلوغرام من $listing.');
          case 'fr': return _clean('$buyer a commandé $qty kg de $listing.');
          default:   return _clean('$buyer ordered $qty kilograms of $listing.');
        }

      case 'product_request':
        final product = data['productTitle'] as String?;
        if (product == null) return _clean(fallback);
        switch (langCode) {
          case 'hi': return _clean('$product का अनुरोध किया गया।');
          case 'ta': return _clean('$product கோரப்பட்டது.');
          case 'te': return _clean('$product అభ్యర్థించబడింది.');
          case 'ar': return _clean('تم طلب $product.');
          case 'fr': return _clean('$product demandé.');
          default:   return _clean('$product requested.');
        }

    // Second-hand item — a buyer tapped "Contact Seller".
      case 'secondhand_interest':
        final buyer = data['fromName'] as String?;
        final item  = data['listingTitle'] as String?;
        if (buyer == null || item == null) return _clean(fallback);
        switch (langCode) {
          case 'hi': return _clean('$buyer आपके $item को खरीदना चाहते हैं।');
          case 'ta': return _clean('$buyer உங்கள் $item-ஐ வாங்க விரும்புகிறார்.');
          case 'te': return _clean('$buyer మీ $item ని కొనుగోలు చేయాలనుకుంటున్నారు.');
          case 'ar': return _clean('يريد $buyer شراء $item الخاص بك.');
          case 'fr': return _clean('$buyer souhaite acheter votre $item.');
          default:   return _clean('$buyer wants to buy your $item.');
        }

      case 'agent_applied':
        final agent   = data['agentName'] as String?;
        final listing = data['listingTitle'] as String?;
        if (agent == null || listing == null || listing.isEmpty) {
          return _clean(fallback);
        }
        switch (langCode) {
          case 'hi': return _clean('$agent आपके $listing के शिपमेंट को डिलीवर करना चाहते हैं।');
          case 'ta': return _clean('$agent உங்கள் $listing ஷிப்மென்ட்டை வழங்க விரும்புகிறார்.');
          case 'te': return _clean('$agent మీ $listing షిప్‌మెంట్‌ను డెలివర్ చేయాలనుకుంటున్నారు.');
          case 'ar': return _clean('يريد $agent توصيل شحنة $listing الخاصة بك.');
          case 'fr': return _clean('$agent souhaite livrer votre expédition de $listing.');
          default:   return _clean('$agent wants to deliver your shipment of $listing.');
        }

      case 'agent_confirmed':
        final listing = data['listingTitle'] as String?;
        if (listing == null || listing.isEmpty) return _clean(fallback);
        switch (langCode) {
          case 'hi': return _clean('आपको $listing के लिए डिलीवरी एजेंट के रूप में पुष्टि किया गया है।');
          case 'ta': return _clean('$listing க்கான டெலிவரி முகவராக நீங்கள் உறுதிப்படுத்தப்பட்டுள்ளீர்கள்.');
          case 'te': return _clean('$listing కోసం మీరు డెలివరీ ఏజెంట్‌గా నిర్ధారించబడ్డారు.');
          case 'ar': return _clean('تم تأكيدك كوكيل توصيل لـ $listing.');
          case 'fr': return _clean('Vous avez été confirmé comme agent de livraison pour $listing.');
          default:   return _clean('You have been confirmed as the delivery agent for $listing.');
        }

    // Buyer-facing: their order's status just changed (pending →
    // confirmed → picked up → in transit → delivered).
      case 'shipment_update':
        final listing = data['listingTitle'] as String?;
        final status  = data['statusLabel'] as String?;
        if (listing == null || status == null) return _clean(fallback);
        switch (langCode) {
          case 'hi': return _clean('आपका ऑर्डर $listing अब $status है।');
          case 'ta': return _clean('உங்கள் $listing ஆர்டர் இப்போது $status ஆக உள்ளது.');
          case 'te': return _clean('మీ $listing ఆర్డర్ ఇప్పుడు $status గా ఉంది.');
          case 'ar': return _clean('طلبك $listing الآن $status.');
          case 'fr': return _clean('Votre commande $listing est maintenant $status.');
          default:   return _clean('Your order $listing is now $status.');
        }

    // Buyer-facing: a delivery agent has just been assigned to their
    // order.
      case 'shipment_assigned':
        final listing = data['listingTitle'] as String?;
        final agent   = data['agentName'] as String?;
        if (listing == null || agent == null) return _clean(fallback);
        switch (langCode) {
          case 'hi': return _clean('$agent आपके $listing ऑर्डर को डिलीवर करेंगे।');
          case 'ta': return _clean('$agent உங்கள் $listing ஆர்டரை வழங்குவார்.');
          case 'te': return _clean('$agent మీ $listing ఆర్డర్‌ను డెలివర్ చేస్తారు.');
          case 'ar': return _clean('سيقوم $agent بتوصيل طلبك $listing.');
          case 'fr': return _clean('$agent livrera votre commande $listing.');
          default:   return _clean('$agent will deliver your order $listing.');
        }

      default:
        return _clean(fallback);
    }
  }

  /// Speaks listing details in current app language — simple and natural
  Future<void> speakListing(Listing listing, LanguageProvider lp) async {
    final langCode = lp.locale.languageCode;
    final bcp47    = _bcp47ByLangCode[langCode] ?? 'en-IN';
    final text     = buildListingSpeech(listing, langCode);
    await speak(text, bcp47);
  }

  /// Speaks greeting in current app language
  Future<void> speakGreeting(String firstName, LanguageProvider lp) async {
    final langCode = lp.locale.languageCode;
    final bcp47    = _bcp47ByLangCode[langCode] ?? 'en-IN';
    final text     = buildGreetingSpeech(firstName, langCode, DateTime.now().hour);
    await speak(text, bcp47);
  }

  /// Speaks a notification in the current app language, reconstructing the
  /// sentence from structured data instead of reading the stored English
  /// title/body/message. [data] should be the notification document's
  /// field map (e.g. doc.data()), and must include 'type'.
  Future<void> speakNotification(
      Map<String, dynamic> data, LanguageProvider lp) async {
    final langCode = lp.locale.languageCode;
    final bcp47    = _bcp47ByLangCode[langCode] ?? 'en-IN';
    final type     = (data['type'] ?? '') as String;
    final text     = buildNotificationSpeech(type, data, langCode);
    await speak(text, bcp47);
  }

  /// Speaks any text in the current app language — strips emoji automatically
  Future<void> speakInAppLanguage(String text, LanguageProvider lp) async {
    final bcp47 = _bcp47ByLangCode[lp.locale.languageCode] ?? 'en-IN';
    await speak(_clean(text), bcp47);
  }

  /// Speaks with an explicit BCP-47 tag
  Future<void> speak(String text, String bcp47) async {
    if (text.trim().isEmpty) return;
    final myToken = ++_token;
    _isSpeaking = true;
    notifyListeners();
    try {
      await _engine.speak(_clean(text), bcp47);
    } finally {
      if (myToken == _token) {
        _isSpeaking = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    _token++;
    await _engine.stop();
    if (_isSpeaking) {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _engine.stop();
    super.dispose();
  }
}