import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ai_glow_theme.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  bool isGrid = true;
  String activeCategory = 'ALL';
  String searchQuery = '';

  final List<Channel> channels = [
    Channel(
      id: 'ai_tools',
      name: 'New AI Tools & Agents',
      followers: '142k',
      tag: 'AI',
      isFollowed: true,
      trending: 'Agentic Workflows in Rust & WASM',
    ),
    Channel(
      id: 'gpus_hw',
      name: 'Datacenter GPUs & Hardware',
      followers: '98k',
      tag: 'Hardware',
      isFollowed: true,
      trending: 'B200 Blackwell HBM3e Memory Specs',
    ),
    Channel(
      id: 'cloud_infra',
      name: 'Cloud & Infra',
      followers: '115k',
      tag: 'Cloud',
      isFollowed: true,
      trending: 'Kubernetes 1.31 Auto-Scaling Optimizations',
    ),
    Channel(
      id: 'cybersec',
      name: 'Cybersecurity',
      followers: '89k',
      tag: 'Security',
      isFollowed: false,
      trending: 'Zero-Day Memory Safety Protections in C++',
    ),
    Channel(
      id: 'dev_tools',
      name: 'Dev Tools',
      followers: '160k',
      tag: 'Tools',
      isFollowed: true,
      trending: 'Vite 6 Server Actions Engine Benchmark',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final followedChannels = ref.watch(followedChannelsProvider);

    final filtered = channels.where((ch) {
      if (activeCategory != 'ALL' && ch.tag != activeCategory) return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        return ch.name.toLowerCase().contains(q) || ch.trending.toLowerCase().contains(q);
      }
      return true;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Explore Channels Hub',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AIGlowColors.inkSlate,
                ),
              ),
              const Text(
                'Follow intelligence vectors & stream breaking updates.',
                style: TextStyle(fontSize: 12, color: AIGlowColors.mediumSlate),
              ),
              const SizedBox(height: 12),

              // My Followed Topics & Custom Feeds Section
              Consumer(
                builder: (context, ref, child) {
                  final customTopics = ref.watch(customTopicsProvider);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AIGlowColors.cardWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AIGlowColors.softBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(139, 92, 246, 0.04),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Flexible(
                              child: Row(
                                children: [
                                  Icon(Icons.rss_feed, size: 16, color: AIGlowColors.electricCyan),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'My Custom Feeds & Followed Topics',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => _showAddTopicDialog(context, ref),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AIGlowColors.electricCyan.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.add, size: 12, color: AIGlowColors.electricCyan),
                                    SizedBox(width: 2),
                                    Text(
                                      'Add Topic',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AIGlowColors.electricCyan),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (customTopics.isEmpty)
                          const Text(
                            'No custom topics added. Tap "+ Add Topic" or save from Gemini Chat.',
                            style: TextStyle(fontSize: 11, color: AIGlowColors.mediumSlate),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: customTopics.map((topic) {
                              return Chip(
                                avatar: const Icon(Icons.star_rate, size: 12, color: AIGlowColors.hyperViolet),
                                label: Text(
                                  topic.name,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 12, color: AIGlowColors.mediumSlate),
                                onDeleted: () {
                                  ref.read(customTopicsProvider.notifier).removeTopic(topic.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Removed "${topic.name}" from Custom Feeds')),
                                  );
                                },
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AIGlowColors.softBorder),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // Search Field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search channels, topics, technologies...',
                  prefixIcon: const Icon(Icons.search, color: AIGlowColors.mediumSlate),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AIGlowColors.softBorder),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Toolbar: Category Chips & Grid/List View Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('ALL', 'All'),
                        _buildCategoryChip('AI', 'AI & Agents'),
                        _buildCategoryChip('Hardware', 'GPUs & HW'),
                        _buildCategoryChip('Cloud', 'Cloud'),
                        _buildCategoryChip('Security', 'Security'),
                      ],
                    ),
                  ),

                  // Grid/List toggle
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AIGlowColors.softBorder),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: Icon(Icons.grid_view,
                              size: 18, color: isGrid ? AIGlowColors.electricCyan : AIGlowColors.mediumSlate),
                          onPressed: () => setState(() => isGrid = true),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(4),
                          icon: Icon(Icons.list,
                              size: 18, color: !isGrid ? AIGlowColors.electricCyan : AIGlowColors.mediumSlate),
                          onPressed: () => setState(() => isGrid = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Channels Grid/List View
              Expanded(
                child: isGrid
                    ? GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildChannelCard(filtered[index], followedChannels);
                        },
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: _buildChannelCard(filtered[index], followedChannels),
                          );
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

  Widget _buildCategoryChip(String id, String label) {
    final isSelected = activeCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AIGlowColors.electricCyan.withOpacity(0.15),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AIGlowColors.electricCyan : AIGlowColors.softBorder,
        ),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AIGlowColors.electricCyan : AIGlowColors.inkSlate,
        ),
        onSelected: (selected) {
          if (selected) setState(() => activeCategory = id);
        },
      ),
    );
  }

  Widget _buildChannelCard(Channel ch, Set<String> followedSet) {
    final isFollowing = followedSet.contains(ch.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AIGlowColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AIGlowColors.softBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(139, 92, 246, 0.05),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AIGlowColors.electricCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    ch.name[0],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AIGlowColors.electricCyan,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  final set = Set<String>.from(followedSet);
                  if (isFollowing) {
                    set.remove(ch.id);
                  } else {
                    set.add(ch.id);
                  }
                  ref.read(followedChannelsProvider.notifier).state = set;
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFollowing
                        ? AIGlowColors.emeraldMint.withOpacity(0.12)
                        : AIGlowColors.electricCyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isFollowing ? AIGlowColors.emeraldMint : AIGlowColors.electricCyan,
                    ),
                  ),
                  child: Text(
                    isFollowing ? '✓ Following' : '+ Follow',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isFollowing ? AIGlowColors.emeraldMint : AIGlowColors.electricCyan,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text(
            ch.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AIGlowColors.inkSlate,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${ch.followers} Subscribers • ${ch.tag}',
            style: const TextStyle(fontSize: 10, color: AIGlowColors.mediumSlate),
          ),
          const SizedBox(height: 6),

          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AIGlowColors.iceWhite,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AIGlowColors.softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔥 TOP TRENDING',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: AIGlowColors.amberWarning,
                  ),
                ),
                Text(
                  ch.trending,
                  style: const TextStyle(fontSize: 10, color: AIGlowColors.mediumSlate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTopicDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final rssController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_circle, color: AIGlowColors.electricCyan),
              SizedBox(width: 8),
              Text('Add Custom Feed Topic', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Topic Name (e.g. PyTorch 2.4, Quantum)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rssController,
                decoration: InputDecoration(
                  labelText: 'Optional RSS / Atom Feed URL',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AIGlowColors.mediumSlate)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AIGlowColors.electricCyan,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final topicTitle = titleController.text.trim();
                if (topicTitle.isNotEmpty) {
                  final newTopic = CustomTopic(
                    id: 'topic-${DateTime.now().millisecondsSinceEpoch}',
                    name: topicTitle,
                    keywords: [topicTitle.toLowerCase()],
                    rssUrl: rssController.text.trim().isNotEmpty ? rssController.text.trim() : null,
                    addedAt: 'Manually Added',
                  );
                  ref.read(customTopicsProvider.notifier).addTopic(newTopic);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('➕ Custom feed "$topicTitle" added and synced to Firestore!'),
                      backgroundColor: AIGlowColors.electricCyan,
                    ),
                  );
                }
              },
              child: const Text('Save Feed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
