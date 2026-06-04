import 'card_model.dart';

/// Jenis kombinasi yang didukung core engine.
///
/// Scope ini sengaja memisahkan regular play dari bomb dan joker agar house
/// rules seperti instant win bisa diproses tanpa if-else yang tersebar.
enum PlayKind {
  single,
  pair,
  triple,
  kawal,
  straight,
  pairSequence,
  tripleSequence,
  bomb,
  multiBomb,
  jokerSet,
}

/// Hasil analisis kartu yang dimainkan.
class Combination {
  const Combination({
    required this.kind,
    required this.cardCount,
    required this.primaryRank,
    required this.highestSuit,
    this.bombCount = 0,
    this.bombRanks = const [],
    this.jokerStrength = 0,
  });

  final PlayKind kind;
  final int cardCount;

  /// Rank utama untuk komparasi. Untuk straight, ini rank kartu tertinggi.
  /// Joker tidak memiliki rank, sehingga nilainya null.
  final Rank? primaryRank;

  /// Suit tertinggi yang muncul di kombinasi, dipakai untuk tie non-heart.
  final Suit? highestSuit;

  /// Jumlah set bomb dalam play. Bomb biasa = 1, 8 kartu bomb = 2, dst.
  final int bombCount;

  /// Rank setiap set bomb, terurut rendah ke tinggi.
  final List<Rank> bombRanks;

  /// Nilai tertinggi di Joker-set. Black Joker = 0, Red Joker = 1.
  final int jokerStrength;

  bool get isBombLike => kind == PlayKind.bomb || kind == PlayKind.multiBomb;
  bool get isJokerSet => kind == PlayKind.jokerSet;
  bool get isRegular => !isBombLike && !isJokerSet;

  Rank? get highestBombRank => bombRanks.isEmpty ? null : bombRanks.last;
}

/// Satu play legal yang sudah terikat ke pemain tertentu.
class CardPlay {
  CardPlay({
    required this.playerId,
    required Iterable<GameCard> cards,
    required this.turnNumber,
  })  : cards = List.unmodifiable(cards),
        combo = analyzeCombination(cards);

  final String playerId;
  final List<GameCard> cards;
  final int turnNumber;
  final Combination combo;

  bool get containsHeart => cards.any((card) => card.isHeart);

  @override
  String toString() =>
      '$playerId: ${cards.map((card) => card.label).join(', ')}';
}

