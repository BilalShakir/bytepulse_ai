import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../services/feed_ingestion_service.dart';

// Demo User Model for Web Testing
class DemoUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final bool isDemo;

  DemoUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    this.isDemo = true,
  });
}

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final String photoUrl;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.photoUrl,
  });
}

final userProfileProvider = StateProvider<UserProfile?>((ref) => null);
final googleAuthSignedInProvider = StateProvider<bool>((ref) => false);
final demoUserProvider = StateProvider<DemoUser?>((ref) => null);

// Navigation tab index (0: Home, 1: Explore, 2: Gemini, 3: Alerts, 4: Profile)
final activeTabProvider = StateProvider<int>((ref) => 0);

// Onboarding & Active Engineering Role
final isOnboardingOpenProvider = StateProvider<bool>((ref) => false);
final selectedRoleProvider = StateProvider<String>((ref) => 'ai_ml');
final followedChannelsProvider = StateProvider<Set<String>>((ref) => {'ai_tools', 'gpus_hw', 'cloud_infra', 'dev_tools'});

// Grounded context for Gemini
final groundedContextProvider = StateProvider<String?>((ref) => 'DeepSeek-R1 Distillation & Open Reasoning Swarms');
final groundedCardProvider = StateProvider<IntelligenceCard?>((ref) => null);
final isStreamingProvider = StateProvider<bool>((ref) => false);
final isRefreshingFeedProvider = StateProvider<bool>((ref) => false);

// Firebase Auth Provider
final authUserProvider = StreamProvider<User?>((ref) {
  FirebaseService.initializeFirebase();
  return FirebaseService.authStateChanges;
});

// Live Firestore Articles Stream Provider
final liveFirestoreStreamProvider = StreamProvider<List<IntelligenceCard>>((ref) {
  return FirestoreService.streamLiveArticles();
});

// Bookmarks & Saved Library
final bookmarksProvider = StateProvider<Set<String>>((ref) => {'card-1'});

class CustomTopicsNotifier extends StateNotifier<List<CustomTopic>> {
  CustomTopicsNotifier()
      : super([
          CustomTopic(
            id: 'topic-1',
            name: 'DeepSeek Reasoning Swarms',
            keywords: ['deepseek', 'distillation', 'vllm', 'reasoning'],
            addedAt: '2 hours ago',
          ),
          CustomTopic(
            id: 'topic-2',
            name: 'Kubernetes Ingress Security Alerts',
            keywords: ['k8s', 'ingress', 'security', 'cve'],
            addedAt: 'Yesterday',
          ),
        ]);

  void addTopic(CustomTopic topic) {
    if (!state.any((t) => t.name.toLowerCase() == topic.name.toLowerCase())) {
      state = [topic, ...state];
      final user = FirebaseService.currentUser;
      if (user != null) {
        FirestoreService.saveCustomTopic(user.uid, topic);
      }
    }
  }

  void removeTopic(String topicId) {
    state = state.where((t) => t.id != topicId).toList();
    final user = FirebaseService.currentUser;
    if (user != null) {
      FirestoreService.deleteCustomTopic(user.uid, topicId);
    }
  }
}

final customTopicsProvider = StateNotifierProvider<CustomTopicsNotifier, List<CustomTopic>>((ref) {
  return CustomTopicsNotifier();
});

class CardsNotifier extends StateNotifier<List<IntelligenceCard>> {
  final Ref ref;

