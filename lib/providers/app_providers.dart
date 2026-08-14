import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import '../services/gemini_service.dart';
import '../services/firebase_service.dart';
import '../services/firestore_service.dart';
import '../services/feed_ingestion_service.dart';

// Demo User Model for Web Testing
class DemoUser {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;
  final bool isDemo;

  DemoUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    this.isDemo = true,
  });
}

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final String photoUrl;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.photoUrl,
  });
}

final userProfileProvider = StateProvider<UserProfile?>((ref) => null);
final googleAuthSignedInProvider = StateProvider<bool>((ref) => false);
final demoUserProvider = StateProvider<DemoUser?>((ref) => null);

// Navigation tab index (0: Home, 1: Explore, 2: Gemini, 3: Alerts, 4: Profile)
final activeTabProvider = StateProvider<int>((ref) => 0);

// Onboarding & Active Engineering Role
final isOnboardingOpenProvider = StateProvider<bool>((ref) => false);
final selectedRoleProvider = StateProvider<String>((ref) => 'ai_ml');
final followedChannelsProvider = StateProvider<Set<String>>((ref) => {'ai_tools', 'gpus_hw', 'cloud_infra', 'dev_tools'});

// Grounded context for Gemini
final groundedContextProvider = StateProvider<String?>((ref) => null);
final groundedCardProvider = StateProvider<IntelligenceCard?>((ref) => null);
final isStreamingProvider = StateProvider<bool>((ref) => false);
final isRefreshingFeedProvider = StateProvider<bool>((ref) => false);

// Firebase Auth Provider
final authUserProvider = StreamProvider<User?>((ref) {
  FirebaseService.initializeFirebase();
  return FirebaseService.authStateChanges;
});

// Live Firestore Articles Stream Provider
final liveFirestoreStreamProvider = StreamProvider<List<IntelligenceCard>>((ref) {
  return FirestoreService.streamLiveArticles();
});

// Bookmarks & Saved Library
final bookmarksProvider = StateProvider<Set<String>>((ref) => {'card-1'});

class CustomTopicsNotifier extends StateNotifier<List<CustomTopic>> {
  CustomTopicsNotifier()
      : super([
          CustomTopic(
            id: 'topic-1',
            name: 'DeepSeek Reasoning Swarms',
            keywords: ['deepseek', 'distillation', 'vllm', 'reasoning'],
            addedAt: '2 hours ago',
          ),
          CustomTopic(
            id: 'topic-2',
            name: 'Kubernetes Ingress Security Alerts',
            keywords: ['k8s', 'ingress', 'security', 'cve'],
            addedAt: 'Yesterday',
          ),
        ]);

  void addTopic(CustomTopic topic) {
    if (!state.any((t) => t.name.toLowerCase() == topic.name.toLowerCase())) {
      state = [topic, ...state];
      final user = FirebaseService.currentUser;
      if (user != null) {
        FirestoreService.saveCustomTopic(user.uid, topic);
      }
    }
  }

  void removeTopic(String topicId) {
    state = state.where((t) => t.id != topicId).toList();
    final user = FirebaseService.currentUser;
    if (user != null) {
      FirestoreService.deleteCustomTopic(user.uid, topicId);
    }
  }
}

final customTopicsProvider = StateNotifierProvider<CustomTopicsNotifier, List<CustomTopic>>((ref) {
  return CustomTopicsNotifier();
});

class CardsNotifier extends StateNotifier<List<IntelligenceCard>> {
  final Ref ref;

