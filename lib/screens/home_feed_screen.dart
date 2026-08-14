import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ai_glow_theme.dart';
import '../providers/app_providers.dart';
import '../widgets/article_card.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  bool isSearching = false;
  String searchQuery = '';

  String _getRoleTitle(String roleKey) {
    switch (roleKey) {
      case 'devops':
        return 'DevOps & Cloud Infrastructure';
      case 'finops':
        return 'FinOps & Cloud Cost Optimization';
      case 'arch':
        return 'Software Systems Architect';
      case 'ai_ml':
      default:
        return 'Senior AI / ML Engineer';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = ref.watch(selectedRoleProvider);
    final roleCards = ref.watch(filteredCardsForRoleProvider);
    final firestoreStream = ref.watch(liveFirestoreStreamProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final isRefreshing = ref.watch(isRefreshingFeedProvider);
    final authState = ref.watch(authUserProvider);
    final demoUser = ref.watch(demoUserProvider);
    final userProfile = ref.watch(userProfileProvider);

    final user = authState.value ?? FirebaseService.currentUser;
    final String displayName = userProfile?.displayName ?? demoUser?.displayName ?? user?.displayName ?? 'Developer';
    final String photoUrl = userProfile?.photoUrl ?? demoUser?.photoUrl ?? user?.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80';

    // Merge live Firestore stream articles with role cards without duplicates
    final List<IntelligenceCard> cloudArticles = firestoreStream.value ?? [];
    final Map<String, IntelligenceCard> cardMap = {};
    for (final card in roleCards) {
      cardMap[card.id] = card;
    }
    for (final card in cloudArticles) {
      if (!cardMap.containsKey(card.id)) {
        cardMap[card.id] = card;
      }
    }
    final allCards = cardMap.values.toList();

    final filteredCards = searchQuery.isEmpty
        ? allCards
        : allCards.where((c) {
            final q = searchQuery.toLowerCase();
            return c.headline.toLowerCase().contains(q) ||
                c.summary.toLowerCase().contains(q) ||
                c.transparencyReason.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Top Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // User Avatar & Dynamic Role Title
                      Expanded(
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AIGlowColors.electricCyan, width: 2),
                                ),
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person, color: AIGlowColors.electricCyan, size: 20);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back, $displayName',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AIGlowColors.inkSlate,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _getRoleTitle(activeRole),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AIGlowColors.electricCyan,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                  // Actions: Refresh Feed, Search Toggle & Bookmarks
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AIGlowColors.electricCyan),
                        tooltip: 'Ingest Live RSS & Firestore Feed',
                        onPressed: () {
                          ref.read(intelligenceCardsProvider.notifier).ingestNewFeed();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ingesting RSS feeds & syncing Firestore...')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.search, color: AIGlowColors.mediumSlate),
                        onPressed: () {
                          setState(() {
                            isSearching = !isSearching;
                            if (!isSearching) searchQuery = '';
                          });
                        },
                      ),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.bookmark_border, color: AIGlowColors.mediumSlate),
                            onPressed: () {
                              ref.read(activeTabProvider.notifier).state = 4; // Profile tab
                            },
                          ),
                          if (bookmarks.isNotEmpty)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AIGlowColors.electricCyan,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${bookmarks.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Live Refreshing Indicator Banner
              if (isRefreshing) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AIGlowColors.electricCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AIGlowColors.electricCyan),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AIGlowColors.electricCyan),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Automated AI Ingestion & Firestore Syncing in Progress...',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AIGlowColors.electricCyan),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Search Field (If active)
              if (isSearching) ...[
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search web news, release notes, benchmarks...',
                    prefixIcon: const Icon(Icons.search, color: AIGlowColors.mediumSlate),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AIGlowColors.softBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AIGlowColors.electricCyan),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val;
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],

              // Feed List with Pull to Refresh
              Expanded(
                child: RefreshIndicator(
                  color: AIGlowColors.electricCyan,
                  onRefresh: () async {
                    await ref.read(intelligenceCardsProvider.notifier).ingestNewFeed();
                  },
                  child: filteredCards.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredCards.length,
                          itemBuilder: (context, index) {
                            final card = filteredCards[index];
                            return ArticleCard(card: card);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AIGlowColors.inkSlate.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, size: 28, color: AIGlowColors.mediumSlate),
          ),
          const SizedBox(height: 12),
          const Text(
            'No Intelligence Found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
          ),
          const SizedBox(height: 4),
          Text(
            'No card matches "$searchQuery". Try clearing filters.',
            style: const TextStyle(fontSize: 12, color: AIGlowColors.mediumSlate),
          ),
        ],
      ),
    );
  }
}
