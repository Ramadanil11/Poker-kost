import 'combination.dart';

/// Comparator rules untuk menentukan apakah [next] boleh menimpa [previous].
class GameRules {
  const GameRules();

  /// Mengecek legalitas response terhadap play di arena.
  ///
  /// Prioritas house rules:
  /// 1. Bomb dapat menimpa regular play.
  /// 2. Joker-set hanya bisa dihentikan oleh jumlah bomb-set yang sama.
  /// 3. Jika play sebelumnya mengandung Heart, tie rank tidak boleh menimpa.
  bool canBeat(CardPlay previous, CardPlay next) {
    final previousCombo = previous.combo;
    final nextCombo = next.combo;

    if (nextCombo.isBombLike) {
      return _bombCanBeat(previousCombo, nextCombo);
    }

    if (previousCombo.isBombLike) {
      return false;
    }

    if (nextCombo.isJokerSet) {
      if (previousCombo.isJokerSet) {
        return nextCombo.cardCount == previousCombo.cardCount &&
            nextCombo.jokerStrength > previousCombo.jokerStrength;
      }
      return _jokerSetCanBeatRegular(previousCombo, nextCombo);
    }

    if (previousCombo.isJokerSet) {
      return false;
    }

    return _regularCanBeat(previous, next);
  }

  /// Menentukan apakah bomb/multi-bomb bisa menimpa play sebelumnya.
  ///
  /// Terhadap Joker, jumlah set bomb harus sama dengan jumlah Joker. Terhadap
  /// bomb lain, jumlah set harus sama dan rank bomb tertinggi harus lebih besar.
  bool _bombCanBeat(Combination previous, Combination next) {
    if (previous.isJokerSet) {
      return next.bombCount == previous.cardCount;
    }

    if (previous.isBombLike) {
      return next.bombCount == previous.bombCount &&
          next.highestBombRank!.strength > previous.highestBombRank!.strength;
    }

    return true;
  }

  /// Joker-set dapat dimainkan sebagai response hanya terhadap regular combo
  /// dengan jumlah kartu yang sama. Contoh: 1 Joker menimpa single 2, 2 Joker
  /// menimpa pair, dan 3 Joker menimpa triple.
  bool _jokerSetCanBeatRegular(Combination previous, Combination next) {
    return previous.isRegular && next.cardCount == previous.cardCount;
  }

  /// Regular play harus sama bentuk dan jumlah kartunya. Rank lebih tinggi
  /// menang; rank sama hanya boleh ditentukan suit jika play sebelumnya tidak
  /// mengandung Heart.
  bool _regularCanBeat(CardPlay previous, CardPlay next) {
    final previousCombo = previous.combo;
    final nextCombo = next.combo;

    if (previousCombo.kind != nextCombo.kind) return false;
    if (previousCombo.cardCount != nextCombo.cardCount) return false;

    final previousRank = previousCombo.primaryRank!;
    final nextRank = nextCombo.primaryRank!;
    if (nextRank.strength > previousRank.strength) return true;
    if (nextRank.strength < previousRank.strength) return false;

    if (previous.containsHeart) {
      return false;
    }

    return nextCombo.highestSuit!.strength >
        previousCombo.highestSuit!.strength;
  }
}
