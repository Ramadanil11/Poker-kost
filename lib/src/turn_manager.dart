import 'dart:math';

import 'card_model.dart';
import 'combination.dart';
import 'game_rules.dart';
import 'player_state.dart';

/// Status global permainan.
enum GameStatus { waiting, opening, playing, finished }

/// Metadata pending instant-win ketika Joker sudah berhasil dichop oleh bomb.
class PendingInstantWin {
  const PendingInstantWin({
    required this.jokerOwnerId,
    required this.jokerCount,
    required this.chopperId,
    required this.bombRank,
  });

  final String jokerOwnerId;
  final int jokerCount;
  final String chopperId;
  final Rank bombRank;
}

/// Hasil aturan pembuka ronde pertama: semua pemain wajib membuang kartu 3.
class OpeningDiscardResult {
  const OpeningDiscardResult({
    required this.starterPlayerId,
    required this.starterThreeCount,
    required this.starterHighestSuit,
    required this.note,
  });

  final String starterPlayerId;
  final int starterThreeCount;
  final Suit? starterHighestSuit;
  final String note;
}

/// State immutable seluruh meja.
class GameState {
  const GameState({
    required this.players,
    required this.burnPile,
    required this.openingDiscardPile,
    required this.openingDiscardByPlayer,
    required this.openingSubmittedPlayerIds,
    required this.history,
    required this.activePlayerIndex,
    required this.passCount,
    required this.status,
    required this.roundNumber,
    this.lastPlay,
    this.pendingInstantWin,
    this.openingDiscardResult,
    this.winnerPlayerId,
  });

  final List<PlayerState> players;
  final List<GameCard> burnPile;
  final List<GameCard> openingDiscardPile;
  final Map<String, List<GameCard>> openingDiscardByPlayer;
  final Set<String> openingSubmittedPlayerIds;
  final List<CardPlay> history;
  final int activePlayerIndex;
  final int passCount;
  final GameStatus status;
  final int roundNumber;
  final CardPlay? lastPlay;
  final PendingInstantWin? pendingInstantWin;
  final OpeningDiscardResult? openingDiscardResult;
  final String? winnerPlayerId;

  PlayerState get activePlayer => players[activePlayerIndex];

  /// Membuat salinan state dengan field yang diganti.
  GameState copyWith({
    List<PlayerState>? players,
    List<GameCard>? burnPile,
    List<GameCard>? openingDiscardPile,
    Map<String, List<GameCard>>? openingDiscardByPlayer,
    Set<String>? openingSubmittedPlayerIds,
    List<CardPlay>? history,
    int? activePlayerIndex,
    int? passCount,
    GameStatus? status,
    int? roundNumber,
    Object? lastPlay = _sentinel,
    Object? pendingInstantWin = _sentinel,
    Object? openingDiscardResult = _sentinel,
    Object? winnerPlayerId = _sentinel,
  }) {
    final nextPlayers = List<PlayerState>.unmodifiable(players ?? this.players);
    final nextBurnPile = List<GameCard>.unmodifiable(burnPile ?? this.burnPile);
    final nextOpeningDiscardPile = List<GameCard>.unmodifiable(
      openingDiscardPile ?? this.openingDiscardPile,
    );
    final nextOpeningDiscardByPlayer = {
      for (final entry
          in (openingDiscardByPlayer ?? this.openingDiscardByPlayer).entries)
        entry.key: List<GameCard>.unmodifiable(entry.value),
    };
    final nextOpeningSubmittedPlayerIds = Set<String>.unmodifiable(
      openingSubmittedPlayerIds ?? this.openingSubmittedPlayerIds,
    );
    _assertUniqueCardsAcrossTable(
      nextPlayers,
      nextBurnPile,
      nextOpeningDiscardPile,
      nextOpeningDiscardByPlayer,
    );

    return GameState(
      players: nextPlayers,
      burnPile: nextBurnPile,
      openingDiscardPile: nextOpeningDiscardPile,
      openingDiscardByPlayer:
          Map<String, List<GameCard>>.unmodifiable(nextOpeningDiscardByPlayer),
      openingSubmittedPlayerIds: nextOpeningSubmittedPlayerIds,
      history: List<CardPlay>.unmodifiable(history ?? this.history),
      activePlayerIndex: activePlayerIndex ?? this.activePlayerIndex,
      passCount: passCount ?? this.passCount,
      status: status ?? this.status,
      roundNumber: roundNumber ?? this.roundNumber,
      lastPlay: lastPlay == _sentinel ? this.lastPlay : lastPlay as CardPlay?,
      pendingInstantWin: pendingInstantWin == _sentinel
          ? this.pendingInstantWin
          : pendingInstantWin as PendingInstantWin?,
      openingDiscardResult: openingDiscardResult == _sentinel
          ? this.openingDiscardResult
          : openingDiscardResult as OpeningDiscardResult?,
      winnerPlayerId: winnerPlayerId == _sentinel
          ? this.winnerPlayerId
          : winnerPlayerId as String?,
    );
  }
}

