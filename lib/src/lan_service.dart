import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'card_model.dart';
import 'game_snapshot.dart';
import 'turn_manager.dart';

const lanGamePort = 4040;

/// Host LAN authoritative. Host memegang state penuh dan semua client hanya
/// mengirim command; host memvalidasi rule lewat [TurnManager].
class LanHostService {
  LanHostService({
    required List<String> playerNames,
    required String hostName,
    this.targetWins = 0,
    this.ballCount = 2,
  }) {
    _manager = TurnManager.newGame(
      playerNames: playerNames,
      seed: DateTime.now().millisecondsSinceEpoch,
      randomizeTurnOrder: true,
      ballCount: ballCount,
    );
    hostPlayerId = _manager.state.players
        .firstWhere((player) => player.name == hostName)
        .id;
  }

  final int targetWins;
  final int ballCount;
  late TurnManager _manager;
  ServerSocket? _server;
  final _clients = <String, Socket>{};
  final _subscriptions = <StreamSubscription<String>>[];
  final _snapshots = StreamController<GameSnapshot>.broadcast();
  final _winsByPlayerId = <String, int>{};
  String hostPlayerId = 'P0';

  Stream<GameSnapshot> get snapshots => _snapshots.stream;
  int get expectedPlayerCount => _manager.state.players.length;
  int get connectedPlayerCount => _clients.length + 1;
  bool get isReady => connectedPlayerCount >= expectedPlayerCount;
  GameSnapshot get hostSnapshot => GameSnapshot.fromState(
        _manager.state,
        hostPlayerId,
        targetWins: targetWins,
        winsByPlayerId: _winsByPlayerId,
      );

  Future<void> start({int port = lanGamePort}) async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _server!.listen(_handleClient);
    _broadcast();
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    for (final socket in _clients.values) {
      socket.destroy();
    }
    await _server?.close();
    await _snapshots.close();
  }

  void performHostAction(String action, List<String> cardIds) {
    performAction(hostPlayerId, action, cardIds);
  }

  void nextRound() {
    final winnerId = _manager.state.winnerPlayerId;
    if (winnerId == null) return;

    _startNextRoundFromWinner(winnerId);
    _broadcast();
  }

  void performAction(String playerId, String action, List<String> cardIds) {
    if (action != 'join' && !isReady) {
      throw StateError('Tunggu semua pemain join dulu.');
    }
    switch (action) {
      case 'continue':
        _startNewMatch();
        _broadcast();
        return;
      case 'opening':
        _manager.submitOpeningThrees(playerId);
      case 'join':
        _manager.renamePlayer(playerId, cardIds.first);
      case 'play':
        final cards = _cardsForPlayer(playerId, cardIds);
        _manager.playCards(playerId, cards);
      case 'pass':
        _manager.pass(playerId);
      case 'show':
        final cards = _cardsForPlayer(playerId, cardIds);
        _manager.pamerKartu(playerId, cards);
        _broadcast();
        return;
      case 'hide':
        final cards = _cardsForPlayer(playerId, cardIds);
        _manager.batalPamerKartu(playerId, cards);
        _broadcast();
        return;
      default:
        throw ArgumentError('Unknown LAN action: $action');
    }
    _settleAfterAction();
  }

  /// Menyelesaikan akibat satu aksi: catat skor ronde, mulai ronde berikutnya
  /// bila ada pemenang, broadcast, lalu jadwalkan auto-play untuk kursi kosong.
  void _settleAfterAction() {
    final winnerId = _manager.state.winnerPlayerId;
    if (winnerId != null) {
      final wins = (_winsByPlayerId[winnerId] ?? 0) + 1;
      _winsByPlayerId[winnerId] = wins;
      if (targetWins > 0 && wins >= targetWins) {
        _broadcast();
        return;
      }
      _startNextRoundFromWinner(winnerId);
    }
    _broadcast();
  }

  void _startNewMatch() {
    _winsByPlayerId.clear();
    _manager = TurnManager.newGame(
      playerNames: _manager.state.players.map((player) => player.name).toList(),
      seed: DateTime.now().millisecondsSinceEpoch,
      roundNumber: 1,
      ballCount: ballCount,
    );
  }

  void _startNextRoundFromWinner(String winnerId) {
    _manager = TurnManager.newGame(
      playerNames: _manager.state.players.map((player) => player.name).toList(),
      seed: DateTime.now().millisecondsSinceEpoch,
      roundNumber: _manager.state.roundNumber + 1,
      startingPlayerId: winnerId,
      ballCount: ballCount,
    );
  }

  void _handleClient(Socket socket) {
    final playerId = _nextUnassignedPlayerId();
    if (playerId == null) {
      _send(socket, {'type': 'error', 'message': 'Meja sudah penuh.'});
      socket.destroy();
      return;
    }

    _clients[playerId] = socket;
    _send(socket, {'type': 'welcome', 'playerId': playerId});
    _sendSnapshot(socket, playerId);

    final subscription = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        try {
          final json = jsonDecode(line) as Map<String, Object?>;
          final action = json['action']! as String;
          final ids = [
            for (final id in json['cardIds'] as List<Object?>) id! as String,
          ];
          performAction(playerId, action, ids);
        } on Object catch (error) {
          _send(socket, {'type': 'error', 'message': _shortError(error)});
        }
      },
      onDone: () {
        _clients.remove(playerId);
      },
      onError: (_) {
        _clients.remove(playerId);
      },
    );
    _subscriptions.add(subscription);
  }

  String? _nextUnassignedPlayerId() {
    for (final player in _manager.state.players) {
      if (player.id == hostPlayerId) continue;
      if (!_clients.containsKey(player.id)) return player.id;
    }
    return null;
  }

  List<GameCard> _cardsForPlayer(String playerId, List<String> cardIds) {
    final player = _manager.state.players.firstWhere(
      (player) => player.id == playerId,
    );
    return [
      for (final id in cardIds) player.hand.firstWhere((card) => card.id == id),
    ];
  }

  void _broadcast() {
    _snapshots.add(hostSnapshot);
    for (final entry in _clients.entries) {
      _sendSnapshot(entry.value, entry.key);
    }
  }

  void _sendSnapshot(Socket socket, String playerId) {
    _send(socket, {
      'type': 'snapshot',
      'state': GameSnapshot.fromState(
        _manager.state,
        playerId,
        targetWins: targetWins,
        winsByPlayerId: _winsByPlayerId,
      ).toJson(),
    });
  }
}

