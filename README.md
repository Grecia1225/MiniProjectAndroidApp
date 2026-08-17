# 🌊 Marine Trade Connect (MTC)

**Connecting fishermen, traders, and logistics agents — in their own language, their own voice.**

Marine Trade Connect is a Flutter-based marketplace app built for India's marine and seafood trade — designed from the ground up with **low-literacy accessibility** in mind, so a fisherman who can't read English (or read at all) can still post a listing, place an order, and track a shipment using icons and voice guidance.

---

## 📱 Features

### For Sellers
- Post listings with an **icon-first category picker** (🐟 🦐 🦀 ⚓) — no reading required
- Up to 3 photos per listing, uploaded via Cloudinary
- Confirm orders, track shipments, manage active listings
- Every listing readable aloud via text-to-speech, in the seller's own language

### For Buyers
- Browse & filter the Marketplace by category with visual chips
- Search listings by product name or location
- Add to cart, adjust quantities, place orders
- Second-hand marketplace for used marine equipment
- Request a product — notifies all sellers instantly

### For Agents
- View open shipping jobs across the platform
- Accept jobs, manage active deliveries
- Mark shipments as delivered — notifies both buyer and seller

### Cross-cutting
- 🔊 **Full multilingual voice support** — English, Hindi, Tamil, Telugu, Arabic, French — for greetings, listings, and notifications, built from structured data (not machine-translated raw text)
- 🔔 **Real-time notifications** for cart adds, orders, confirmations, shipping updates, and chat messages
- 💬 **In-app chat** with photo and location sharing between buyers, sellers, and agents
- 🌐 Full localization across the entire UI
- 🎨 Multiple theme options

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Firebase (Auth, Firestore, Cloud Functions) |
| Image hosting | Cloudinary |
| State management | Provider |
| Voice | flutter_tts |
| Maps/Location | url_launcher (Google Maps links) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed
- A [Firebase](https://console.firebase.google.com) project
- A [Cloudinary](https://cloudinary.com) account (free tier works)

### Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/Grecia1225/MiniProjectAndroidApp.git
   cd MiniProjectAndroidApp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase setup**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Authentication** (Email/Password)
   - Enable **Cloud Firestore**
   - Download `google-services.json` and place it in `android/app/`
   - Deploy the included Firestore security rules (`firestore.rules`)

4. **Cloudinary setup**
   - Create an unsigned upload preset in your Cloudinary dashboard (**Settings → Upload → Upload presets**)
   - Update the cloud name and preset name in `lib/screens/marketplace/create_listing_screen.dart`

5. **Run the app**
   ```bash
   flutter run
   ```

### Building a release APK
```bash
flutter build apk --release
```
The installable APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📂 Project Structure

```
lib/
├── models/              # Data models (Listing, Chat, User)
├── screens/
│   ├── auth/            # Login, signup, role selection
│   ├── chat/            # Messaging
│   ├── home/            # Dashboard
│   ├── marketplace/     # Listings, cart, second-hand
│   ├── settings/        # Profile, notifications, language, theme
│   └── trackingg/       # Shipment tracking
├── utils/
│   ├── voice_provider/  # Multilingual text-to-speech engine
│   ├── category_icons.dart
│   ├── theme_provider.dart
│   └── language_provider.dart
└── widgets/              # Shared reusable UI components
```

---

## ♿ Accessibility-First Design

This app was built with a specific goal: **usable by people who can't read English, or can't read at all.**

- Categories are picked via **emoji icons**, not text dropdowns
- Every screen supports **voice readback** in the user's selected language
- Notifications are **spoken aloud**, reconstructed from structured data rather than reading raw stored English text
- Visual selection states (highlighted vs. dimmed) reduce reliance on reading labels

---

## 🌍 Supported Languages

🇬🇧 English · 🇮🇳 Hindi · 🇮🇳 Tamil · 🇮🇳 Telugu · 🇸🇦 Arabic · 🇫🇷 French

---

## 📄 License

This project was built as part of a mini-project submission. All rights reserved unless otherwise specified.

---

## 🙏 Acknowledgements

Built for coastal marine traders and fishing communities across India — designed so technology adapts to people, not the other way around.
