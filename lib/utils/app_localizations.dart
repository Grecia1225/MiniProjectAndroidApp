import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const _strings = {
    // ──────────────────────────────────────────────────────────────── ENGLISH
    'en': {
      // Nav
      'home': 'Home', 'market': 'Market', 'chat': 'Chat',
      'tracking': 'Tracking', 'profile': 'Profile',
      // Greetings
      'goodMorning': 'Good morning ☀️', 'goodAfternoon': 'Good afternoon 🌤️',
      'goodEvening': 'Good evening 🌙',
      // Dashboard
      'quickActions': 'Quick actions', 'recentActivity': 'Recent activity',
      'noActivity': 'No activity yet', 'viewAll': 'View all',
      'browseMarket': 'Browse Market', 'myListings': 'My Listings',
      // Stat card labels
      'listings': 'Listings', 'deals': 'Deals', 'shipments': 'Shipments',
      'chats': 'Chats', 'inTransit': 'In Transit',
      'orders': 'Orders', 'openJobs': 'Open Jobs', 'myDeliveries': 'My Deliveries',
      // Quick action labels
      'myOrders': 'My Orders', 'trackOrders': 'Track Orders',
      'trackPurchases': 'Track purchases', 'postListing': 'Post Listing',
      'sellYourGoods': 'Sell your goods', 'secondHand': 'Second Hand',
      'buyUsedItems': 'Buy used items', 'listUsedItems': 'List used items',
      'liveShipments': 'Live shipments', 'chatWithTraders': 'Chat with traders',
      'browseListings': 'Browse listings',
      'fishCalendar': 'Fish Calendar', 'bestCatchesByMonth': 'Best catches by month',
      'availableJobs': 'Available Jobs', 'pickUpShipments': 'Pick up shipments',
      'trackActiveJobs': 'Track active jobs',
      'myCart': 'My Cart', 'viewYourCart': 'View your cart',
      // Marketplace
      'marketplace': 'Marketplace',
      'search': 'Search listings, products, location...',
      'noListings': 'No listings found', 'postAListing': 'Post a listing',
      'requestSent': 'Request sent! Sellers will be notified.',
      'contactSeller': 'Contact Seller', 'available': 'Available',
      'addToCart': 'Add to Cart', 'viewCart': 'View Cart',
      'placeOrder': 'Place Order', 'orderPlaced': 'Order Placed!',
      // Profile
      'signOut': 'Sign out', 'appTheme': 'App theme',
      'editProfile': 'Edit profile', 'notifications': 'Notifications',
      'privacy': 'Privacy & Security', 'help': 'Help & Support',
      'terms': 'Terms & Conditions', 'about': 'About MTC',
      'language': 'Language', 'selectLanguage': 'Select language',
      'saveChanges': 'Save changes',
      'personalisation': 'PERSONALISATION', 'preferences': 'PREFERENCES',
      'support': 'SUPPORT',
      'chooseColourScheme': 'Choose your colour scheme',
      'updateYourDetails': 'Update your details',
      'manageAlerts': 'Manage alerts', 'controlYourData': 'Control your data',
      'faqsAndLiveChat': 'FAQs and live chat',
      'legalInformation': 'Legal information',
      'versionAndCompanyInfo': 'Version and company info',
      'userFallback': 'User',
      'signOutConfirmTitle': 'Sign out?',
      'signOutConfirmBody': 'You will be returned to the login screen.',
      // Roles
      'roleSeller': 'SELLER', 'roleAgent': 'AGENT', 'roleBuyer': 'BUYER',
      // Home greeting subtitles
      'greetSellerEarly': 'Early start — best catches go first 🐟',
      'greetSellerWeekend': 'Weekend markets are busy. Post your listings!',
      'greetSellerDefault': 'Ready to make some sales today?',
      'greetAgentDefault': 'Any deliveries to pick up today? 🚢',
      'greetBuyerEarly': 'Morning catch is freshest — great time to browse! 🌊',
      'greetBuyerWeekend': "Happy weekend! See what's fresh at the market.",
      'greetBuyerDefault': 'What are you looking for today?',
      // Marine news
      'marineNews': 'Marine News',
      'aiGeneratedDisclaimer':
      'AI-generated advisories — verify with INCOIS for official alerts',
      // Recent activity
      'orderFallback': 'Order', 'buyerPrefix': 'Buyer',
      'sellerPrefix': 'Seller', 'unknownUser': 'Unknown',
      // Misc
      'messages': 'Messages',

      // ── Listing detail screen ──────────────────────────────────────────
      'category': 'Category', 'description': 'Description', 'details': 'Details',
      'quantity': 'Quantity', 'currency': 'Currency', 'posted': 'Posted',
      'seller': 'Seller', 'locationNotSpecified': 'Location not specified',
      'yourListing': 'YOUR LISTING', 'sold': 'Sold',
      'editListing': 'Edit Listing', 'markAsSold': 'Mark as Sold',
      'markAvailableAgain': 'Mark as Available Again',
      'itemSoldNotice': 'This item has been sold and is no longer available.',
      'itemSold': 'Item Sold',
      'addedToCartSuffix': 'added to cart!',
      'deleteListingTitle': 'Delete listing?',
      'deleteListingBody': 'This cannot be undone.',
      'cancel': 'Cancel', 'delete': 'Delete',
      'markSoldConfirmTitle': 'Mark as Sold?',
      'markSoldConfirmBody':
      'Buyers will see this item as sold. You can mark it available again anytime.',
      'listingMarkedSold': 'Listing marked as sold',
      'listingMarkedAvailable': 'Listing is now available again',
      'daysAgo': '{n}d ago', 'hoursAgo': '{n}h ago', 'minsAgo': '{n}m ago',
      // Voice-only labels (used to build the spoken summary)
      'voiceCategory': 'Category', 'voicePrice': 'Price',
      'voiceQuantityAvailable': 'available',
      'voiceSeller': 'Seller', 'voiceLocation': 'Location',
      'welcomeMessage': 'Welcome to Marine Trade Connect.',

      // ── Fish seasonal calendar (month-first view) ───────────────────────
      'thisMonthBadge': 'This month',
      'noFishThisMonth': 'No fish in season this month',
      'peakSeasonLabel': 'In season during',
      // Fish names — only defined here. Other locales intentionally omit
      // these so get() falls back to English until real regional market
      // names are confirmed (these vary a lot by coast/dialect — e.g. the
      // same fish is "Surmai" in Mumbai and "Vanjaram" on the Tamil/Telugu
      // coast). Do not guess-fill these without checking with local sellers.
      'fishRohu': 'Rohu', 'fishCatla': 'Catla', 'fishHilsa': 'Hilsa',
      'fishPomfret': 'Pomfret', 'fishMackerel': 'Mackerel', 'fishSardine': 'Sardine',
      'fishTuna': 'Tuna', 'fishPrawn': 'Prawn', 'fishLobster': 'Lobster',
      'fishCrab': 'Crab', 'fishSurmai': 'Surmai', 'fishSquid': 'Squid',
    },
    // ────────────────────────────────────────────────────────────────── HINDI
    'hi': {
      'home': 'होम', 'market': 'बाज़ार', 'chat': 'चैट',
      'tracking': 'ट्रैकिंग', 'profile': 'प्रोफ़ाइल',
      'goodMorning': 'सुप्रभात ☀️', 'goodAfternoon': 'नमस्कार 🌤️',
      'goodEvening': 'शुभ संध्या 🌙',
      'quickActions': 'त्वरित क्रियाएं', 'recentActivity': 'हाल की गतिविधि',
      'noActivity': 'कोई गतिविधि नहीं', 'viewAll': 'सभी देखें',
      'browseMarket': 'बाज़ार देखें', 'myListings': 'मेरी लिस्टिंग',
      'listings': 'लिस्टिंग', 'deals': 'सौदे', 'shipments': 'शिपमेंट',
      'chats': 'चैट', 'inTransit': 'रास्ते में',
      'orders': 'ऑर्डर', 'openJobs': 'खुले काम', 'myDeliveries': 'मेरी डिलीवरी',
      'myOrders': 'मेरे ऑर्डर', 'trackOrders': 'ऑर्डर ट्रैक करें',
      'trackPurchases': 'खरीदारी ट्रैक करें', 'postListing': 'लिस्टिंग पोस्ट करें',
      'sellYourGoods': 'अपना माल बेचें', 'secondHand': 'सेकंड हैंड',
      'buyUsedItems': 'पुरानी चीज़ें खरीदें', 'listUsedItems': 'पुरानी चीज़ें बेचें',
      'liveShipments': 'लाइव शिपमेंट', 'chatWithTraders': 'व्यापारियों से चैट करें',
      'browseListings': 'लिस्टिंग देखें',
      'fishCalendar': 'मछली कैलेंडर', 'bestCatchesByMonth': 'महीने के अनुसार सबसे अच्छी पकड़',
      'availableJobs': 'उपलब्ध काम', 'pickUpShipments': 'शिपमेंट लें',
      'trackActiveJobs': 'सक्रिय काम ट्रैक करें',
      'myCart': 'मेरी कार्ट', 'viewYourCart': 'अपनी कार्ट देखें',
      'marketplace': 'मार्केटप्लेस',
      'search': 'लिस्टिंग, उत्पाद, स्थान खोजें...',
      'noListings': 'कोई लिस्टिंग नहीं मिली', 'postAListing': 'लिस्टिंग पोस्ट करें',
      'requestSent': 'अनुरोध भेजा गया! विक्रेताओं को सूचित किया जाएगा।',
      'contactSeller': 'विक्रेता से संपर्क करें', 'available': 'उपलब्ध',
      'addToCart': 'कार्ट में डालें', 'viewCart': 'कार्ट देखें',
      'placeOrder': 'ऑर्डर दें', 'orderPlaced': 'ऑर्डर हो गया!',
      'signOut': 'साइन आउट', 'appTheme': 'ऐप थीम',
      'editProfile': 'प्रोफ़ाइल संपादित करें', 'notifications': 'सूचनाएं',
      'privacy': 'गोपनीयता और सुरक्षा', 'help': 'सहायता',
      'terms': 'नियम और शर्तें', 'about': 'MTC के बारे में',
      'language': 'भाषा', 'selectLanguage': 'भाषा चुनें',
      'saveChanges': 'परिवर्तन सहेजें', 'messages': 'संदेश',
      'personalisation': 'निजीकरण', 'preferences': 'प्राथमिकताएं',
      'support': 'सहायता',
      'chooseColourScheme': 'अपनी रंग योजना चुनें',
      'updateYourDetails': 'अपनी जानकारी अपडेट करें',
      'manageAlerts': 'अलर्ट प्रबंधित करें', 'controlYourData': 'अपना डेटा नियंत्रित करें',
      'faqsAndLiveChat': 'सामान्य प्रश्न और लाइव चैट',
      'legalInformation': 'कानूनी जानकारी',
      'versionAndCompanyInfo': 'संस्करण और कंपनी जानकारी',
      'userFallback': 'उपयोगकर्ता',
      'signOutConfirmTitle': 'साइन आउट करें?',
      'signOutConfirmBody': 'आपको लॉगिन स्क्रीन पर वापस भेज दिया जाएगा।',
      'roleSeller': 'विक्रेता', 'roleAgent': 'एजेंट', 'roleBuyer': 'खरीदार',
      'greetSellerEarly': 'जल्दी शुरुआत — सबसे अच्छी पकड़ पहले मिलती है 🐟',
      'greetSellerWeekend': 'सप्ताहांत बाज़ार व्यस्त हैं। अपनी लिस्टिंग पोस्ट करें!',
      'greetSellerDefault': 'आज कुछ बिक्री करने के लिए तैयार हैं?',
      'greetAgentDefault': 'आज कोई डिलीवरी लेनी है? 🚢',
      'greetBuyerEarly': 'सुबह की पकड़ सबसे ताज़ी होती है — देखने का सही समय! 🌊',
      'greetBuyerWeekend': 'खुशहाल सप्ताहांत! देखें बाज़ार में क्या ताज़ा है।',
      'greetBuyerDefault': 'आज आप क्या ढूंढ रहे हैं?',
      'marineNews': 'समुद्री समाचार',
      'aiGeneratedDisclaimer':
      'AI-जनित सलाह — आधिकारिक अलर्ट के लिए INCOIS से सत्यापित करें',
      'orderFallback': 'ऑर्डर', 'buyerPrefix': 'खरीदार',
      'sellerPrefix': 'विक्रेता', 'unknownUser': 'अज्ञात',

      'category': 'श्रेणी', 'description': 'विवरण', 'details': 'जानकारी',
      'quantity': 'मात्रा', 'currency': 'मुद्रा', 'posted': 'पोस्ट किया गया',
      'seller': 'विक्रेता', 'locationNotSpecified': 'स्थान निर्दिष्ट नहीं है',
      'yourListing': 'आपकी लिस्टिंग', 'sold': 'बिका हुआ',
      'editListing': 'लिस्टिंग संपादित करें', 'markAsSold': 'बिका हुआ चिह्नित करें',
      'markAvailableAgain': 'फिर से उपलब्ध चिह्नित करें',
      'itemSoldNotice': 'यह वस्तु बिक चुकी है और अब उपलब्ध नहीं है।',
      'itemSold': 'वस्तु बिक गई',
      'addedToCartSuffix': 'कार्ट में जोड़ा गया!',
      'deleteListingTitle': 'लिस्टिंग हटाएं?',
      'deleteListingBody': 'इसे पूर्ववत नहीं किया जा सकता।',
      'cancel': 'रद्द करें', 'delete': 'हटाएं',
      'markSoldConfirmTitle': 'बिका हुआ चिह्नित करें?',
      'markSoldConfirmBody':
      'खरीदार इस वस्तु को बिका हुआ देखेंगे। आप इसे कभी भी फिर से उपलब्ध चिह्नित कर सकते हैं।',
      'listingMarkedSold': 'लिस्टिंग बिका हुआ चिह्नित की गई',
      'listingMarkedAvailable': 'लिस्टिंग अब फिर से उपलब्ध है',
      'daysAgo': '{n} दिन पहले', 'hoursAgo': '{n} घंटे पहले',
      'minsAgo': '{n} मिनट पहले',
      'voiceCategory': 'श्रेणी', 'voicePrice': 'कीमत',
      'voiceQuantityAvailable': 'उपलब्ध',
      'voiceSeller': 'विक्रेता', 'voiceLocation': 'स्थान',
      'welcomeMessage': 'मरीन ट्रेड कनेक्ट में आपका स्वागत है।',

      'thisMonthBadge': 'इस महीने',
      'noFishThisMonth': 'इस महीने कोई मछली सीज़न में नहीं है',
      'peakSeasonLabel': 'इन महीनों में मिलती है',
    },
    // ─────────────────────────────────────────────────────────────────── TAMIL
    'ta': {
      'home': 'முகப்பு', 'market': 'சந்தை', 'chat': 'அரட்டை',
      'tracking': 'கண்காணிப்பு', 'profile': 'சுயவிவரம்',
      'goodMorning': 'காலை வணக்கம் ☀️', 'goodAfternoon': 'மதிய வணக்கம் 🌤️',
      'goodEvening': 'மாலை வணக்கம் 🌙',
      'quickActions': 'விரைவு செயல்கள்', 'recentActivity': 'சமீபத்திய செயல்பாடு',
      'noActivity': 'செயல்பாடு இல்லை', 'viewAll': 'அனைத்தும் பார்க்க',
      'browseMarket': 'சந்தையை பார்க்க', 'myListings': 'என் பட்டியல்கள்',
      'listings': 'பட்டியல்கள்', 'deals': 'ஒப்பந்தங்கள்',
      'shipments': 'ஏற்றுமதி', 'chats': 'அரட்டைகள்', 'inTransit': 'வழியில்',
      'orders': 'ஆர்டர்கள்', 'openJobs': 'திறந்த வேலைகள்', 'myDeliveries': 'என் டெலிவரிகள்',
      'myOrders': 'என் ஆர்டர்கள்', 'trackOrders': 'ஆர்டர்கள் கண்காணி',
      'trackPurchases': 'கொள்முதல் கண்காணி', 'postListing': 'பட்டியல் இடுக',
      'sellYourGoods': 'உங்கள் பொருட்களை விற்க', 'secondHand': 'பழையது',
      'buyUsedItems': 'பழைய பொருட்கள் வாங்க', 'listUsedItems': 'பழைய பொருட்கள் விற்க',
      'liveShipments': 'நேரடி ஏற்றுமதி', 'chatWithTraders': 'வணிகர்களுடன் அரட்டை',
      'browseListings': 'பட்டியல்கள் பார்க்க',
      'fishCalendar': 'மீன் காலண்டர்', 'bestCatchesByMonth': 'மாதம் வாரியாக சிறந்த மீன்பிடி',
      'availableJobs': 'கிடைக்கும் வேலைகள்', 'pickUpShipments': 'ஏற்றுமதிகளை எடுக்கவும்',
      'trackActiveJobs': 'செயலில் உள்ள வேலைகளை கண்காணிக்கவும்',
      'myCart': 'என் கார்ட்', 'viewYourCart': 'உங்கள் கார்ட்டைப் பார்க்கவும்',
      'marketplace': 'சந்தை இடம்',
      'search': 'பட்டியல்கள், பொருட்கள், இடம் தேடு...',
      'noListings': 'பட்டியல்கள் இல்லை', 'postAListing': 'பட்டியல் இடுக',
      'requestSent': 'கோரிக்கை அனுப்பப்பட்டது!',
      'contactSeller': 'விற்பனையாளரை தொடர்பு கொள்', 'available': 'கிடைக்கும்',
      'addToCart': 'கார்ட்டில் சேர்', 'viewCart': 'கார்ட் பார்க்க',
      'placeOrder': 'ஆர்டர் செய்', 'orderPlaced': 'ஆர்டர் வந்தது!',
      'signOut': 'வெளியேறு', 'appTheme': 'ஆப் தீம்',
      'editProfile': 'சுயவிவரம் திருத்து', 'notifications': 'அறிவிப்புகள்',
      'privacy': 'தனியுரிமை & பாதுகாப்பு', 'help': 'உதவி',
      'terms': 'விதிமுறைகள்', 'about': 'MTC பற்றி',
      'language': 'மொழி', 'selectLanguage': 'மொழி தேர்வு',
      'saveChanges': 'மாற்றங்களை சேமி', 'messages': 'செய்திகள்',
      'personalisation': 'தனிப்பயனாக்கம்', 'preferences': 'விருப்பங்கள்',
      'support': 'ஆதரவு',
      'chooseColourScheme': 'உங்கள் நிற திட்டத்தை தேர்வு செய்யவும்',
      'updateYourDetails': 'உங்கள் விவரங்களைப் புதுப்பிக்கவும்',
      'manageAlerts': 'எச்சரிக்கைகளை நிர்வகிக்கவும்',
      'controlYourData': 'உங்கள் தரவைக் கட்டுப்படுத்தவும்',
      'faqsAndLiveChat': 'அடிக்கடி கேட்கப்படும் கேள்விகள் & நேரடி அரட்டை',
      'legalInformation': 'சட்டத் தகவல்',
      'versionAndCompanyInfo': 'பதிப்பு & நிறுவனத் தகவல்',
      'userFallback': 'பயனர்',
      'signOutConfirmTitle': 'வெளியேறவா?',
      'signOutConfirmBody': 'நீங்கள் உள்நுழைவு திரைக்குத் திரும்புவீர்கள்.',
      'roleSeller': 'விற்பனையாளர்', 'roleAgent': 'முகவர்', 'roleBuyer': 'வாங்குபவர்',
      'greetSellerEarly': 'சீக்கிரம் தொடங்குங்கள் — சிறந்த மீன்பிடி முதலில் கிடைக்கும் 🐟',
      'greetSellerWeekend': 'வார இறுதி சந்தைகள் பரபரப்பாக உள்ளன. உங்கள் பட்டியல்களை இடுங்கள்!',
      'greetSellerDefault': 'இன்று விற்பனை செய்ய தயாரா?',
      'greetAgentDefault': 'இன்று எடுக்க வேண்டிய டெலிவரி உள்ளதா? 🚢',
      'greetBuyerEarly': 'காலை மீன் புதியது — உலாவ சிறந்த நேரம்! 🌊',
      'greetBuyerWeekend': 'இனிய வார இறுதி! சந்தையில் என்ன புதியது என்று பாருங்கள்.',
      'greetBuyerDefault': 'இன்று நீங்கள் எதைத் தேடுகிறீர்கள்?',
      'marineNews': 'கடல்சார் செய்திகள்',
      'aiGeneratedDisclaimer':
      'AI உருவாக்கிய ஆலோசனைகள் — அதிகாரப்பூர்வ எச்சரிக்கைகளுக்கு INCOIS உடன் சரிபார்க்கவும்',
      'orderFallback': 'ஆர்டர்', 'buyerPrefix': 'வாங்குபவர்',
      'sellerPrefix': 'விற்பனையாளர்', 'unknownUser': 'தெரியாதது',

      'category': 'வகை', 'description': 'விளக்கம்', 'details': 'விவரங்கள்',
      'quantity': 'அளவு', 'currency': 'நாணயம்', 'posted': 'வெளியிடப்பட்டது',
      'seller': 'விற்பனையாளர்', 'locationNotSpecified': 'இடம் குறிப்பிடப்படவில்லை',
      'yourListing': 'உங்கள் பட்டியல்', 'sold': 'விற்றுவிட்டது',
      'editListing': 'பட்டியலை திருத்து', 'markAsSold': 'விற்றதாக குறி',
      'markAvailableAgain': 'மீண்டும் கிடைக்கும் எனக் குறி',
      'itemSoldNotice': 'இந்த பொருள் விற்கப்பட்டது, இனி கிடைக்காது.',
      'itemSold': 'பொருள் விற்றது',
      'addedToCartSuffix': 'கார்ட்டில் சேர்க்கப்பட்டது!',
      'deleteListingTitle': 'பட்டியலை நீக்கவா?',
      'deleteListingBody': 'இதை மீட்க முடியாது.',
      'cancel': 'ரத்து செய்', 'delete': 'நீக்கு',
      'markSoldConfirmTitle': 'விற்றதாக குறிக்கவா?',
      'markSoldConfirmBody':
      'வாங்குபவர்கள் இதை விற்றதாக காண்பர். எப்போது வேண்டுமானாலும் மீண்டும் கிடைக்கும் எனக் குறிக்கலாம்.',
      'listingMarkedSold': 'பட்டியல் விற்றதாக குறிக்கப்பட்டது',
      'listingMarkedAvailable': 'பட்டியல் மீண்டும் கிடைக்கிறது',
      'daysAgo': '{n} நாட்களுக்கு முன்', 'hoursAgo': '{n} மணி நேரத்திற்கு முன்',
      'minsAgo': '{n} நிமிடங்களுக்கு முன்',
      'voiceCategory': 'வகை', 'voicePrice': 'விலை',
      'voiceQuantityAvailable': 'கிடைக்கும்',
      'voiceSeller': 'விற்பனையாளர்', 'voiceLocation': 'இடம்',
      'welcomeMessage': 'மெரைன் டிரேட் கனெக்ட்-க்கு உங்களை வரவேற்கிறோம்.',

      'thisMonthBadge': 'இந்த மாதம்',
      'noFishThisMonth': 'இந்த மாதம் மீன் கிடைக்கவில்லை',
      'peakSeasonLabel': 'இந்த மாதங்களில் கிடைக்கும்',
    },
    // ────────────────────────────────────────────────────────────────── ARABIC
    'ar': {
      'home': 'الرئيسية', 'market': 'السوق', 'chat': 'دردشة',
      'tracking': 'التتبع', 'profile': 'الملف الشخصي',
      'goodMorning': 'صباح الخير ☀️', 'goodAfternoon': 'مساء الخير 🌤️',
      'goodEvening': 'مساء النور 🌙',
      'quickActions': 'إجراءات سريعة', 'recentActivity': 'النشاط الأخير',
      'noActivity': 'لا يوجد نشاط', 'viewAll': 'عرض الكل',
      'browseMarket': 'تصفح السوق', 'myListings': 'إعلاناتي',
      'listings': 'الإعلانات', 'deals': 'الصفقات',
      'shipments': 'الشحنات', 'chats': 'المحادثات', 'inTransit': 'في الطريق',
      'orders': 'الطلبات', 'openJobs': 'وظائف مفتوحة', 'myDeliveries': 'توصيلاتي',
      'myOrders': 'طلباتي', 'trackOrders': 'تتبع الطلبات',
      'trackPurchases': 'تتبع المشتريات', 'postListing': 'نشر إعلان',
      'sellYourGoods': 'بع بضاعتك', 'secondHand': 'مستعمل',
      'buyUsedItems': 'شراء مستعمل', 'listUsedItems': 'بيع مستعمل',
      'liveShipments': 'الشحنات المباشرة', 'chatWithTraders': 'تحدث مع التجار',
      'browseListings': 'تصفح الإعلانات',
      'fishCalendar': 'تقويم الأسماك', 'bestCatchesByMonth': 'أفضل الصيد حسب الشهر',
      'availableJobs': 'الوظائف المتاحة', 'pickUpShipments': 'استلام الشحنات',
      'trackActiveJobs': 'تتبع المهام النشطة',
      'myCart': 'سلتي', 'viewYourCart': 'عرض سلتك',
      'marketplace': 'السوق',
      'search': 'ابحث عن منتجات، مواقع...',
      'noListings': 'لا توجد إعلانات', 'postAListing': 'نشر إعلان',
      'requestSent': 'تم إرسال الطلب! سيتم إخطار البائعين.',
      'contactSeller': 'تواصل مع البائع', 'available': 'متاح',
      'addToCart': 'أضف للسلة', 'viewCart': 'عرض السلة',
      'placeOrder': 'تأكيد الطلب', 'orderPlaced': 'تم الطلب!',
      'signOut': 'تسجيل الخروج', 'appTheme': 'مظهر التطبيق',
      'editProfile': 'تعديل الملف', 'notifications': 'الإشعارات',
      'privacy': 'الخصوصية والأمان', 'help': 'المساعدة',
      'terms': 'الشروط والأحكام', 'about': 'عن MTC',
      'language': 'اللغة', 'selectLanguage': 'اختر اللغة',
      'saveChanges': 'حفظ التغييرات', 'messages': 'الرسائل',
      'personalisation': 'التخصيص', 'preferences': 'التفضيلات',
      'support': 'الدعم',
      'chooseColourScheme': 'اختر نظام الألوان الخاص بك',
      'updateYourDetails': 'تحديث بياناتك',
      'manageAlerts': 'إدارة التنبيهات', 'controlYourData': 'التحكم في بياناتك',
      'faqsAndLiveChat': 'الأسئلة الشائعة والدردشة المباشرة',
      'legalInformation': 'معلومات قانونية',
      'versionAndCompanyInfo': 'معلومات الإصدار والشركة',
      'userFallback': 'مستخدم',
      'signOutConfirmTitle': 'تسجيل الخروج؟',
      'signOutConfirmBody': 'سيتم إعادتك إلى شاشة تسجيل الدخول.',
      'roleSeller': 'بائع', 'roleAgent': 'وكيل', 'roleBuyer': 'مشترٍ',
      'greetSellerEarly': 'بداية مبكرة — أفضل الصيد يذهب أولاً 🐟',
      'greetSellerWeekend': 'أسواق نهاية الأسبوع مزدحمة. انشر إعلاناتك!',
      'greetSellerDefault': 'هل أنت مستعد لتحقيق بعض المبيعات اليوم؟',
      'greetAgentDefault': 'هل لديك توصيلات لاستلامها اليوم؟ 🚢',
      'greetBuyerEarly': 'صيد الصباح هو الأطزج — وقت رائع للتصفح! 🌊',
      'greetBuyerWeekend': 'عطلة نهاية أسبوع سعيدة! تصفح ما هو طازج في السوق.',
      'greetBuyerDefault': 'ماذا تبحث عنه اليوم؟',
      'marineNews': 'أخبار بحرية',
      'aiGeneratedDisclaimer':
      'إرشادات مولدة بالذكاء الاصطناعي — تحقق من INCOIS للحصول على التنبيهات الرسمية',
      'orderFallback': 'طلب', 'buyerPrefix': 'المشتري',
      'sellerPrefix': 'البائع', 'unknownUser': 'غير معروف',

      'category': 'الفئة', 'description': 'الوصف', 'details': 'التفاصيل',
      'quantity': 'الكمية', 'currency': 'العملة', 'posted': 'تاريخ النشر',
      'seller': 'البائع', 'locationNotSpecified': 'الموقع غير محدد',
      'yourListing': 'إعلانك', 'sold': 'تم البيع',
      'editListing': 'تعديل الإعلان', 'markAsSold': 'وضع علامة كمباع',
      'markAvailableAgain': 'وضع علامة كمتاح مرة أخرى',
      'itemSoldNotice': 'تم بيع هذا العنصر ولم يعد متاحًا.',
      'itemSold': 'تم بيع العنصر',
      'addedToCartSuffix': 'أضيف إلى السلة!',
      'deleteListingTitle': 'حذف الإعلان؟',
      'deleteListingBody': 'لا يمكن التراجع عن هذا.',
      'cancel': 'إلغاء', 'delete': 'حذف',
      'markSoldConfirmTitle': 'وضع علامة كمباع؟',
      'markSoldConfirmBody':
      'سيرى المشترون هذا العنصر كمباع. يمكنك وضع علامة متاح مرة أخرى في أي وقت.',
      'listingMarkedSold': 'تم وضع علامة على الإعلان كمباع',
      'listingMarkedAvailable': 'الإعلان متاح الآن مرة أخرى',
      'daysAgo': 'قبل {n} يوم', 'hoursAgo': 'قبل {n} ساعة',
      'minsAgo': 'قبل {n} دقيقة',
      'voiceCategory': 'الفئة', 'voicePrice': 'السعر',
      'voiceQuantityAvailable': 'متاح',
      'voiceSeller': 'البائع', 'voiceLocation': 'الموقع',
      'welcomeMessage': 'مرحبًا بك في Marine Trade Connect.',

      'thisMonthBadge': 'هذا الشهر',
      'noFishThisMonth': 'لا توجد أسماك في الموسم هذا الشهر',
      'peakSeasonLabel': 'متوفر خلال',
    },
    // ────────────────────────────────────────────────────────────────── TELUGU
    'te': {
      'home': 'హోమ్', 'market': 'మార్కెట్', 'chat': 'చాట్',
      'tracking': 'ట్రాకింగ్', 'profile': 'ప్రొఫైల్',
      'goodMorning': 'శుభోదయం ☀️', 'goodAfternoon': 'నమస్కారం 🌤️',
      'goodEvening': 'శుభ సాయంత్రం 🌙',
      'quickActions': 'శీఘ్ర చర్యలు', 'recentActivity': 'ఇటీవలి కార్యకలాపాలు',
      'noActivity': 'కార్యకలాపాలు లేవు', 'viewAll': 'అన్నీ చూడు',
      'browseMarket': 'మార్కెట్ చూడు', 'myListings': 'నా లిస్టింగ్‌లు',
      'listings': 'లిస్టింగ్‌లు', 'deals': 'డీల్స్',
      'shipments': 'షిప్మెంట్లు', 'chats': 'చాట్లు', 'inTransit': 'రవాణాలో',
      'orders': 'ఆర్డర్లు', 'openJobs': 'ఓపెన్ జాబ్‌లు', 'myDeliveries': 'నా డెలివరీలు',
      'myOrders': 'నా ఆర్డర్లు', 'trackOrders': 'ఆర్డర్లు ట్రాక్ చేయి',
      'trackPurchases': 'కొనుగోళ్లు ట్రాక్ చేయి', 'postListing': 'లిస్టింగ్ పోస్ట్ చేయి',
      'sellYourGoods': 'మీ వస్తువులు అమ్మండి', 'secondHand': 'సెకండ్ హ్యాండ్',
      'buyUsedItems': 'వాడిన వస్తువులు కొనండి', 'listUsedItems': 'వాడిన వస్తువులు అమ్మండి',
      'liveShipments': 'లైవ్ షిప్మెంట్లు', 'chatWithTraders': 'వ్యాపారులతో చాట్ చేయి',
      'browseListings': 'లిస్టింగ్‌లు చూడు',
      'fishCalendar': 'చేప క్యాలెండర్', 'bestCatchesByMonth': 'నెల వారీగా ఉత్తమ పట్టు',
      'availableJobs': 'అందుబాటులో ఉన్న పనులు', 'pickUpShipments': 'షిప్మెంట్లు తీసుకోండి',
      'trackActiveJobs': 'యాక్టివ్ పనులు ట్రాక్ చేయండి',
      'myCart': 'నా కార్ట్', 'viewYourCart': 'మీ కార్ట్ చూడండి',
      'marketplace': 'మార్కెట్‌ప్లేస్',
      'search': 'లిస్టింగ్‌లు, ఉత్పత్తులు, స్థానం వెతకండి...',
      'noListings': 'లిస్టింగ్‌లు కనుగొనబడలేదు', 'postAListing': 'లిస్టింగ్ పోస్ట్ చేయి',
      'requestSent': 'అభ్యర్థన పంపబడింది! విక్రేతలకు తెలియజేయబడుతుంది.',
      'contactSeller': 'విక్రేతను సంప్రదించు', 'available': 'అందుబాటులో ఉంది',
      'addToCart': 'కార్ట్‌కు జోడించు', 'viewCart': 'కార్ట్ చూడు',
      'placeOrder': 'ఆర్డర్ ఇవ్వు', 'orderPlaced': 'ఆర్డర్ అయింది!',
      'signOut': 'సైన్ అవుట్', 'appTheme': 'యాప్ థీమ్',
      'editProfile': 'ప్రొఫైల్ సవరించు', 'notifications': 'నోటిఫికేషన్లు',
      'privacy': 'గోప్యత & భద్రత', 'help': 'సహాయం',
      'terms': 'నిబంధనలు', 'about': 'MTC గురించి',
      'language': 'భాష', 'selectLanguage': 'భాష ఎంచుకోండి',
      'saveChanges': 'మార్పులు సేవ్ చేయి', 'messages': 'సందేశాలు',
      'personalisation': 'వ్యక్తిగతీకరణ', 'preferences': 'ప్రాధాన్యతలు',
      'support': 'మద్దతు',
      'chooseColourScheme': 'మీ రంగు పథకాన్ని ఎంచుకోండి',
      'updateYourDetails': 'మీ వివరాలను నవీకరించండి',
      'manageAlerts': 'అలర్ట్‌లను నిర్వహించండి',
      'controlYourData': 'మీ డేటాను నియంత్రించండి',
      'faqsAndLiveChat': 'తరచుగా అడిగే ప్రశ్నలు & లైవ్ చాట్',
      'legalInformation': 'చట్టపరమైన సమాచారం',
      'versionAndCompanyInfo': 'వెర్షన్ & కంపెనీ సమాచారం',
      'userFallback': 'వినియోగదారు',
      'signOutConfirmTitle': 'సైన్ అవుట్ చేయాలా?',
      'signOutConfirmBody': 'మిమ్మల్ని లాగిన్ స్క్రీన్‌కు తిరిగి పంపబడుతుంది.',
      'roleSeller': 'విక్రేత', 'roleAgent': 'ఏజెంట్', 'roleBuyer': 'కొనుగోలుదారు',
      'greetSellerEarly': 'త్వరగా మొదలుపెట్టండి — మంచి పట్టు మొదట వస్తుంది 🐟',
      'greetSellerWeekend': 'వారాంతపు మార్కెట్లు బిజీగా ఉంటాయి. మీ లిస్టింగ్‌లు పోస్ట్ చేయండి!',
      'greetSellerDefault': 'ఈరోజు అమ్మకాలు చేయడానికి సిద్ధమేనా?',
      'greetAgentDefault': 'ఈరోజు తీసుకోవాల్సిన డెలివరీలు ఉన్నాయా? 🚢',
      'greetBuyerEarly': 'ఉదయం పట్టు తాజాగా ఉంటుంది — చూసేందుకు మంచి సమయం! 🌊',
      'greetBuyerWeekend': 'సంతోషకరమైన వారాంతం! మార్కెట్‌లో ఏమి తాజాగా ఉందో చూడండి.',
      'greetBuyerDefault': 'ఈరోజు మీరు ఏమి వెతుకుతున్నారు?',
      'marineNews': 'సముద్ర వార్తలు',
      'aiGeneratedDisclaimer':
      'AI రూపొందించిన సలహాలు — అధికారిక హెచ్చరికల కోసం INCOISతో ధృవీకరించండి',
      'orderFallback': 'ఆర్డర్', 'buyerPrefix': 'కొనుగోలుదారు',
      'sellerPrefix': 'విక్రేత', 'unknownUser': 'తెలియదు',

      'category': 'వర్గం', 'description': 'వివరణ', 'details': 'వివరాలు',
      'quantity': 'పరిమాణం', 'currency': 'కరెన్సీ', 'posted': 'పోస్ట్ చేయబడింది',
      'seller': 'విక్రేత', 'locationNotSpecified': 'స్థానం పేర్కొనలేదు',
      'yourListing': 'మీ లిస్టింగ్', 'sold': 'అమ్మబడింది',
      'editListing': 'లిస్టింగ్ సవరించు', 'markAsSold': 'అమ్మినట్లు గుర్తించు',
      'markAvailableAgain': 'మళ్లీ అందుబాటులో ఉంచు',
      'itemSoldNotice': 'ఈ వస్తువు అమ్ముడైంది మరియు ఇక అందుబాటులో లేదు.',
      'itemSold': 'వస్తువు అమ్ముడైంది',
      'addedToCartSuffix': 'కార్ట్‌కు జోడించబడింది!',
      'deleteListingTitle': 'లిస్టింగ్ తొలగించాలా?',
      'deleteListingBody': 'దీన్ని రద్దు చేయలేరు.',
      'cancel': 'రద్దు చేయి', 'delete': 'తొలగించు',
      'markSoldConfirmTitle': 'అమ్మినట్లు గుర్తించాలా?',
      'markSoldConfirmBody':
      'కొనుగోలుదారులు దీన్ని అమ్ముడైనట్లు చూస్తారు. మీరు దీన్ని ఎప్పుడైనా మళ్లీ అందుబాటులో ఉంచవచ్చు.',
      'listingMarkedSold': 'లిస్టింగ్ అమ్ముడైనట్లు గుర్తించబడింది',
      'listingMarkedAvailable': 'లిస్టింగ్ ఇప్పుడు మళ్లీ అందుబాటులో ఉంది',
      'daysAgo': '{n} రోజుల క్రితం', 'hoursAgo': '{n} గంటల క్రితం',
      'minsAgo': '{n} నిమిషాల క్రితం',
      'voiceCategory': 'వర్గం', 'voicePrice': 'ధర',
      'voiceQuantityAvailable': 'అందుబాటులో ఉంది',
      'voiceSeller': 'విక్రేత', 'voiceLocation': 'స్థానం',
      'welcomeMessage': 'మెరైన్ ట్రేడ్ కనెక్ట్‌కు స్వాగతం.',

      'thisMonthBadge': 'ఈ నెల',
      'noFishThisMonth': 'ఈ నెలలో సీజన్‌లో చేపలు లేవు',
      'peakSeasonLabel': 'ఈ నెలల్లో లభిస్తుంది',
    },
    // ────────────────────────────────────────────────────────────────── FRENCH
    'fr': {
      'home': 'Accueil', 'market': 'Marché', 'chat': 'Chat',
      'tracking': 'Suivi', 'profile': 'Profil',
      'goodMorning': 'Bonjour ☀️', 'goodAfternoon': 'Bon après-midi 🌤️',
      'goodEvening': 'Bonsoir 🌙',
      'quickActions': 'Actions rapides', 'recentActivity': 'Activité récente',
      'noActivity': 'Aucune activité', 'viewAll': 'Voir tout',
      'browseMarket': 'Voir le marché', 'myListings': 'Mes annonces',
      'listings': 'Annonces', 'deals': 'Affaires',
      'shipments': 'Expéditions', 'chats': 'Discussions', 'inTransit': 'En transit',
      'orders': 'Commandes', 'openJobs': 'Missions ouvertes', 'myDeliveries': 'Mes livraisons',
      'myOrders': 'Mes commandes', 'trackOrders': 'Suivre les commandes',
      'trackPurchases': 'Suivre les achats', 'postListing': 'Publier une annonce',
      'sellYourGoods': 'Vendez vos produits', 'secondHand': 'Occasion',
      'buyUsedItems': "Acheter d'occasion", 'listUsedItems': "Vendre d'occasion",
      'liveShipments': 'Expéditions en direct', 'chatWithTraders': 'Discuter avec les traders',
      'browseListings': 'Parcourir les annonces',
      'fishCalendar': 'Calendrier des poissons',
      'bestCatchesByMonth': 'Meilleures prises par mois',
      'availableJobs': 'Missions disponibles',
      'pickUpShipments': 'Récupérer les expéditions',
      'trackActiveJobs': 'Suivre les missions actives',
      'myCart': 'Mon panier', 'viewYourCart': 'Voir votre panier',
      'marketplace': 'Marché',
      'search': 'Rechercher des annonces, produits, lieux...',
      'noListings': 'Aucune annonce trouvée', 'postAListing': 'Publier une annonce',
      'requestSent': 'Demande envoyée ! Les vendeurs seront notifiés.',
      'contactSeller': 'Contacter le vendeur', 'available': 'Disponible',
      'addToCart': 'Ajouter au panier', 'viewCart': 'Voir le panier',
      'placeOrder': 'Passer la commande', 'orderPlaced': 'Commande passée!',
      'signOut': 'Se déconnecter', 'appTheme': 'Thème',
      'editProfile': 'Modifier le profil', 'notifications': 'Notifications',
      'privacy': 'Confidentialité', 'help': 'Aide et support',
      'terms': 'Conditions générales', 'about': 'À propos de MTC',
      'language': 'Langue', 'selectLanguage': 'Choisir la langue',
      'saveChanges': 'Enregistrer', 'messages': 'Messages',
      'personalisation': 'PERSONNALISATION', 'preferences': 'PRÉFÉRENCES',
      'support': 'ASSISTANCE',
      'chooseColourScheme': 'Choisissez votre palette de couleurs',
      'updateYourDetails': 'Mettez à jour vos informations',
      'manageAlerts': 'Gérer les alertes',
      'controlYourData': 'Contrôlez vos données',
      'faqsAndLiveChat': 'FAQ et chat en direct',
      'legalInformation': 'Informations légales',
      'versionAndCompanyInfo': "Version et informations sur l'entreprise",
      'userFallback': 'Utilisateur',
      'signOutConfirmTitle': 'Se déconnecter ?',
      'signOutConfirmBody': "Vous serez redirigé vers l'écran de connexion.",
      'roleSeller': 'VENDEUR', 'roleAgent': 'AGENT', 'roleBuyer': 'ACHETEUR',
      'greetSellerEarly': 'Départ matinal — les meilleures prises partent en premier 🐟',
      'greetSellerWeekend': 'Les marchés du week-end sont animés. Publiez vos annonces!',
      'greetSellerDefault': "Prêt à faire des ventes aujourd'hui?",
      'greetAgentDefault': 'Des livraisons à récupérer aujourd\'hui? 🚢',
      'greetBuyerEarly': 'La pêche du matin est la plus fraîche — bon moment pour parcourir! 🌊',
      'greetBuyerWeekend': 'Bon week-end! Découvrez les produits frais du marché.',
      'greetBuyerDefault': "Que recherchez-vous aujourd'hui?",
      'marineNews': 'Actualités maritimes',
      'aiGeneratedDisclaimer':
      "Avis générés par IA — vérifiez auprès d'INCOIS pour les alertes officielles",
      'orderFallback': 'Commande', 'buyerPrefix': 'Acheteur',
      'sellerPrefix': 'Vendeur', 'unknownUser': 'Inconnu',

      'category': 'Catégorie', 'description': 'Description', 'details': 'Détails',
      'quantity': 'Quantité', 'currency': 'Devise', 'posted': 'Publié',
      'seller': 'Vendeur', 'locationNotSpecified': 'Lieu non précisé',
      'yourListing': 'VOTRE ANNONCE', 'sold': 'Vendu',
      'editListing': "Modifier l'annonce", 'markAsSold': 'Marquer comme vendu',
      'markAvailableAgain': 'Marquer comme disponible à nouveau',
      'itemSoldNotice': "Cet article a été vendu et n'est plus disponible.",
      'itemSold': 'Article vendu',
      'addedToCartSuffix': 'ajouté au panier !',
      'deleteListingTitle': "Supprimer l'annonce ?",
      'deleteListingBody': 'Cette action est irréversible.',
      'cancel': 'Annuler', 'delete': 'Supprimer',
      'markSoldConfirmTitle': 'Marquer comme vendu ?',
      'markSoldConfirmBody':
      "Les acheteurs verront cet article comme vendu. Vous pouvez le rendre à nouveau disponible à tout moment.",
      'listingMarkedSold': 'Annonce marquée comme vendue',
      'listingMarkedAvailable': "L'annonce est de nouveau disponible",
      'daysAgo': 'il y a {n} j', 'hoursAgo': 'il y a {n} h',
      'minsAgo': 'il y a {n} min',
      'voiceCategory': 'Catégorie', 'voicePrice': 'Prix',
      'voiceQuantityAvailable': 'disponible',
      'voiceSeller': 'Vendeur', 'voiceLocation': 'Lieu',
      'welcomeMessage': 'Bienvenue sur Marine Trade Connect.',

      'thisMonthBadge': 'Ce mois-ci',
      'noFishThisMonth': 'Aucun poisson de saison ce mois-ci',
      'peakSeasonLabel': 'Disponible durant',
    },
  };

  String get(String key) {
    final code = locale.languageCode;
    return _strings[code]?[key] ?? _strings['en']![key] ?? key;
  }

  /// Same as get(), but replaces `{n}` in the template with [n].
  /// Used for "3d ago" / "{n} दिन पहले" style strings.
  String getWithCount(String key, num n) =>
      get(key).replaceAll('{n}', n.toString());

  // ── Nav ──────────────────────────────────────────────────────────────────
  String get home           => get('home');
  String get market         => get('market');
  String get chat           => get('chat');
  String get tracking       => get('tracking');
  String get profile        => get('profile');

  // ── Greetings ────────────────────────────────────────────────────────────
  String get goodMorning    => get('goodMorning');
  String get goodAfternoon  => get('goodAfternoon');
  String get goodEvening    => get('goodEvening');

  // ── Dashboard ────────────────────────────────────────────────────────────
  String get quickActions   => get('quickActions');
  String get recentActivity => get('recentActivity');
  String get noActivity     => get('noActivity');
  String get viewAll        => get('viewAll');
  String get browseMarket   => get('browseMarket');
  String get myListings     => get('myListings');

  // ── Stat card labels ──────────────────────────────────────────────────────
  String get listings       => get('listings');
  String get deals          => get('deals');
  String get shipments      => get('shipments');
  String get chats          => get('chats');
  String get inTransit      => get('inTransit');
  String get orders         => get('orders');
  String get openJobs       => get('openJobs');
  String get myDeliveries   => get('myDeliveries');

  // ── Quick actions ─────────────────────────────────────────────────────────
  String get myOrders       => get('myOrders');
  String get trackOrders    => get('trackOrders');
  String get trackPurchases => get('trackPurchases');
  String get postListing    => get('postListing');
  String get sellYourGoods  => get('sellYourGoods');
  String get secondHand     => get('secondHand');
  String get buyUsedItems   => get('buyUsedItems');
  String get listUsedItems  => get('listUsedItems');
  String get liveShipments  => get('liveShipments');
  String get chatWithTraders=> get('chatWithTraders');
  String get browseListings => get('browseListings');
  String get fishCalendar        => get('fishCalendar');
  String get bestCatchesByMonth  => get('bestCatchesByMonth');
  String get availableJobs       => get('availableJobs');
  String get pickUpShipments     => get('pickUpShipments');
  String get trackActiveJobs     => get('trackActiveJobs');
  String get myCart              => get('myCart');
  String get viewYourCart        => get('viewYourCart');

  // ── Marketplace ───────────────────────────────────────────────────────────
  String get marketplace    => get('marketplace');
  String get search         => get('search');
  String get noListings     => get('noListings');
  String get postAListing   => get('postAListing');
  String get requestSent    => get('requestSent');
  String get contactSeller  => get('contactSeller');
  String get available      => get('available');
  String get addToCart      => get('addToCart');
  String get viewCart       => get('viewCart');
  String get placeOrder     => get('placeOrder');
  String get orderPlaced    => get('orderPlaced');

  // ── Profile ───────────────────────────────────────────────────────────────
  String get signOut        => get('signOut');
  String get appTheme       => get('appTheme');
  String get editProfile    => get('editProfile');
  String get notifications  => get('notifications');
  String get privacy        => get('privacy');
  String get help           => get('help');
  String get terms          => get('terms');
  String get about          => get('about');
  String get language       => get('language');
  String get selectLanguage => get('selectLanguage');
  String get saveChanges    => get('saveChanges');
  String get personalisation      => get('personalisation');
  String get preferences          => get('preferences');
  String get support              => get('support');
  String get chooseColourScheme   => get('chooseColourScheme');
  String get updateYourDetails    => get('updateYourDetails');
  String get manageAlerts         => get('manageAlerts');
  String get controlYourData      => get('controlYourData');
  String get faqsAndLiveChat      => get('faqsAndLiveChat');
  String get legalInformation     => get('legalInformation');
  String get versionAndCompanyInfo=> get('versionAndCompanyInfo');
  String get userFallback         => get('userFallback');
  String get signOutConfirmTitle  => get('signOutConfirmTitle');
  String get signOutConfirmBody   => get('signOutConfirmBody');

  // ── Roles ────────────────────────────────────────────────────────────────
  String get roleSeller => get('roleSeller');
  String get roleAgent  => get('roleAgent');
  String get roleBuyer  => get('roleBuyer');

  // ── Home greeting subtitles ─────────────────────────────────────────────
  String get greetSellerEarly    => get('greetSellerEarly');
  String get greetSellerWeekend  => get('greetSellerWeekend');
  String get greetSellerDefault  => get('greetSellerDefault');
  String get greetAgentDefault   => get('greetAgentDefault');
  String get greetBuyerEarly     => get('greetBuyerEarly');
  String get greetBuyerWeekend   => get('greetBuyerWeekend');
  String get greetBuyerDefault   => get('greetBuyerDefault');

  // ── Marine news ──────────────────────────────────────────────────────────
  String get marineNews            => get('marineNews');
  String get aiGeneratedDisclaimer => get('aiGeneratedDisclaimer');

  // ── Recent activity ──────────────────────────────────────────────────────
  String get orderFallback => get('orderFallback');
  String get buyerPrefix   => get('buyerPrefix');
  String get sellerPrefix  => get('sellerPrefix');
  String get unknownUser   => get('unknownUser');

  // ── Misc ─────────────────────────────────────────────────────────────────
  String get messages       => get('messages');

  // ── Listing detail screen ───────────────────────────────────────────────
  String get category             => get('category');
  String get description          => get('description');
  String get details              => get('details');
  String get quantity             => get('quantity');
  String get currency             => get('currency');
  String get posted               => get('posted');
  String get seller                => get('seller');
  String get locationNotSpecified => get('locationNotSpecified');
  String get yourListing          => get('yourListing');
  String get sold                 => get('sold');
  String get editListing          => get('editListing');
  String get markAsSold           => get('markAsSold');
  String get markAvailableAgain   => get('markAvailableAgain');
  String get itemSoldNotice       => get('itemSoldNotice');
  String get itemSold             => get('itemSold');
  String get addedToCartSuffix    => get('addedToCartSuffix');
  String get deleteListingTitle   => get('deleteListingTitle');
  String get deleteListingBody    => get('deleteListingBody');
  String get cancel               => get('cancel');
  String get delete               => get('delete');
  String get markSoldConfirmTitle => get('markSoldConfirmTitle');
  String get markSoldConfirmBody  => get('markSoldConfirmBody');
  String get listingMarkedSold      => get('listingMarkedSold');
  String get listingMarkedAvailable => get('listingMarkedAvailable');

  String daysAgo(int n)  => getWithCount('daysAgo', n);
  String hoursAgo(int n) => getWithCount('hoursAgo', n);
  String minsAgo(int n)  => getWithCount('minsAgo', n);

  // Voice-only labels
  String get voiceCategory           => get('voiceCategory');
  String get voicePrice              => get('voicePrice');
  String get voiceQuantityAvailable  => get('voiceQuantityAvailable');
  String get voiceSeller             => get('voiceSeller');
  String get voiceLocation           => get('voiceLocation');
  String get welcomeMessage          => get('welcomeMessage');

  // ── Fish seasonal calendar ──────────────────────────────────────────────
  String get thisMonthBadge  => get('thisMonthBadge');
  String get noFishThisMonth => get('noFishThisMonth');
  String get peakSeasonLabel => get('peakSeasonLabel');
  String get fishRohu     => get('fishRohu');
  String get fishCatla    => get('fishCatla');
  String get fishHilsa    => get('fishHilsa');
  String get fishPomfret  => get('fishPomfret');
  String get fishMackerel => get('fishMackerel');
  String get fishSardine  => get('fishSardine');
  String get fishTuna     => get('fishTuna');
  String get fishPrawn    => get('fishPrawn');
  String get fishLobster  => get('fishLobster');
  String get fishCrab     => get('fishCrab');
  String get fishSurmai   => get('fishSurmai');
  String get fishSquid    => get('fishSquid');
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'hi', 'ta', 'te', 'ar', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_) => false;
}