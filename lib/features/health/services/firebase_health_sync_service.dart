import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/daily_health_summary.dart';
import '../domain/models/device_connection_metadata.dart';
import 'health_sync_local_storage.dart';

class FirebaseHealthSyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;
  final HealthSyncLocalStorage _localStorage;

  FirebaseHealthSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseMessaging? messaging,
    HealthSyncLocalStorage? localStorage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _messaging = messaging ?? FirebaseMessaging.instance,
        _localStorage = localStorage ?? HealthSyncLocalStorage();

  /// Synchronizes a daily health summary to Cloud Firestore under users/{uid}/daily_summaries/{date}
  Future<bool> syncDailySummaryToCloud(DailyHealthSummary summary) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('FirebaseHealthSyncService: User not authenticated, skipping cloud sync.');
        return false;
      }

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('daily_summaries')
          .doc(summary.date);

      final payload = summary.toMap();
      payload['isCloudSynced'] = true;
      payload['serverSyncedAt'] = FieldValue.serverTimestamp();

      await docRef.set(payload, SetOptions(merge: true));

      // Mark as cloud synced locally
      final updated = summary.copyWith(isCloudSynced: true);
      await _localStorage.saveDailySummary(updated);
      return true;
    } catch (e) {
      debugPrint('FirebaseHealthSyncService.syncDailySummaryToCloud error: $e');
      return false;
    }
  }

  /// Registers/updates device metadata and FCM token in Firestore under users/{uid}/devices/{deviceId}
  Future<void> registerDeviceMetadata(DeviceConnectionMetadata metadata) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String? fcmToken;
      try {
        // ignore: deprecated_member_use
        fcmToken = await _messaging.getToken();
      } catch (_) {}

      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(metadata.deviceId);

      final data = metadata.toMap();
      data['fcmToken'] = fcmToken;
      data['os'] = Platform.operatingSystem;
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseHealthSyncService.registerDeviceMetadata error: $e');
    }
  }
}
