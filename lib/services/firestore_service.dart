import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';
import 'firebase_service.dart';

class FirestoreService {
  static FirebaseFirestore? get _db {
    try {
      if (!FirebaseService.isInitialized) return null;
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint("FirebaseFirestore instance access caught safely: $e");
      return null;
    }
  }

  // Publish Ingested Article to global `articles` collection
  static Future<void> publishIngestedArticle(IntelligenceCard card) async {
    try {
      final db = _db;
      if (db == null) return;
      await db.collection('articles').doc(card.id).set({
        'id': card.id,
        'headline': card.headline,
        'summary': card.summary,
        'source': card.source,
        'credibilityType': card.credibilityType.name,
        'readTime': card.readTime,
        'transparencyReason': card.transparencyReason,
        'pros': card.pros,
        'cons': card.cons,
        'channelId': card.channelId,
        'groundedContext': card.groundedContext,
        'url': card.url,
        'takeaways': card.takeaways,
        'publishedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore publishIngestedArticle caught safely: $e");
    }
  }

  // Real-Time Stream of Articles from `articles` collection
  static Stream<List<IntelligenceCard>> streamLiveArticles() {
    try {
      final db = _db;
      if (db == null) return Stream.value([]);
      return db
          .collection('articles')
          .orderBy('publishedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return IntelligenceCard(
            id: doc.id,
            headline: data['headline'] ?? '',
            summary: data['summary'] ?? '',
            credibilityType: _parseCredibility(data['credibilityType']),
            source: data['source'] ?? 'Verified Feed',
            readTime: data['readTime'] ?? '3 min read',
            transparencyReason: data['transparencyReason'] ?? 'Live Streamed Intelligence',
            pros: data['pros'] ?? 'Pros: Verified technical update',
            cons: data['cons'] ?? 'Cons: Standard deployment evaluation',
            channelId: data['channelId'] ?? 'ai_tools',
            groundedContext: data['groundedContext'] ?? data['headline'],
            url: data['url'] ?? 'https://news.ycombinator.com',
            takeaways: (data['takeaways'] as List?)?.map((e) => e.toString()).toList() ?? const [],
          );
        }).toList();
      });
    } catch (e) {
      debugPrint("Firestore streamLiveArticles caught safely: $e");
      return Stream.value([]);
    }
  }

  static CredibilityType _parseCredibility(String? name) {
    if (name == 'official') return CredibilityType.official;
    if (name == 'analysis') return CredibilityType.analysis;
    if (name == 'speculation') return CredibilityType.speculation;
    return CredibilityType.verified;
  }

  // Save Article to users/{userId}/saved_articles/{articleId}
  static Future<void> saveArticle(String userId, IntelligenceCard card) async {
    try {
      final db = _db;
      if (db == null) return;
      await db
          .collection('users')
          .doc(userId)
          .collection('saved_articles')
          .doc(card.id)
          .set({
        'id': card.id,
        'headline': card.headline,
        'summary': card.summary,
        'source': card.source,
        'credibilityType': card.credibilityType.name,
        'transparencyReason': card.transparencyReason,
        'pros': card.pros,
        'cons': card.cons,
        'savedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firestore saveArticle caught safely: $e");
    }
  }

  // Delete Article from users/{userId}/saved_articles/{articleId}
  static Future<void> deleteSavedArticle(String userId, String articleId) async {
    try {
      final db = _db;
      if (db == null) return;
      await db
          .collection('users')
          .doc(userId)
          .collection('saved_articles')
          .doc(articleId)
          .delete();
    } catch (e) {
      debugPrint("Firestore deleteSavedArticle caught safely: $e");
    }
  }

  // Fetch Saved Articles from users/{userId}/saved_articles
  static Future<List<SavedItem>> fetchSavedArticles(String userId) async {
    try {
      final db = _db;
      if (db == null) return [];
      final snapshot = await db
          .collection('users')
          .doc(userId)
          .collection('saved_articles')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return SavedItem(
          id: doc.id,
          type: 'article',
          title: data['headline'] ?? '',
          snippet: data['summary'] ?? '',
          savedAt: 'Synced from Cloud',
          source: data['source'] ?? 'BytePulse AI Feed',
        );
      }).toList();
    } catch (e) {
      debugPrint("Firestore fetchSavedArticles caught safely: $e");
      return [];
    }
  }

  // Sync Preferences to users/{userId}/preferences
  static Future<void> syncPreferences(
    String userId, {
    required String selectedRole,
    required Set<String> followedChannels,
    required double relevanceLevel,
    required bool quietHours,
  }) async {
    try {
      final db = _db;
      if (db == null) return;
      await db.collection('users').doc(userId).collection('preferences').doc('config').set({
        'selectedRole': selectedRole,
        'followedChannels': followedChannels.toList(),
        'relevanceLevel': relevanceLevel,
        'quietHours': quietHours,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Firestore syncPreferences caught safely: $e");
    }
  }

  // Save Custom Topic to users/{userId}/custom_topics/{topicId}
  static Future<void> saveCustomTopic(String userId, CustomTopic topic) async {
    try {
      final db = _db;
      if (db == null) return;
      await db
          .collection('users')
          .doc(userId)
          .collection('custom_topics')
          .doc(topic.id)
          .set({
        'id': topic.id,
        'name': topic.name,
        'keywords': topic.keywords,
        'rssUrl': topic.rssUrl,
        'addedAt': topic.addedAt,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Firestore saveCustomTopic caught safely: $e");
    }
  }

  // Delete Custom Topic from users/{userId}/custom_topics/{topicId}
  static Future<void> deleteCustomTopic(String userId, String topicId) async {
    try {
      final db = _db;
      if (db == null) return;
      await db
          .collection('users')
          .doc(userId)
          .collection('custom_topics')
          .doc(topicId)
          .delete();
    } catch (e) {
      debugPrint("Firestore deleteCustomTopic caught safely: $e");
    }
  }

  // Real-Time Stream of Custom Topics from users/{userId}/custom_topics
  static Stream<List<CustomTopic>> streamCustomTopics(String userId) {
    try {
      final db = _db;
      if (db == null) return Stream.value([]);
      return db
          .collection('users')
          .doc(userId)
          .collection('custom_topics')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return CustomTopic(
            id: doc.id,
            name: data['name'] ?? '',
            keywords: (data['keywords'] as List?)?.map((e) => e.toString()).toList() ?? const [],
            rssUrl: data['rssUrl'],
            addedAt: data['addedAt'] ?? 'Recently Added',
          );
        }).toList();
      });
    } catch (e) {
      debugPrint("Firestore streamCustomTopics caught safely: $e");
      return Stream.value([]);
    }
  }
}