const _sentinel = Object();

/// Turn manager utama. Class ini sengaja memegang state immutable agar mudah
/// dipakai di Flutter state management apa pun: Riverpod, Bloc, Provider, dsb.
class TurnManager {
  TurnManager._(this._state, {GameRules? rules})
      : _rules = rules ?? const GameRules();

  GameState _state;
  final GameRules _rules;

  GameState get state => _state;

  void renamePlayer(String playerId, String name) {
    final index = _playerIndex(playerId);
    final players = _state.players.toList();
    players[index] = players[index].copyWith(name: name);
    _state = _state.copyWith(players: players);
  }

  /// Membuat game baru, mengocok kartu, membagi rata, dan membakar sisa.
  ///
  /// Satu ball berisi 52 kartu standar + 2 Joker. Sisa pembagian masuk burn.
  factory TurnManager.newGame({
    required List<String> playerNames,
    int? seed,
    int roundNumber = 1,
    String? startingPlayerId,
    bool randomizeTurnOrder = false,
    int ballCount = 2,
    GameRules? rules,
  }) {
    _validatePlayerCount(playerNames.length);
    _validateBallCount(ballCount);
    if (roundNumber < 1) {
      throw ArgumentError.value(
          roundNumber, 'roundNumber', 'Must be positive.');
    }

    final random = seed == null ? null : seed + 7919;
    final orderedPlayerNames = playerNames.toList();
    if (randomizeTurnOrder) {
      orderedPlayerNames.shuffle(random == null ? null : Random(random));
    }

    final deck = shuffledFullDeck(seed: seed, ballCount: ballCount);
    final cardsPerPlayer = deck.length ~/ orderedPlayerNames.length;
    var cursor = 0;

    final players = <PlayerState>[];
    for (var i = 0; i < orderedPlayerNames.length; i++) {
      final hand = deck.sublist(cursor, cursor + cardsPerPlayer);
      cursor += cardsPerPlayer;
      players.add(
        PlayerState(
          id: 'P$i',
          name: orderedPlayerNames[i],
          hand: List<GameCard>.unmodifiable(sortCards(hand)),
        ),
      );
    }

    final burnPile = deck.sublist(cursor);
    var activePlayerIndex = 0;
    var status = GameStatus.playing;

    if (roundNumber == 1 && startingPlayerId == null) {
      status = GameStatus.opening;
    } else if (startingPlayerId != null) {
      activePlayerIndex = players.indexWhere(
        (player) => player.id == startingPlayerId,
      );
      if (activePlayerIndex == -1) {
        throw ArgumentError('Unknown startingPlayerId: $startingPlayerId');
      }
    }

    return TurnManager._(
      GameState(
        players: List<PlayerState>.unmodifiable(players),
        burnPile: List<GameCard>.unmodifiable(burnPile),
        openingDiscardPile: const [],
        openingDiscardByPlayer: const {},
        openingSubmittedPlayerIds: const {},
        history: const [],
        activePlayerIndex: activePlayerIndex,
        passCount: 0,
        status: status,
        roundNumber: roundNumber,
      ),
      rules: rules,
    );
  }

  /// Factory khusus test/simulasi agar skenario house-rules bisa dibuat tanpa
  /// bergantung pada hasil shuffle.
  factory TurnManager.fromHands({
    required List<List<GameCard>> hands,
    List<String>? playerNames,
    GameRules? rules,
  }) {
    _validatePlayerCount(hands.length);
    final names = playerNames ??
        List.generate(hands.length, (index) => 'Player ${index + 1}');
    if (names.length != hands.length) {
      throw ArgumentError('playerNames length must match hands length.');
    }

    final players = <PlayerState>[];
    for (var i = 0; i < hands.length; i++) {
      players.add(
        PlayerState(
          id: 'P$i',
          name: names[i],
          hand: List<GameCard>.unmodifiable(sortCards(hands[i])),
        ),
      );
    }

    _assertUniqueCardsAcrossTable(players, const [], const [], const {});
    return TurnManager._(
      GameState(
        players: List<PlayerState>.unmodifiable(players),
        burnPile: const [],
        openingDiscardPile: const [],
        openingDiscardByPlayer: const {},
        openingSubmittedPlayerIds: const {},
        history: const [],
        activePlayerIndex: 0,
        passCount: 0,
        status: GameStatus.playing,
        roundNumber: 1,
      ),
      rules: rules,
    );
  }

