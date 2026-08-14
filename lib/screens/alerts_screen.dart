import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ai_glow_theme.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';
import '../widgets/article_detail_sheet.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  bool isDrawerOpen = false;
  String selectedFreq = 'instant';

  final List<AlertItem> alerts = [
    AlertItem(
      id: 'alt-1',
      title: 'CRITICAL: Zero-Day Memory Leak in vLLM Async Engine v0.6.0',
      body: 'Official security alert: heap corruption vulnerability detected when handling concurrent streaming websocket connections. Upgrade to v0.6.1 immediately.',
      time: '5m ago',
      source: 'Official • Cybersecurity Advisory',
      severity: 'critical',
    ),
    AlertItem(
      id: 'alt-2',
      title: 'NEW MODEL RELEASE: Claude 3.5 Sonnet v2 Available on Vertex AI',
      body: 'Verified release notes: Improved coding capabilities and 200k context window now deployed in us-central1 region.',
      time: '1h ago',
      source: 'Official • Cloud Release Notes',
      severity: 'high',
    ),
    AlertItem(
      id: 'alt-3',
      title: 'AWS US-East-1 EC2 P5 Instance Fleet Expansion',
      body: 'Technical update: Additional H100 capacity available for reserved instances in N. Virginia availability zones.',
      time: '3h ago',
      source: 'Verified • Cloud & Infra',
      severity: 'info',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final relevance = ref.watch(relevanceLevelProvider);
    final quietHours = ref.watch(quietHoursProvider);
    final allCards = ref.watch(intelligenceCardsProvider);

    List<AlertItem> filteredAlerts = alerts;
    if (relevance == 1.0) {
      filteredAlerts = alerts.where((a) => a.severity == 'critical').toList();
    } else if (relevance == 2.0) {
      filteredAlerts = alerts.where((a) => a.severity == 'critical' || a.severity == 'high').toList();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Alerts & Relevance Engine',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AIGlowColors.inkSlate,
                    ),
                  ),
                  const Text(
                    'Configure live push threshold & tap alerts to read intelligence.',
                    style: TextStyle(fontSize: 12, color: AIGlowColors.mediumSlate),
                  ),
                  const SizedBox(height: 16),

                  // Relevance Slider Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AIGlowColors.cardWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AIGlowColors.softBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(139, 92, 246, 0.08),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.bolt, color: AIGlowColors.electricCyan, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Relevance Filter Engine',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AIGlowColors.electricCyan,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AIGlowColors.emeraldMint.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'LIVE ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AIGlowColors.emeraldMint,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Slider
                        Slider(
                          value: relevance,
                          min: 1.0,
                          max: 3.0,
                          divisions: 2,
                          activeColor: AIGlowColors.electricCyan,
                          inactiveColor: AIGlowColors.softBorder,
                          onChanged: (val) {
                            ref.read(relevanceLevelProvider.notifier).state = val;
                          },
                        ),

                        // Labels
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Only Critical (CVEs)', style: TextStyle(fontSize: 10, color: AIGlowColors.mediumSlate)),
                            Text('Balanced (Rec)', style: TextStyle(fontSize: 10, color: AIGlowColors.electricCyan, fontWeight: FontWeight.bold)),
                            Text('Everything', style: TextStyle(fontSize: 10, color: AIGlowColors.mediumSlate)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Text(
                          _getRelevanceDesc(relevance),
                          style: const TextStyle(fontSize: 11, color: AIGlowColors.mediumSlate, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notification Delivery Preferences (Expandable)
                  Container(
                    decoration: BoxDecoration(
                      color: AIGlowColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AIGlowColors.softBorder),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => isDrawerOpen = !isDrawerOpen),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.tune, color: AIGlowColors.inkSlate, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Delivery Preferences & Quiet Hours',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
                                    ),
                                  ],
                                ),
                                Icon(
                                  isDrawerOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: AIGlowColors.mediumSlate,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isDrawerOpen) ...[
                          const Divider(height: 1, color: AIGlowColors.softBorder),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Quiet Hours (10 PM - 7 AM)',
                                      style: TextStyle(fontSize: 12, color: AIGlowColors.mediumSlate),
                                    ),
                                    Switch(
                                      value: quietHours,
                                      activeColor: AIGlowColors.emeraldMint,
                                      onChanged: (val) {
                                        ref.read(quietHoursProvider.notifier).state = val;
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildFreqButton('instant', 'Instant'),
                                    _buildFreqButton('hourly', 'Hourly Digest'),
                                    _buildFreqButton('daily', 'Daily Summary'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivered Alerts Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Delivered Push Notifications',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
                      ),
                      Text(
                        '${filteredAlerts.length} items • Tap to read details',
                        style: const TextStyle(fontSize: 11, color: AIGlowColors.mediumSlate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Alerts History List
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredAlerts.length,
                      itemBuilder: (context, index) {
                        final item = filteredAlerts[index];
                        return _buildAlertCard(item, allCards);
                      },
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

  String _getRelevanceDesc(double level) {
    if (level == 1.0) {
      return '🔒 Only Critical Mode: Delivers zero-day CVE security advisories and critical outages only.';
    }
    if (level == 2.0) {
      return '⚡ Balanced Recommended Mode: Delivers critical security alerts plus high-impact AI model releases.';
    }
    return '📡 Everything I Follow Mode: Unfiltered live stream of all updates across followed channels.';
  }

  Widget _buildFreqButton(String id, String label) {
    final isSelected = selectedFreq == id;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AIGlowColors.electricCyan,
      backgroundColor: AIGlowColors.iceWhite,
      labelStyle: TextStyle(
        fontSize: 10,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AIGlowColors.inkSlate,
      ),
      onSelected: (selected) {
        if (selected) setState(() => selectedFreq = id);
      },
    );
  }

  Widget _buildAlertCard(AlertItem item, List<IntelligenceCard> allCards) {
    Color sideColor;
    if (item.severity == 'critical') {
      sideColor = AIGlowColors.roseCritical;
    } else if (item.severity == 'high') {
      sideColor = AIGlowColors.amberWarning;
    } else {
      sideColor = AIGlowColors.electricCyan;
    }

    final matchingCard = allCards.firstWhere(
      (c) => c.headline.toLowerCase().contains(item.title.split(':').last.trim().toLowerCase()) ||
             c.summary.toLowerCase().contains(item.title.split(':').last.trim().toLowerCase()),
      orElse: () => IntelligenceCard(
        id: item.id,
        headline: item.title,
        summary: item.body,
        credibilityType: item.severity == 'critical' ? CredibilityType.official : CredibilityType.verified,
        source: item.source,
        readTime: '2 min read',
        transparencyReason: 'Delivered via Push Relevance Engine',
        pros: 'Immediate operational awareness & mitigation baseline',
        cons: 'Requires production health verification',
        channelId: 'cloud_infra',
        groundedContext: item.title,
        url: 'https://news.ycombinator.com',
        takeaways: [
          item.body,
          'Verified via BytePulse Automated Relevance Dispatch.',
          'Review configuration before pushing emergency rollout.',
        ],
      ),
    );

    return InkWell(
      onTap: () => ArticleDetailSheet.show(context, matchingCard),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AIGlowColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AIGlowColors.softBorder),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(139, 92, 246, 0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: sideColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.source,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AIGlowColors.mediumSlate),
                      ),
                      Text(
                        item.time,
                        style: const TextStyle(fontSize: 10, color: AIGlowColors.mediumSlate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: const TextStyle(fontSize: 11, color: AIGlowColors.mediumSlate),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.menu_book, size: 12, color: AIGlowColors.electricCyan),
                      SizedBox(width: 4),
                      Text(
                        'Tap to read full intelligence & ask Gemini',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AIGlowColors.electricCyan),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
