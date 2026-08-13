# 🌊 Marine Trade Connect

A cross-platform mobile app connecting marine product **sellers**, **buyers**, and **shipping agents** in one role-based ecosystem — built to bring India's marine export trade (shrimp, seafood — a multi-billion dollar export sector concentrated in Andhra Pradesh and Kerala) out of fragmented phone calls and WhatsApp groups and into a single, structured platform.

## The problem

Small and medium marine exporters currently rely on manual, disconnected tools: generic B2B listing sites with no real-time communication, tariff changes tracked by manually checking government bulletins, shipment tracking on a separate logistics portal entirely, and virtually no support for non-English speakers. When a buyer cancels an order or a tariff hits overnight, exporters often find out too late to react — and coastal communities with lower digital literacy are excluded from existing platforms almost entirely.

## What it does

Marine Trade Connect gives each side of the trade — **Seller**, **Buyer**, and **Shipper** — its own dedicated interface within one app:

- **Sellers** list products with real photos (not URLs), manage inventory, edit listings anytime, and check a seasonal fish calendar for planning around species availability
- **Buyers** browse a live marketplace, request products that aren't listed yet, get tariff-change alerts, and message sellers directly
- **Shippers** manage assigned shipments and push real-time delivery status updates that buyers and sellers both see instantly

All three roles share a **WhatsApp-style chat** (text, photos, live location), a dashboard with live marine-industry news headlines, and support for **5 languages** (English, Hindi, Tamil, Arabic, French) with a built-in voice assistant — aimed specifically at making the app usable for coastal and fishing communities who aren't comfortable with English-only, text-heavy apps.

## Key features

- Role-based onboarding and dashboards (Buyer / Seller / Shipper)
- Real-photo product listings with full edit support
- Product request system (buyers can request items not yet listed)
- Real-time WhatsApp-style chat with photo and live location sharing
- Shipment tracking with live status updates (Confirmed → Picked Up → In Transit → At Port → Delivered)
- Seasonal fish calendar showing species availability by month
- 5-language support with a voice assistant for hands-free navigation
- Offline mode — recently loaded listings and chats stay accessible without a connection
- 5 selectable app themes
- Live marine-industry news feed on the dashboard

> **In progress:** AI-driven price/demand forecasting is scoped and partially surfaced in the seller dashboard, but the underlying ML model is a planned future enhancement, not a trained model in the current build.

## Tech stack

**Frontend:** Flutter 3.x (Dart) — Android & iOS from one codebase
**Backend:** Firebase (Firestore for real-time data, Firebase Auth, Firebase Storage)
**State management:** Provider
**Voice:** speech_to_text + flutter_tts
**Location:** Geolocator
**Other:** cached_network_image, image_picker, http (news feed), flutter_localizations + intl (5-language support via ARB files)

## Architecture

Three-layer structure:
- **Presentation** — Flutter UI, organized by role and feature module
- **Business logic** — Provider-based state classes (`CartProvider`, `LanguageProvider`, `ThemeProvider`, `VoiceProvider`) plus Firebase service classes
- **Data** — Firebase Firestore (real-time NoSQL) + Firebase Authentication

## Testing

The app went through a full testing pass across four levels:

| Level | Coverage | Result |
|---|---|---|
| Unit testing | Cart logic, language/theme switching, voice trigger, data model serialization | 10/10 passed |
| Integration testing | Auth + Firestore, listings + storage, chat + real-time delivery, shipment tracking | 12/12 passed |
| User acceptance testing | Real task-based testing across all 3 roles (create listing, chat, track shipment, voice nav, etc.) | 10/10 passed |
| Performance testing | Load times and real-time delivery speed under 4G/3G | All within target thresholds |

Some real numbers from performance testing under 4G: marketplace listings loaded in **1.9s**, chat messages delivered in **under 1s**, photo messages in **2.4s**. Offline mode was confirmed to serve cached data without crashing when network dropped entirely.

## Team

Built as a 3-person college team project (Flutter/Firebase development, feature design, and testing split across the team).

## Future enhancements

- Trained ML model for real price/demand forecasting (currently a placeholder in the dashboard)
- Payment gateway integration
- Government trade portal integration (MPEDA / DGFT)
- Push notifications via Firebase Cloud Messaging
- Ratings and reviews system
- Companion web portal (Flutter Web)
