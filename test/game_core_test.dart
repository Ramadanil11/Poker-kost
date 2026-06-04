import 'package:flutter_test/flutter_test.dart';

import 'package:custom_card_core/custom_card_game.dart';

void main() {
  test('builds selectable card balls', () {
    for (var ballCount = 1; ballCount <= 4; ballCount++) {
      final deck = buildFullDeck(ballCount: ballCount);

      expect(deck, hasLength(ballCount * 54));
      expect(deck.map((card) => card.id).toSet(), hasLength(deck.length));
    }
  });

  test('deals selected ball count through turn manager', () {
    final manager = TurnManager.newGame(
      playerNames: ['A', 'B', 'C', 'D'],
      seed: 9,
      ballCount: 4,
    );

    expect(manager.state.players.first.hand, hasLength(54));
    expect(manager.state.burnPile, isEmpty);
  });
}
