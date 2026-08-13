import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bytepulse_ai_flutter/main.dart';

void main() {
  testWidgets('BytePulseApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BytePulseApp()));
    expect(find.byType(BytePulseApp), findsOneWidget);
  });
}