  /// Fase pembuka ronde 1: pemain aktif membuang sendiri semua kartu angka 3.
  ///
  /// Engine sengaja mengambil semua rank 3 dari hand pemain aktif agar aturan
  /// "wajib buang 3" tidak bisa dicurangi dengan memilih sebagian saja.
  void submitOpeningThrees(String playerId) {
    if (_state.status != GameStatus.opening) {
      throw StateError('Game is not in opening state.');
    }
    if (_state.activePlayer.id != playerId) {
      throw StateError('It is not $playerId opening turn.');
    }
    if (_state.openingSubmittedPlayerIds.contains(playerId)) {
      throw StateError('$playerId already submitted opening threes.');
    }

    final playerIndex = _playerIndex(playerId);
    final player = _state.players[playerIndex];
    final threes = player.hand
        .where((card) => card.rank == Rank.three)
        .toList(growable: false);

    final players = _state.players.toList();
    if (threes.isNotEmpty) {
      players[playerIndex] = player.removeCards(threes);
    }

    final byPlayer = {
      for (final entry in _state.openingDiscardByPlayer.entries)
        entry.key: entry.value,
      playerId: threes,
    };
    final submitted = {..._state.openingSubmittedPlayerIds, playerId};

    if (submitted.length == _state.players.length) {
      final opening = _resolveOpeningStarter(_state.players, byPlayer);
      _state = _state.copyWith(
        players: players,
        openingDiscardPile: [
          ..._state.openingDiscardPile,
          ...threes,
        ],
        openingDiscardByPlayer: byPlayer,
        openingSubmittedPlayerIds: submitted,
        openingDiscardResult: opening.$2,
        activePlayerIndex: opening.$1,
        status: GameStatus.playing,
      );
      return;
    }

    _state = _state.copyWith(
      players: players,
      openingDiscardPile: [
        ..._state.openingDiscardPile,
        ...threes,
      ],
      openingDiscardByPlayer: byPlayer,
      openingSubmittedPlayerIds: submitted,
      activePlayerIndex: _nextOpeningPlayerIndex(playerIndex, submitted),
    );
  }

  /// Fitur pamer kartu: kartu menjadi public face-up tetapi tetap berada di hand.
  void pamerKartu(String playerId, Iterable<GameCard> selectedCards) {
    _ensurePlaying();
    final index = _playerIndex(playerId);
    final players = _state.players.toList();
    players[index] = players[index].showCards(selectedCards);
    _state = _state.copyWith(players: players);
  }

  /// Membatalkan status pamer untuk kartu tertentu.
  void batalPamerKartu(String playerId, Iterable<GameCard> selectedCards) {
    _ensurePlaying();
    final index = _playerIndex(playerId);
    final players = _state.players.toList();
    players[index] = players[index].hideCards(selectedCards);
    _state = _state.copyWith(players: players);
  }

  /// Memainkan kartu ke arena, memvalidasi kombinasi, rule beat, dan kondisi
  /// instant win Joker-vs-bomb.
  CardPlay playCards(String playerId, Iterable<GameCard> selectedCards) {
    _ensurePlaying();
    if (_state.activePlayer.id != playerId) {
      throw StateError('It is not $playerId turn.');
    }

    final selected = selectedCards.toList(growable: false);
    assertUniqueCards(selected);

    final playerIndex = _playerIndex(playerId);
    final player = _state.players[playerIndex];
    if (!player.hasCards(selected)) {
      throw ArgumentError('Selected cards are not all in $playerId hand.');
    }

    final play = CardPlay(
      playerId: playerId,
      cards: selected,
      turnNumber: _state.history.length,
    );

    final lastPlay = _state.lastPlay;
    if (lastPlay != null && !_rules.canBeat(lastPlay, play)) {
      throw StateError('Selected cards cannot beat current table play.');
    }

    final players = _state.players.toList();
    players[playerIndex] = player.removeCards(selected);

    final pendingInstantWin = _nextPendingInstantWin(lastPlay, play);
    final nextStatus =
        _shouldFinishNormally(players[playerIndex], play, pendingInstantWin)
            ? GameStatus.finished
            : GameStatus.playing;
    final winnerId = nextStatus == GameStatus.finished ? playerId : null;

    _state = _state.copyWith(
      players: players,
      history: [..._state.history, play],
      lastPlay: play,
      pendingInstantWin: pendingInstantWin,
      passCount: 0,
      status: nextStatus,
      winnerPlayerId: winnerId,
      activePlayerIndex: nextStatus == GameStatus.finished
          ? _state.activePlayerIndex
          : _nextPlayerIndex(playerIndex),
    );

    return play;
  }

