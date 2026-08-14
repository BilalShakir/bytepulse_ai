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
    final userProfile = ref.watch(userProfileProvider);
    final fallbackSignedIn = ref.watch(googleAuthSignedInProvider);
    final savedItems = ref.watch(savedLibraryProvider);
    final followedChannels = ref.watch(followedChannelsProvider);
    final selectedRole = ref.watch(selectedRoleProvider);

    final user = authState.value ?? FirebaseService.currentUser;
    final bool isSignedIn = user != null || fallbackSignedIn || demoUser != null || userProfile != null;
    final String displayName = userProfile?.displayName ?? demoUser?.displayName ?? user?.displayName ?? 'Test Developer';
    final String email = userProfile?.email ?? demoUser?.email ?? user?.email ?? 'dev@bytepulse.ai';
    final String photoUrl = userProfile?.photoUrl ?? demoUser?.photoUrl ?? user?.photoURL ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80';

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
                            child: Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, color: AIGlowColors.electricCyan, size: 26),
                            ),
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
                              onPressed: () => _showAccountSelectorBottomSheet(context),
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
                              onPressed: () => _showAccountSelectorBottomSheet(context),
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

  void _showAccountSelectorBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AIGlowColors.cardWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: AuthWorkflowForm(
            onSuccess: (uid, name, email, role, photoUrl) {
              _authenticateAs(uid, name, email, role, photoUrl);
              Navigator.pop(modalContext);
            },
          ),
        );
      },
    );
  }

  void _authenticateAs(String uid, String name, String email, String role, String photoUrl) {
    final mockUser = FirebaseService.signInDemoUser(
      uid: uid,
      displayName: name,
      email: email,
      photoUrl: photoUrl,
    );
    ref.read(demoUserProvider.notifier).state = DemoUser(
      uid: uid,
      displayName: name,
      email: email,
      photoUrl: photoUrl,
    );
    ref.read(googleAuthSignedInProvider.notifier).state = true;
    ref.read(selectedRoleProvider.notifier).state = role;
    ref.read(savedLibraryProvider.notifier).loadCloudSavedArticles(mockUser.uid);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully authenticated as $name ($email)'),
        backgroundColor: AIGlowColors.electricCyan,
      ),
    );
  }
}

class AuthWorkflowForm extends StatefulWidget {
  final Function(String uid, String name, String email, String role, String photoUrl) onSuccess;

  const AuthWorkflowForm({super.key, required this.onSuccess});

  @override
  State<AuthWorkflowForm> createState() => _AuthWorkflowFormState();
}

class _AuthWorkflowFormState extends State<AuthWorkflowForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'ai_ml';

  final List<Map<String, String>> _roles = [
    {'id': 'ai_ml', 'label': 'AI / ML Engineer'},
    {'id': 'architect', 'label': 'Software Systems Architect'},
    {'id': 'devops', 'label': 'DevOps & Cloud Lead'},
    {'id': 'security', 'label': 'Security Specialist'},
    {'id': 'fullstack', 'label': 'Fullstack & Infra Developer'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _errorMessage;

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : email.split('@').first;

      if (_isSignUp) {
        final user = await FirebaseService.signUpWithEmailAndPassword(
          email: email,
          password: password,
          displayName: name,
          role: _selectedRole,
        );
        if (user != null && mounted) {
          widget.onSuccess(user.uid, name, email, _selectedRole, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80');
        }
      } else {
        final user = await FirebaseService.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        if (user != null && mounted) {
          widget.onSuccess(user.uid, user.displayName ?? name, email, _selectedRole, 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isSignUp ? 'Create Developer Account' : 'Developer Sign In',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AIGlowColors.inkSlate),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isSignUp
                ? 'Register with your developer email to personalize your AI feed.'
                : 'Enter your credentials to access saved vectors & cloud history.',
            style: const TextStyle(fontSize: 12, color: AIGlowColors.mediumSlate),
          ),
          const SizedBox(height: 16),

          // Mode Toggle (Sign In vs Sign Up)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AIGlowColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AIGlowColors.softBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isSignUp = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isSignUp ? AIGlowColors.electricCyan : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: !_isSignUp ? Colors.white : AIGlowColors.mediumSlate,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isSignUp = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isSignUp ? AIGlowColors.electricCyan : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _isSignUp ? Colors.white : AIGlowColors.mediumSlate,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Full Name Field (Sign Up mode)
          if (_isSignUp) ...[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'e.g. Alex Rivers',
                prefixIcon: const Icon(Icons.person_outline, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) {
                if (_isSignUp && (val == null || val.trim().isEmpty)) {
                  return 'Full name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              hintText: 'e.g. alex.rivers@bytepulse.ai',
              prefixIcon: const Icon(Icons.email_outlined, size: 18),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Email address is required';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(val.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Password is required';
              }
              if (val.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Confirm Password Field (Sign Up mode)
          if (_isSignUp) ...[
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) {
                if (_isSignUp) {
                  if (val == null || val.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (val != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Engineering Role Selector
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Primary Engineering Role',
                prefixIcon: const Icon(Icons.work_outline, size: 18),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: _roles.map((role) {
                return DropdownMenuItem<String>(
                  value: role['id'],
                  child: Text(role['label']!, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
            const SizedBox(height: 16),
          ],

          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AIGlowColors.roseCritical.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AIGlowColors.roseCritical.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AIGlowColors.roseCritical),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12, color: AIGlowColors.roseCritical, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AIGlowColors.electricCyan,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _isSignUp ? 'Complete Sign Up' : 'Sign In to Account',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Preset Quick Switch Option
          const Divider(height: 1),
          const SizedBox(height: 12),
          const Text('PRESET DEVELOPER DEMO ACCOUNTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AIGlowColors.mediumSlate, letterSpacing: 0.8)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ActionChip(
                  avatar: const CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80')),
                  label: const Text('Alex Rivers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    widget.onSuccess('demo-dev-101', 'Alex Rivers', 'alex.rivers@bytepulse.ai', 'ai_ml', 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActionChip(
                  avatar: const CircleAvatar(backgroundImage: NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=250&q=80')),
                  label: const Text('Sarah Chen', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    widget.onSuccess('demo-dev-102', 'Sarah Chen', 'sarah.chen@bytepulse.ai', 'architect', 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=250&q=80');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