  CardsNotifier(this.ref)
      : super([
          // AI / ML Engineer Cards
          IntelligenceCard(
            id: 'card-1',
            headline: 'DeepSeek-R1 Distillation & Open Reasoning Swarms Benchmark Analysis',
            summary: 'Developer forum analysis confirms distilled 14B and 32B models match 94% of proprietary 700B reasoning baselines at low inference VRAM costs.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • Hacker News Engineering Thread',
            readTime: '3 min read',
            transparencyReason: 'Matched via LLM distillation vector',
            pros: 'Pros: 84% lower VRAM overhead, runnable on single RTX 4090',
            cons: 'Cons: Requires custom vLLM 0.6.2 runtime patch',
            channelId: 'ai_tools',
            groundedContext: 'DeepSeek-R1 Distillation Study (Aug 2026)',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Distilled 14B/32B models achieve 94% reasoning parity with 700B baselines.',
              'Significant reduction in inference VRAM cost enables single-node deployment.',
              'Requires custom vLLM 0.6.2 compilation patch for optimal tensor parallelism.',
            ],
          ),
          IntelligenceCard(
            id: 'card-2',
            headline: 'Google Cloud Release Notes: Native Gemini 3.1 Pro API Function Calling Extensions',
            summary: 'Official release documentation details structured JSON outputs, streaming tool calls, and automated subagent orchestration pipelines.',
            credibilityType: CredibilityType.official,
            source: 'Official • Google Cloud Docs',
            readTime: '4 min read',
            transparencyReason: 'Matched via Cloud AI provider vector',
            pros: 'Pros: Zero regex parsing needed for tool invocation',
            cons: 'Cons: Strict JSON schema compliance required',
            channelId: 'ai_tools',
            groundedContext: 'Google Cloud Release Notes (Aug 2026)',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              'Native function calling extensions eliminate regex parsing overhead.',
              'Subsecond streaming JSON outputs for agentic workflows.',
              'Automated fallback handling across Gemini 3.6 Flash models.',
            ],
          ),
          IntelligenceCard(
            id: 'card-3',
            headline: 'NVIDIA B200 Blackwell Benchmarks: NVLink 5 Interconnect Throughput Analysis',
            summary: 'In-depth technical architecture breakdown evaluating sustained 1.8 PFLOPS FP8 performance across 64-node clusters.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • SemiAnalysis DeepDive',
            readTime: '6 min read',
            transparencyReason: 'Matched via Datacenter Hardware vector',
            pros: 'Pros: 2.8x throughput speedup over H100 SXM5',
            cons: 'Cons: Mandatory direct-to-chip liquid cooling',
            channelId: 'gpus_hw',
            groundedContext: 'NVIDIA Blackwell Technical DeepDive',
            url: 'https://aws.amazon.com/blogs/aws',
            takeaways: const [
              'Sustained 1.8 PFLOPS FP8 matrix math throughput in 64-node clusters.',
              'NVLink 5 interconnect delivers 1.8TB/s bidirectional bandwidth per GPU.',
              'Requires facility infrastructure retrofitting for liquid cooling loops.',
            ],
          ),

          // DevOps & Cloud Cards
          IntelligenceCard(
            id: 'card-devops-1',
            headline: 'Kubernetes 1.31 Release Notes: Ingress Security Hotfix & Zero-Day Mitigation',
            summary: 'Official CNCF security advisory details immediate patch requirements for cloud-managed k8s ingress controllers.',
            credibilityType: CredibilityType.official,
            source: 'Official • Kubernetes Security Advisory',
            readTime: '4 min read',
            transparencyReason: 'Matched via Cloud Security vector',
            pros: 'Pros: Fixes remote privilege escalation in NGINX ingress',
            cons: 'Cons: Requires rolling pod restart across nodes',
            channelId: 'cloud_infra',
            groundedContext: 'Kubernetes 1.31 Security Advisory',
            url: 'https://aws.amazon.com/blogs/aws',
            takeaways: const [
              'Critical security patch mitigates zero-day ingress vulnerability.',
              'Automated rolling updates supported via kubectl rollout restart.',
              'Zero cluster downtime when deployed with pod disruption budgets.',
            ],
          ),
          IntelligenceCard(
            id: 'card-devops-2',
            headline: 'Terraform AWS Provider v5.6: Parallel Infrastructure Provisioning Engine',
            summary: 'HashiCorp release documentation introduces 4x faster plan/apply execution times across multi-region VPC setups.',
            credibilityType: CredibilityType.official,
            source: 'Official • HashiCorp Release Blog',
            readTime: '3 min read',
            transparencyReason: 'Matched via Infrastructure-as-Code vector',
            pros: 'Pros: 75% reduction in CI/CD pipeline execution duration',
            cons: 'Cons: Requires updated provider block configuration',
            channelId: 'cloud_infra',
            groundedContext: 'Terraform AWS Provider Release',
            url: 'https://github.blog',
            takeaways: const [
              'Parallel state file evaluation speeds up large workspace deployment.',
              'Native AWS SDK v2 integration reduces API throttling retries.',
              'Backward compatible with Terraform HCL 1.5+ syntax.',
            ],
          ),