/// Client LAN untuk connect ke host via IP WiFi/hotspot.
class LanClientService {
  LanClientService();

  Socket? _socket;
  String? playerId;
  final _snapshots = StreamController<GameSnapshot>.broadcast();
  final _errors = StreamController<String>.broadcast();

  Stream<GameSnapshot> get snapshots => _snapshots.stream;
  Stream<String> get errors => _errors.stream;

  Future<void> connect(
    String hostIp, {
    String playerName = 'Player',
    int port = lanGamePort,
  }) async {
    _socket =
        await Socket.connect(hostIp, port, timeout: const Duration(seconds: 8));
    _socket!
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_handleLine, onError: _handleError, onDone: _handleDone);
    sendAction('join', [playerName]);
  }

  Future<void> dispose() async {
    _socket?.destroy();
    await _snapshots.close();
    await _errors.close();
  }

  void sendAction(String action, List<String> cardIds) {
    _send(_socket!, {
      'action': action,
      'cardIds': cardIds,
    });
  }

  void _handleLine(String line) {
    final json = jsonDecode(line) as Map<String, Object?>;
    switch (json['type']) {
      case 'welcome':
        playerId = json['playerId']! as String;
      case 'snapshot':
        _snapshots.add(
          GameSnapshot.fromJson(json['state']! as Map<String, Object?>),
        );
      case 'error':
        _errors.add(json['message']! as String);
    }
  }

  void _handleError(Object error) {
    _errors.add(_shortError(error));
  }

  void _handleDone() {
    _errors.add('Koneksi host terputus.');
  }
}

void _send(Socket socket, Map<String, Object?> payload) {
  socket.writeln(jsonEncode(payload));
}

String _shortError(Object error) {
  final text = error.toString();
  return text
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('StateError: ', '')
      .replaceFirst('ArgumentError: ', '');
}
