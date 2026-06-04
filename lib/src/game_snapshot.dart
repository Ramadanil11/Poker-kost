import 'card_model.dart';
import 'combination.dart';
import 'turn_manager.dart';

/// Snapshot yang aman dikirim ke client LAN.
///
/// Hand pemain lain tidak dikirim; client hanya menerima hand miliknya sendiri,
/// jumlah kartu lawan, kartu pamer publik, dan kartu yang sudah dimainkan.
class GameSnapshot {
  const GameSnapshot({
    required this.viewerPlayerId,
    required this.players,
    required this.activePlayerId,
    required this.status,
    required this.roundNumber,
    required this.burnCount,
    required this.openingDiscardPile,
    required this.openingText,
    required this.lastPlayPlayerId,
    required this.lastPlayCards,
    required this.lastPlayLabel,
    required this.pendingText,
    required this.winnerPlayerId,
    this.targetWins = 0,
    this.winsByPlayerId = const {},
  });

  factory GameSnapshot.fromState(
    GameState state,
    String viewerPlayerId, {
    int targetWins = 0,
    Map<String, int> winsByPlayerId = const {},
  }) {
    final lastPlay = state.lastPlay;
    return GameSnapshot(
      viewerPlayerId: viewerPlayerId,
      players: [
        for (final player in state.players)
          PlayerSnapshot(
            id: player.id,
            name: player.name,
            handCount: player.hand.length,
            shownCards: player.shownCards,
            openingCards: state.openingDiscardByPlayer[player.id] ?? const [],
            hand: player.id == viewerPlayerId ? player.hand : const [],
          ),
      ],
      activePlayerId: state.activePlayer.id,
      status: state.status,
      roundNumber: state.roundNumber,
      burnCount: state.burnPile.length,
      openingDiscardPile: state.openingDiscardPile,
      openingText: _openingText(state),
      lastPlayPlayerId: lastPlay?.playerId,
      lastPlayCards: lastPlay?.cards ?? const [],
      lastPlayLabel: lastPlay == null ? null : comboLabel(lastPlay.combo),
      pendingText: _pendingText(state),
      winnerPlayerId: state.winnerPlayerId,
      targetWins: targetWins,
      winsByPlayerId: winsByPlayerId,
    );
  }

  factory GameSnapshot.fromJson(Map<String, Object?> json) {
    return GameSnapshot(
      viewerPlayerId: json['viewerPlayerId']! as String,
      players: [
        for (final item in json['players']! as List<Object?>)
          PlayerSnapshot.fromJson(item! as Map<String, Object?>),
      ],
      activePlayerId: json['activePlayerId']! as String,
      status: GameStatus.values.firstWhere(
        (status) => status.name == json['status'],
      ),
      roundNumber: json['roundNumber']! as int,
      burnCount: json['burnCount']! as int,
      openingDiscardPile: _cardsFromJson(json['openingDiscardPile']),
      openingText: json['openingText'] as String?,
      lastPlayPlayerId: json['lastPlayPlayerId'] as String?,
      lastPlayCards: _cardsFromJson(json['lastPlayCards']),
      lastPlayLabel: json['lastPlayLabel'] as String?,
      pendingText: json['pendingText'] as String?,
      winnerPlayerId: json['winnerPlayerId'] as String?,
      targetWins: (json['targetWins'] as int?) ?? 0,
      winsByPlayerId: {
        for (final entry
            in ((json['winsByPlayerId'] as Map<Object?, Object?>?) ?? const {})
                .entries)
          entry.key! as String: entry.value! as int,
      },
    );
  }

  final String viewerPlayerId;
  final List<PlayerSnapshot> players;
  final String activePlayerId;
  final GameStatus status;
  final int roundNumber;
  final int burnCount;
  final List<GameCard> openingDiscardPile;
  final String? openingText;
  final String? lastPlayPlayerId;
  final List<GameCard> lastPlayCards;
  final String? lastPlayLabel;
  final String? pendingText;
  final String? winnerPlayerId;