  /// Pemain aktif pass. Jika semua pemain lain pass terhadap last play, trick
  /// ditutup; pending instant-win diselesaikan di titik ini.
  void pass(String playerId) {
    _ensurePlaying();
    if (_state.activePlayer.id != playerId) {
      throw StateError('It is not $playerId turn.');
    }
    if (_state.lastPlay == null) {
      throw StateError('The leading player cannot pass.');
    }

    final nextPassCount = _state.passCount + 1;
    final requiredPasses = _activePlayerCount() - 1;

    if (nextPassCount >= requiredPasses) {
      _closeTrick();
      return;
    }

    _state = _state.copyWith(
      passCount: nextPassCount,
      activePlayerIndex: _nextPlayerIndex(_state.activePlayerIndex),
    );
  }

  /// Skip paksa untuk timeout/koneksi putus.
  ///
  /// Saat opening, skip tetap membuang semua kartu 3 milik pemain tersebut.
  /// Saat playing dan ada play di meja, skip diperlakukan seperti pass biasa.
  /// Jika pemain sedang lead dan meja kosong, giliran langsung dilempar ke
  /// pemain berikutnya karena pass normal memang tidak legal untuk leader.
  void skipTurn(String playerId) {
    if (_state.activePlayer.id != playerId) {
      throw StateError('It is not $playerId turn.');
    }

    if (_state.status == GameStatus.opening) {
      submitOpeningThrees(playerId);
      return;
    }

    _ensurePlaying();
    if (_state.lastPlay != null) {
      pass(playerId);
      return;
    }

    _state = _state.copyWith(
      activePlayerIndex: _nextPlayerIndex(_state.activePlayerIndex),
      passCount: 0,
    );
  }

  /// Snapshot kartu yang sedang dipamerkan oleh semua pemain.
  Map<String, List<GameCard>> publicShownCards() {
    return {for (final player in _state.players) player.id: player.shownCards};
  }

  /// Menghitung pending instant-win berikutnya berdasarkan play baru.
  ///
  /// Pending dibuat saat Joker-set langsung ditimpa bomb dengan jumlah set yang
  /// sama, lalu dialihkan ke bomber terbaru jika bomb tersebut ditimpa lebih tinggi.
  PendingInstantWin? _nextPendingInstantWin(CardPlay? previous, CardPlay play) {
    if (!play.combo.isBombLike) {
      return null;
    }

    if (previous != null &&
        previous.combo.isJokerSet &&
        play.combo.bombCount == previous.combo.cardCount) {
      return PendingInstantWin(
        jokerOwnerId: previous.playerId,
        jokerCount: previous.combo.cardCount,
        chopperId: play.playerId,
        bombRank: play.combo.highestBombRank!,
      );
    }

    final pending = _state.pendingInstantWin;
    if (pending != null && play.combo.bombCount == pending.jokerCount) {
      return PendingInstantWin(
        jokerOwnerId: pending.jokerOwnerId,
        jokerCount: pending.jokerCount,
        chopperId: play.playerId,
        bombRank: play.combo.highestBombRank!,
      );
    }

    return null;
  }

  /// Normal win terjadi saat pemain menghabiskan hand, kecuali sedang ada
  /// jendela Joker/bomb yang masih harus diberi kesempatan untuk ditimpa.
  bool _shouldFinishNormally(
    PlayerState playerAfterPlay,
    CardPlay play,
    PendingInstantWin? pending,
  ) {
    if (playerAfterPlay.hand.isNotEmpty) return false;
    if (pending != null) return false;
    if (play.combo.isJokerSet && _activePlayerCount() > 2) return false;
    return true;
  }

  /// Menutup trick, memberi lead ke pemain terakhir yang berhasil play, dan
  /// menyelesaikan instant-win jika bomb chop tidak tertimpa lagi.
  void _closeTrick() {
    final lastPlay = _state.lastPlay!;
    final pending = _state.pendingInstantWin;
    if (pending != null && pending.chopperId == lastPlay.playerId) {
      _state = _state.copyWith(
        status: GameStatus.finished,
        winnerPlayerId: pending.chopperId,
      );
      return;
    }

    final leaderIndex = _playerIndex(lastPlay.playerId);
    _state = _state.copyWith(
      lastPlay: null,
      pendingInstantWin: null,
      passCount: 0,
      activePlayerIndex: leaderIndex,
    );
  }

