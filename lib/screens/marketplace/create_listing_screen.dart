import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:mtc/utils/theme_provider.dart';
import 'package:mtc/utils/constants.dart';
import 'package:mtc/utils/category_icons.dart';
import 'package:mtc/utils/language_provider.dart';

const _kCloudName    = 'djcuje59h';
const _kmtc_upload = 'mtc_upload';

class CreateListingScreen extends StatefulWidget {
  final Map<String, dynamic>? existingListing;
  final String? listingId;
  const CreateListingScreen({super.key, this.existingListing, this.listingId});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl   = TextEditingController();

  String _category   = AppConstants.categories.first;
  String _currency   = 'INR';
  String _unit       = 'kg';
  bool   _loading    = false;
  String _loadingMsg = 'Posting...';

  final List<dynamic> _photos = [null, null, null];
  final _picker = ImagePicker();

  bool get _isEdit => widget.existingListing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.existingListing!;
      _titleCtrl.text = d['title'] ?? '';
      _descCtrl.text  = d['description'] ?? '';
      _priceCtrl.text = '${d['pricePerKg'] ?? ''}';
      _qtyCtrl.text   = '${d['quantityKg'] ?? ''}';
      _category       = d['category'] ?? AppConstants.categories.first;
      _currency       = d['currency'] ?? 'INR';
      _unit           = d['priceUnit'] ?? 'kg';
      final imgs = List<String>.from(d['imageUrls'] ?? []);
      for (int i = 0; i < imgs.length && i < 3; i++) {
        _photos[i] = imgs[i];
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose(); _descCtrl.dispose();
    _priceCtrl.dispose(); _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(int index) async {
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
              title: const Text('Take photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final x = await _picker.pickImage(
                    source: ImageSource.camera, imageQuality: 80);
                if (x != null && mounted)
                  setState(() => _photos[index] = File(x.path));
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: t.primary),
              title: const Text('Choose from gallery',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                final x = await _picker.pickImage(
                    source: ImageSource.gallery, imageQuality: 80);
                if (x != null && mounted)
                  setState(() => _photos[index] = File(x.path));
              },
            ),
            if (_photos[index] != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photos[index] = null);
                },
              ),
          ]),
        ),
      ),
    );
  }

  Future<String> _uploadToCloudinary(File file, int index) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_kCloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _kmtc_upload
      ..fields['folder']        = 'mtc_listings'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send().timeout(
        const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      final err = jsonDecode(body);
      throw Exception(
          'Image upload failed: ${err['error']?['message'] ?? body}');
    }
    final data = jsonDecode(body);
    return data['secure_url'] as String;
  }

  Future<List<String>> _uploadPhotos() async {
    final urls  = <String>[];
    int fileIdx = 0;
    for (int i = 0; i < _photos.length; i++) {
      final photo = _photos[i];
      if (photo == null) continue;
      if (photo is String) {
        urls.add(photo);
      } else if (photo is File) {
        fileIdx++;
        if (mounted) setState(() => _loadingMsg = 'Uploading photo $fileIdx...');
        final url = await _uploadToCloudinary(photo, i);
        urls.add(url);
      }
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_photos.every((p) => p == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add at least one photo.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(left: 16, right: 16, bottom: 80),
      ));
      return;
    }

    setState(() { _loading = true; _loadingMsg = 'Preparing...'; });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in.');

      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final data = userDoc.data() ?? {};

      if (mounted) setState(() => _loadingMsg = 'Uploading photos...');
      final imageUrls = await _uploadPhotos();

      if (mounted)
        setState(() =>
        _loadingMsg = _isEdit ? 'Updating listing...' : 'Posting listing...');

      final listing = {
        'title':          _titleCtrl.text.trim(),
        'description':    _descCtrl.text.trim(),
        'category':       _category,
        'pricePerKg':     double.tryParse(_priceCtrl.text) ?? 0,
        'priceUnit':      _unit,
        'quantityKg':     double.tryParse(_qtyCtrl.text) ?? 0,
        'quantityUnit':   _unit,
        'currency':       _currency,
        'imageUrls':      imageUrls,
        'status':         'active',
        'sellerId':       user.uid,
        'sellerName':     data['name'] ?? user.displayName ?? 'Seller',
        'sellerLocation': data['location'] ?? '',
        'updatedAt':      FieldValue.serverTimestamp(),
      };
      await FirebaseAuth.instance.currentUser?.getIdToken(true); // force-refresh token before write
      if (_isEdit && widget.listingId != null) {
        // ── Edit existing listing ──────────────────────────────────────
        await FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.listingId)
            .update(listing);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Listing updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
          Navigator.pop(context);
        }
      } else {
        // ── Create new listing ─────────────────────────────────────────
        listing['createdAt'] = FieldValue.serverTimestamp();
        final listingRef = await FirebaseFirestore.instance
            .collection('listings')
            .add(listing);

        // Auto-create open shipment_request so all agents see it immediately
        await FirebaseFirestore.instance
            .collection('shipment_requests')
            .add({
          'shipmentId':   '',
          'listingId':    listingRef.id,
          'listingTitle': _titleCtrl.text.trim(),
          'sellerId':     user.uid,
          'sellerName':   data['name'] ?? user.displayName ?? 'Seller',
          'buyerId':      '',
          'buyerName':    '',
          'quantityKg':   double.tryParse(_qtyCtrl.text) ?? 0,
          'totalPrice':   double.tryParse(_priceCtrl.text) ?? 0,
          'pickupPort':   data['location'] ?? '',
          'dropoffPort':  '',
          'status':       'open',
          'applicants':   [],
          'createdAt':    FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Listing posted!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('CreateListing error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
          duration: const Duration(seconds: 6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Provider.of<ThemeProvider>(context).current;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background, elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: t.primary.withOpacity(0.25)),
            ),
            child: const Icon(Icons.arrow_back_ios_new,
                color: Colors.white70, size: 15),
          ),
        ),
        title: Text(
          _isEdit ? 'Edit listing' : 'Post listing',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(24), children: [

          _label('Photos * (up to 3)', t),
          const SizedBox(height: 10),
          Row(children: List.generate(3, (i) {
            final photo = _photos[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                child: GestureDetector(
                  onTap: () => _pickPhoto(i),
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: t.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: photo != null
                            ? t.primary.withOpacity(0.5)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: photo == null
                        ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: Colors.white.withOpacity(0.3),
                              size: 26),
                          const SizedBox(height: 4),
                          Text('Photo ${i + 1}',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                  fontSize: 10)),
                        ])
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: photo is File
                          ? Image.file(photo,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 90)
                          : Image.network(
                        photo as String,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 90,
                        errorBuilder: (_, __, ___) => Container(
                          color: t.card,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white30),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          })),
          const SizedBox(height: 6),
          Text('Tap a slot to add/change photo • Tap again to remove',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25), fontSize: 11)),
          const SizedBox(height: 20),

          _label('Title *', t),
          _field(_titleCtrl, 'e.g. Fresh Lobster — Grade A', t,
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Title required' : null),

          // Icon-first category picker — lets low-literacy sellers pick by
          // recognising a picture/emoji instead of reading English text.
          // Names shown are also translated into the app's current language.
          _label('Category *', t),
          const SizedBox(height: 8),
          _CategoryGrid(
            selected: _category,
            onSelected: (c) => setState(() => _category = c),
            t: t,
          ),
          const SizedBox(height: 18),

          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Price *', t),
                    _field(_priceCtrl, '500', t,
                        keyboard: TextInputType.number,
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null),
                  ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Quantity *', t),
                    _field(_qtyCtrl, '100', t,
                        keyboard: TextInputType.number,
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null),
                  ]),
            ),
          ]),

          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Currency', t),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _currency,
                          dropdownColor: t.card,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          isExpanded: true,
                          items: AppConstants.currencies
                              .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _currency = v!),
                        ),
                      ),
                    ),
                  ]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Unit', t),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: t.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _unit,
                          dropdownColor: t.card,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          isExpanded: true,
                          items: AppConstants.units
                              .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v!),
                        ),
                      ),
                    ),
                  ]),
            ),
          ]),
          const SizedBox(height: 18),

          _label('Description', t),
          _field(_descCtrl, 'Describe your product, quality, origin...', t,
              maxLines: 4),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _loading
                  ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text(_loadingMsg,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14)),
                  ])
                  : Text(
                _isEdit ? 'Update listing' : 'Post listing',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _label(String text, AppTheme t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 13,
            fontWeight: FontWeight.w500)),
  );

  Widget _field(
      TextEditingController ctrl,
      String hint,
      AppTheme t, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          filled: true,
          fillColor: t.card,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: t.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

// Icon-first category picker — lets low-literacy sellers pick by
// recognising a picture/emoji instead of reading English category names.
// Names shown are also translated into the app's current language.
class _CategoryGrid extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final AppTheme t;
  const _CategoryGrid(
      {required this.selected, required this.onSelected, required this.t});

  @override
  Widget build(BuildContext context) {
    final langCode = Provider.of<LanguageProvider>(context, listen: false)
        .locale.languageCode;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: AppConstants.categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, i) {
        final cat = AppConstants.categories[i];
        final isSelected = cat == selected;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? t.primary.withOpacity(0.15)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? t.primary
                    : Colors.white.withOpacity(0.05),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: isSelected ? 1.0 : 0.35,
                  child: Text(CategoryIcons.emojiFor(cat),
                      style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(height: 6),
                Text(
                  CategoryIcons.translatedName(cat, langCode),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? t.primary
                        : Colors.white.withOpacity(0.65),
                    fontSize: 9,
                    fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}