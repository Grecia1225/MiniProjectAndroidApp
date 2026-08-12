import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/language_provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherName;
  final String otherId;
  final String listingTitle;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherName,
    required this.otherId,
    required this.listingTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();
  final _picker = ImagePicker();
  final _tts    = FlutterTts();

  bool _sending   = false;
  bool _uploading = false;
  bool _speaking  = false;
  String _senderName = ''; // current user's display name, used on outgoing notifications

  // ── TTS language map: app locale → BCP-47 TTS language tag ───────────────
  static const _ttsLangMap = {
    'en': 'en-IN',
    'hi': 'hi-IN',
    'ta': 'ta-IN',
    'te': 'te-IN',
    'ml': 'ml-IN',
    'kn': 'kn-IN',
    'ar': 'ar-SA',
    'fr': 'fr-FR',
  };

  @override
  void initState() {
    super.initState();
    _loadSenderName();
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _speaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // Loads the current user's display name once, for use on outgoing
  // message notifications (so the recipient sees "Suresh Nair sent you a
  // message" instead of a generic label).
  Future<void> _loadSenderName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() => _senderName =
            (doc.data()?['name'] as String?) ?? user.displayName ?? 'Someone');
      }
    } catch (_) {
      if (mounted) setState(() => _senderName = user.displayName ?? 'Someone');
    }
  }

  // ── Send text message ──────────────────────────────────────────────────────
  Future<void> _send({String? text, String type = 'text'}) async {
    final msg = (text ?? _ctrl.text).trim();
    if (msg.isEmpty || _sending) return;
    setState(() => _sending = true);
    _ctrl.clear();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final batch  = FirebaseFirestore.instance.batch();
      final msgRef = FirebaseFirestore.instance
          .collection('chats').doc(widget.chatId)
          .collection('messages').doc();
      batch.set(msgRef, {
        'senderId':  uid,
        'text':      msg,
        'type':      type,
        'timestamp': FieldValue.serverTimestamp(),
      });
      final lastMessagePreview = type == 'image'
          ? '📷 Photo'
          : type == 'location'
          ? '📍 Location'
          : msg;
      batch.update(
        FirebaseFirestore.instance.collection('chats').doc(widget.chatId),
        {
          'lastMessage': lastMessagePreview,
          'lastMessageTime': FieldValue.serverTimestamp(),
        },
      );
      await batch.commit();

      // Notify the other participant. Previously the only notification a
      // chat ever produced was the one-time "Contact Seller" ping when the
      // thread was first created — every message after that (from either
      // side) was silent unless the recipient happened to have the chat
      // open. This fires on every message, both directions, so replies
      // are no longer invisible to the seller/buyer.
      if (widget.otherId.isNotEmpty) {
        final displayName = _senderName.isNotEmpty ? _senderName : 'Someone';
        await FirebaseFirestore.instance.collection('notifications').add({
          'toUid':        widget.otherId,
          'fromUid':      uid,
          'fromName':     displayName,
          'type':         'new_message',
          'title':        '$displayName sent you a message',
          'body':         lastMessagePreview,
          'chatId':       widget.chatId,
          'listingTitle': widget.listingTitle,
          'read':         false,
          'createdAt':    FieldValue.serverTimestamp(),
        });
      }

      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ── Pick photo from gallery or camera and upload to Firebase Storage ───────
  Future<void> _pickAndSendImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 72);
    if (xfile == null) return;
    setState(() => _uploading = true);
    try {
      final file = File(xfile.path);
      final ext  = xfile.name.split('.').last;
      final ref  = FirebaseStorage.instance.ref(
          'chat_images/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}.$ext');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      await _send(text: url, type: 'image');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Show bottom sheet to choose camera or gallery ──────────────────────────
  void _showImageSourceSheet() {
    final t = Provider.of<ThemeProvider>(context, listen: false).current;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: t.primary),
              title: const Text('Take photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: t.primary),
              title: const Text('Choose from gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
          ]),
        ),
      ),
    );
  }

  // ── Manual location picker dialog (no geolocator package required) ─────────
  Future<void> _shareLocation() async {
    final t    = Provider.of<ThemeProvider>(context, listen: false).current;
    final latC = TextEditingController();
    final lngC = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Icon(Icons.location_on, color: t.primary, size: 22),
          const SizedBox(width: 8),
          const Text('Share Location',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            'Enter coordinates to share a Google Maps link.',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
          ),
          const SizedBox(height: 16),
          _coordField(latC, 'Latitude  (e.g. 19.0760)', t),
          const SizedBox(height: 10),
          _coordField(lngC, 'Longitude  (e.g. 72.8777)', t),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.4))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: t.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final lat = double.tryParse(latC.text.trim());
    final lng = double.tryParse(lngC.text.trim());

    if (lat == null || lng == null ||
        lat < -90  || lat > 90 ||
        lng < -180 || lng > 180) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter valid latitude (−90 to 90) and longitude (−180 to 180).'),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    final mapsUrl = 'https://maps.google.com/?q=$lat,$lng';
    await _send(text: mapsUrl, type: 'location');
  }

  /// Styled coordinate text field used inside the location dialog.
  Widget _coordField(TextEditingController ctrl, String hint, dynamic t) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: t.primary, width: 1.2)),
      ),
    );
  }

  // ── TTS: speak the last received message aloud ────────────────────────────
  Future<void> _speakLastMessage() async {
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }

    // Pull the most-recent message from Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final snap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;

    final data = snap.docs.first.data();
    final type = (data['type'] ?? 'text') as String;
    final text = (data['text'] ?? '') as String;
    final senderId = (data['senderId'] ?? '') as String;

    String toSpeak;
    if (type == 'image') {
      toSpeak = senderId == uid ? 'You sent a photo.' : '${widget.otherName} sent a photo.';
    } else if (type == 'location') {
      toSpeak = senderId == uid ? 'You shared a location.' : '${widget.otherName} shared a location.';
    } else {
      toSpeak = text;
    }

    if (toSpeak.isEmpty) return;

    final langCode = Provider.of<LanguageProvider>(context, listen: false)
        .locale.languageCode;
    final ttsLang = _ttsLangMap[langCode] ?? 'en-IN';

    await _tts.setLanguage(ttsLang);
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    if (mounted) setState(() => _speaking = true);
    await _tts.speak(toSpeak);
  }


  @override
  Widget build(BuildContext context) {
    final t   = Provider.of<ThemeProvider>(context).current;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.card,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.primary.withOpacity(0.2)),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 15),
          ),
        ),
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: t.primary.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: t.primary.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                widget.otherName.isNotEmpty ? widget.otherName[0].toUpperCase() : '?',
                style: TextStyle(
                    color: t.primary, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.otherName,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            if (widget.listingTitle.isNotEmpty)
              Text(
                widget.listingTitle,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ]),
        ]),
      ),
      body: Column(children: [

        // Upload progress bar
        if (_uploading)
          LinearProgressIndicator(color: t.primary, backgroundColor: t.card),

        // Messages list
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chatId)
                .collection('messages')
                .orderBy('timestamp')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: t.primary));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          color: t.primary.withOpacity(0.2), size: 48),
                      const SizedBox(height: 12),
                      Text('Start the conversation',
                          style: TextStyle(color: Colors.white.withOpacity(0.4))),
                    ],
                  ),
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scroll.hasClients) {
                  _scroll.jumpTo(_scroll.position.maxScrollExtent);
                }
              });
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final isMe = data['senderId'] == uid;
                  final text = (data['text'] ?? '') as String;
                  final type = (data['type'] ?? 'text') as String;
                  final time = (data['timestamp'] as Timestamp?)?.toDate();

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.72),
                      decoration: BoxDecoration(
                        color: isMe ? t.primary : t.card,
                        borderRadius: BorderRadius.only(
                          topLeft:     const Radius.circular(16),
                          topRight:    const Radius.circular(16),
                          bottomLeft:  Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: type == 'image'
                      // ── Image bubble ──────────────────────────────
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Image.network(
                              text,
                              width: 220, height: 180,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : SizedBox(
                                width: 220, height: 180,
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: t.primary, strokeWidth: 2),
                                ),
                              ),
                              errorBuilder: (_, __, ___) => Container(
                                width: 220, height: 60,
                                color: t.card,
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.white30),
                                ),
                              ),
                            ),
                            if (time != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                                child: Text(_fmt(time),
                                    style: TextStyle(
                                        color: isMe
                                            ? Colors.black45
                                            : Colors.white38,
                                        fontSize: 9)),
                              ),
                          ],
                        ),
                      )
                          : type == 'location'
                      // ── Location bubble ───────────────────────
                          ? GestureDetector(
                        onTap: () => launchUrl(Uri.parse(text),
                            mode: LaunchMode.externalApplication),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.location_on,
                                color: isMe ? Colors.black : t.primary,
                                size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'View location',
                              style: TextStyle(
                                color: isMe ? Colors.black : t.primary,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ]),
                        ),
                      )
                      // ── Text bubble ───────────────────────────
                          : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(text,
                                style: TextStyle(
                                    color: isMe ? Colors.black : Colors.white,
                                    fontSize: 14,
                                    height: 1.4)),
                            if (time != null) ...[
                              const SizedBox(height: 4),
                              Text(_fmt(time),
                                  style: TextStyle(
                                      color: isMe
                                          ? Colors.black45
                                          : Colors.white38,
                                      fontSize: 10)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // ── Input bar ─────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
          decoration: BoxDecoration(
            color: t.card,
            border: Border(top: BorderSide(color: t.primary.withOpacity(0.08))),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [

            // Photo button (camera + gallery)
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: 40, height: 40,
                margin: const EdgeInsets.only(right: 6, bottom: 2),
                decoration: BoxDecoration(
                    color: t.background, borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.image_outlined,
                    color: Colors.white.withOpacity(0.5), size: 20),
              ),
            ),

            // Location button
            GestureDetector(
              onTap: _shareLocation,
              child: Container(
                width: 40, height: 40,
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                decoration: BoxDecoration(
                    color: t.background, borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.location_on_outlined,
                    color: Colors.white.withOpacity(0.5), size: 20),
              ),
            ),

            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                    color: t.background, borderRadius: BorderRadius.circular(24)),
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // TTS button — tap to hear the last message read aloud
            GestureDetector(
              onTap: _speakLastMessage,
              child: Container(
                width: 40, height: 40,
                margin: const EdgeInsets.only(left: 2, bottom: 2),
                decoration: BoxDecoration(
                  color: _speaking ? t.primary : t.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _speaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                  color: _speaking ? Colors.black : Colors.white.withOpacity(0.5),
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Send button
            GestureDetector(
              onTap: () => _send(),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
                child: _sending
                    ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 2),
                )
                    : const Icon(Icons.send_rounded, color: Colors.black, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}