  /// Mengambil indeks pemain berikutnya secara melingkar.
  int _nextPlayerIndex(int fromIndex) {
    return (fromIndex + 1) % _state.players.length;
  }

  /// Mengambil pemain berikutnya yang belum submit opening kartu 3.
  int _nextOpeningPlayerIndex(int fromIndex, Set<String> submittedPlayerIds) {
    var index = fromIndex;
    for (var i = 0; i < _state.players.length; i++) {
      index = (index + 1) % _state.players.length;
      if (!submittedPlayerIds.contains(_state.players[index].id)) {
        return index;
      }
    }
    return fromIndex;
  }

  /// Menghitung pemain aktif untuk kebutuhan pass-cycle.
  int _activePlayerCount() {
    return _state.players.length;
  }

  /// Mengambil index pemain dari id.
  int _playerIndex(String playerId) {
    final index = _state.players.indexWhere((player) => player.id == playerId);
    if (index == -1) throw ArgumentError('Unknown player id: $playerId');
    return index;
  }

  /// Guard agar action tidak berjalan saat game belum mulai atau sudah selesai.
  void _ensurePlaying() {
    if (_state.status != GameStatus.playing) {
      throw StateError('Game is not in playing state.');
    }
  }
}

/// Menghitung pemenang opening setelah semua pemain membuang sendiri kartu 3.
///
/// Starter dipilih dari jumlah kartu 3 terbanyak; jika seri, suit 3 tertinggi
/// menang. Jika tidak ada pemain yang memiliki 3, pemain pertama menjadi
/// fallback deterministik.
(int, OpeningDiscardResult) _resolveOpeningStarter(
  List<PlayerState> players,
  Map<String, List<GameCard>> openingDiscardByPlayer,
) {
  var bestPlayerIndex = 0;
  var bestThreeCount = -1;
  Suit? bestHighestSuit;

  for (var i = 0; i < players.length; i++) {
    final threes = openingDiscardByPlayer[players[i].id] ?? const <GameCard>[];

    final highestSuit = threes.isEmpty
        ? null
        : threes
            .map((card) => card.suit!)
            .reduce((a, b) => a.strength >= b.strength ? a : b);
    final highestSuitStrength = highestSuit?.strength ?? -1;
    final bestHighestSuitStrength = bestHighestSuit?.strength ?? -1;

    if (threes.length > bestThreeCount ||
        (threes.length == bestThreeCount &&
            highestSuitStrength > bestHighestSuitStrength)) {
      bestPlayerIndex = i;
      bestThreeCount = threes.length;
      bestHighestSuit = highestSuit;
    }
  }

  final starter = players[bestPlayerIndex];
  final totalDiscarded = openingDiscardByPlayer.values
      .fold<int>(0, (sum, cards) => sum + cards.length);
  final note = totalDiscarded == 0
      ? 'Tidak ada kartu 3 di hand pemain; starter fallback adalah ${starter.name}.'
      : '${starter.name} jalan duluan dari opening kartu 3.';

  return (
    bestPlayerIndex,
    OpeningDiscardResult(
      starterPlayerId: starter.id,
      starterThreeCount: bestThreeCount < 0 ? 0 : bestThreeCount,
      starterHighestSuit: bestHighestSuit,
      note: note,
    ),
  );
}

/// Validasi jumlah pemain sesuai requirement: 2 sampai 10.
void _validatePlayerCount(int playerCount) {
  if (playerCount < 2 || playerCount > 10) {
    throw ArgumentError.value(
      playerCount,
      'playerCount',
      'Must be between 2 and 10.',
    );
  }
}

void _validateBallCount(int ballCount) {
  if (ballCount < 1 || ballCount > 4) {
    throw ArgumentError.value(
      ballCount,
      'ballCount',
      'Must be between 1 and 4.',
    );
  }
}

/// Memastikan tidak ada kartu fisik yang muncul ganda di hand pemain atau burn.
void _assertUniqueCardsAcrossTable(
  List<PlayerState> players,
  List<GameCard> burnPile,
  List<GameCard> openingDiscardPile,
  Map<String, List<GameCard>> openingDiscardByPlayer,
) {
  final allCards = <GameCard>[
    for (final player in players) ...player.hand,
    ...burnPile,
    ...openingDiscardPile,
  ];
  assertUniqueCards(allCards);

  final mappedOpeningCards = <GameCard>[
    for (final cards in openingDiscardByPlayer.values) ...cards,
  ];
  assertUniqueCards(mappedOpeningCards);
}
