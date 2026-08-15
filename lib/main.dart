import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/ai_glow_theme.dart';
import 'providers/app_providers.dart';
import 'services/firebase_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_feed_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/gemini_agent_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Safe Firebase Initialization with Offline/Mock Mode Fallback
  try {
    await FirebaseService.initializeFirebase();
  } catch (e) {
    debugPrint("Firebase main initialization caught safely: $e");
  }

  runApp(const ProviderScope(child: BytePulseApp()));
}

class BytePulseApp extends StatelessWidget {
  const BytePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BytePulse AI — Developer Intelligence Suite',
      debugShowCheckedModeBanner: false,
      theme: AIGlowTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends ConsumerWidget {
  const MainNavigationShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final isOnboardingOpen = ref.watch(isOnboardingOpenProvider);

    final screens = [
      const HomeFeedScreen(),
      const ExploreScreen(),
      const GeminiAgentScreen(),
      const AlertsScreen(),
      const ProfileScreen(),
    ];

    return Stack(
      children: [
        Scaffold(
          extendBody: true,
          body: SizedBox.expand(
            child: IndexedStack(
              index: activeTab,
              children: screens,
            ),
          ),

          // Modern Level Bottom Navigation Bar
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              border: const Border(
                top: BorderSide(color: AIGlowColors.softBorder, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SizedBox(
                    height: 62,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(context, ref, index: 0, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
                        _buildNavItem(context, ref, index: 1, icon: Icons.explore_outlined, activeIcon: Icons.explore_rounded, label: 'Explore'),
                        _buildNavItem(
                          context,
                          ref,
                          index: 2,
                          icon: Icons.smart_toy_outlined,
                          activeIcon: Icons.smart_toy_rounded,
                          label: 'Ask BytePulse',
                          isAiPulse: true,
                        ),
                        _buildNavItem(context, ref, index: 3, icon: Icons.notifications_outlined, activeIcon: Icons.notifications_rounded, label: 'Alerts'),
                        _buildNavItem(context, ref, index: 4, icon: Icons.person_outline, activeIcon: Icons.person_rounded, label: 'Profile'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Screen 0: Cold-Start Onboarding Modal Overlay
        if (isOnboardingOpen) const OnboardingScreen(),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    bool isAiPulse = false,
  }) {
    final activeTab = ref.watch(activeTabProvider);
    final isActive = activeTab == index;
    final color = isActive ? AIGlowColors.electricCyan : AIGlowColors.mediumSlate;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(activeTabProvider.notifier).state = index;
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAiPulse)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: isActive ? AIGlowColors.centerFabGradient : null,
                    color: isActive ? null : AIGlowColors.electricCyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isActive
                        ? [
                            const BoxShadow(
                              color: Color.fromRGBO(6, 182, 212, 0.4),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? Colors.white : AIGlowColors.electricCyan,
                    size: 20,
                  ),
                )
              else
                Icon(isActive ? activeIcon : icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isAiPulse && isActive ? AIGlowColors.electricCyan : color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
