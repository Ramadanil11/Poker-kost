import 'package:flutter_test/flutter_test.dart';

import 'package:custom_card_core/main.dart';

void main() {
  testWidgets('shows game mode menu', (tester) async {
    await tester.pumpWidget(const PokerSetshootApp());

    expect(find.text('POKER KOST'), findsWidgets);
    expect(find.text('LOKAL'), findsNothing);
    expect(find.text('MULTIPLAYER'), findsOneWidget);
    expect(find.text('EXIT'), findsOneWidget);
  });

  testWidgets('opens combined multiplayer setup', (tester) async {
    await tester.pumpWidget(const PokerSetshootApp());

    await tester.tap(find.text('MULTIPLAYER'));
    await tester.pumpAndSettle();

    expect(find.text('Join Meja'), findsWidgets);
    expect(find.text('Host Meja'), findsOneWidget);
    expect(find.text('Buka Meja'), findsOneWidget);
  });
}