/// Menganalisis selected cards menjadi kombinasi legal.
///
/// Fungsi ini juga menjadi gerbang validasi bentuk play: campuran Joker dengan
/// kartu standar tidak diterima, dan semua kartu harus unik secara fisik.
Combination analyzeCombination(Iterable<GameCard> selectedCards) {
  final cards = selectedCards.toList(growable: false);
  if (cards.isEmpty) {
    throw ArgumentError('At least one card must be selected.');
  }
  assertUniqueCards(cards);

  final jokerCount = cards.where((card) => card.isJoker).length;
  if (jokerCount == cards.length) {
    if (jokerCount > 3) {
      throw ArgumentError('Only 1, 2, or 3 Jokers can be played together.');
    }
    return Combination(
      kind: PlayKind.jokerSet,
      cardCount: cards.length,
      primaryRank: null,
      highestSuit: null,
      jokerStrength: cards
          .map((card) => card.jokerStrength)
          .reduce((a, b) => a >= b ? a : b),
    );
  }

  final standardCards =
      cards.where((card) => !card.isJoker).toList(growable: false);
  final byRank = _groupByRank(standardCards);
  final highestSuit =
      standardCards.isEmpty ? null : _highestSuit(standardCards);

  if (jokerCount > 0) {
    final wildcardCombo = _analyzeWildcardCombination(
      cards.length,
      byRank,
      jokerCount,
      highestSuit,
    );
    if (wildcardCombo != null) return wildcardCombo;
    throw ArgumentError('Unsupported Joker wildcard combination.');
  }

  if (byRank.length == 1) {
    final rank = byRank.keys.single;
    return switch (cards.length) {
      1 => Combination(
          kind: PlayKind.single,
          cardCount: 1,
          primaryRank: rank,
          highestSuit: highestSuit,
        ),
      2 => Combination(
          kind: PlayKind.pair,
          cardCount: 2,
          primaryRank: rank,
          highestSuit: highestSuit,
        ),
      3 => Combination(
          kind: PlayKind.triple,
          cardCount: 3,
          primaryRank: rank,
          highestSuit: highestSuit,
        ),
      4 => Combination(
          kind: PlayKind.bomb,
          cardCount: 4,
          primaryRank: rank,
          highestSuit: highestSuit,
          bombCount: 1,
          bombRanks: [rank],
        ),
      5 => Combination(
          kind: PlayKind.kawal,
          cardCount: 5,
          primaryRank: rank,
          highestSuit: highestSuit,
        ),
      _ when cards.length % 4 == 0 => Combination(
          kind: PlayKind.multiBomb,
          cardCount: cards.length,
          primaryRank: rank,
          highestSuit: highestSuit,
          bombCount: cards.length ~/ 4,
          bombRanks: List.filled(cards.length ~/ 4, rank),
        ),
      _ => throw ArgumentError('Unsupported same-rank combination.'),
    };
  }

  if (_isKawal(byRank)) {
    final tripleRank = byRank.length == 1
        ? byRank.keys.single
        : byRank.entries.firstWhere((entry) => entry.value.length == 3).key;
    return Combination(
      kind: PlayKind.kawal,
      cardCount: cards.length,
      primaryRank: tripleRank,
      highestSuit: highestSuit,
    );
  }

  if (_isMultiBomb(byRank)) {
    final ranks = <Rank>[];
    for (final entry in byRank.entries) {
      for (var i = 0; i < entry.value.length ~/ 4; i++) {
        ranks.add(entry.key);
      }
    }
    ranks.sort((a, b) => a.strength.compareTo(b.strength));

    return Combination(
      kind: PlayKind.multiBomb,
      cardCount: cards.length,
      primaryRank: ranks.last,
      highestSuit: highestSuit,
      bombCount: cards.length ~/ 4,
      bombRanks: ranks,
    );
  }

  if (_isStraight(byRank)) {
    final ranks = byRank.keys.toList()
      ..sort((a, b) => a.strength.compareTo(b.strength));
    return Combination(
      kind: PlayKind.straight,
      cardCount: cards.length,
      primaryRank: ranks.last,
      highestSuit: highestSuit,
    );
  }

  if (_isGroupedSequence(byRank, groupSize: 2, minRankCount: 3)) {
    final ranks = byRank.keys.toList()
      ..sort((a, b) => a.strength.compareTo(b.strength));
    return Combination(
      kind: PlayKind.pairSequence,
      cardCount: cards.length,
      primaryRank: ranks.last,
      highestSuit: highestSuit,
    );
  }

  if (_isGroupedSequence(byRank, groupSize: 3, minRankCount: 2)) {
    final ranks = byRank.keys.toList()
      ..sort((a, b) => a.strength.compareTo(b.strength));
    return Combination(
      kind: PlayKind.tripleSequence,
      cardCount: cards.length,
      primaryRank: ranks.last,
      highestSuit: highestSuit,
    );
  }

  throw ArgumentError('Unsupported card combination.');
}

/// Mengelompokkan kartu standar berdasarkan rank.
Map<Rank, List<GameCard>> _groupByRank(List<GameCard> cards) {
  final groups = <Rank, List<GameCard>>{};
  for (final card in cards) {
    groups.putIfAbsent(card.rank!, () => <GameCard>[]).add(card);
  }
  return groups;
}

/// Mencari suit tertinggi dalam kombinasi standar.
Suit _highestSuit(List<GameCard> cards) {
  return cards
      .map((card) => card.suit!)
      .reduce((a, b) => a.strength >= b.strength ? a : b);
}

/// Kawal adalah kombinasi 5 kartu: satu triple dan satu pair.
///
/// Rank utama untuk membandingkan kawal adalah rank dari triple-nya.
bool _isKawal(Map<Rank, List<GameCard>> byRank) {
  if (byRank.length == 1 && byRank.values.single.length == 5) return true;
  if (byRank.length != 2) return false;
  final groupSizes = byRank.values.map((cards) => cards.length).toList()
    ..sort();
  return groupSizes[0] == 2 && groupSizes[1] == 3;
}

Combination? _analyzeWildcardCombination(
  int totalCardCount,
  Map<Rank, List<GameCard>> byRank,
  int jokerCount,
  Suit? highestSuit,
) {
  final kawalRank = _wildcardKawalRank(totalCardCount, byRank, jokerCount);
  if (kawalRank != null) {
    return Combination(
      kind: PlayKind.kawal,
      cardCount: totalCardCount,
      primaryRank: kawalRank,
      highestSuit: highestSuit,
    );
  }

  final straightRank = _wildcardSequenceHighRank(
    totalCardCount,
    byRank,
    jokerCount,
    groupSize: 1,
    minRankCount: 5,
  );
  if (straightRank != null) {
    return Combination(
      kind: PlayKind.straight,
      cardCount: totalCardCount,
      primaryRank: straightRank,
      highestSuit: highestSuit,
    );
  }

  final pairSequenceRank = _wildcardSequenceHighRank(
    totalCardCount,
    byRank,
    jokerCount,
    groupSize: 2,
    minRankCount: 3,
  );
  if (pairSequenceRank != null) {
    return Combination(
      kind: PlayKind.pairSequence,
      cardCount: totalCardCount,
      primaryRank: pairSequenceRank,
      highestSuit: highestSuit,
    );
  }

  final tripleSequenceRank = _wildcardSequenceHighRank(
    totalCardCount,
    byRank,
    jokerCount,
    groupSize: 3,
    minRankCount: 2,
  );
  if (tripleSequenceRank != null) {
    return Combination(
      kind: PlayKind.tripleSequence,
      cardCount: totalCardCount,
      primaryRank: tripleSequenceRank,
      highestSuit: highestSuit,
    );
  }

  return null;
}

