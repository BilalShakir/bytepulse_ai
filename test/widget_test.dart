import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytepulse_ai_flutter/main.dart';
import 'package:bytepulse_ai_flutter/providers/app_providers.dart';
import 'package:bytepulse_ai_flutter/screens/profile_screen.dart';

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

  testWidgets('BytePulseApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BytePulseApp()));
    expect(find.byType(BytePulseApp), findsOneWidget);
  });

  group('Auth Form Validation Tests', () {
    testWidgets('AuthWorkflowForm renders email, password fields and validates inputs', (WidgetTester tester) async {
      String? successEmail;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AuthWorkflowForm(
                onSuccess: (uid, name, email, role, photoUrl) {
                  successEmail = email;
                },
              ),
            ),
          ),
        ),
      );

      // Verify Initial Form Widgets
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Sign In to Account'), findsOneWidget);

      // Tap Submit on empty fields -> Should show validation errors
      await tester.tap(find.text('Sign In to Account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(successEmail, isNull);

      // Enter invalid email format
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'invalid-email');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '123');
      await tester.tap(find.text('Sign In to Account'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(successEmail, isNull);

      // Switch to Sign Up mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Complete Sign Up'), findsOneWidget);

      // Empty full name validation in Sign Up mode
      await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'valid@bytepulse.ai');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'password123');
      await tester.tap(find.text('Complete Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(successEmail, isNull);
    });
  });

  group('Role-Based Filtering & Dynamic Reasons', () {
    test('filteredCardsForRoleProvider filters cards and dynamically updates reason text', () {
      final container = ProviderContainer();

      // Test DevOps Role
      container.read(selectedRoleProvider.notifier).state = 'devops';
      final devopsCards = container.read(filteredCardsForRoleProvider);
      expect(devopsCards.isNotEmpty, isTrue);
      for (final card in devopsCards) {
        expect(card.transparencyReason, contains('DevOps & Cloud Infrastructure'));
      }

      // Test FinOps Role
      container.read(selectedRoleProvider.notifier).state = 'finops';
      final finopsCards = container.read(filteredCardsForRoleProvider);
      expect(finopsCards.isNotEmpty, isTrue);
      for (final card in finopsCards) {
        expect(card.transparencyReason, contains('FinOps Consultant'));
      }

      // Test AI/ML Role
      container.read(selectedRoleProvider.notifier).state = 'ai_ml';
      final aimlCards = container.read(filteredCardsForRoleProvider);
      expect(aimlCards.isNotEmpty, isTrue);
      for (final card in aimlCards) {
        expect(card.transparencyReason, contains('AI / ML Engineer'));
      }

      // Test Architect Role
      container.read(selectedRoleProvider.notifier).state = 'arch';
      final archCards = container.read(filteredCardsForRoleProvider);
      expect(archCards.isNotEmpty, isTrue);
      for (final card in archCards) {
        expect(card.transparencyReason, contains('Software Systems Architect'));
      }
    });
  });
}
