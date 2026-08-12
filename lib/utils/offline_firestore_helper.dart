// lib/utils/offline_firestore_helper.dart
// Drop this file in lib/utils/ and use it everywhere instead of
// raw FirebaseFirestore.instance.collection().doc().get()
//
// It always tries cache first → instant render → then updates from server
// silently in background. Perfect for low/no connectivity.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FS {
  // ── Get a single document — cache first, server fallback ─────────────────
  static Future<DocumentSnapshot> getDoc(
      String collection,
      String docId, {
        bool serverOnly = false,
      }) async {
    final ref = FirebaseFirestore.instance.collection(collection).doc(docId);
    if (serverOnly) return ref.get(const GetOptions(source: Source.server));
    try {
      // Try cache first — instant, works offline
      final cached = await ref.get(const GetOptions(source: Source.cache));
      if (cached.exists) return cached;
    } catch (_) {}
    // Cache miss or empty → try server
    try {
      return await ref.get(const GetOptions(source: Source.server));
    } catch (e) {
      debugPrint('FS.getDoc offline: $e');
      rethrow;
    }
  }

  // ── Get a collection — cache first, server fallback ───────────────────────
  static Future<QuerySnapshot> getCollection(
      Query query, {
        bool serverOnly = false,
      }) async {
    if (serverOnly) return query.get(const GetOptions(source: Source.server));
    try {
      final cached = await query.get(const GetOptions(source: Source.cache));
      if (cached.docs.isNotEmpty) return cached;
    } catch (_) {}
    try {
      return await query.get(const GetOptions(source: Source.server));
    } catch (e) {
      debugPrint('FS.getCollection offline: $e');
      rethrow;
    }
  }

  // ── Set a document — queues write even when offline ───────────────────────
  // Firestore SDK automatically syncs when connection returns
  static Future<void> setDoc(
      String collection,
      String docId,
      Map<String, dynamic> data, {
        bool merge = true,
      }) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
    // No try/catch — Firestore queues offline writes automatically
  }

  // ── Update a document — queues even when offline ──────────────────────────
  static Future<void> updateDoc(
      String collection,
      String docId,
      Map<String, dynamic> data,
      ) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .update(data);
  }
}