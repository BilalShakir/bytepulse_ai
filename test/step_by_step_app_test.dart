import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytepulse_ai_flutter/main.dart';
import 'package:bytepulse_ai_flutter/providers/app_providers.dart';
import 'package:bytepulse_ai_flutter/screens/home_feed_screen.dart';
import 'package:bytepulse_ai_flutter/widgets/article_detail_sheet.dart';

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends StreamView<List<int>> implements HttpClientResponse {
  static final List<int> _kTransparentImage = <int>[
    0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00,
    0x01, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
    0xff, 0xff, 0xff, 0x21, 0xf9, 0x04, 0x01, 0x00,
    0x00, 0x00, 0x00, 0x2c, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44,
    0x01, 0x00, 0x3b,
  ];

  _MockHttpClientResponse() : super(Stream<List<int>>.fromIterable([_kTransparentImage]));

  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _MockHttpOverrides();
  });

  group('Step-by-Step Functional Integration Tests', () {
    testWidgets('Step 1: Onboarding & Guest Setup -> Tap Continue as Guest -> Home Feed loads', (WidgetTester tester) async {
      final container = ProviderContainer();
      container.read(isOnboardingOpenProvider.notifier).state = true;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BytePulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Onboarding dialog is visible
      final guestFinder = find.textContaining('Continue as Guest');
      expect(guestFinder, findsOneWidget);

      // Scroll into view & tap Continue as Guest
      await tester.ensureVisible(guestFinder);
      await tester.pumpAndSettle();
      await tester.tap(guestFinder);
      await tester.pumpAndSettle();

      // Verify onboarding closed and Home Feed loaded
      expect(container.read(isOnboardingOpenProvider), isFalse);
      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.textContaining('Welcome back'), findsOneWidget);
    });

    testWidgets('Step 2: Article Tap Interaction -> Tap an ArticleCard -> Verify ArticleDetailSheet appears', (WidgetTester tester) async {
      final container = ProviderContainer();
      container.read(isOnboardingOpenProvider.notifier).state = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BytePulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the first article headline
      final headlineFinder = find.textContaining('DeepSeek-R1 Distillation');
      expect(headlineFinder, findsOneWidget);

      await tester.tap(headlineFinder);
      await tester.pumpAndSettle();

      // Verify ArticleDetailSheet modal appears with Intelligence Deepdive and Summary
      expect(find.byType(ArticleDetailSheet), findsOneWidget);
      expect(find.text('INTELLIGENCE DEEPDIVE'), findsOneWidget);
      expect(find.text('EXECUTIVE SUMMARY'), findsOneWidget);
    });

    testWidgets('Step 3: Ask Gemini Handoff -> Tap Ask Live Gemini -> Verify Tab 2 opens with article context attached', (WidgetTester tester) async {
      final container = ProviderContainer();
      container.read(isOnboardingOpenProvider.notifier).state = false;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BytePulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the "Ask Live Gemini" button on the first card
      final askGeminiBtn = find.text('Ask Live Gemini').first;
      expect(askGeminiBtn, findsOneWidget);

      await tester.tap(askGeminiBtn);
      await tester.pumpAndSettle();

      // Verify active tab switched to Tab 2 (Gemini Agent)
      expect(container.read(activeTabProvider), 2);
      expect(container.read(groundedCardProvider), isNotNull);
      expect(find.textContaining('Grounded in:'), findsOneWidget);
      expect(find.text('Detach Context'), findsOneWidget);
    });

    testWidgets('Step 4: Chat Input Verification -> Send "Explain Kubernetes ingress" -> Verify response & topic button', (WidgetTester tester) async {
      final container = ProviderContainer();
      container.read(isOnboardingOpenProvider.notifier).state = false;
      container.read(activeTabProvider.notifier).state = 2; // Gemini Tab

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BytePulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Find chat text field and submit query
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);

      await tester.enterText(inputField, 'Explain Kubernetes ingress');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Verify response is generated and topic button shows "Kubernetes Ingress"
      expect(find.textContaining('Kubernetes Ingress'), findsWidgets);
      expect(find.textContaining('➕ Add "Kubernetes Ingress" to My Feeds'), findsOneWidget);
    });

    testWidgets('Step 5: Conversational Filter -> Send "ok" -> Verify NO "Add \'ok\' to My Feeds" button is created', (WidgetTester tester) async {
      final container = ProviderContainer();
      container.read(isOnboardingOpenProvider.notifier).state = false;
      container.read(activeTabProvider.notifier).state = 2; // Gemini Tab

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BytePulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      final inputField = find.byType(TextField);
      await tester.enterText(inputField, 'ok');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      // Verify NO topic button with 'ok' was generated
      expect(find.textContaining('➕ Add "ok" to My Feeds'), findsNothing);
      expect(find.textContaining('➕ Add "okay" to My Feeds'), findsNothing);
      expect(find.textContaining('Sounds good!'), findsOneWidget);
    });

    testWidgets('Step 6: Explore Filter -> Open Tab 1 -> Search "Terraform" -> Verify filtered cards display', (WidgetTester tester) async {
      final container = ProviderContainer();
      container.read(isOnboardingOpenProvider.notifier).state = false;
      container.read(activeTabProvider.notifier).state = 1; // Explore Tab

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BytePulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Find search field in Explore screen
      final searchField = find.widgetWithText(TextField, 'Search channels, topics, technologies...');
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Terraform');
      await tester.pumpAndSettle();

      // Verify filtered card contains Terraform
      expect(find.textContaining('Terraform AWS Provider'), findsOneWidget);
    });
  });
}