          // FinOps Consultant Cards
          IntelligenceCard(
            id: 'card-finops-1',
            headline: 'Cloud FinOps Strategy: Reducing AI Model Inference Spend by 62% via Dynamic Batching',
            summary: 'Detailed financial engineering case study demonstrating \$480,000 annual cloud savings across multi-tenant GPU clusters.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Cloud FinOps Weekly',
            readTime: '5 min read',
            transparencyReason: 'Matched via Cloud Spend Optimization vector',
            pros: 'Pros: 62% reduction in monthly GPU compute bills',
            cons: 'Cons: Slight P99 latency increase during off-peak hours',
            channelId: 'dev_tools',
            groundedContext: 'Cloud FinOps Inference Cost Optimization',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              'Dynamic queue batching optimizes GPU utilization from 34% to 88%.',
              'Automated spot instance fallback saves 62% on inference infrastructure.',
              'Real-time cost anomaly metrics wired to Slack alerts.',
            ],
          ),
          IntelligenceCard(
            id: 'card-finops-2',
            headline: 'AWS & GCP Billing APIs: Real-Time Unit Economics & Cost Allocation Tagging',
            summary: 'Technical guide on streaming cloud consumption logs directly into BigQuery FinOps dashboards.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • Cloud Architecture Journal',
            readTime: '4 min read',
            transparencyReason: 'Matched via Billing API vector',
            pros: 'Pros: Real-time per-query cost attribution for LLM APIs',
            cons: 'Cons: Requires setting up GCS cost export buckets',
            channelId: 'dev_tools',
            groundedContext: 'Cloud Billing API Cost Tagging Guide',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              'Per-token and per-request cost attribution across enterprise teams.',
              'Automated alerts trigger when daily spend exceeds 15% threshold.',
              'Direct integration with Google Cloud BigQuery FinOps exports.',
            ],
          ),

          // Software Architect Cards
          IntelligenceCard(
            id: 'card-4',
            headline: 'Developer Forum Leaks: Next-Gen Ultra-Low Latency Rust WASM Runtime for Edge AI',
            summary: 'Community leaks indicate upcoming web assembly micro-runtime capable of cold-starting AI agents in under 1.2ms.',
            credibilityType: CredibilityType.speculation,
            source: 'Speculation • Developer Forum Leak',
            readTime: '2 min read',
            transparencyReason: 'Matched via Edge Systems vector',
            pros: 'Pros: Sub-millisecond cold start overhead',
            cons: 'Cons: Unconfirmed API stability & edge benchmarks',
            channelId: 'dev_tools',
            groundedContext: 'Developer Forum Discussion Thread',
            url: 'https://github.blog',
            takeaways: const [
              'Sub-millisecond cold start latency for WASM edge microservices.',
              'Memory-isolated sandbox execution with zero native C-binding risks.',
              'Compatible with standard Wasmtime and Spin runtime drivers.',
            ],
          ),
          IntelligenceCard(
            id: 'card-arch-1',
            headline: 'Distributed Systems Patterns: Event-Driven Microservices with Kafka & gRPC',
            summary: 'Architecture specification detailing CQRS event sourcing, idempotent message processing, and schema registry validation.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Software Architecture Review',
            readTime: '7 min read',
            transparencyReason: 'Matched via Distributed Systems vector',
            pros: 'Pros: High fault tolerance with zero message loss guarantee',
            cons: 'Cons: Increased architectural complexity for schema evolution',
            channelId: 'dev_tools',
            groundedContext: 'Event-Driven Microservices Architecture',
            url: 'https://aws.amazon.com/blogs/aws',
            takeaways: const [
              'CQRS pattern decouples heavy read models from transactional writes.',
              'gRPC protocol buffers reduce payload size by 65% compared to REST JSON.',
              'Idempotency keys prevent duplicate transaction execution.',
            ],
          ),
        ]);

  Future<void> ingestNewFeed() async {
    ref.read(isRefreshingFeedProvider.notifier).state = true;

    final activeTopics = ref.read(customTopicsProvider);
    final newIngestedCards = await FeedIngestionService.fetchAndProcessIngestionFeed(customTopics: activeTopics);
    if (newIngestedCards.isNotEmpty) {
      state = [...newIngestedCards, ...state];

      for (final card in newIngestedCards) {
        await FirestoreService.publishIngestedArticle(card);
      }
    }

    ref.read(isRefreshingFeedProvider.notifier).state = false;
  }

  void setFeedback(String cardId, String feedbackType) {
    state = [
      for (final card in state)
        if (card.id == cardId)
          card.copyWith(userFeedback: card.userFeedback == feedbackType ? null : feedbackType)
        else
          card
    ];

    // Async sync to Firestore if user signed in
    final user = FirebaseService.currentUser;
    if (user != null) {
      final role = ref.read(selectedRoleProvider);
      final channels = ref.read(followedChannelsProvider);
      final relevance = ref.read(relevanceLevelProvider);
      final quiet = ref.read(quietHoursProvider);
      FirestoreService.syncPreferences(
        user.uid,
        selectedRole: role,
        followedChannels: channels,
        relevanceLevel: relevance,
        quietHours: quiet,
      );
    }
  }

  void muteCard(String cardId) {
    state = state.where((c) => c.id != cardId).toList();
  }
}

