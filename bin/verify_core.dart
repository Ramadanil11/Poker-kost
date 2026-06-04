import 'package:custom_card_core/custom_card_game.dart';

void main() {
  verifyDeckAndDeal();
  verifyHeartAbsoluteRule();
  verifyPamerKartu();
  verifyGroupedSequences();
  verifyKawal();
  verifyJokerWildcards();
  verifyJokerColorStrength();
  verifyJokerBombInstantWin();
  print('Core verification passed.');
}

void verifyDeckAndDeal() {
  final deck = buildFullDeck();
  assert(deck.length == 108);
  assert(deck.map((card) => card.id).toSet().length == 108);

  final manager = TurnManager.newGame(
    playerNames: List.generate(10, (index) => 'P$index'),
    seed: 7,
  );
  assert(manager.state.status == GameStatus.opening);
  while (manager.state.status == GameStatus.opening) {
    manager.submitOpeningThrees(manager.state.activePlayer.id);
  }
  final activeCardsAfterOpening = manager.state.players
          .fold<int>(0, (sum, player) => sum + player.hand.length) +
      manager.state.openingDiscardPile.length;
  assert(activeCardsAfterOpening == 100);
  assert(manager.state.burnPile.length == 8);
  assert(manager.state.openingDiscardPile
      .every((card) => card.rank == Rank.three));
}

void verifyHeartAbsoluteRule() {
  const rules = GameRules();
  final fiveHeart = GameCard.standard(
    rank: Rank.five,
    suit: Suit.heart,
    deckIndex: 0,
  );
  final fiveHeartTwin = GameCard.standard(
    rank: Rank.five,
    suit: Suit.heart,
    deckIndex: 1,
  );
  final sixSpade = GameCard.standard(
    rank: Rank.six,
    suit: Suit.spade,
    deckIndex: 0,
  );

  final previous = CardPlay(playerId: 'P0', cards: [fiveHeart], turnNumber: 0);
  final sameRankHeart = CardPlay(
    playerId: 'P1',
    cards: [fiveHeartTwin],
    turnNumber: 1,
  );
  final higherRank = CardPlay(playerId: 'P1', cards: [sixSpade], turnNumber: 2);

  assert(!rules.canBeat(previous, sameRankHeart));
  assert(rules.canBeat(previous, higherRank));
}

void verifyPamerKartu() {
  final cardA = GameCard.standard(
    rank: Rank.three,
    suit: Suit.spade,
    deckIndex: 0,
  );
  final cardB = GameCard.standard(
    rank: Rank.four,
    suit: Suit.club,
    deckIndex: 0,
  );
  final manager = TurnManager.fromHands(
    hands: [
      [cardA, cardB],
      [GameCard.standard(rank: Rank.five, suit: Suit.spade, deckIndex: 0)],
    ],
  );

  manager.pamerKartu('P0', [cardA]);
  assert(manager.publicShownCards()['P0']!.single.id == cardA.id);
  assert(manager.state.players.first.hand.length == 2);
}

void verifyGroupedSequences() {
  final pairSequence = [
    ..._cardsForRank(Rank.three, 2),
    ..._cardsForRank(Rank.four, 2),
    ..._cardsForRank(Rank.five, 2),
  ];
  final pairCombo = analyzeCombination(pairSequence);
  assert(pairCombo.kind == PlayKind.pairSequence);
  assert(pairCombo.cardCount == 6);
  assert(pairCombo.primaryRank == Rank.five);

  final longPairSequence = [
    ..._cardsForRank(Rank.three, 2),
    ..._cardsForRank(Rank.four, 2),
    ..._cardsForRank(Rank.five, 2),
    ..._cardsForRank(Rank.six, 2),
    ..._cardsForRank(Rank.seven, 2),
  ];
  assert(analyzeCombination(longPairSequence).kind == PlayKind.pairSequence);

  final tripleSequence = [
    ..._cardsForRank(Rank.three, 3),
    ..._cardsForRank(Rank.four, 3),
  ];
  final tripleCombo = analyzeCombination(tripleSequence);
  assert(tripleCombo.kind == PlayKind.tripleSequence);
  assert(tripleCombo.cardCount == 6);
  assert(tripleCombo.primaryRank == Rank.four);

  final higherPairSequence = CardPlay(
    playerId: 'P1',
    cards: [
      ..._cardsForRank(Rank.four, 2),
      ..._cardsForRank(Rank.five, 2),
      ..._cardsForRank(Rank.six, 2),
    ],
    turnNumber: 1,
  );
  final lowerPairSequence = CardPlay(
    playerId: 'P0',
    cards: pairSequence,
    turnNumber: 0,
  );
  assert(const GameRules().canBeat(lowerPairSequence, higherPairSequence));

  var rejectedShortPairSequence = false;
  try {
    analyzeCombination([
      ..._cardsForRank(Rank.three, 2),
      ..._cardsForRank(Rank.four, 2),
    ]);
  } on ArgumentError {
    rejectedShortPairSequence = true;
  }
  assert(rejectedShortPairSequence);
}

