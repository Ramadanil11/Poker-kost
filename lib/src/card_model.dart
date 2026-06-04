import 'dart:math';

/// Kembang kartu dengan urutan kekuatan house-rules:
/// Spade < Club < Diamond < Heart.
enum Suit {
  spade(0, 'S', '♠'),
  club(1, 'C', '♣'),
  diamond(2, 'D', '♦'),
  heart(3, 'H', '♥');

  const Suit(this.strength, this.code, this.symbol);

  final int strength;
  final String code;
  final String symbol;
}

/// Rank kartu dengan urutan kekuatan house-rules:
/// 3 < 4 < 5 < 6 < 7 < 8 < 9 < 10 < J < Q < K < A < 2.
enum Rank {
  three(0, '3'),
  four(1, '4'),
  five(2, '5'),
  six(3, '6'),
  seven(4, '7'),
  eight(5, '8'),
  nine(6, '9'),
  ten(7, '10'),
  jack(8, 'J'),
  queen(9, 'Q'),
  king(10, 'K'),
  ace(11, 'A'),
  two(12, '2');

  const Rank(this.strength, this.label);

  final int strength;
  final String label;

  bool get canBeInStraight => this != Rank.two;
}

/// Representasi satu kartu fisik.
///
/// Dua dek membuat kartu seperti 3♠ muncul dua kali, jadi equality tidak boleh
/// bergantung pada rank+suit saja. Field [id] adalah identitas fisik unik.
class GameCard {
  const GameCard._({
    required this.id,
    required this.rank,
    required this.suit,
    required this.deckIndex,
    required this.jokerIndex,
  });

  /// Membuat kartu standar dari dek ke-[deckIndex].
  factory GameCard.standard({
    required Rank rank,
    required Suit suit,
    required int deckIndex,
  }) {
    if (deckIndex < 0 || deckIndex > 3) {
      throw ArgumentError.value(deckIndex, 'deckIndex', 'Must be 0..3.');
    }

    return GameCard._(
      id: 'D$deckIndex-${rank.name}-${suit.name}',
      rank: rank,
      suit: suit,
      deckIndex: deckIndex,
      jokerIndex: null,
    );
  }

  /// Membuat satu Joker fisik unik.
  factory GameCard.joker(int jokerIndex) {
    if (jokerIndex < 0 || jokerIndex > 7) {
      throw ArgumentError.value(jokerIndex, 'jokerIndex', 'Must be 0..7.');
    }

    return GameCard._(
      id: 'J$jokerIndex',
      rank: null,
      suit: null,
      deckIndex: null,
      jokerIndex: jokerIndex,
    );
  }

  /// Membuat ulang kartu fisik dari [id] unik, dipakai oleh payload jaringan.
  factory GameCard.fromId(String id) {
    if (id.startsWith('J')) {
      return GameCard.joker(int.parse(id.substring(1)));
    }

    final parts = id.split('-');
    if (parts.length != 3 || !parts[0].startsWith('D')) {
      throw ArgumentError.value(id, 'id', 'Unknown card id format.');
    }

    return GameCard.standard(
      deckIndex: int.parse(parts[0].substring(1)),
      rank: Rank.values.firstWhere((rank) => rank.name == parts[1]),
      suit: Suit.values.firstWhere((suit) => suit.name == parts[2]),
    );
  }

  final String id;
  final Rank? rank;
  final Suit? suit;
  final int? deckIndex;
  final int? jokerIndex;

  bool get isJoker => jokerIndex != null;
  bool get isRedJoker =>
      isJoker &&
      (jokerIndex == 2 ||
          jokerIndex == 3 ||
          jokerIndex == 5 ||
          jokerIndex == 7);
  bool get isBlackJoker => isJoker && !isRedJoker;
  int get jokerStrength => isJoker ? (isRedJoker ? 1 : 0) : -1;
  bool get isHeart => suit == Suit.heart;

  /// Label pendek untuk log/UI/debug tanpa menghilangkan identitas fisik kartu.
  String get label {
    if (isJoker) return isRedJoker ? 'Red Joker' : 'Black Joker';
    return '${rank!.label}${suit!.symbol}#${deckIndex! + 1}';
  }

  /// Payload ringkas untuk sinkronisasi UI multiplayer lokal.
  Map<String, Object?> toJson() {
    return {'id': id};
  }

  /// Kartu dibandingkan berdasarkan identitas fisik agar tidak terjadi bug
  /// duplicate-card saat dua dek memiliki rank dan suit yang sama.
  @override
  bool operator ==(Object other) => other is GameCard && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => label;
}

/// Membuat kartu dari 1-4 ball. Satu ball = 52 kartu standar + 2 Joker.
List<GameCard> buildFullDeck({int ballCount = 2}) {
  _validateBallCount(ballCount);
  final cards = <GameCard>[];

  for (var deckIndex = 0; deckIndex < ballCount; deckIndex++) {
    for (final rank in Rank.values) {
      for (final suit in Suit.values) {
        cards.add(
          GameCard.standard(rank: rank, suit: suit, deckIndex: deckIndex),
        );
      }
    }
  }

  const blackJokerIndexes = [0, 1, 4, 6];
  const redJokerIndexes = [2, 3, 5, 7];
  for (var ballIndex = 0; ballIndex < ballCount; ballIndex++) {
    cards.add(GameCard.joker(blackJokerIndexes[ballIndex]));
    cards.add(GameCard.joker(redJokerIndexes[ballIndex]));
  }

  assertUniqueCards(cards);
  return cards;
}

/// Mengacak dek dengan optional [seed] agar simulasi/test bisa deterministik.
List<GameCard> shuffledFullDeck({int? seed, int ballCount = 2}) {
  final cards = buildFullDeck(ballCount: ballCount);
  cards.shuffle(seed == null ? Random() : Random(seed));
  return cards;
}

void _validateBallCount(int ballCount) {
  if (ballCount < 1 || ballCount > 4) {
    throw ArgumentError.value(ballCount, 'ballCount', 'Must be 1..4.');
  }
}

/// Memastikan tidak ada kartu fisik dengan id yang sama di satu koleksi.
void assertUniqueCards(Iterable<GameCard> cards) {
  final ids = <String>{};
  for (final card in cards) {
    if (!ids.add(card.id)) {
      throw StateError('Duplicate physical card detected: ${card.id}');
    }
  }
}

/// Sort stabil untuk tampilan hand: rank rendah ke tinggi, suit rendah ke tinggi,
/// Joker ditempatkan paling akhir.
List<GameCard> sortCards(Iterable<GameCard> cards) {
  final sorted = cards.toList();
  sorted.sort((a, b) {
    if (a.isJoker && b.isJoker) {
      final strengthCompare = a.jokerStrength.compareTo(b.jokerStrength);
      if (strengthCompare != 0) return strengthCompare;
      return a.jokerIndex!.compareTo(b.jokerIndex!);
    }
    if (a.isJoker) return 1;
    if (b.isJoker) return -1;

    final rankCompare = a.rank!.strength.compareTo(b.rank!.strength);
    if (rankCompare != 0) return rankCompare;

    final suitCompare = a.suit!.strength.compareTo(b.suit!.strength);
    if (suitCompare != 0) return suitCompare;

    return a.deckIndex!.compareTo(b.deckIndex!);
  });
  return sorted;
}