final intelligenceCardsProvider = StateNotifierProvider<CardsNotifier, List<IntelligenceCard>>((ref) {
  return CardsNotifier(ref);
});

// Role Filtered Cards Provider
final filteredCardsForRoleProvider = Provider<List<IntelligenceCard>>((ref) {
  final role = ref.watch(selectedRoleProvider);
  final cards = ref.watch(intelligenceCardsProvider);

  String reasonLabel = '✨ Because your active role is AI / ML Engineer';
  if (role == 'devops') {
    reasonLabel = '✨ Because your active role is DevOps & Cloud Infrastructure';
  } else if (role == 'finops') {
    reasonLabel = '✨ Because your active role is FinOps Consultant';
  } else if (role == 'arch' || role == 'architect') {
    reasonLabel = '✨ Because your active role is Software Systems Architect';
  }

  final filtered = cards.where((card) {
    if (role == 'devops') {
      return card.channelId == 'cloud_infra' ||
          card.headline.toLowerCase().contains('kubernetes') ||
          card.headline.toLowerCase().contains('terraform') ||
          card.headline.toLowerCase().contains('cloud');
    }
    if (role == 'finops') {
      return card.headline.toLowerCase().contains('finops') ||
          card.headline.toLowerCase().contains('cost') ||
          card.headline.toLowerCase().contains('billing') ||
          card.summary.toLowerCase().contains('spend');
    }
    if (role == 'arch' || role == 'architect') {
      return card.channelId == 'dev_tools' ||
          card.headline.toLowerCase().contains('architecture') ||
          card.headline.toLowerCase().contains('microservices') ||
          card.headline.toLowerCase().contains('rust') ||
          card.headline.toLowerCase().contains('wasm');
    }
    // Default 'ai_ml':
    return card.channelId == 'ai_tools' ||
        card.channelId == 'gpus_hw' ||
        card.headline.toLowerCase().contains('deepseek') ||
        card.headline.toLowerCase().contains('gemini') ||
        card.headline.toLowerCase().contains('nvidia') ||
        card.headline.toLowerCase().contains('model');
  }).toList();

  return filtered.map((card) {
    return card.copyWith(
      transparencyReason: reasonLabel,
    );
  }).toList();
});