void verifyKawal() {
  final kawal = [
    ..._cardsForRank(Rank.five, 3),
    ..._cardsForRank(Rank.nine, 2),
  ];
  final combo = analyzeCombination(kawal);
  assert(combo.kind == PlayKind.kawal);
  assert(combo.cardCount == 5);
  assert(combo.primaryRank == Rank.five);

  final lowerKawal = CardPlay(
    playerId: 'P0',
    cards: [
      ..._cardsForRank(Rank.five, 3),
      ..._cardsForRank(Rank.nine, 2),
    ],
    turnNumber: 0,
  );
  final higherKawal = CardPlay(
    playerId: 'P1',
    cards: [
      ..._cardsForRank(Rank.six, 3),
      ..._cardsForRank(Rank.three, 2),
    ],
    turnNumber: 1,
  );
  assert(const GameRules().canBeat(lowerKawal, higherKawal));

  final fiveOfKindCombo = analyzeCombination(_cardsForRank(Rank.seven, 5));
  assert(fiveOfKindCombo.kind == PlayKind.kawal);
  assert(fiveOfKindCombo.primaryRank == Rank.seven);
}

void verifyJokerWildcards() {
  final jokerKawal = analyzeCombination([
    ..._cardsForRank(Rank.five, 2),
    ..._cardsForRank(Rank.nine, 2),
    GameCard.joker(0),
  ]);
  assert(jokerKawal.kind == PlayKind.kawal);

  final jokerStraight = analyzeCombination([
    GameCard.standard(rank: Rank.three, suit: Suit.spade, deckIndex: 0),
    GameCard.standard(rank: Rank.four, suit: Suit.spade, deckIndex: 0),
    GameCard.standard(rank: Rank.six, suit: Suit.spade, deckIndex: 0),
    GameCard.standard(rank: Rank.seven, suit: Suit.spade, deckIndex: 0),
    GameCard.joker(1),
  ]);
  assert(jokerStraight.kind == PlayKind.straight);
  assert(jokerStraight.primaryRank == Rank.seven);

  final jokerPairSequence = analyzeCombination([
    ..._cardsForRank(Rank.three, 2),
    ..._cardsForRank(Rank.four, 1),
    ..._cardsForRank(Rank.five, 2),
    GameCard.joker(2),
  ]);
  assert(jokerPairSequence.kind == PlayKind.pairSequence);
}

void verifyJokerColorStrength() {
  final blackJoker = CardPlay(
    playerId: 'P0',
    cards: [GameCard.joker(0)],
    turnNumber: 0,
  );
  final redJoker = CardPlay(
    playerId: 'P1',
    cards: [GameCard.joker(2)],
    turnNumber: 1,
  );

  assert(const GameRules().canBeat(blackJoker, redJoker));
  assert(!const GameRules().canBeat(redJoker, blackJoker));
}

List<GameCard> _cardsForRank(Rank rank, int count) {
  final suits = [Suit.spade, Suit.club, Suit.diamond, Suit.heart];
  return [
    for (var i = 0; i < count; i++)
      GameCard.standard(
        rank: rank,
        suit: suits[i % suits.length],
        deckIndex: i ~/ suits.length,
      ),
  ];
}

void verifyJokerBombInstantWin() {
  final joker = GameCard.joker(0);
  final p0Extra = GameCard.standard(
    rank: Rank.seven,
    suit: Suit.spade,
    deckIndex: 0,
  );
  final p1Extra = GameCard.standard(
    rank: Rank.eight,
    suit: Suit.spade,
    deckIndex: 0,
  );
  final p2Extra = GameCard.standard(
    rank: Rank.nine,
    suit: Suit.spade,
    deckIndex: 0,
  );

  final bomb3 = [
    GameCard.standard(rank: Rank.three, suit: Suit.spade, deckIndex: 0),
    GameCard.standard(rank: Rank.three, suit: Suit.club, deckIndex: 0),
    GameCard.standard(rank: Rank.three, suit: Suit.diamond, deckIndex: 0),
    GameCard.standard(rank: Rank.three, suit: Suit.heart, deckIndex: 0),
  ];
  final bomb4 = [
    GameCard.standard(rank: Rank.four, suit: Suit.spade, deckIndex: 0),
    GameCard.standard(rank: Rank.four, suit: Suit.club, deckIndex: 0),
    GameCard.standard(rank: Rank.four, suit: Suit.diamond, deckIndex: 0),
    GameCard.standard(rank: Rank.four, suit: Suit.heart, deckIndex: 0),
  ];

  final manager = TurnManager.fromHands(
    hands: [
      [joker, p0Extra],
      [...bomb3, p1Extra],
      [...bomb4, p2Extra],
    ],
  );

  manager.playCards('P0', [joker]);
  manager.playCards('P1', bomb3);
  manager.playCards('P2', bomb4);
  manager.pass('P0');
  manager.pass('P1');

  assert(manager.state.status == GameStatus.finished);
  assert(manager.state.winnerPlayerId == 'P2');
}