  CardsNotifier(this.ref)
      : super([
          // -------------------------------------------------------------
          // 1. AI & AGENTS CHANNEL (ai_tools)
          // -------------------------------------------------------------
          IntelligenceCard(
            id: 'card-1',
            headline: 'DeepSeek-R1 Distillation & Open Reasoning Swarms Benchmark Analysis',
            summary: 'Developer forum analysis confirms distilled 14B and 32B models match 94% of proprietary 700B reasoning baselines at low inference VRAM costs.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • Hacker News Engineering Thread',
            readTime: '3 min read',
            transparencyReason: 'Matched via LLM distillation vector',
            pros: 'Pros: 84% lower VRAM overhead, runnable on single RTX 4090',
            cons: 'Cons: Requires custom vLLM 0.6.2 runtime patch',
            channelId: 'ai_tools',
            groundedContext: 'DeepSeek-R1 Distillation Study (Aug 2026)',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Distilled 14B/32B models achieve 94% reasoning parity with 700B baselines.',
              'Significant reduction in inference VRAM cost enables single-node deployment.',
              'Requires custom vLLM 0.6.2 compilation patch for optimal tensor parallelism.',
            ],
          ),
          IntelligenceCard(
            id: 'card-2',
            headline: 'Google Cloud Release Notes: Native Gemini 3.1 Pro API Function Calling Extensions',
            summary: 'Official release documentation details structured JSON outputs, streaming tool calls, and automated subagent orchestration pipelines.',
            credibilityType: CredibilityType.official,
            source: 'Official • Google Cloud Docs',
            readTime: '4 min read',
            transparencyReason: 'Matched via Cloud AI provider vector',
            pros: 'Pros: Zero regex parsing needed for tool invocation',
            cons: 'Cons: Strict JSON schema compliance required',
            channelId: 'ai_tools',
            groundedContext: 'Google Cloud Release Notes (Aug 2026)',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              'Native function calling extensions eliminate regex parsing overhead.',
              'Subsecond streaming JSON outputs for agentic workflows.',
              'Automated fallback handling across Gemini 3.6 Flash models.',
            ],
          ),
          IntelligenceCard(
            id: 'card-ai-3',
            headline: 'Anthropic Releases Claude 3.7 Sonnet with Hybrid Reasoning & Extended Thinking Mode',
            summary: 'Anthropic unveils its latest flagship frontier model featuring dynamic chain-of-thought switching and 128k output token generation.',
            credibilityType: CredibilityType.official,
            source: 'Official • Anthropic Research Blog',
            readTime: '5 min read',
            transparencyReason: 'Matched via Frontier LLM vector',
            pros: 'Pros: Superior reasoning benchmarks on SWE-bench and MATH-500',
            cons: 'Cons: Extended thinking incurs higher token billing duration',
            channelId: 'ai_tools',
            groundedContext: 'Claude 3.7 Hybrid Reasoning Release',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Dynamic thinking mode lets developers control token spend per query complexity.',
              'Achieves state-of-the-art score on SWE-bench Verified coding benchmark.',
              'Zero degradation on fast conversational turnarounds.',
            ],
          ),
          IntelligenceCard(
            id: 'card-ai-4',
            headline: 'Meta Releases LLaMA 3.3 70B: Open Weights Challenging Frontier LLM Economics',
            summary: 'Meta releases open weights for LLaMA 3.3 70B, delivering competitive parity with previous generation 405B models at 80% lower compute requirements.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • Meta AI Engineering',
            readTime: '4 min read',
            transparencyReason: 'Matched via Open Source AI vector',
            pros: 'Pros: Permissive community license with easy fine-tuning',
            cons: 'Cons: Requires dual-GPU setup for unquantized weights',
            channelId: 'ai_tools',
            groundedContext: 'LLaMA 3.3 Architecture & Evaluation',
            url: 'https://github.blog',
            takeaways: const [
              'Matches LLaMA 3.1 405B benchmark performance at 70B scale.',
              'Supports 128K context window natively with rotary embeddings.',
              'Rapidly adopted across Ollama, vLLM, and Hugging Face pipelines.',
            ],
          ),
          IntelligenceCard(
            id: 'card-ai-5',
            headline: 'OpenAI Unveils Sora Video Generation API for Enterprise Media Workflows',
            summary: 'OpenAI opens developer API access to Sora with storyboard keyframing, resolution upscaling, and camera movement controls.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Tech Media Dispatch',
            readTime: '4 min read',
            transparencyReason: 'Matched via Generative Video vector',
            pros: 'Pros: High temporal consistency and physics realism',
            cons: 'Cons: Generation cost remains high per video second',
            channelId: 'ai_tools',
            groundedContext: 'OpenAI Sora API Release',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Direct API integration allows automated video rendering from text & scripts.',
              'Temporal consistency improved by 3x over early diffusion baselines.',
              'Watermarking and C2PA provenance embedded in all generated assets.',
            ],
          ),
          IntelligenceCard(
            id: 'card-ai-6',
            headline: 'Cursor & Agentic Coding Ecosystem: The Rapid Evolution of AI-Assisted Development',
            summary: 'Industry report analyzes the shift from inline autocomplete to multi-file autonomous agents, MCP plugins, and background bug hunters.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Developer Tooling Review',
            readTime: '6 min read',
            transparencyReason: 'Matched via Agentic Workflows vector',
            pros: 'Pros: Drastic productivity boost on boilerplate and refactoring',
            cons: 'Cons: Risk of codebase drift if tests are missing',
            channelId: 'ai_tools',
            groundedContext: 'State of AI Developer Tools 2026',
            url: 'https://github.blog',
            takeaways: const [
              'Over 60% of engineering teams report adopting agentic IDE extensions.',
              'Model Context Protocol (MCP) emerged as the leading standard for tool connectivity.',
              'Focus shifting from code generation to automated test verification.',
            ],
          ),

          // -------------------------------------------------------------
          // 2. DATACENTER GPUS & HARDWARE CHANNEL (gpus_hw)
          // -------------------------------------------------------------
          IntelligenceCard(
            id: 'card-3',
            headline: 'NVIDIA B200 Blackwell Benchmarks: NVLink 5 Interconnect Throughput Analysis',
            summary: 'In-depth technical architecture breakdown evaluating sustained 1.8 PFLOPS FP8 performance across 64-node clusters.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • SemiAnalysis DeepDive',
            readTime: '6 min read',
            transparencyReason: 'Matched via Datacenter Hardware vector',
            pros: 'Pros: 2.8x throughput speedup over H100 SXM5',
            cons: 'Cons: Mandatory direct-to-chip liquid cooling',
            channelId: 'gpus_hw',
            groundedContext: 'NVIDIA Blackwell Technical DeepDive',
            url: 'https://aws.amazon.com/blogs/aws',
            takeaways: const [
              'Sustained 1.8 PFLOPS FP8 matrix math throughput in 64-node clusters.',
              'NVLink 5 interconnect delivers 1.8TB/s bidirectional bandwidth per GPU.',
              'Requires facility infrastructure retrofitting for liquid cooling loops.',
            ],
          ),
          IntelligenceCard(
            id: 'card-gpu-2',
            headline: 'AMD Instinct MI325X GPU Architecture: 256GB HBM3e Memory Density Breakdown',
            summary: 'AMD releases benchmarks for MI325X showing 1.3x memory capacity advantage over H200, enabling larger model weights per node.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • AnandTech Hardware Report',
            readTime: '5 min read',
            transparencyReason: 'Matched via Hardware Architecture vector',
            pros: 'Pros: 256GB HBM3e memory per accelerator reduces required cluster size',
            cons: 'Cons: ROCm software ecosystem still maturing compared to CUDA',
            channelId: 'gpus_hw',
            groundedContext: 'AMD Instinct MI325X Benchmark Suite',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Industry-leading 256GB HBM3e VRAM per socket.',
              'Up to 6.0 TB/s memory bandwidth for memory-bound LLM decoding.',
              'Direct drop-in compatibility with existing OAM infrastructure.',
            ],
          ),
          IntelligenceCard(
            id: 'card-gpu-3',
            headline: 'Apple Silicon M4 Ultra Specs Leak: Unified Memory Bandwidth for Local 120B Models',
            summary: 'Supply chain leaks indicate M4 Ultra Mac Studio will feature up to 512GB unified memory with 1,600 GB/s bandwidth for offline AI research.',
            credibilityType: CredibilityType.speculation,
            source: 'Speculation • MacRumors Supply Chain Leak',
            readTime: '3 min read',
            transparencyReason: 'Matched via Edge Silicon vector',
            pros: 'Pros: Run 70B-120B quantized models silently under 120W power',
            cons: 'Cons: Premium workstation pricing',
            channelId: 'gpus_hw',
            groundedContext: 'Apple Silicon M4 Ultra Architecture Leak',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Up to 512GB unified memory shared between CPU and 80-core GPU.',
              'Provides single-box local inference for research labs avoiding cloud bills.',
              'Expected launch targeted for late 2026 workstations.',
            ],
          ),
          IntelligenceCard(
            id: 'card-gpu-4',
            headline: 'Liquid Cooling Infrastructure Retrofits in Hyperscale AI Datacenters',
            summary: 'Facilities report detailing how cloud providers are transitioning existing air-cooled server halls to closed-loop liquid cooling manifolds.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Data Center Knowledge',
            readTime: '6 min read',
            transparencyReason: 'Matched via Datacenter Operations vector',
            pros: 'Pros: 30% reduction in facility Power Usage Effectiveness (PUE)',
            cons: 'Cons: High upfront plumbing and heat-exchanger retrofitting costs',
            channelId: 'gpus_hw',
            groundedContext: 'Hyperscale Liquid Cooling Engineering Report',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              '1,000W+ per-socket TDP accelerators make liquid cooling mandatory.',
              'Reduces overall facility PUE down to 1.12 in modern deployments.',
              'CDU (Cooling Distribution Unit) supply chains stabilizing globally.',
            ],
          ),
          IntelligenceCard(
            id: 'card-gpu-5',
            headline: 'Intel Gaudi 3 AI Accelerators: Cost-per-Token Benchmark vs H100 in Production',
            summary: 'Independent cloud benchmark compares Intel Gaudi 3 against H100 across LLaMA 3.1 70B and Mixtral 8x22B workloads.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • Cloud Hardware Benchmarks',
            readTime: '4 min read',
            transparencyReason: 'Matched via Cloud Hardware Economics vector',
            pros: 'Pros: Up to 40% better price-performance ratio on inference',
            cons: 'Cons: Lower peak training throughput on ultra-large datasets',
            channelId: 'gpus_hw',
            groundedContext: 'Intel Gaudi 3 Inference Benchmark',
            url: 'https://aws.amazon.com/blogs/aws',
            takeaways: const [
              'Integrated 24 200GbE Ethernet ports eliminate proprietary fabric switches.',
              '128GB HBM2e memory per chip at competitive cloud hourly rates.',
              'Strong adoption in cost-sensitive mid-market SaaS inference clusters.',
            ],
          ),
          IntelligenceCard(
            id: 'card-gpu-6',
            headline: 'Custom Silicon Trends: Google TPU v6 Trillium & Amazon Trainium2 In-Depth Comparison',
            summary: 'Comparative analysis of hyperscaler custom ASICs, evaluating software SDK maturity, interconnect topology, and cost savings.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Cloud Infrastructure Journal',
            readTime: '7 min read',
            transparencyReason: 'Matched via Hyperscaler Silicon vector',
            pros: 'Pros: Up to 50% lower operational cost compared to standard commodity GPUs',
            cons: 'Cons: Vendor lock-in to respective cloud ecosystems',
            channelId: 'gpus_hw',
            groundedContext: 'Custom Cloud Silicon Architecture Review',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              'TPU v6 Trillium increases compute density by 4.7x over TPU v5e.',
              'Amazon Trainium2 deployed across 100,000-chip Project Rainier clusters.',
              'Both providers offering PyTorch-native compilers to ease model migration.',
            ],
          ),

          // -------------------------------------------------------------
          // 3. CLOUD & INFRASTRUCTURE CHANNEL (cloud_infra)
          // -------------------------------------------------------------
          IntelligenceCard(
            id: 'card-devops-1',
            headline: 'Kubernetes 1.31 Release Notes: Ingress Security Hotfix & Zero-Day Mitigation',
            summary: 'Official CNCF security advisory details immediate patch requirements for cloud-managed k8s ingress controllers.',
            credibilityType: CredibilityType.official,
            source: 'Official • Kubernetes Security Advisory',
            readTime: '4 min read',
            transparencyReason: 'Matched via Cloud Security vector',
            pros: 'Pros: Fixes remote privilege escalation in NGINX ingress',
            cons: 'Cons: Requires rolling pod restart across nodes',
            channelId: 'cloud_infra',
            groundedContext: 'Kubernetes 1.31 Security Advisory',
            url: 'https://aws.amazon.com/blogs/aws',
            takeaways: const [
              'Critical security patch mitigates zero-day ingress vulnerability.',
              'Automated rolling updates supported via kubectl rollout restart.',
              'Zero cluster downtime when deployed with pod disruption budgets.',
            ],
          ),
          IntelligenceCard(
            id: 'card-devops-2',
            headline: 'Terraform AWS Provider v5.6: Parallel Infrastructure Provisioning Engine',
            summary: 'HashiCorp release documentation introduces 4x faster plan/apply execution times across multi-region VPC setups.',
            credibilityType: CredibilityType.official,
            source: 'Official • HashiCorp Release Blog',
            readTime: '3 min read',
            transparencyReason: 'Matched via Infrastructure-as-Code vector',
            pros: 'Pros: 75% reduction in CI/CD pipeline execution duration',
            cons: 'Cons: Requires updated provider block configuration',
            channelId: 'cloud_infra',
            groundedContext: 'Terraform AWS Provider Release',
            url: 'https://github.blog',
            takeaways: const [
              'Parallel state file evaluation speeds up large workspace deployment.',
              'Native AWS SDK v2 integration reduces API throttling retries.',
              'Backward compatible with Terraform HCL 1.5+ syntax.',
            ],
          ),
          IntelligenceCard(
            id: 'card-cloud-3',
            headline: 'AWS Unveils Serverless Aurora DSQL: Globally Distributed PostgreSQL Engine',
            summary: 'Amazon announces serverless multi-region distributed SQL with active-active writes and zero operational sharding management.',
            credibilityType: CredibilityType.official,
            source: 'Official • AWS Architecture Blog',
            readTime: '5 min read',
            transparencyReason: 'Matched via Distributed Database vector',
            pros: 'Pros: Active-active global multi-master writes with ACID guarantees',
            cons: 'Cons: Not all legacy PostgreSQL extensions are currently supported',
            channelId: 'cloud_infra',
            groundedContext: 'Amazon Aurora DSQL Launch',
            url: 'https://aws.amazon.com/blogs/aws',
            takeaways: const [
              'Built on distributed transaction engines with sub-millisecond local reads.',
              'Automatic scale-to-zero when databases are idle.',
              'Replaces complex Spanner and CockroachDB manual configurations.',
            ],
          ),
          IntelligenceCard(
            id: 'card-cloud-4',
            headline: 'Cloudflare Workers vs AWS Lambda: Cold-Start Latency & V8 Isolate Economics',
            summary: 'Benchmark study analyzing 10 million serverless function invocations across edge isolates vs containerized microVMs.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Cloud Performance Labs',
            readTime: '6 min read',
            transparencyReason: 'Matched via Serverless Architecture vector',
            pros: 'Pros: V8 isolates achieve 0ms cold starts across global PoPs',
            cons: 'Cons: 128MB memory ceiling and limited native binary support',
            channelId: 'cloud_infra',
            groundedContext: 'Serverless Edge vs MicroVM Benchmark',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Edge isolates deliver sub-5ms TTFB for API gateway proxy services.',
              'Containerized lambdas remain superior for heavy compiled binary jobs.',
              'Hybrid architecture becoming the de facto pattern in enterprise web apps.',
            ],
          ),
          IntelligenceCard(
            id: 'card-cloud-5',
            headline: 'Platform Engineering 2026: Internal Developer Portals (IDPs) Replacing Raw Terraform',
            summary: 'Survey of 500 engineering leaders reveals widespread adoption of Backstage and Port to provide self-service cloud infrastructure.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Platform Engineering Weekly',
            readTime: '5 min read',
            transparencyReason: 'Matched via Platform Engineering vector',
            pros: 'Pros: Developers spin up compliant environments in minutes without tickets',
            cons: 'Cons: Upfront setup overhead for platform engineering teams',
            channelId: 'cloud_infra',
            groundedContext: 'State of Platform Engineering 2026',
            url: 'https://github.blog',
            takeaways: const [
              'Reduces infrastructure onboarding time from 3 weeks to 30 minutes.',
              'Built-in security policy guardrails prevent accidental public S3 buckets.',
              'Standardizes microservice scaffolding and CI/CD pipelines.',
            ],
          ),
          IntelligenceCard(
            id: 'card-cloud-6',
            headline: 'OpenTelemetry Standardizes eBPF Instrumentation for Zero-Code Kubernetes Observability',
            summary: 'CNCF announces OTel eBPF agent reaching general availability, capturing distributed traces and network metrics without code changes.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • Cloud Native Computing Foundation',
            readTime: '4 min read',
            transparencyReason: 'Matched via Cloud Observability vector',
            pros: 'Pros: Zero SDK modifications required inside application codebases',
            cons: 'Cons: Requires root kernel privileges for eBPF bytecode loader',
            channelId: 'cloud_infra',
            groundedContext: 'OpenTelemetry eBPF Instrumentation GA',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              'Captures HTTP, gRPC, and SQL latency directly from kernel sockets.',
              'Reduces APM vendor SDK maintenance overhead.',
              'Seamlessly exports data to Grafana, Datadog, and Google Cloud Trace.',
            ],
          ),

          // -------------------------------------------------------------
          // 4. CYBERSECURITY & ADVISORIES CHANNEL (cybersec)
          // -------------------------------------------------------------
          IntelligenceCard(
            id: 'card-sec-1',
            headline: 'CRITICAL: Zero-Day Memory Leak in vLLM Async Engine v0.6.0',
            summary: 'Official security alert: heap corruption vulnerability detected when handling concurrent streaming websocket connections. Upgrade to v0.6.1 immediately.',
            credibilityType: CredibilityType.official,
            source: 'Official • Cybersecurity Advisory',
            readTime: '3 min read',
            transparencyReason: 'Delivered via Push Relevance Engine',
            pros: 'Pros: Instant advisory disclosure prevents remote exploitation',
            cons: 'Cons: Requires rolling worker restart in production inference pools',
            channelId: 'cybersec',
            groundedContext: 'vLLM Security Advisory CVE-2026-8812',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Vulnerability affects concurrent websocket streaming sessions.',
              'Patched in official release v0.6.1.',
              'Deploy patch immediately across all GPU inference nodes.',
            ],
          ),
          IntelligenceCard(
            id: 'card-sec-2',
            headline: 'SSH Backdoor Vulnerability XZ Utils Post-Mortem & Open Source Supply Chain Lessons',
            summary: 'Comprehensive forensic analysis detailing multi-year social engineering campaign targeting core Linux utility maintainers.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Security Intelligence Journal',
            readTime: '8 min read',
            transparencyReason: 'Matched via Supply Chain Security vector',
            pros: 'Pros: Catalyzed automated binary artifact signing across Linux distros',
            cons: 'Cons: Highlighted maintainer burnout vulnerability in critical utilities',
            channelId: 'cybersec',
            groundedContext: 'XZ Backdoor Post-Mortem Analysis',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Attacker spent over two years building trust to inject obfuscated test files.',
              'Automated build script inspection now standard in major package registries.',
              'Sigstore and SLSA framework adoption accelerated globally.',
            ],
          ),
          IntelligenceCard(
            id: 'card-sec-3',
            headline: 'Microsoft Azure Cross-Tenant Identity Isolation Patch & Cloud Security Advisory',
            summary: 'Microsoft releases security bulletin regarding role-based access token scoping across multi-tenant Azure Kubernetes Service clusters.',
            credibilityType: CredibilityType.official,
            source: 'Official • Microsoft Security Response Center',
            readTime: '4 min read',
            transparencyReason: 'Matched via Cloud Identity Security vector',
            pros: 'Pros: Automated backend mitigation deployed with zero customer downtime',
            cons: 'Cons: Requires rotating existing managed identity credentials',
            channelId: 'cybersec',
            groundedContext: 'Azure Identity Isolation Bulletin',
            url: 'https://aws.amazon.com/blogs/aws',
            takeaways: const [
              'No evidence of customer data access identified by security monitoring.',
              'Strengthens token audience validation across all Azure IAM APIs.',
              'Guidance provided for checking audit logs in Azure Defender.',
            ],
          ),
          IntelligenceCard(
            id: 'card-sec-4',
            headline: 'Prompt Injection & MCP Security: OWASP Top 10 Guidelines for Autonomous AI Agents',
            summary: 'OWASP releases revised security framework addressing indirect prompt injection, tool execution sandboxing, and autonomous agent permissions.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • OWASP GenAI Security Project',
            readTime: '5 min read',
            transparencyReason: 'Matched via AI Application Security vector',
            pros: 'Pros: Practical architectural checklists for securing agent tool calls',
            cons: 'Cons: Input validation adds slight processing overhead to LLM chains',
            channelId: 'cybersec',
            groundedContext: 'OWASP Top 10 for AI Agents 2026',
            url: 'https://github.blog',
            takeaways: const [
              'Never grant agents unconstrained shell or database write permissions.',
              'Enforce strict human-in-the-loop validation for destructive operations.',
              'Sanitize external web content before passing to agent context windows.',
            ],
          ),
          IntelligenceCard(
            id: 'card-sec-5',
            headline: 'Quantum-Resistant Cryptography: NIST Finalizes Post-Quantum Encryption Standards',
            summary: 'NIST officially publishes FIPS standards for ML-KEM and ML-DSA post-quantum algorithms, urging enterprise migration roadmaps.',
            credibilityType: CredibilityType.official,
            source: 'Official • NIST Standards Release',
            readTime: '6 min read',
            transparencyReason: 'Matched via Cryptographic Standards vector',
            pros: 'Pros: Mathematical protection against future quantum decryption attacks',
            cons: 'Cons: Larger key sizes increase TLS handshake payload bytes',
            channelId: 'cybersec',
            groundedContext: 'NIST Post-Quantum Encryption Standards',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              'ML-KEM selected as the primary key-encapsulation mechanism.',
              'Cloud providers rolling out hybrid classic/post-quantum TLS endpoints.',
              'Enterprises advised to inventory legacy RSA and ECC cryptographic assets.',
            ],
          ),
          IntelligenceCard(
            id: 'card-sec-6',
            headline: 'CI/CD Pipeline Poisoning: Attackers Target GitHub Actions Runners & npm Packages',
            summary: 'Threat intelligence report reveals surging attacks exploiting leaked GitHub personal access tokens to modify build artifacts.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Cloud Security Threat Matrix',
            readTime: '4 min read',
            transparencyReason: 'Matched via DevSecOps vector',
            pros: 'Pros: Ephemeral self-hosted runners mitigate credential theft',
            cons: 'Cons: Requires auditing all third-party marketplace actions',
            channelId: 'cybersec',
            groundedContext: 'CI/CD Supply Chain Threat Assessment',
            url: 'https://github.blog',
            takeaways: const [
              'Pin actions to explicit commit SHAs instead of mutable version tags.',
              'Use OIDC tokens with short lifespans instead of hardcoded secrets.',
              'Enforce branch protection rules requiring multiple PR code reviews.',
            ],
          ),

          // -------------------------------------------------------------
          // 5. DEVELOPER PLATFORMS & FINOPS CHANNEL (dev_tools)
          // -------------------------------------------------------------
          IntelligenceCard(
            id: 'card-finops-1',
            headline: 'Cloud FinOps Strategy: Reducing AI Model Inference Spend by 62% via Dynamic Batching',
            summary: 'Detailed financial engineering case study demonstrating \$480,000 annual cloud savings across multi-tenant GPU clusters.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Cloud FinOps Weekly',
            readTime: '5 min read',
            transparencyReason: 'Matched via Cloud Spend Optimization vector',
            pros: 'Pros: 62% reduction in monthly GPU compute bills',
            cons: 'Cons: Slight P99 latency increase during off-peak hours',
            channelId: 'dev_tools',
            groundedContext: 'Cloud FinOps Inference Cost Optimization',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              'Dynamic queue batching optimizes GPU utilization from 34% to 88%.',
              'Automated spot instance fallback saves 62% on inference infrastructure.',
              'Real-time cost anomaly metrics wired to Slack alerts.',
            ],
          ),
          IntelligenceCard(
            id: 'card-finops-2',
            headline: 'AWS & GCP Billing APIs: Real-Time Unit Economics & Cost Allocation Tagging',
            summary: 'Technical guide on streaming cloud consumption logs directly into BigQuery FinOps dashboards.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • Cloud Architecture Journal',
            readTime: '4 min read',
            transparencyReason: 'Matched via Billing API vector',
            pros: 'Pros: Real-time per-query cost attribution for LLM APIs',
            cons: 'Cons: Requires setting up GCS cost export buckets',
            channelId: 'dev_tools',
            groundedContext: 'Cloud Billing API Cost Tagging Guide',
            url: 'https://cloud.google.com/blog',
            takeaways: const [
              'Per-token and per-request cost attribution across enterprise teams.',
              'Automated alerts trigger when daily spend exceeds 15% threshold.',
              'Direct integration with Google Cloud BigQuery FinOps exports.',
            ],
          ),
          IntelligenceCard(
            id: 'card-4',
            headline: 'Developer Forum Leaks: Next-Gen Ultra-Low Latency Rust WASM Runtime for Edge AI',
            summary: 'Community leaks indicate upcoming web assembly micro-runtime capable of cold-starting AI agents in under 1.2ms.',
            credibilityType: CredibilityType.speculation,
            source: 'Speculation • Developer Forum Leak',
            readTime: '2 min read',
            transparencyReason: 'Matched via Edge Systems vector',
            pros: 'Pros: Sub-millisecond cold start overhead',
            cons: 'Cons: Unconfirmed API stability & edge benchmarks',
            channelId: 'dev_tools',
            groundedContext: 'Developer Forum Discussion Thread',
            url: 'https://github.blog',
            takeaways: const [
              'Sub-millisecond cold start latency for WASM edge microservices.',
              'Memory-isolated sandbox execution with zero native C-binding risks.',
              'Compatible with standard Wasmtime and Spin runtime drivers.',
            ],
          ),
          IntelligenceCard(
            id: 'card-arch-1',
            headline: 'Distributed Systems Patterns: Event-Driven Microservices with Kafka & gRPC',
            summary: 'Architecture specification detailing CQRS event sourcing, idempotent message processing, and schema registry validation.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Software Architecture Review',
            readTime: '7 min read',
            transparencyReason: 'Matched via Distributed Systems vector',
            pros: 'Pros: High fault tolerance with zero message loss guarantee',
            cons: 'Cons: Increased architectural complexity for schema evolution',
            channelId: 'dev_tools',
            groundedContext: 'Event-Driven Microservices Architecture',
            url: 'https://aws.amazon.com/blogs/aws',
            takeaways: const [
              'CQRS pattern decouples heavy read models from transactional writes.',
              'gRPC protocol buffers reduce payload size by 65% compared to REST JSON.',
              'Idempotency keys prevent duplicate transaction execution.',
            ],
          ),
          IntelligenceCard(
            id: 'card-dev-3',
            headline: 'Rust in the Linux Kernel: 2 Years In, What Worked and What Broke',
            summary: 'Retrospective report from Linux kernel maintainers assessing memory safety improvements, C-binding ergonomics, and build toolchain integration.',
            credibilityType: CredibilityType.analysis,
            source: 'Analysis • Kernel Development Journal',
            readTime: '6 min read',
            transparencyReason: 'Matched via Systems Programming vector',
            pros: 'Pros: Zero null-pointer or use-after-free bugs in new Rust drivers',
            cons: 'Cons: Rustc toolchain version synchronization hurdles',
            channelId: 'dev_tools',
            groundedContext: 'Rust in Linux Kernel Assessment',
            url: 'https://news.ycombinator.com',
            takeaways: const [
              'Major reduction in driver-related kernel panics and memory corruption.',
              'Binder and NVMe driver implementations proving production stability.',
              'Community consensus shifting toward long-term support for Rust subsystem.',
            ],
          ),
          IntelligenceCard(
            id: 'card-dev-4',
            headline: 'Next.js 15 Server Actions & React 19 Compiler: Performance Shift in Full-Stack Web',
            summary: 'Technical evaluation of React 19 memoization compiler and Next.js 15 async request lifecycle optimizations.',
            credibilityType: CredibilityType.verified,
            source: 'Verified • Modern Web Standards Blog',
            readTime: '5 min read',
            transparencyReason: 'Matched via Web Frameworks vector',
            pros: 'Pros: Automatic memoization eliminates useMemo and useCallback boilerplate',
            cons: 'Cons: Breaking changes in async header cookie access APIs',
            channelId: 'dev_tools',
            groundedContext: 'Next.js 15 & React 19 Architectural Review',
            url: 'https://github.blog',
            takeaways: const [
              'React Compiler automates fine-grained component re-rendering optimizations.',
              'Server Actions provide seamless type-safe RPCs without custom API routes.',
              'Default fetch caching changed to uncached for predictable data fetching.',
            ],
          ),
        ]);

  Future<void> ingestNewFeed() async {
    ref.read(isRefreshingFeedProvider.notifier).state = true;

    final activeTopics = ref.read(customTopicsProvider);
    final newIngestedCards = await FeedIngestionService.fetchAndProcessIngestionFeed(customTopics: activeTopics);
    if (newIngestedCards.isNotEmpty) {
      state = [...newIngestedCards, ...state];

      for (final card in newIngestedCards) {
        await FirestoreService.publishIngestedArticle(card);
      }
    }

    ref.read(isRefreshingFeedProvider.notifier).state = false;
  }

  void setFeedback(String cardId, String feedbackType) {
    state = [
      for (final card in state)
        if (card.id == cardId)
          card.copyWith(userFeedback: card.userFeedback == feedbackType ? null : feedbackType)
        else
          card
    ];

    // Async sync to Firestore if user signed in
    final user = FirebaseService.currentUser;
    if (user != null) {
      final role = ref.read(selectedRoleProvider);
      final channels = ref.read(followedChannelsProvider);
      final relevance = ref.read(relevanceLevelProvider);
      final quiet = ref.read(quietHoursProvider);
      FirestoreService.syncPreferences(
        user.uid,
        selectedRole: role,
        followedChannels: channels,
        relevanceLevel: relevance,
        quietHours: quiet,
      );
    }
  }

  void muteCard(String cardId) {
    state = state.where((c) => c.id != cardId).toList();
  }
}

