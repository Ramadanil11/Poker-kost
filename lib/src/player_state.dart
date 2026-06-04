import 'card_model.dart';

/// State immutable untuk satu pemain.
class PlayerState {
  const PlayerState({
    required this.id,
    required this.name,
    required this.hand,
    this.shownCardIds = const {},
  });

  final String id;
  final String name;
  final List<GameCard> hand;

  /// Kartu yang sedang dipamerkan ke publik, tetapi masih berada di hand.
  final Set<String> shownCardIds;

  /// Membuat salinan state dengan field yang diganti.
  PlayerState copyWith({
    String? id,
    String? name,
    List<GameCard>? hand,
    Set<String>? shownCardIds,
  }) {
    final nextHand = List<GameCard>.unmodifiable(sortCards(hand ?? this.hand));
    assertUniqueCards(nextHand);

    final nextShown = Set<String>.unmodifiable(
      shownCardIds ?? this.shownCardIds,
    );
    final handIds = nextHand.map((card) => card.id).toSet();
    if (!nextShown.every(handIds.contains)) {
      throw StateError('Shown cards must still exist in player hand.');
    }

    return PlayerState(
      id: id ?? this.id,
      name: name ?? this.name,
      hand: nextHand,
      shownCardIds: nextShown,
    );
  }

  /// Mengecek apakah semua kartu yang dipilih benar-benar ada di hand pemain.
  bool hasCards(Iterable<GameCard> selectedCards) {
    final handIds = hand.map((card) => card.id).toSet();
    return selectedCards.every((card) => handIds.contains(card.id));
  }

  /// Menghapus kartu yang dimainkan dari hand dan otomatis menghilangkan status
  /// pamer untuk kartu yang sudah keluar ke arena.
  PlayerState removeCards(Iterable<GameCard> selectedCards) {
    final selectedIds = selectedCards.map((card) => card.id).toSet();
    if (selectedIds.length != selectedCards.length) {
      throw ArgumentError('Duplicate selected cards.');
    }
    if (!hasCards(selectedCards)) {
      throw ArgumentError('Selected cards are not all in player hand.');
    }

    final nextHand =
        hand.where((card) => !selectedIds.contains(card.id)).toList();
    final nextShown =
        shownCardIds.where((id) => !selectedIds.contains(id)).toSet();
    return copyWith(hand: nextHand, shownCardIds: nextShown);
  }

  /// Menandai kartu sebagai face-up untuk fitur pamer kartu.
  PlayerState showCards(Iterable<GameCard> selectedCards) {
    final selected = selectedCards.toList(growable: false);
    assertUniqueCards(selected);
    if (!hasCards(selected)) {
      throw ArgumentError('Shown cards must be in player hand.');
    }

    return copyWith(
      shownCardIds: {...shownCardIds, ...selected.map((card) => card.id)},
    );
  }

  /// Membatalkan pamer untuk kartu tertentu tanpa mengubah posisi kartu di hand.
  PlayerState hideCards(Iterable<GameCard> selectedCards) {
    final selectedIds = selectedCards.map((card) => card.id).toSet();
    return copyWith(
      shownCardIds:
          shownCardIds.where((id) => !selectedIds.contains(id)).toSet(),
    );
  }

  /// Snapshot kartu pamer yang aman dibaca layer UI/network.
  List<GameCard> get shownCards {
    return hand
        .where((card) => shownCardIds.contains(card.id))
        .toList(growable: false);
  }
}
