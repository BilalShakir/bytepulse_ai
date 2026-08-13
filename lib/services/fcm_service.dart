import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';
import 'firebase_service.dart';

class FcmService {
  static FirebaseMessaging? get _messaging {
    try {
      if (!FirebaseService.isInitialized) return null;
      return FirebaseMessaging.instance;
    } catch (e) {
      debugPrint("FirebaseMessaging instance access caught safely: $e");
      return null;
    }
  }

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Function(String targetTab, IntelligenceCard? card)? onDeepLinkTap;

  static Future<void> initializeFcm(WidgetRef ref) async {
    try {
      final messaging = _messaging;
      if (messaging == null) return;

      // 1. Request Notification Permissions
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Register local notification channel
        const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const InitializationSettings initSettings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (response) {
            _handleNotificationPayloadTap(response.payload, ref);
          },
        );

        // 3. Store FCM Token in Firestore if signed in
        final token = await messaging.getToken();
        if (token != null) {
          await _saveFcmToken(token);
        }

        messaging.onTokenRefresh.listen((newToken) {
          _saveFcmToken(newToken);
        });

        // 4. Foreground Message Listener
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _processIncomingMessage(message, ref, isForeground: true);
        });

        // 5. App Opened From Terminated or Background State
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _processIncomingMessage(message, ref, isForeground: false, isTap: true);
        });
      }
    } catch (e) {
      debugPrint("FCM Initialization caught safely: $e");
    }
  }

  static Future<void> _saveFcmToken(String token) async {
    final user = FirebaseService.currentUser;
    if (user != null && FirebaseService.isInitialized) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("FCM save token caught safely: $e");
      }
    }
  }

  static void _processIncomingMessage(
    RemoteMessage message,
    WidgetRef ref, {
    required bool isForeground,
    bool isTap = false,
  }) {
    final data = message.data;
    final double messagePriorityLevel = double.tryParse(data['priorityLevel'] ?? '2.0') ?? 2.0;
    final double userRelevanceSetting = ref.read(relevanceLevelProvider);
    final bool quietHours = ref.read(quietHoursProvider);

    // Filter notification by user relevance setting (1.0: Critical, 2.0: Balanced, 3.0: Everything)
    if (quietHours || messagePriorityLevel < userRelevanceSetting) {
      return; // Suppressed by relevance threshold slider or quiet hours
    }

    final card = IntelligenceCard(
      id: data['cardId'] ?? 'fcm-${DateTime.now().millisecondsSinceEpoch}',
      headline: message.notification?.title ?? data['title'] ?? 'Critical Technical Alert',
      summary: message.notification?.body ?? data['summary'] ?? 'Urgent release update matching your interest profile.',
      credibilityType: CredibilityType.official,
      source: data['source'] ?? 'Official • FCM Intelligence',
      readTime: '2 min read',
      transparencyReason: 'Triggered by FCM High Relevance Alert',
      pros: 'Pros: Sub-second infrastructure notification',
      cons: 'Cons: Requires quick review',
      channelId: data['channelId'] ?? 'cloud_infra',
      groundedContext: data['title'] ?? 'FCM Push Notification',
      takeaways: const [
        'High-priority alert delivered via Firebase Cloud Messaging.',
        'Matched user relevance slider filter setting.',
        'Deep-linked directly to Gemini agent interactive context.',
      ],
    );

    if (isTap) {
      _triggerDeepLink(data['targetTab'] ?? 'gemini', card, ref);
    } else if (isForeground) {
      _showLocalNotification(
        id: message.hashCode,
        title: card.headline,
        body: card.summary,
        payload: data['targetTab'] ?? 'gemini',
      );
    }
  }

  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'bytepulse_alerts_channel',
        'BytePulse AI Alerts',
        channelDescription: 'Real-time developer push notifications and release alerts',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      await _localNotifications.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint("Local notification display caught safely: $e");
    }
  }

  static void _handleNotificationPayloadTap(String? payload, WidgetRef ref) {
    if (payload == null) return;
    _triggerDeepLink(payload, null, ref);
  }

  static void _triggerDeepLink(String targetTab, IntelligenceCard? card, WidgetRef ref) {
    if (targetTab == 'gemini') {
      ref.read(activeTabProvider.notifier).state = 2; // Gemini Tab
      if (card != null) {
        ref.read(groundedCardProvider.notifier).state = card;
        ref.read(groundedContextProvider.notifier).state = card.headline;
      }
    } else if (targetTab == 'alerts') {
      ref.read(activeTabProvider.notifier).state = 3; // Alerts Tab
    } else {
      ref.read(activeTabProvider.notifier).state = 0; // Home Feed Tab
    }

    if (onDeepLinkTap != null) {
      onDeepLinkTap!(targetTab, card);
    }
  }

  static Future<void> simulateTestPushNotification(WidgetRef ref) async {
    final testCard = IntelligenceCard(
      id: 'fcm-test-${DateTime.now().millisecondsSinceEpoch}',
      headline: 'CRITICAL SECURITY: Zero-Day Patch Released for Kubernetes Ingress Controller',
      summary: 'Official security advisory details immediate patch requirements for all production multi-tenant clusters.',
      credibilityType: CredibilityType.official,
      source: 'Official • Security Bulletin',
      readTime: '1 min read',
      transparencyReason: 'Matches your Critical Alerts preference setting (Level 1.0)',
      pros: 'Pros: Fixes remote privilege escalation vulnerability',
      cons: 'Cons: Requires rolling pod restart',
      channelId: 'cloud_infra',
      groundedContext: 'Kubernetes Ingress Zero-Day Security Advisory',
      takeaways: const [
        'Urgent zero-day vulnerability patched in v1.28.4.',
        'Applies immediately to all cloud-managed k8s clusters.',
        'Ask Gemini Agent for automated upgrade script commands.',
      ],
    );

    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: testCard.headline,
      body: testCard.summary,
      payload: 'gemini',
    );

    // Deep link directly to Gemini Agent with context
    _triggerDeepLink('gemini', testCard, ref);
  }
}
