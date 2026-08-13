import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/ai_glow_theme.dart';
import '../models/app_models.dart';
import '../providers/app_providers.dart';

class ArticleDetailSheet extends ConsumerWidget {
  final IntelligenceCard card;

  const ArticleDetailSheet({
    super.key,
    required this.card,
  });

  static void show(BuildContext context, IntelligenceCard card) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: ArticleDetailSheet(card: card),
      ),
    );
  }

  Future<void> _launchSourceUrl(BuildContext context, String rawUrl) async {
    try {
      String targetUrl = rawUrl.trim();

      // Determine default parent feed URL based on source domain
      String parentFeedUrl = 'https://news.ycombinator.com';
      if (targetUrl.contains('cloud.google.com')) {
        parentFeedUrl = 'https://cloud.google.com/blog';
      } else if (targetUrl.contains('aws.amazon.com')) {
        parentFeedUrl = 'https://aws.amazon.com/blogs/aws';
      } else if (targetUrl.contains('github.blog')) {
        parentFeedUrl = 'https://github.blog';
      } else if (targetUrl.contains('ycombinator.com')) {
        parentFeedUrl = 'https://news.ycombinator.com';
      }

      // Check if URL is invalid, an XML/feed endpoint, or mock format
      bool isMockOrInvalid = targetUrl.isEmpty ||
          !targetUrl.startsWith('http') ||
          targetUrl.endsWith('.xml') ||
          targetUrl.contains('/feed') ||
          targetUrl.contains('/rss') ||
          targetUrl.contains('mock');

      if (isMockOrInvalid) {
        targetUrl = parentFeedUrl;
      }

      final Uri uri = Uri.parse(targetUrl);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (launched) return;
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }

    if (!context.mounted) return;

    // Display friendly alert dialog if URL is invalid or unavailable
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AIGlowColors.electricCyan),
            SizedBox(width: 8),
            Text('Source Notice', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Original source link unavailable in preview mode',
          style: TextStyle(fontSize: 13, color: AIGlowColors.inkSlate),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final parentUri = Uri.parse('https://news.ycombinator.com');
              if (await canLaunchUrl(parentUri)) {
                await launchUrl(parentUri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text('Open Parent Feed', style: TextStyle(color: AIGlowColors.electricCyan, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AIGlowColors.mediumSlate)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: AIGlowColors.cardWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle Pill
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AIGlowColors.mediumSlate.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Modal Title Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'INTELLIGENCE DEEPDIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AIGlowColors.electricCyan,
                    letterSpacing: 0.8,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AIGlowColors.mediumSlate),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AIGlowColors.softBorder),

          // Scrollable Article Details
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Credibility & Source Badge Row
                  Row(
                    children: [
                      _buildCredibilityBadge(card.credibilityType, card.source),
                      const SizedBox(width: 8),
                      Text(
                        '• ${card.readTime}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AIGlowColors.mediumSlate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Headline
                  Text(
                    card.headline,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AIGlowColors.inkSlate,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Transparency Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AIGlowColors.electricCyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AIGlowColors.electricCyan.withOpacity(0.2)),
                    ),
                    child: Text(
                      card.transparencyReason,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AIGlowColors.electricCyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Technical Executive Summary Paragraph
                  const Text(
                    'EXECUTIVE SUMMARY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AIGlowColors.mediumSlate,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.summary,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AIGlowColors.inkSlate,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bulleted Key Architectural Takeaways
                  const Text(
                    'KEY ARCHITECTURAL TAKEAWAYS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AIGlowColors.mediumSlate,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: card.takeaways.map((takeaway) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AIGlowColors.electricCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                takeaway,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AIGlowColors.inkSlate,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Community Sentiment Pills
                  const Text(
                    'COMMUNITY SENTIMENT & TRADE-OFFS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AIGlowColors.mediumSlate,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildSentimentPill(card.pros, true),
                      _buildSentimentPill(card.cons, false),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Open Original Web Source Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text('Open Original Web Source (${card.source})'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                      foregroundColor: AIGlowColors.inkSlate,
                      side: const BorderSide(color: AIGlowColors.softBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _launchSourceUrl(context, card.url);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Prominent Iridescent "Ask Live Gemini" Button
                  GestureDetector(
                    onTap: () {
                      ref.read(groundedCardProvider.notifier).state = card;
                      ref.read(groundedContextProvider.notifier).state = '${card.headline} (${card.source})';
                      Navigator.pop(context); // Close bottom sheet modal
                      ref.read(activeTabProvider.notifier).state = 2; // Jump to Gemini Tab
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: AIGlowColors.iridescentGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(6, 182, 212, 0.35),
                            blurRadius: 14,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Ask Live Gemini About This Article',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
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
          Text(
            source,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentPill(String text, bool isPro) {
    final color = isPro ? AIGlowColors.emeraldMint : AIGlowColors.roseCritical;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
