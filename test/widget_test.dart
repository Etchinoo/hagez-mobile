// Basic smoke test — verifies the app boots without throwing.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hagez/main.dart';

void main() {
  testWidgets('App boots and shows the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HagezApp()));
    await tester.pump();

    expect(find.text('حاجز'), findsOneWidget);
  });
}