  /// Jumlah ronde menang yang dibutuhkan untuk memenangkan match (0 = tak dibatasi).
  final int targetWins;

  /// Skor ronde per playerId untuk match berjalan.
  final Map<String, int> winsByPlayerId;

  PlayerSnapshot get viewer =>
      players.firstWhere((player) => player.id == viewerPlayerId);

  PlayerSnapshot get activePlayer =>
      players.firstWhere((player) => player.id == activePlayerId);

  Map<String, Object?> toJson() {
    return {
      'viewerPlayerId': viewerPlayerId,
      'players': [for (final player in players) player.toJson()],
      'activePlayerId': activePlayerId,
      'status': status.name,
      'roundNumber': roundNumber,
      'burnCount': burnCount,
      'openingDiscardPile': _cardsToJson(openingDiscardPile),
      'openingText': openingText,
      'lastPlayPlayerId': lastPlayPlayerId,
      'lastPlayCards': _cardsToJson(lastPlayCards),
      'lastPlayLabel': lastPlayLabel,
      'pendingText': pendingText,
      'winnerPlayerId': winnerPlayerId,
      'targetWins': targetWins,
      'winsByPlayerId': winsByPlayerId,
    };
  }
}

class PlayerSnapshot {
  const PlayerSnapshot({
    required this.id,
    required this.name,
    required this.handCount,
    required this.shownCards,
    required this.openingCards,
    required this.hand,
  });

  factory PlayerSnapshot.fromJson(Map<String, Object?> json) {
    return PlayerSnapshot(
      id: json['id']! as String,
      name: json['name']! as String,
      handCount: json['handCount']! as int,
      shownCards: _cardsFromJson(json['shownCards']),
      openingCards: _cardsFromJson(json['openingCards']),
      hand: _cardsFromJson(json['hand']),
    );
  }

  final String id;
  final String name;
  final int handCount;
  final List<GameCard> shownCards;
  final List<GameCard> openingCards;
  final List<GameCard> hand;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'handCount': handCount,
      'shownCards': _cardsToJson(shownCards),
      'openingCards': _cardsToJson(openingCards),
      'hand': _cardsToJson(hand),
    };
  }
}

String comboLabel(Combination combo) {
  final rank = combo.primaryRank?.label;
  return switch (combo.kind) {
    PlayKind.single => 'Single $rank',
    PlayKind.pair => 'Pair $rank',
    PlayKind.triple => 'Triple $rank',
    PlayKind.kawal => 'Kawal $rank',
    PlayKind.straight => 'Straight sampai $rank',
    PlayKind.pairSequence => 'Urutan Pair sampai $rank',
    PlayKind.tripleSequence => 'Urutan Triple sampai $rank',
    PlayKind.bomb => 'Bomb $rank',
    PlayKind.multiBomb => '${combo.bombCount}x Bomb',
    PlayKind.jokerSet => '${combo.cardCount} Joker',
  };
}

List<Map<String, Object?>> _cardsToJson(List<GameCard> cards) {
  return [for (final card in cards) card.toJson()];
}

List<GameCard> _cardsFromJson(Object? value) {
  if (value == null) return const [];
  return [
    for (final item in value as List<Object?>)
      GameCard.fromId((item! as Map<String, Object?>)['id']! as String),
  ];
}

String? _openingText(GameState state) {
  if (state.status == GameStatus.opening) {
    return null;
  }

  if (state.openingDiscardResult != null && state.history.isEmpty) {
    return null;
  }

  return null;
}

String? _pendingText(GameState state) {
  final pending = state.pendingInstantWin;
  if (pending == null) return null;

  final chopper = state.players.firstWhere(
    (player) => player.id == pending.chopperId,
  );
  return 'Instant win pending: ${chopper.name} harus tidak tertimpa bomb lebih tinggi.';
}