// Gemini Chat Messages Notifier with Live Gemini API Streaming
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;

  ChatNotifier(this.ref)
      : super([
          ChatMessage(
            id: 'msg-1',
            sender: 'assistant',
            text: '### 👋 Welcome to Live Gemini Agent\n\nI am your **Gemini Enterprise Agent** in BytePulse AI. I deliver real-time technical analysis grounded in your developer feeds.\n\n• Ask about high-throughput GPU inference & FP8 quantization.\n• Synthesize system architecture trade-offs & security alerts.\n• Generate PyTorch / vLLM benchmark scripts.',
            confidence: '99.4%',
            citations: ['Hacker News Thread', 'Google Cloud Release Notes'],
            suggestedTopic: 'DeepSeek Distillation Architecture',
          ),
        ]);

  Future<void> sendUserQuery(String promptText) async {
    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: promptText,
    );
    state = [...state, userMsg];

    // Stream response from GeminiService
    ref.read(isStreamingProvider.notifier).state = true;
    final groundedCard = ref.read(groundedCardProvider);
    final contextTitle = ref.read(groundedContextProvider);

    final assistantMsgId = 'msg-${DateTime.now().millisecondsSinceEpoch + 1}';

    String derivedTopic;
    final lower = promptText.toLowerCase();
    if (lower.contains('deepseek') || lower.contains('reasoning')) {
      derivedTopic = 'DeepSeek Distillation Architecture';
    } else if (lower.contains('code') || lower.contains('rust') || lower.contains('wasm')) {
      derivedTopic = 'Rust WASM Micro-Runtimes';
    } else if (lower.contains('gpu') || lower.contains('nvidia') || lower.contains('blackwell')) {
      derivedTopic = 'NVIDIA Blackwell & NVLink 5';
    } else if (lower.contains('vllm')) {
      derivedTopic = 'vLLM Performance';
    } else {
      derivedTopic = promptText.length > 28 ? '${promptText.substring(0, 25)}...' : promptText;
    }

    var assistantMsg = ChatMessage(
      id: assistantMsgId,
      sender: 'assistant',
      text: '',
      confidence: '99.2%',
      citations: [
        if (groundedCard != null) groundedCard.source else 'BytePulse AI Index',
        'Gemini 3.6 Flash API',
      ],
      suggestedTopic: derivedTopic,
    );

    state = [...state, assistantMsg];

    final conversationHistory = List<ChatMessage>.from(state.where((m) => m.id != assistantMsgId));

    final geminiService = GeminiService();
    final stream = geminiService.streamGeminiResponse(
      prompt: promptText,
      groundedCard: groundedCard,
      customContextTitle: contextTitle,
      history: conversationHistory,
    );

    var currentAccumulatedText = '';
    String? extractedCode;

    await for (final chunk in stream) {
      if (chunk.contains('CODE_BLOCK_MARKER:')) {
        final parts = chunk.split('CODE_BLOCK_MARKER:');
        currentAccumulatedText += parts[0];
        if (parts.length > 1) {
          extractedCode = parts[1].replaceAll('*AI-generated analysis may contain errors. Verify critical technical decisions.*', '').trim();
        }
      } else {
        currentAccumulatedText += chunk;
      }

      state = [
        for (final msg in state)
          if (msg.id == assistantMsgId)
            msg.copyWith(saved: msg.saved, suggestedTopic: derivedTopic).let((m) => ChatMessage(
                  id: m.id,
                  sender: m.sender,
                  text: currentAccumulatedText,
                  confidence: m.confidence,
                  citations: m.citations,
                  codeSnippet: extractedCode ?? m.codeSnippet,
                  saved: m.saved,
                  suggestedTopic: derivedTopic,
                ))
          else
            msg
      ];
    }

    ref.read(isStreamingProvider.notifier).state = false;
  }

  void toggleSave(String msgId) {
    state = [
      for (final msg in state)
        if (msg.id == msgId) msg.copyWith(saved: true) else msg
    ];
  }
}

extension LetExtension<T> on T {
  R let<R>(R Function(T it) op) => op(this);
}

final chatMessagesProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});

// Alerts Relevance Slider
final relevanceLevelProvider = StateProvider<double>((ref) => 2.0);
final quietHoursProvider = StateProvider<bool>((ref) => false);

// Saved Library Notifier with Firestore Integration
class SavedLibraryNotifier extends StateNotifier<List<SavedItem>> {
  SavedLibraryNotifier()
      : super([
          SavedItem(
            id: 'lib-1',
            type: 'gemini_answer',
            title: 'Optimal Quantization Script for QLoRA 4-bit Models',
            snippet: 'import bitsandbytes as bnb\nfrom transformers import AutoModelForCausalLM...',
            savedAt: '2 hours ago',
            source: 'Live Gemini Session',
          ),
          SavedItem(
            id: 'lib-2',
            type: 'article',
            title: 'DeepSeek-R1 Distillation & Open Reasoning Swarms Benchmark Analysis',
            snippet: 'Distilled 14B and 32B parameters achieve 94% parity...',
            savedAt: 'Yesterday',
            source: 'Personalized For You Feed',
          ),
        ]);

  void addItem(SavedItem item, {IntelligenceCard? originalCard}) {
    state = [item, ...state];

    // Async sync to Firestore if user signed in
    final user = FirebaseService.currentUser;
    if (user != null && originalCard != null) {
      FirestoreService.saveArticle(user.uid, originalCard);
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();

    // Async delete from Firestore if user signed in
    final user = FirebaseService.currentUser;
    if (user != null) {
      FirestoreService.deleteSavedArticle(user.uid, id);
    }
  }

  Future<void> loadCloudSavedArticles(String userId) async {
    final cloudItems = await FirestoreService.fetchSavedArticles(userId);
    if (cloudItems.isNotEmpty) {
      state = [...cloudItems, ...state];
    }
  }
}

final savedLibraryProvider = StateNotifierProvider<SavedLibraryNotifier, List<SavedItem>>((ref) {
  return SavedLibraryNotifier();
});