final intelligenceCardsProvider = StateNotifierProvider<CardsNotifier, List<IntelligenceCard>>((ref) {
  return CardsNotifier(ref);
});

// Role Filtered Cards Provider
final filteredCardsForRoleProvider = Provider<List<IntelligenceCard>>((ref) {
  final role = ref.watch(selectedRoleProvider);
  final cards = ref.watch(intelligenceCardsProvider);

  String reasonLabel = '✨ Because your active role is AI / ML Engineer';
  if (role == 'devops') {
    reasonLabel = '✨ Because your active role is DevOps & Cloud Infrastructure';
  } else if (role == 'finops') {
    reasonLabel = '✨ Because your active role is FinOps Consultant';
  } else if (role == 'arch' || role == 'architect') {
    reasonLabel = '✨ Because your active role is Software Systems Architect';
  }

  final filtered = cards.where((card) {
    if (role == 'devops') {
      return card.channelId == 'cloud_infra' ||
          card.headline.toLowerCase().contains('kubernetes') ||
          card.headline.toLowerCase().contains('terraform') ||
          card.headline.toLowerCase().contains('cloud');
    }
    if (role == 'finops') {
      return card.headline.toLowerCase().contains('finops') ||
          card.headline.toLowerCase().contains('cost') ||
          card.headline.toLowerCase().contains('billing') ||
          card.summary.toLowerCase().contains('spend');
    }
    if (role == 'arch' || role == 'architect') {
      return card.channelId == 'dev_tools' ||
          card.headline.toLowerCase().contains('architecture') ||
          card.headline.toLowerCase().contains('microservices') ||
          card.headline.toLowerCase().contains('rust') ||
          card.headline.toLowerCase().contains('wasm');
    }
    // Default 'ai_ml':
    return card.channelId == 'ai_tools' ||
        card.channelId == 'gpus_hw' ||
        card.headline.toLowerCase().contains('deepseek') ||
        card.headline.toLowerCase().contains('gemini') ||
        card.headline.toLowerCase().contains('nvidia') ||
        card.headline.toLowerCase().contains('model');
  }).toList();

  return filtered.map((card) {
    return card.copyWith(
      transparencyReason: reasonLabel,
    );
  }).toList();
});