Rank? _wildcardKawalRank(
  int totalCardCount,
  Map<Rank, List<GameCard>> byRank,
  int jokerCount,
) {
  if (totalCardCount != 5) return null;
  Rank? bestRank;

  for (final tripleRank in Rank.values) {
    var remainingJokers = jokerCount;
    final tripleNeed = 3 - (byRank[tripleRank]?.length ?? 0);
    if (tripleNeed < 0 || tripleNeed > remainingJokers) continue;
    remainingJokers -= tripleNeed;

    var pairPossible = false;
    for (final pairRank in Rank.values) {
      final pairNeed = 2 - (byRank[pairRank]?.length ?? 0);
      if (pairNeed >= 0 && pairNeed <= remainingJokers) {
        pairPossible = true;
        break;
      }
    }
    if (!pairPossible) continue;

    if (bestRank == null || tripleRank.strength > bestRank.strength) {
      bestRank = tripleRank;
    }
  }

  return bestRank;
}

Rank? _wildcardSequenceHighRank(
  int totalCardCount,
  Map<Rank, List<GameCard>> byRank,
  int jokerCount, {
  required int groupSize,
  required int minRankCount,
}) {
  if (totalCardCount % groupSize != 0) return null;
  final rankCount = totalCardCount ~/ groupSize;
  if (rankCount < minRankCount) return null;

  final straightRanks =
      Rank.values.where((rank) => rank.canBeInStraight).toList();
  Rank? bestHighRank;
  for (var start = 0; start <= straightRanks.length - rankCount; start++) {
    final window = straightRanks.sublist(start, start + rankCount);
    if (!byRank.keys.every(window.contains)) continue;
    var neededJokers = 0;
    var legal = true;
    for (final rank in window) {
      final count = byRank[rank]?.length ?? 0;
      if (count > groupSize) {
        legal = false;
        break;
      }
      neededJokers += groupSize - count;
    }
    if (!legal || neededJokers != jokerCount) continue;

    final highRank = window.last;
    if (bestHighRank == null || highRank.strength > bestHighRank.strength) {
      bestHighRank = highRank;
    }
  }

  return bestHighRank;
}

/// Multi-bomb legal jika total kartu kelipatan 4 dan setiap rank dapat dibagi
/// menjadi satu atau beberapa set four-of-a-kind.
bool _isMultiBomb(Map<Rank, List<GameCard>> byRank) {
  final totalCards = byRank.values.fold<int>(
    0,
    (sum, cards) => sum + cards.length,
  );
  if (totalCards < 8 || totalCards % 4 != 0) return false;
  return byRank.values.every((cards) => cards.length % 4 == 0);
}

/// Straight minimal 5 kartu, rank berurutan, tanpa rank 2, dan tanpa duplikasi
/// rank. Joker tidak dipakai sebagai wildcard di core rules ini.
bool _isStraight(Map<Rank, List<GameCard>> byRank) {
  if (byRank.length < 5) return false;
  if (byRank.values.any((cards) => cards.length != 1)) return false;

  final ranks = byRank.keys.toList()
    ..sort((a, b) => a.strength.compareTo(b.strength));
  if (ranks.any((rank) => !rank.canBeInStraight)) return false;

  for (var i = 1; i < ranks.length; i++) {
    if (ranks[i].strength != ranks[i - 1].strength + 1) {
      return false;
    }
  }
  return true;
}

/// Urutan kembar, misalnya:
/// - pair sequence: 33 44 55, minimal 3 rank berurutan / total 6 kartu.
/// - triple sequence: 333 444, minimal 2 rank berurutan / total 6 kartu.
///
/// Rank 2 tidak boleh masuk urutan, mengikuti pola straight biasa.
bool _isGroupedSequence(
  Map<Rank, List<GameCard>> byRank, {
  required int groupSize,
  required int minRankCount,
}) {
  if (byRank.length < minRankCount) return false;
  if (byRank.values.any((cards) => cards.length != groupSize)) return false;

  final ranks = byRank.keys.toList()
    ..sort((a, b) => a.strength.compareTo(b.strength));
  if (ranks.any((rank) => !rank.canBeInStraight)) return false;

  for (var i = 1; i < ranks.length; i++) {
    if (ranks[i].strength != ranks[i - 1].strength + 1) {
      return false;
    }
  }
  return true;
}
