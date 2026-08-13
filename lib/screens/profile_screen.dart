import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ai_glow_theme.dart';
import '../providers/app_providers.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int activeSubTab = 0; // 0: Saved, 1: Taste, 2: Settings

  final Map<String, String> _rolesMap = {
    'ai_ml': 'AI / ML Engineer',
    'devops': 'DevOps & Cloud Engineer',
    'finops': 'FinOps Consultant',
    'arch': 'Software Systems Architect',
  };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authUserProvider);
    final demoUser = ref.watch(demoUserProvider);
    final fallbackSignedIn = ref.watch(googleAuthSignedInProvider);
    final savedItems = ref.watch(savedLibraryProvider);
    final followedChannels = ref.watch(followedChannelsProvider);
    final selectedRole = ref.watch(selectedRoleProvider);

    final user = authState.value ?? FirebaseService.currentUser;
    final bool isSignedIn = user != null || fallbackSignedIn || demoUser != null;
    final String displayName = demoUser?.displayName ?? user?.displayName ?? 'Test Developer';
    final String email = demoUser?.email ?? user?.email ?? 'dev@bytepulse.ai';
    final String? photoUrl = demoUser?.photoUrl ?? user?.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // User Profile & OAuth Header Card
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
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AIGlowColors.electricCyan, width: 2),
                            ),
                            child: photoUrl != null
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.person, color: AIGlowColors.electricCyan, size: 26),
                                  )
                                : const Icon(Icons.person, color: AIGlowColors.electricCyan, size: 26),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSignedIn ? displayName : 'Guest Developer',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                isSignedIn ? email : 'guest@bytepulse.ai',
                                style: const TextStyle(fontSize: 12, color: AIGlowColors.electricCyan, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    isSignedIn ? Icons.check_circle : Icons.offline_bolt_outlined,
                                    size: 11,
                                    color: isSignedIn ? AIGlowColors.emeraldMint : AIGlowColors.mediumSlate,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    demoUser != null
                                        ? 'Web Demo Session Active'
                                        : (user != null ? 'Google OAuth Connected' : 'Guest Mode (Local Sync)'),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSignedIn ? AIGlowColors.emeraldMint : AIGlowColors.mediumSlate,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AIGlowColors.softBorder),
                    const SizedBox(height: 12),
                    // Action Buttons Row
                    Row(
                      children: [
                        if (isSignedIn)
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.logout, size: 14),
                              label: const Text('Sign Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AIGlowColors.softBorder),
                                foregroundColor: AIGlowColors.roseCritical,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () async {
                                await FirebaseService.signOut();
                                ref.read(googleAuthSignedInProvider.notifier).state = false;
                                ref.read(demoUserProvider.notifier).state = null;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Signed out of developer session.'),
                                      backgroundColor: AIGlowColors.mediumSlate,
                                    ),
                                  );
                                }
                              },
                            ),
                          )
                        else ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.bolt, size: 14),
                              label: const Text('Demo / Test Sign In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AIGlowColors.electricCyan,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () {
                                final mockUser = FirebaseService.signInDemoUser(
                                  uid: 'demo-dev-101',
                                  displayName: 'Test Developer',
                                  email: 'dev@bytepulse.ai',
                                  photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80',
                                );
                                ref.read(demoUserProvider.notifier).state = DemoUser(
                                  uid: 'demo-dev-101',
                                  displayName: 'Test Developer',
                                  email: 'dev@bytepulse.ai',
                                  photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80',
                                );
                                ref.read(googleAuthSignedInProvider.notifier).state = true;
                                ref.read(savedLibraryProvider.notifier).loadCloudSavedArticles(mockUser.uid);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Signed in as Test Developer (Web Demo Auth active)'),
                                    backgroundColor: AIGlowColors.electricCyan,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.g_mobiledata, size: 18),
                              label: const Text('Sign in with Google', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AIGlowColors.softBorder),
                                foregroundColor: AIGlowColors.inkSlate,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                              onPressed: () async {
                                final cred = await FirebaseService.signInWithGoogle();
                                if (cred?.user != null) {
                                  ref.read(savedLibraryProvider.notifier).loadCloudSavedArticles(cred!.user!.uid);
                                } else {
                                  final mockUser = FirebaseService.signInDemoUser();
                                  ref.read(googleAuthSignedInProvider.notifier).state = true;
                                  ref.read(savedLibraryProvider.notifier).loadCloudSavedArticles(mockUser.uid);
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Sub-Tab Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AIGlowColors.softBorder),
                ),
                child: Row(
                  children: [
                    _buildSegmentBtn(0, 'Saved (${savedItems.length})'),
                    _buildSegmentBtn(1, 'Role & Vector'),
                    _buildSegmentBtn(2, 'Settings'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sub-tab Content
              Expanded(
                child: _buildSubTabContent(savedItems, followedChannels, selectedRole),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentBtn(int index, String label) {
    final isSelected = activeSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeSubTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? AIGlowColors.iridescentGradient : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : AIGlowColors.mediumSlate,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubTabContent(List savedItems, Set<String> followedChannels, String selectedRole) {
    if (activeSubTab == 0) {
      if (savedItems.isEmpty) {
        return const Center(
          child: Text('No saved items in your library.', style: TextStyle(color: AIGlowColors.mediumSlate)),
        );
      }
      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: savedItems.length,
        itemBuilder: (context, index) {
          final item = savedItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.cloud_done_outlined, size: 12, color: AIGlowColors.emeraldMint),
                        SizedBox(width: 4),
                        Text(
                          'Firestore Synced',
                          style: TextStyle(fontSize: 10, color: AIGlowColors.emeraldMint, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AIGlowColors.mediumSlate),
                      onPressed: () {
                        ref.read(savedLibraryProvider.notifier).removeItem(item.id);
                      },
                    ),
                  ],
                ),
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
                ),
                const SizedBox(height: 4),
                Text(
                  item.snippet,
                  style: const TextStyle(fontSize: 11, color: AIGlowColors.mediumSlate),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      );
    }

    if (activeSubTab == 1) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AIGlowColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AIGlowColors.softBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Primary Engineering Role Filter',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
            ),
            const SizedBox(height: 4),
            const Text(
              'Feed re-filters immediately in Riverpod and syncs selection to Firestore.',
              style: TextStyle(fontSize: 11, color: AIGlowColors.mediumSlate),
            ),
            const SizedBox(height: 12),
            Column(
              children: _rolesMap.entries.map((entry) {
                final isSelected = selectedRole == entry.key;
                return GestureDetector(
                  onTap: () {
                    ref.read(selectedRoleProvider.notifier).state = entry.key;
                    final user = FirebaseService.currentUser;
                    if (user != null) {
                      FirestoreService.syncPreferences(
                        user.uid,
                        selectedRole: entry.key,
                        followedChannels: followedChannels,
                        relevanceLevel: ref.read(relevanceLevelProvider),
                        quietHours: ref.read(quietHoursProvider),
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Switched active role to "${entry.value}". Feed re-filtered!'),
                        backgroundColor: AIGlowColors.electricCyan,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AIGlowColors.electricCyan.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AIGlowColors.electricCyan : AIGlowColors.softBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AIGlowColors.electricCyan : AIGlowColors.inkSlate,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, size: 16, color: AIGlowColors.electricCyan),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Re-Run Cold Start Setup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AIGlowColors.electricCyan,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ref.read(isOnboardingOpenProvider.notifier).state = true;
                },
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AIGlowColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AIGlowColors.softBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Theme & UI System',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
          ),
          SizedBox(height: 8),
          Text(
            'Currently active theme: AI Glow Light Theme (Aurora Glassmorphism)',
            style: TextStyle(fontSize: 12, color: AIGlowColors.mediumSlate),
          ),
          SizedBox(height: 16),
          ListTile(
            title: Text('High Contrast Mode'),
            trailing: Icon(Icons.chevron_right),
          ),
          ListTile(
            title: Text('AMOLED Dark Theme'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