// Gemini Chat Messages Notifier with Live Gemini API Streaming
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;

  ChatNotifier(this.ref)
      : super([
          ChatMessage(
            id: 'msg-1',
            sender: 'assistant',
            text: '### 👋 Welcome to Live Gemini Agent\n\nI am your **Gemini Enterprise Agent** in BytePulse AI. I deliver real-time technical analysis grounded in your developer feeds.\n\n• Ask about high-throughput GPU inference & FP8 quantization.\n• Synthesize system architecture trade-offs & security alerts.\n• Generate PyTorch / vLLM benchmark scripts.',
            confidence: '99.4%',
            citations: ['Hacker News Thread', 'Google Cloud Release Notes'],
            suggestedTopic: 'DeepSeek Distillation Architecture',
          ),
        ]);

  Future<void> sendUserQuery(String promptText) async {
    final userMsg = ChatMessage(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: promptText,
    );
    state = [...state, userMsg];

    // Stream response from GeminiService
    ref.read(isStreamingProvider.notifier).state = true;
    final groundedCard = ref.read(groundedCardProvider);
    final contextTitle = ref.read(groundedContextProvider);

    final assistantMsgId = 'msg-${DateTime.now().millisecondsSinceEpoch + 1}';

    String? derivedTopic;
    final lower = promptText.toLowerCase().trim();

    if (lower.contains('kubernetes') || lower.contains('k8s') || lower.contains('ingress')) {
      derivedTopic = 'Kubernetes Ingress';
    } else if (lower.contains('deepseek') || lower.contains('reasoning') || lower.contains('distillation')) {
      derivedTopic = 'DeepSeek Reasoning Swarms';
    } else if (lower.contains('terraform') || lower.contains('iac')) {
      derivedTopic = 'Terraform AWS Provider';
    } else if (lower.contains('finops') || lower.contains('billing') || lower.contains('cloud cost') || lower.contains('spend')) {
      derivedTopic = 'Cloud FinOps Strategy';
    } else if (lower.contains('rust') || lower.contains('wasm')) {
      derivedTopic = 'Rust WASM Micro-Runtimes';
    } else if (lower.contains('blackwell') || lower.contains('b200') || lower.contains('nvlink') || lower.contains('nvidia')) {
      derivedTopic = 'NVIDIA Blackwell & NVLink 5';
    } else if (lower.contains('vllm')) {
      derivedTopic = 'vLLM Performance';
    } else if (lower.contains('kafka') || lower.contains('grpc')) {
      derivedTopic = 'Kafka & Distributed Systems';
    } else {
      derivedTopic = null; // Generic / conversational queries do not create topic buttons
    }

    var assistantMsg = ChatMessage(
      id: assistantMsgId,
      sender: 'assistant',
      text: '',
      confidence: '99.2%',
      citations: [
        if (groundedCard != null) groundedCard.source else 'BytePulse AI Index',
        'Gemini 3.6 Flash API',
      ],
      suggestedTopic: derivedTopic,
    );

    state = [...state, assistantMsg];

    final conversationHistory = List<ChatMessage>.from(state.where((m) => m.id != assistantMsgId));

    final geminiService = GeminiService();
    final stream = geminiService.streamGeminiResponse(
      prompt: promptText,
      groundedCard: groundedCard,
      customContextTitle: contextTitle,
      history: conversationHistory,
    );

    var currentAccumulatedText = '';
    String? extractedCode;

    await for (final chunk in stream) {
      if (chunk.contains('CODE_BLOCK_MARKER:')) {
        final parts = chunk.split('CODE_BLOCK_MARKER:');
        currentAccumulatedText += parts[0];
        if (parts.length > 1) {
          extractedCode = parts[1].replaceAll('*AI-generated analysis may contain errors. Verify critical technical decisions.*', '').trim();
        }
      } else {
        currentAccumulatedText += chunk;
      }

      state = [
        for (final msg in state)
          if (msg.id == assistantMsgId)
            msg.copyWith(saved: msg.saved, suggestedTopic: derivedTopic).let((m) => ChatMessage(
                  id: m.id,
                  sender: m.sender,
                  text: currentAccumulatedText,
                  confidence: m.confidence,
                  citations: m.citations,
                  codeSnippet: extractedCode ?? m.codeSnippet,
                  saved: m.saved,
                  suggestedTopic: derivedTopic,
                ))
          else
            msg
      ];
    }

    ref.read(isStreamingProvider.notifier).state = false;
  }

  void toggleSave(String msgId) {
    state = [
      for (final msg in state)
        if (msg.id == msgId) msg.copyWith(saved: true) else msg
    ];
  }
}

