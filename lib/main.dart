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
          body: screens[activeTab],

          // Elevated Center Action FloatingActionButton for Gemini
          floatingActionButton: SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              onPressed: () {
                ref.read(activeTabProvider.notifier).state = 2; // Gemini tab
              },
              elevation: 4,
              shape: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AIGlowColors.centerFabGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(6, 182, 212, 0.45),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 26),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

          // iOS Cupertino Style Bottom Navigation Bar
          bottomNavigationBar: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            color: Colors.white,
            elevation: 10,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(context, ref, index: 0, icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
                      _buildNavItem(context, ref, index: 1, icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Explore'),
                      const SizedBox(width: 48), // Gap for center FAB
                      _buildNavItem(context, ref, index: 3, icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts'),
                      _buildNavItem(context, ref, index: 4, icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
                    ],
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
  }) {
    final activeTab = ref.watch(activeTabProvider);
    final isActive = activeTab == index;
    final color = isActive ? AIGlowColors.electricCyan : AIGlowColors.mediumSlate;

    return InkWell(
      onTap: () {
        ref.read(activeTabProvider.notifier).state = index;
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isActive ? activeIcon : icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
