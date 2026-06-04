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

  test('timeout skip can move a leading player on an empty table', () {
    final manager = TurnManager.newGame(
      playerNames: ['A', 'B', 'C', 'D'],
      seed: 11,
      roundNumber: 2,
      startingPlayerId: 'P0',
    );

    expect(manager.state.activePlayer.id, 'P0');
    manager.skipTurn('P0');

    expect(manager.state.activePlayer.id, 'P1');
    expect(manager.state.lastPlay, isNull);
  });

  test('last joker immediately wins in a two player game', () {
    final joker = GameCard.joker(0);
    final manager = TurnManager.fromHands(
      playerNames: ['A', 'B'],
      hands: [
        [joker],
        [
          GameCard.standard(rank: Rank.four, suit: Suit.club, deckIndex: 0),
          GameCard.standard(rank: Rank.four, suit: Suit.diamond, deckIndex: 0),
          GameCard.standard(rank: Rank.four, suit: Suit.heart, deckIndex: 0),
          GameCard.standard(rank: Rank.four, suit: Suit.spade, deckIndex: 0),
        ],
      ],
    );

    manager.playCards('P0', [joker]);

    expect(manager.state.status, GameStatus.finished);
    expect(manager.state.winnerPlayerId, 'P0');
  });
}