extension LetExtension<T> on T {
  R let<R>(R Function(T it) op) => op(this);
}

final chatMessagesProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});

// Alerts Relevance Slider
final relevanceLevelProvider = StateProvider<double>((ref) => 2.0);
final quietHoursProvider = StateProvider<bool>((ref) => false);

// Saved Library Notifier with Firestore Integration
class SavedLibraryNotifier extends StateNotifier<List<SavedItem>> {
  SavedLibraryNotifier()
      : super([
          SavedItem(
            id: 'lib-1',
            type: 'gemini_answer',
            title: 'Optimal Quantization Script for QLoRA 4-bit Models',
            snippet: 'import bitsandbytes as bnb\nfrom transformers import AutoModelForCausalLM...',
            savedAt: '2 hours ago',
            source: 'Live Gemini Session',
          ),
          SavedItem(
            id: 'lib-2',
            type: 'article',
            title: 'DeepSeek-R1 Distillation & Open Reasoning Swarms Benchmark Analysis',
            snippet: 'Distilled 14B and 32B parameters achieve 94% parity...',
            savedAt: 'Yesterday',
            source: 'Personalized For You Feed',
          ),
        ]);

  void addItem(SavedItem item, {IntelligenceCard? originalCard}) {
    state = [item, ...state];

    // Async sync to Firestore if user signed in
    final user = FirebaseService.currentUser;
    if (user != null && originalCard != null) {
      FirestoreService.saveArticle(user.uid, originalCard);
    }
  }

  void removeItem(String id) {
    state = state.where((item) => item.id != id).toList();

    // Async delete from Firestore if user signed in
    final user = FirebaseService.currentUser;
    if (user != null) {
      FirestoreService.deleteSavedArticle(user.uid, id);
    }
  }

  Future<void> loadCloudSavedArticles(String userId) async {
    final cloudItems = await FirestoreService.fetchSavedArticles(userId);
    if (cloudItems.isNotEmpty) {
      state = [...cloudItems, ...state];
    }
  }
}

final savedLibraryProvider = StateNotifierProvider<SavedLibraryNotifier, List<SavedItem>>((ref) {
  return SavedLibraryNotifier();
});
