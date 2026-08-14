import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../theme/ai_glow_theme.dart';
import '../providers/app_providers.dart';
import '../screens/article_detail_sheet.dart';

class ArticleCard extends ConsumerWidget {
  final IntelligenceCard card;

  const ArticleCard({super.key, required this.card});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.contains(card.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AIGlowColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AIGlowColors.softBorder, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(139, 92, 246, 0.06),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          ArticleDetailSheet.show(context, card);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transparency Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AIGlowColors.electricCyan.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AIGlowColors.electricCyan.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, size: 12, color: AIGlowColors.electricCyan),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        card.transparencyReason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AIGlowColors.electricCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Meta Row: Credibility Badge & Read Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: _buildCredibilityBadge(card.credibilityType, card.source),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 12, color: AIGlowColors.mediumSlate),
                      const SizedBox(width: 4),
                      Text(
                        card.readTime,
                        style: const TextStyle(fontSize: 11, color: AIGlowColors.mediumSlate),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Headline
              Text(
                card.headline,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AIGlowColors.inkSlate,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),

              // Summary
              Text(
                card.summary,
                style: const TextStyle(
                  fontSize: 13,
                  color: AIGlowColors.mediumSlate,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Sentiment Pills
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildSentimentPill(card.pros, true),
                  _buildSentimentPill(card.cons, false),
                ],
              ),
              const SizedBox(height: 12),

              const Divider(color: AIGlowColors.softBorder, height: 1),
              const SizedBox(height: 10),

              // Bottom Toolbar: Feedback + Ask Live Gemini
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Feedback Group
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFeedbackButton(
                        context,
                        ref,
                        icon: Icons.thumb_up_alt_outlined,
                        label: 'More',
                        isActive: card.userFeedback == 'liked',
                        activeColor: AIGlowColors.emeraldMint,
                        onTap: () {
                          ref.read(intelligenceCardsProvider.notifier).setFeedback(card.id, 'liked');
                          _showSnackBar(context, 'Updated algorithm: More like this');
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildFeedbackButton(
                        context,
                        ref,
                        icon: Icons.thumb_down_alt_outlined,
                        label: 'Less',
                        isActive: card.userFeedback == 'disliked',
                        activeColor: AIGlowColors.roseCritical,
                        onTap: () {
                          ref.read(intelligenceCardsProvider.notifier).setFeedback(card.id, 'disliked');
                          _showSnackBar(context, 'Updated algorithm: Less like this');
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildFeedbackButton(
                        context,
                        ref,
                        icon: Icons.visibility_off_outlined,
                        label: 'Mute',
                        isActive: false,
                        onTap: () {
                          ref.read(intelligenceCardsProvider.notifier).muteCard(card.id);
                          _showSnackBar(context, 'Topic muted from feed');
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildFeedbackButton(
                        context,
                        ref,
                        icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        label: isBookmarked ? 'Saved' : '',
                        isActive: isBookmarked,
                        activeColor: AIGlowColors.electricCyan,
                        onTap: () {
                          final set = ref.read(bookmarksProvider);
                          final newSet = Set<String>.from(set);
                          if (isBookmarked) {
                            newSet.remove(card.id);
                            ref.read(savedLibraryProvider.notifier).removeItem(card.id);
                            _showSnackBar(context, 'Removed from Bookmarks & Firestore');
                          } else {
                            newSet.add(card.id);
                            ref.read(savedLibraryProvider.notifier).addItem(
                                  SavedItem(
                                    id: card.id,
                                    type: 'article',
                                    title: card.headline,
                                    snippet: card.summary,
                                    savedAt: 'Just now',
                                    source: card.source,
                                  ),
                                  originalCard: card,
                                );
                            _showSnackBar(context, 'Saved to Bookmarks & Synced to Firestore');
                          }
                          ref.read(bookmarksProvider.notifier).state = newSet;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Iridescent "Ask Live Gemini" Trigger
              GestureDetector(
                onTap: () {
                  ref.read(groundedCardProvider.notifier).state = card;
                  ref.read(groundedContextProvider.notifier).state = '${card.headline} (${card.source})';
                  ref.read(activeTabProvider.notifier).state = 2; // Jump to Gemini Tab
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: AIGlowColors.iridescentGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(6, 182, 212, 0.35),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Ask Live Gemini',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildCredibilityBadge(CredibilityType type, String source) {
    Color bg;
    Color border;
    Color text;

    switch (type) {
      case CredibilityType.official:
        bg = const Color(0xFF0284C7).withOpacity(0.12);
        border = const Color(0xFF0284C7).withOpacity(0.3);
        text = const Color(0xFF0284C7);
        break;
      case CredibilityType.analysis:
        bg = AIGlowColors.hyperViolet.withOpacity(0.12);
        border = AIGlowColors.hyperViolet.withOpacity(0.3);
        text = AIGlowColors.hyperViolet;
        break;
      case CredibilityType.speculation:
        bg = AIGlowColors.amberWarning.withOpacity(0.12);
        border = AIGlowColors.amberWarning.withOpacity(0.3);
        text = AIGlowColors.amberWarning;
        break;
      case CredibilityType.verified:
        bg = AIGlowColors.emeraldMint.withOpacity(0.12);
        border = AIGlowColors.emeraldMint.withOpacity(0.3);
        text = AIGlowColors.emeraldMint;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 12, color: text),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentPill(String text, bool isPro) {
    final color = isPro ? AIGlowColors.emeraldMint : AIGlowColors.roseCritical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }

  Widget _buildFeedbackButton(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required bool isActive,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final color = isActive ? (activeColor ?? AIGlowColors.electricCyan) : AIGlowColors.mediumSlate;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AIGlowColors.inkSlate,
      ),
    );
  }
}
