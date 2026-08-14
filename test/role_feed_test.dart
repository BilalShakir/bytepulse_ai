import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytepulse_ai_flutter/providers/app_providers.dart';
import 'package:bytepulse_ai_flutter/screens/profile_screen.dart';
import 'package:bytepulse_ai_flutter/screens/home_feed_screen.dart';

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

  testWidgets('Auth form rejects invalid email and short password', (WidgetTester tester) async {
    String? successEmail;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
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
      ),
    );

    // Enter invalid email format and short password (< 6 chars)
    await tester.enterText(find.widgetWithText(TextFormField, 'Email Address'), 'invalid-email');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '123');

    // Tap submit button
    await tester.tap(find.text('Sign In to Account'));
    await tester.pumpAndSettle();

    // Assert validation error messages appear on screen
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Password must be at least 6 characters'), findsOneWidget);

    // Assert auth state did NOT change
    expect(successEmail, isNull);
  });

  testWidgets('DevOps role only renders DevOps recommendation tags', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(selectedRoleProvider.notifier).state = 'devops';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: HomeFeedScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Asserts that NO card contains the text "Because your active role is AI / ML Engineer"
    expect(find.textContaining('Because your active role is AI / ML Engineer'), findsNothing);

    // Asserts all visible cards contain "Because your active role is DevOps & Cloud Infrastructure"
    expect(find.textContaining('Because your active role is DevOps & Cloud Infrastructure'), findsWidgets);
  });

  testWidgets('FinOps role only renders FinOps recommendation tags', (WidgetTester tester) async {
    final container = ProviderContainer();
    container.read(selectedRoleProvider.notifier).state = 'finops';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: HomeFeedScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Asserts all visible cards contain "Because your active role is FinOps Consultant"
    expect(find.textContaining('Because your active role is FinOps Consultant'), findsWidgets);

    // Asserts that NO card contains DevOps or AI/ML role tags
    expect(find.textContaining('Because your active role is DevOps & Cloud Infrastructure'), findsNothing);
    expect(find.textContaining('Because your active role is AI / ML Engineer'), findsNothing);
  });
}
