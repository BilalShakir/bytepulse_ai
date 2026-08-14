import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ai_glow_theme.dart';
import '../providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int currentStep = 1;
  String tempRole = 'ai_ml';
  final Set<String> tempChannels = {'ai_tools', 'gpus_hw', 'cloud_infra', 'dev_tools'};
  final Map<String, String> tempReactions = {
    'h1': 'interested',
    'h2': 'interested',
    'h3': 'not_interested',
  };

  final List<Map<String, String>> roles = [
    {'id': 'ai_ml', 'title': 'AI / ML Engineer', 'desc': 'LLMs, GPUs, Agentic workflows'},
    {'id': 'fullstack', 'title': 'Fullstack Dev', 'desc': 'Vite, React, Rust, APIs'},
    {'id': 'devops', 'title': 'DevOps & Cloud', 'desc': 'Kubernetes, Terraform, FinOps'},
    {'id': 'security', 'title': 'Security Specialist', 'desc': 'Zero-day, Post-Quantum Crypto'},
    {'id': 'systems', 'title': 'Systems Architect', 'desc': 'Low-latency C++, WASM, DBs'},
  ];

  final List<Map<String, String>> starterChannels = [
    {'id': 'ai_tools', 'name': 'New AI Tools & Agents'},
    {'id': 'gpus_hw', 'name': 'Datacenter GPUs & Hardware'},
    {'id': 'cloud_infra', 'name': 'Cloud & Infra'},
    {'id': 'cybersec', 'name': 'Cybersecurity'},
    {'id': 'dev_tools', 'name': 'Dev Tools'},
    {'id': 'llm_finetune', 'name': 'LLM Fine-Tuning'},
  ];

  final List<Map<String, String>> headlines = [
    {'id': 'h1', 'text': 'NVIDIA Rubin Architecture Unveils 3.5x Training Efficiency for 100B+ Model Swarms'},
    {'id': 'h2', 'text': 'DeepSeek-R1 Distilled Models Outperform Proprietary Baselines on Complex Reasoning'},
    {'id': 'h3', 'text': 'Post-Quantum Cryptography Mandate: NSA Approves Module Standards for Cloud API Endpoints'},
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AIGlowColors.softBorder),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(139, 92, 246, 0.15),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Logo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AIGlowColors.electricCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AIGlowColors.electricCyan.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: AIGlowColors.electricCyan),
                    SizedBox(width: 6),
                    Text(
                      'BYTEPULSE AI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AIGlowColors.electricCyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Title & Subtitle
              Text(
                _getStepTitle(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AIGlowColors.inkSlate,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _getStepSubtitle(),
                style: const TextStyle(fontSize: 12, color: AIGlowColors.mediumSlate),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Progress Indicator Dots
              Row(
                children: List.generate(3, (index) {
                  final stepNum = index + 1;
                  final isActive = currentStep == stepNum;
                  final isDone = currentStep > stepNum;
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isDone
                            ? AIGlowColors.emeraldMint
                            : (isActive ? AIGlowColors.electricCyan : AIGlowColors.softBorder),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Step Content
              _buildStepContent(),
              const SizedBox(height: 24),

              // Primary CTA Button
              GestureDetector(
                onTap: () {
                  if (currentStep < 3) {
                    setState(() {
                      currentStep++;
                    });
                  } else {
                    ref.read(selectedRoleProvider.notifier).state = tempRole;
                    ref.read(followedChannelsProvider.notifier).state = tempChannels;
                    ref.read(isOnboardingOpenProvider.notifier).state = false;
                  }
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
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentStep == 3 ? 'Complete Personalization' : 'Continue to Next Step',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Guest Mode Button
              GestureDetector(
                onTap: () {
                  ref.read(isOnboardingOpenProvider.notifier).state = false;
                },
                child: const Text(
                  'Continue as Guest (Default Recommendations)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AIGlowColors.mediumSlate,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  String _getStepTitle() {
    if (currentStep == 1) return 'Select Engineering Role';
    if (currentStep == 2) return 'Pick Starter Channels';
    return 'Seed Your Taste Profile';
  }

  String _getStepSubtitle() {
    if (currentStep == 1) return 'Tailors algorithm weightings for hardware vs software.';
    if (currentStep == 2) return 'Choose topic channels to follow in your live feed.';
    return 'React to recent intelligence headlines to train Gemini filters.';
  }

  Widget _buildStepContent() {
    if (currentStep == 1) {
      return Column(
        children: roles.map((role) {
          final isSelected = tempRole == role['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                setState(() {
                  tempRole = role['id']!;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AIGlowColors.electricCyan.withOpacity(0.08)
                      : AIGlowColors.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AIGlowColors.electricCyan : AIGlowColors.softBorder,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? AIGlowColors.electricCyan : AIGlowColors.mutedSlate,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role['title']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AIGlowColors.inkSlate,
                          ),
                        ),
                        Text(
                          role['desc']!,
                          style: const TextStyle(fontSize: 11, color: AIGlowColors.mediumSlate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (currentStep == 2) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: starterChannels.map((ch) {
          final isSelected = tempChannels.contains(ch['id']);
          return ChoiceChip(
            label: Text(ch['name']!),
            selected: isSelected,
            selectedColor: AIGlowColors.electricCyan.withOpacity(0.15),
            backgroundColor: AIGlowColors.cardWhite,
            side: BorderSide(
              color: isSelected ? AIGlowColors.electricCyan : AIGlowColors.softBorder,
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AIGlowColors.electricCyan : AIGlowColors.inkSlate,
            ),
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  tempChannels.add(ch['id']!);
                } else {
                  tempChannels.remove(ch['id']!);
                }
              });
            },
          );
        }).toList(),
      );
    }

    return Column(
      children: headlines.map((h) {
        final reaction = tempReactions[h['id']];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AIGlowColors.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AIGlowColors.softBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h['text']!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AIGlowColors.inkSlate,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.thumb_up, size: 14),
                      label: const Text('Interested'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: reaction == 'interested'
                            ? AIGlowColors.emeraldMint
                            : AIGlowColors.mediumSlate,
                        side: BorderSide(
                          color: reaction == 'interested'
                              ? AIGlowColors.emeraldMint
                              : AIGlowColors.softBorder,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          tempReactions[h['id']!] = 'interested';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.thumb_down, size: 14),
                      label: const Text('Not Interested'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: reaction == 'not_interested'
                            ? AIGlowColors.roseCritical
                            : AIGlowColors.mediumSlate,
                        side: BorderSide(
                          color: reaction == 'not_interested'
                              ? AIGlowColors.roseCritical
                              : AIGlowColors.softBorder,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          tempReactions[h['id']!] = 'not_interested';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
