import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'custom_card_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const PokerSetshootApp());
}

class _GameAudio {
  static const _channel = MethodChannel('poker_kost/audio');

  static Future<void> playEffect(String name) async {
    try {
      await _channel.invokeMethod<void>('playEffect', {'name': name});
    } on Object {
      // Audio files are optional project assets during development.
    }
  }

  static Future<void> startBacksound() async {
    try {
      await _channel.invokeMethod<void>('startBacksound');
    } on Object {
      // Ignore unsupported platforms or placeholder audio files.
    }
  }

  static Future<void> stopBacksound() async {
    try {
      await _channel.invokeMethod<void>('stopBacksound');
    } on Object {
      // Ignore unsupported platforms or placeholder audio files.
    }
  }
}

class PokerSetshootApp extends StatelessWidget {
  const PokerSetshootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poker Kost',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD45A),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF07121A),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
              child: CustomPaint(painter: _PixelPokerHomePainter())),
          Positioned(
            left: 58,
            top: 70,
            bottom: 46,
            width: 430,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PixelTitle(text: 'POKER KOST'),
                const SizedBox(height: 24),
                _HomeMenuButton(
                  label: 'MULTIPLAYER',
                  selected: true,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MultiplayerSetupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 9),
                _HomeMenuButton(label: 'EXIT', onPressed: SystemNavigator.pop),
              ],
            ),
          ),
          Positioned(
            right: 36,
            top: 44,
            bottom: 40,
            width: 300,
            child: _HomeCardShowcase(),
          ),
        ],
      ),
    );
  }
}

class _PixelTitle extends StatelessWidget {
  const _PixelTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Transform.translate(
          offset: const Offset(5, 6),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF05080D),
              fontSize: 56,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFFFD45A),
            fontSize: 56,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: [
              Shadow(color: Color(0xFF7A2F13), offset: Offset(0, 4)),
              Shadow(color: Color(0xFF05080D), offset: Offset(3, 0)),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeMenuButton extends StatelessWidget {
  const _HomeMenuButton({
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 390,
          height: 45,
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: selected
                    ? const Icon(
                        Icons.play_arrow,
                        color: Color(0xFFFFD45A),
                        size: 32,
                      )
                    : null,
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFFD45A),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                  shadows: [
                    Shadow(color: Color(0xFF05080D), offset: Offset(3, 3)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCardShowcase extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CustomPaint(painter: _CardTrailPainter())),
        Transform.translate(
          offset: const Offset(50, -74),
          child: Transform.rotate(
            angle: 0.15,
            child: _PlayingCard(
              card: GameCard.standard(
                rank: Rank.two,
                suit: Suit.spade,
                deckIndex: 0,
              ),
              width: 96,
              height: 140,
              selected: false,
              shown: false,
              enabled: false,
              onTap: () {},
              onDoubleTap: () {},
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(-42, 0),
          child: Transform.rotate(
            angle: -0.18,
            child: _PlayingCard(
              card: GameCard.standard(
                rank: Rank.ace,
                suit: Suit.heart,
                deckIndex: 0,
              ),
              width: 96,
              height: 140,
              selected: false,
              shown: false,
              enabled: false,
              onTap: () {},
              onDoubleTap: () {},
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(82, 78),
          child: Transform.rotate(
            angle: 0.22,
            child: _PlayingCard(
              card: GameCard.joker(2),
              width: 96,
              height: 140,
              selected: false,
              shown: false,
              enabled: false,
              onTap: () {},
              onDoubleTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}

class _PixelPokerHomePainter extends CustomPainter {
  const _PixelPokerHomePainter({this.showDecorations = true});

  final bool showDecorations;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF232A59), Color(0xFF545393)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    if (!showDecorations) return;

    final cloudPaint = Paint()..color = const Color(0x334E5AA0);
    for (final cloud in const [
      Rect.fromLTWH(-20, 118, 240, 28),
      Rect.fromLTWH(88, 96, 140, 18),
      Rect.fromLTWH(318, 130, 270, 30),
      Rect.fromLTWH(604, 108, 260, 24),
      Rect.fromLTWH(896, 122, 210, 24),
    ]) {
      canvas.drawRect(_scaledRect(cloud, size), cloudPaint);
      canvas.drawRect(
        _scaledRect(cloud.shift(const Offset(34, 22)), size),
        cloudPaint,
      );
    }

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.76);
    for (final star in const [
      Offset(48, 58),
      Offset(182, 18),
      Offset(346, 64),
      Offset(540, 28),
      Offset(704, 84),
      Offset(905, 44),
      Offset(1024, 132),
      Offset(86, 330),
      Offset(238, 396),
      Offset(426, 304),
      Offset(690, 382),
      Offset(950, 338),
    ]) {
      _drawPixelStar(canvas, starPaint, _scaledOffset(star, size), 5);
    }

    final smallStarPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.62);
    for (final star in const [
      Offset(132, 92),
      Offset(278, 142),
      Offset(492, 182),
      Offset(812, 60),
      Offset(978, 202),
      Offset(42, 226),
      Offset(314, 318),
      Offset(548, 352),
      Offset(742, 278),
    ]) {
      final point = _scaledOffset(star, size);
      canvas.drawRect(
        Rect.fromCenter(center: point, width: 4, height: 4),
        smallStarPaint,
      );
    }
  }

  Rect _scaledRect(Rect rect, Size size) {
    final sx = size.width / 1100;
    final sy = size.height / 480;
    return Rect.fromLTWH(
      rect.left * sx,
      rect.top * sy,
      rect.width * sx,
      rect.height * sy,
    );
  }

  Offset _scaledOffset(Offset offset, Size size) {
    return Offset(offset.dx * size.width / 1100, offset.dy * size.height / 480);
  }

  void _drawPixelStar(Canvas canvas, Paint paint, Offset center, double size) {
    canvas.drawRect(
      Rect.fromCenter(center: center, width: size * 3, height: size),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: center, width: size, height: size * 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelPokerHomePainter oldDelegate) {
    return oldDelegate.showDecorations != showDecorations;
  }
}

class _CardTrailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final trail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0x00FFE8A3), Color(0xFFFFE8A3), Color(0xFFFF9F43)],
      ).createShader(Offset.zero & size);
    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.72)
      ..cubicTo(
        size.width * 0.58,
        size.height * 0.86,
        size.width * 1.02,
        size.height * 0.30,
        size.width * 0.66,
        size.height * 0.18,
      );
    canvas.drawPath(path, trail);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LegacyHomeScreen extends StatefulWidget {
  const LegacyHomeScreen({super.key});

  @override
  State<LegacyHomeScreen> createState() => _LegacyHomeScreenState();
}

class _LegacyHomeScreenState extends State<LegacyHomeScreen> {
  int _playerCount = 4;
  int _ballCount = 2;
  final _hostIpController = TextEditingController();
  final List<TextEditingController> _nameControllers = [
    for (final name in [
      'Kamu',
      'Budi',
      'Sari',
      'Doni',
      'Rina',
      'Agus',
      'Maya',
      'Tono',
      'Nina',
      'Joko',
    ])
      TextEditingController(text: name),
  ];

  @override
  void dispose() {
    _hostIpController.dispose();
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _playerNames {
    return [
      for (var i = 0; i < _playerCount; i++)
        _nameControllers[i].text.trim().isEmpty
            ? 'Pemain ${i + 1}'
            : _nameControllers[i].text.trim(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Poker Setshoot',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 10),
                    const Text('Tiến Lên + Dou Dizhu + house rules.'),
                    const SizedBox(height: 12),
                    Text('Jumlah pemain: $_playerCount'),
                    Slider(
                      value: _playerCount.toDouble(),
                      min: 2,
                      max: 10,
                      divisions: 8,
                      label: '$_playerCount',
                      onChanged: (value) {
                        setState(() {
                          _playerCount = value.round();
                        });
                      },
                    ),
                    Text('Ball kartu: $_ballCount'),
                    Slider(
                      value: _ballCount.toDouble(),
                      min: 1,
                      max: 4,
                      divisions: 3,
                      label: '$_ballCount',
                      onChanged: (value) {
                        setState(() => _ballCount = value.round());
                      },
                    ),
                    Text(
                      '${_cardsPerPlayer(_ballCount, _playerCount)} kartu per pemain, '
                      '${_burnCount(_ballCount, _playerCount)} burn. '
                      'Ronde 1 buang semua kartu 3.',
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 118,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 5.6,
                        ),
                        itemCount: _playerCount,
                        itemBuilder: (context, index) {
                          return TextField(
                            controller: _nameControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Nama ${index + 1}',
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 22),
              SizedBox(
                width: 330,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LocalSetupScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.groups),
                      label: const Text('Main Lokal'),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LanHostScreen(
                              playerNames: _playerNames,
                              ballCount: _ballCount,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.wifi_tethering),
                      label: const Text('Host WiFi/Hotspot'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Join meja LAN',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _hostIpController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        isDense: true,
                        labelText: 'IP host',
                        hintText: '192.168.1.10',
                        prefixIcon: Icon(Icons.router),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        final hostIp = _hostIpController.text.trim();
                        if (hostIp.isEmpty) return;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => LanClientScreen(hostIp: hostIp),
                          ),
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('Join LAN'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Untuk LAN: semua device harus satu WiFi/hotspot. Client join pakai IP device host.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchSettingsPanel extends StatelessWidget {
  const _MatchSettingsPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232A59), Color(0xFF151A3C)],
        ),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFFFD45A).withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              Expanded(child: children[i]),
              if (i != children.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingSlider extends StatelessWidget {
  const _SettingSlider({
    required this.icon,
    required this.title,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String valueText;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFFFFD45A)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              activeTrackColor: const Color(0xFFFFD45A),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
              thumbColor: const Color(0xFFFFD45A),
              overlayColor: const Color(0xFFFFD45A).withValues(alpha: 0.16),
              valueIndicatorColor: const Color(0xFFC57C1D),
              valueIndicatorTextStyle: const TextStyle(
                color: Color(0xFF231307),
                fontWeight: FontWeight.w900,
              ),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: divisions,
              label: '$value',
              onChanged: (nextValue) => onChanged(nextValue.round()),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFD45A),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DealSummary extends StatelessWidget {
  const _DealSummary({
    required this.ballCount,
    required this.playerCount,
  });

  final int ballCount;
  final int playerCount;

  @override
  Widget build(BuildContext context) {
    final totalCards = _totalCardsForBall(ballCount);
    final cardsPerPlayer = _cardsPerPlayer(ballCount, playerCount);
    final burnCount = _burnCount(ballCount, playerCount);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC171B3D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            _SummaryMetric(label: 'Total', value: '$totalCards'),
            const SizedBox(width: 10),
            _SummaryMetric(label: 'Per pemain', value: '$cardsPerPlayer'),
            const SizedBox(width: 10),
            _SummaryMetric(label: 'Burn', value: '$burnCount'),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFFFD45A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class MultiplayerSetupScreen extends StatefulWidget {
  const MultiplayerSetupScreen({super.key});

  @override
  State<MultiplayerSetupScreen> createState() => _MultiplayerSetupScreenState();
}

class _MultiplayerSetupScreenState extends State<MultiplayerSetupScreen> {
  final _joinNameController = TextEditingController(text: 'Player');
  final _hostNameController = TextEditingController(text: 'Host');
  final _ipController = TextEditingController();
  int _playerCount = 4;
  int _targetWins = 3;
  int _ballCount = 2;

  @override
  void dispose() {
    _joinNameController.dispose();
    _hostNameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: const _PixelPokerHomePainter(showDecorations: false),
              ),
            ),
            Positioned(
              left: 12,
              top: 10,
              child: _RoundIconButton(
                icon: Icons.arrow_back,
                onPressed: Navigator.of(context).pop,
                setupStyle: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 14, 18, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildJoinPanel()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildHostPanel()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinPanel() {
    return _SetupSectionPanel(
      icon: Icons.login,
      title: 'Join Meja',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _joinNameController,
            decoration: _setupInputDecoration(
              label: 'Username kamu',
              icon: Icons.person,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ipController,
            keyboardType: TextInputType.url,
            decoration: _setupInputDecoration(
              label: 'IP host',
              hint: '192.168.1.10',
              icon: Icons.router,
            ),
          ),
          const Spacer(),
          _SetupActionButton(
            onPressed: () {
              final hostIp = _ipController.text.trim();
              if (hostIp.isEmpty) return;
              final playerName = _joinNameController.text.trim().isEmpty
                  ? 'Player'
                  : _joinNameController.text.trim();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => LanClientScreen(
                    hostIp: hostIp,
                    playerName: playerName,
                  ),
                ),
              );
            },
            icon: Icons.login,
            label: 'Join Meja',
            outlined: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHostPanel() {
    return _SetupSectionPanel(
      icon: Icons.wifi_tethering,
      title: 'Host Meja',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _hostNameController,
            decoration: _setupInputDecoration(
              label: 'Username host',
              icon: Icons.person,
            ),
          ),
          const SizedBox(height: 12),
          _MatchSettingsPanel(
            children: [
              _SettingSlider(
                icon: Icons.groups,
                title: 'Slot pemain',
                valueText: '$_playerCount',
                value: _playerCount,
                min: 2,
                max: 10,
                divisions: 8,
                onChanged: (value) => setState(() => _playerCount = value),
              ),
              _SettingSlider(
                icon: Icons.emoji_events,
                title: 'Target menang',
                valueText: '$_targetWins win',
                value: _targetWins,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) => setState(() => _targetWins = value),
              ),
              _SettingSlider(
                icon: Icons.style,
                title: 'Ball kartu',
                valueText: '$_ballCount ball',
                value: _ballCount,
                min: 1,
                max: 4,
                divisions: 3,
                onChanged: (value) => setState(() => _ballCount = value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DealSummary(ballCount: _ballCount, playerCount: _playerCount),
          const Spacer(),
          _SetupActionButton(
            onPressed: () {
              final hostName = _hostNameController.text.trim().isEmpty
                  ? 'Host'
                  : _hostNameController.text.trim();
              final names = [
                hostName,
                for (var i = 1; i < _playerCount; i++) 'Tamu ${i + 1}',
              ];
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => LanHostScreen(
                    playerNames: names,
                    targetWins: _targetWins,
                    ballCount: _ballCount,
                  ),
                ),
              );
            },
            icon: Icons.wifi_tethering,
            label: 'Buka Meja',
          ),
        ],
      ),
    );
  }
}

class _SetupSectionPanel extends StatelessWidget {
  const _SetupSectionPanel({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF232A59), Color(0xFF151A3C)],
        ),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFFFD45A).withValues(alpha: 0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 10),
            blurRadius: 18,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFFFFD45A)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

InputDecoration _setupInputDecoration({
  required String label,
  required IconData icon,
  String? hint,
}) {
  return InputDecoration(
    isDense: true,
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, size: 18),
    filled: true,
    fillColor: const Color(0xFF171B3D),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFFFD45A), width: 1.4),
    ),
  );
}

class MultiplayerHostSetupScreen extends StatefulWidget {
  const MultiplayerHostSetupScreen({super.key});

  @override
  State<MultiplayerHostSetupScreen> createState() =>
      _MultiplayerHostSetupScreenState();
}

class _MultiplayerHostSetupScreenState
    extends State<MultiplayerHostSetupScreen> {
  final _nameController = TextEditingController(text: 'Host');
  int _playerCount = 4;
  int _targetWins = 3;
  int _ballCount = 2;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleSetupScaffold(
      title: 'Host Multiplayer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Username kamu',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _MatchSettingsPanel(
            children: [
              _SettingSlider(
                icon: Icons.groups,
                title: 'Slot pemain',
                valueText: '$_playerCount',
                value: _playerCount,
                min: 2,
                max: 10,
                divisions: 8,
                onChanged: (value) {
                  setState(() => _playerCount = value);
                },
              ),
              _SettingSlider(
                icon: Icons.emoji_events,
                title: 'Target menang',
                valueText: '$_targetWins win',
                value: _targetWins,
                min: 1,
                max: 10,
                divisions: 9,
                onChanged: (value) {
                  setState(() => _targetWins = value);
                },
              ),
              _SettingSlider(
                icon: Icons.style,
                title: 'Ball kartu',
                valueText: '$_ballCount ball',
                value: _ballCount,
                min: 1,
                max: 4,
                divisions: 3,
                onChanged: (value) {
                  setState(() => _ballCount = value);
                },
              ),
              _DealSummary(
                ballCount: _ballCount,
                playerCount: _playerCount,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _SetupActionButton(
            onPressed: () {
              final hostName = _nameController.text.trim().isEmpty
                  ? 'Host'
                  : _nameController.text.trim();
              final names = [
                hostName,
                for (var i = 1; i < _playerCount; i++) 'Tamu ${i + 1}',
              ];
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => LanHostScreen(
                    playerNames: names,
                    targetWins: _targetWins,
                    ballCount: _ballCount,
                  ),
                ),
              );
            },
            icon: Icons.wifi_tethering,
            label: 'Buka Meja',
          ),
        ],
      ),
    );
  }
}

class MultiplayerJoinSetupScreen extends StatefulWidget {
  const MultiplayerJoinSetupScreen({super.key});

  @override
  State<MultiplayerJoinSetupScreen> createState() =>
      _MultiplayerJoinSetupScreenState();
}

class _MultiplayerJoinSetupScreenState
    extends State<MultiplayerJoinSetupScreen> {
  final _nameController = TextEditingController(text: 'Player');
  final _ipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SimpleSetupScaffold(
      title: 'Join Multiplayer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Username kamu',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _ipController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'IP host',
              hintText: '192.168.1.10',
              prefixIcon: Icon(Icons.router),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _SetupActionButton(
            onPressed: () {
              final hostIp = _ipController.text.trim();
              if (hostIp.isEmpty) return;
              final playerName = _nameController.text.trim().isEmpty
                  ? 'Player'
                  : _nameController.text.trim();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => LanClientScreen(
                    hostIp: hostIp,
                    playerName: playerName,
                  ),
                ),
              );
            },
            icon: Icons.login,
            label: 'Join Meja',
            outlined: true,
          ),
        ],
      ),
    );
  }
}

class _SimpleSetupScaffold extends StatelessWidget {
  const _SimpleSetupScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: const _PixelPokerHomePainter(showDecorations: false),
              ),
            ),
            Positioned(
              left: 12,
              top: 10,
              child: _RoundIconButton(
                icon: Icons.arrow_back,
                onPressed: Navigator.of(context).pop,
                setupStyle: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 14, 18, 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const contentWidth = 980.0;
                  return Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: contentWidth,
                        height: constraints.maxHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 12),
                            child,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalSetupScreen extends StatefulWidget {
  const LocalSetupScreen({super.key});

  @override
  State<LocalSetupScreen> createState() => _LocalSetupScreenState();
}

class _LocalSetupScreenState extends State<LocalSetupScreen> {
  int _playerCount = 4;
  int _targetWins = 3;
  int _ballCount = 2;
  final List<TextEditingController> _controllers = [
    for (final name in _defaultLocalNames) TextEditingController(text: name),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: const _PixelPokerHomePainter(showDecorations: false),
              ),
            ),
            Positioned(
              left: 12,
              top: 10,
              child: _RoundIconButton(
                icon: Icons.arrow_back,
                onPressed: Navigator.of(context).pop,
                setupStyle: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(64, 14, 18, 14),
              child: _SetupSectionPanel(
                icon: Icons.style,
                title: 'Setting Match Lokal',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _MatchSettingsPanel(
                      children: [
                        _SettingSlider(
                          icon: Icons.groups,
                          title: 'Jumlah pemain',
                          valueText: '$_playerCount',
                          value: _playerCount,
                          min: 2,
                          max: 10,
                          divisions: 8,
                          onChanged: (value) {
                            setState(() => _playerCount = value);
                          },
                        ),
                        _SettingSlider(
                          icon: Icons.emoji_events,
                          title: 'Target menang',
                          valueText: '$_targetWins win',
                          value: _targetWins,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          onChanged: (value) {
                            setState(() => _targetWins = value);
                          },
                        ),
                        _SettingSlider(
                          icon: Icons.style,
                          title: 'Ball kartu',
                          valueText: '$_ballCount ball',
                          value: _ballCount,
                          min: 1,
                          max: 4,
                          divisions: 3,
                          onChanged: (value) {
                            setState(() => _ballCount = value);
                          },
                        ),
                        _DealSummary(
                          ballCount: _ballCount,
                          playerCount: _playerCount,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _LocalNamesPanel(
                        playerCount: _playerCount,
                        controllers: _controllers,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LocalStartButton(
                      onPressed: () {
                        final names = [
                          for (var i = 0; i < _playerCount; i++)
                            _controllers[i].text.trim().isEmpty
                                ? _defaultLocalNames[i]
                                : _controllers[i].text.trim(),
                        ];
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => LocalGameScreen(
                              playerNames: names,
                              targetWins: _targetWins,
                              ballCount: _ballCount,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalNamesPanel extends StatelessWidget {
  const _LocalNamesPanel({
    required this.playerCount,
    required this.controllers,
  });

  final int playerCount;
  final List<TextEditingController> controllers;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD171B3D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.badge, size: 18, color: Color(0xFFFFD45A)),
                SizedBox(width: 8),
                Text(
                  'Nama Pemain',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 4.2,
                ),
                itemCount: playerCount,
                itemBuilder: (context, index) {
                  return TextField(
                    controller: controllers[index],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: index == 0 ? 'Nama kamu' : 'Lawan $index',
                      prefixIcon: Icon(
                        index == 0 ? Icons.person : Icons.person_outline,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF171B3D),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(7),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFD45A),
                          width: 1.4,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalStartButton extends StatelessWidget {
  const _LocalStartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _SetupActionButton(
      onPressed: onPressed,
      icon: Icons.play_arrow,
      label: 'Mulai Match',
    );
  }
}

class _SetupActionButton extends StatelessWidget {
  const _SetupActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.outlined = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);
    final side = BorderSide(
      color: const Color(0xFFFFD45A).withValues(alpha: 0.60),
      width: 1.2,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            offset: Offset(0, 8),
            blurRadius: 14,
          ),
        ],
      ),
      child: SizedBox(
        height: 46,
        child: outlined
            ? OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 19),
                label: Text(label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFFD45A),
                  side: side,
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              )
            : FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 19),
                label: Text(label),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD45A),
                  foregroundColor: const Color(0xFF231307),
                  shape: RoundedRectangleBorder(borderRadius: borderRadius),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
      ),
    );
  }
}

const _defaultLocalNames = [
  'Kamu',
  'Budi',
  'Sari',
  'Doni',
  'Rina',
  'Agus',
  'Maya',
  'Tono',
  'Nina',
  'Joko',
];

int _totalCardsForBall(int ballCount) => ballCount * 54;

int _cardsPerPlayer(int ballCount, int playerCount) {
  return _totalCardsForBall(ballCount) ~/ playerCount;
}

int _burnCount(int ballCount, int playerCount) {
  return _totalCardsForBall(ballCount) % playerCount;
}

class LocalGameScreen extends StatefulWidget {
  const LocalGameScreen({
    super.key,
    required this.playerNames,
    this.targetWins = 3,
    this.ballCount = 2,
  });

  final List<String> playerNames;
  final int targetWins;
  final int ballCount;

  @override
  State<LocalGameScreen> createState() => _LocalGameScreenState();
}

class _LocalGameScreenState extends State<LocalGameScreen> {
  late TurnManager _manager;
  final Set<String> _selectedCardIds = {};
  final Map<String, int> _scores = {};

  @override
  void initState() {
    super.initState();
    _newMatch();
    _GameAudio.startBacksound();
  }

  @override
  void dispose() {
    _GameAudio.stopBacksound();
    super.dispose();
  }

  void _newMatch() {
    _selectedCardIds.clear();
    _scores
      ..clear()
      ..addEntries(widget.playerNames.map((name) => MapEntry(name, 0)));
    _manager = TurnManager.newGame(
      playerNames: List.generate(
        widget.playerNames.length,
        (index) => widget.playerNames[index],
      ),
      seed: DateTime.now().millisecondsSinceEpoch,
      roundNumber: 1,
      randomizeTurnOrder: true,
      ballCount: widget.ballCount,
    );
  }

  void _startNextRoundFromWinner(String winnerId) {
    _selectedCardIds.clear();
    _manager = TurnManager.newGame(
      playerNames: _manager.state.players.map((player) => player.name).toList(),
      seed: DateTime.now().millisecondsSinceEpoch,
      roundNumber: _manager.state.roundNumber + 1,
      startingPlayerId: winnerId,
      ballCount: widget.ballCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _manager.state;
    final winsByPlayerId = {
      for (final player in state.players) player.id: _scores[player.name] ?? 0,
    };
    final snapshot = GameSnapshot.fromState(
      state,
      state.activePlayer.id,
      targetWins: widget.targetWins,
      winsByPlayerId: winsByPlayerId,
    );

    return Scaffold(
      body: GameTableView(
        snapshot: snapshot,
        matchTitle: 'Match ID:',
        matchValue:
            '${_manager.state.roundNumber}${widget.playerNames.length}0841',
        stakeText: _targetProgressText(snapshot),
        selectedCardIds: _selectedCardIds,
        canAct: snapshot.status == GameStatus.playing ||
            snapshot.status == GameStatus.opening,
        onToggleCard: _toggleCard,
        onAction: _runAction,
        onBack: Navigator.of(context).pop,
        onNewMatch: () => setState(_newMatch),
      ),
    );
  }

  void _toggleCard(GameCard card) {
    setState(() {
      if (!_selectedCardIds.add(card.id)) {
        _selectedCardIds.remove(card.id);
      }
    });
  }

  void _runAction(String action) {
    try {
      var playedBomb = false;
      var shouldDrop = false;
      setState(() {
        final player = _manager.state.activePlayer;
        final cards = [
          for (final id in _selectedCardIds)
            player.hand.firstWhere((card) => card.id == id),
        ];
        switch (action) {
          case 'opening':
            _manager.submitOpeningThrees(player.id);
            shouldDrop = true;
          case 'play':
            _manager.playCards(player.id, cards);
            shouldDrop = true;
            final combo = _manager.state.lastPlay?.combo;
            playedBomb = combo?.isBombLike ?? false;
          case 'pass':
            _manager.pass(player.id);
          case 'show':
            _manager.pamerKartu(player.id, cards);
          case 'hide':
            _manager.batalPamerKartu(player.id, cards);
        }
        _selectedCardIds.clear();
      });
      if (shouldDrop) _GameAudio.playEffect('drop');
      if (playedBomb) _GameAudio.playEffect('bomb');
      _resetRoundIfWinner();
    } on Object catch (error) {
      _showMessage(_shortError(error));
    }
  }

  void _resetRoundIfWinner() {
    final winnerId = _manager.state.winnerPlayerId;
    if (winnerId == null) return;
    final winner = _manager.state.players.firstWhere(
      (player) => player.id == winnerId,
    );
    final nextScore = (_scores[winner.name] ?? 0) + 1;
    _scores[winner.name] = nextScore;
    if (nextScore >= widget.targetWins) {
      _GameAudio.playEffect('win');
      _showMessage(
          '${winner.name} menang match $nextScore/${widget.targetWins}.');
      setState(() {});
      return;
    }

    _GameAudio.playEffect('win');
    _showMessage(
      '${winner.name} menang ronde. Skor $nextScore/${widget.targetWins}.',
    );
    setState(() => _startNextRoundFromWinner(winnerId));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class LanHostScreen extends StatefulWidget {
  const LanHostScreen({
    super.key,
    required this.playerNames,
    this.targetWins = 3,
    this.ballCount = 2,
  });

  final List<String> playerNames;
  final int targetWins;
  final int ballCount;

  @override
  State<LanHostScreen> createState() => _LanHostScreenState();
}

class _LanHostScreenState extends State<LanHostScreen> {
  late final LanHostService _service;
  StreamSubscription<GameSnapshot>? _snapshotSubscription;
  GameSnapshot? _snapshot;
  final Set<String> _selectedCardIds = {};
  String _hostIp = 'loading...';

  @override
  void initState() {
    super.initState();
    _GameAudio.startBacksound();
    _service = LanHostService(
      playerNames: widget.playerNames,
      hostName: widget.playerNames.first,
      targetWins: widget.targetWins,
      ballCount: widget.ballCount,
    );
    _start();
  }

  Future<void> _start() async {
    _hostIp = await _findLocalIp();
    await _service.start();
    _snapshotSubscription = _service.snapshots.listen((snapshot) {
      if (!mounted) return;
      _playSnapshotAudio(_snapshot, snapshot);
      setState(() {
        _snapshot = snapshot;
      });
    });
    setState(() {
      _snapshot = _service.hostSnapshot;
    });
  }

  @override
  void dispose() {
    _snapshotSubscription?.cancel();
    _service.dispose();
    _GameAudio.stopBacksound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : GameTableView(
              snapshot: snapshot,
              matchTitle: 'Host:',
              matchValue: '$_hostIp:$lanGamePort',
              stakeText: _service.isReady
                  ? _targetProgressText(snapshot)
                  : 'Menunggu: ${_service.connectedPlayerCount}/${_service.expectedPlayerCount}',
              selectedCardIds: _selectedCardIds,
              canAct: _service.isReady &&
                  (snapshot.status == GameStatus.playing &&
                          snapshot.activePlayerId == snapshot.viewerPlayerId ||
                      snapshot.status == GameStatus.opening &&
                          snapshot.activePlayerId == snapshot.viewerPlayerId),
              onToggleCard: _toggleCard,
              onAction: _runAction,
              onBack: Navigator.of(context).pop,
              onNewMatch: () => _runAction('continue'),
              waitingConnectedCount:
                  _service.isReady ? null : _service.connectedPlayerCount,
              waitingExpectedCount:
                  _service.isReady ? null : _service.expectedPlayerCount,
            ),
    );
  }

  void _toggleCard(GameCard card) {
    setState(() {
      if (!_selectedCardIds.add(card.id)) {
        _selectedCardIds.remove(card.id);
      }
    });
  }

  void _runAction(String action) {
    try {
      _service.performHostAction(action, _selectedCardIds.toList());
      if (action == 'opening') {
        _GameAudio.playEffect('drop');
      }
      setState(_selectedCardIds.clear);
    } on Object catch (error) {
      _showMessage(_shortError(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WaitingProgress extends StatelessWidget {
  const _WaitingProgress({
    required this.connectedCount,
    required this.expectedCount,
  });

  final int connectedCount;
  final int expectedCount;

  @override
  Widget build(BuildContext context) {
    final progress = expectedCount <= 0 ? 0.0 : connectedCount / expectedCount;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$connectedCount/$expectedCount',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFD45A),
            fontSize: 58,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Color(0xFF05080D), offset: Offset(4, 4)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'PEMAIN SIAP',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFFFD45A),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(color: Color(0xFF05080D), offset: Offset(3, 3)),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 18,
            backgroundColor: const Color(0xFF171B3D),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD45A)),
          ),
        ),
      ],
    );
  }
}

class LanClientScreen extends StatefulWidget {
  const LanClientScreen({
    super.key,
    required this.hostIp,
    this.playerName = 'Player',
  });

  final String hostIp;
  final String playerName;

  @override
  State<LanClientScreen> createState() => _LanClientScreenState();
}

class _LanClientScreenState extends State<LanClientScreen> {
  final _service = LanClientService();
  StreamSubscription<GameSnapshot>? _snapshotSubscription;
  StreamSubscription<String>? _errorSubscription;
  GameSnapshot? _snapshot;
  final Set<String> _selectedCardIds = {};

  @override
  void initState() {
    super.initState();
    _GameAudio.startBacksound();
    _connect();
  }

  Future<void> _connect() async {
    _snapshotSubscription = _service.snapshots.listen((snapshot) {
      if (!mounted) return;
      _playSnapshotAudio(_snapshot, snapshot);
      setState(() {
        _snapshot = snapshot;
      });
    });
    _errorSubscription = _service.errors.listen(_showMessage);
    try {
      await _service.connect(widget.hostIp, playerName: widget.playerName);
    } on Object catch (error) {
      _showMessage(_shortError(error));
    }
  }

  @override
  void dispose() {
    _snapshotSubscription?.cancel();
    _errorSubscription?.cancel();
    _service.dispose();
    _GameAudio.stopBacksound();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : GameTableView(
              snapshot: snapshot,
              matchTitle: 'Client:',
              matchValue: '${widget.hostIp}:$lanGamePort',
              stakeText: _targetProgressText(snapshot),
              selectedCardIds: _selectedCardIds,
              canAct: snapshot.status == GameStatus.playing &&
                      snapshot.activePlayerId == snapshot.viewerPlayerId ||
                  snapshot.status == GameStatus.opening &&
                      snapshot.activePlayerId == snapshot.viewerPlayerId,
              onToggleCard: _toggleCard,
              onAction: _runAction,
              onBack: Navigator.of(context).pop,
              onNewMatch: () => _runAction('continue'),
            ),
    );
  }

  void _toggleCard(GameCard card) {
    setState(() {
      if (!_selectedCardIds.add(card.id)) {
        _selectedCardIds.remove(card.id);
      }
    });
  }

  void _runAction(String action) {
    _service.sendAction(action, _selectedCardIds.toList());
    if (action == 'opening') {
      _GameAudio.playEffect('drop');
    }
    setState(_selectedCardIds.clear);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class GameTableView extends StatelessWidget {
  const GameTableView({
    super.key,
    required this.snapshot,
    required this.matchTitle,
    required this.matchValue,
    required this.stakeText,
    required this.selectedCardIds,
    required this.canAct,
    required this.onToggleCard,
    required this.onAction,
    required this.onBack,
    required this.onNewMatch,
    this.waitingConnectedCount,
    this.waitingExpectedCount,
  });

  final GameSnapshot snapshot;
  final String matchTitle;
  final String matchValue;
  final String stakeText;
  final Set<String> selectedCardIds;
  final bool canAct;
  final ValueChanged<GameCard> onToggleCard;
  final ValueChanged<String> onAction;
  final VoidCallback onBack;
  final VoidCallback? onNewMatch;
  final int? waitingConnectedCount;
  final int? waitingExpectedCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _TableArena(
            snapshot: snapshot,
            selectedCardIds: selectedCardIds,
            canAct: canAct,
            onToggleCard: onToggleCard,
            onAction: onAction,
            waitingConnectedCount: waitingConnectedCount,
            waitingExpectedCount: waitingExpectedCount,
          ),
        ),
        Positioned(
          left: 12,
          top: 10,
          child: Row(
            children: [
              _RoundIconButton(icon: Icons.exit_to_app, onPressed: onBack),
              const SizedBox(width: 10),
              _RoundIconButton(
                icon: Icons.rule,
                onPressed: () => _showRulesDialog(context),
              ),
            ],
          ),
        ),
        Positioned(
          top: 10,
          right: 14,
          child: _MatchInfoPanel(
            title: matchTitle,
            value: matchValue,
            stake: stakeText,
          ),
        ),
        if (_isMatchFinished(snapshot))
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Center(
              child: _FinishedMatchActions(
                onContinue: onNewMatch,
                onExit: onBack,
              ),
            ),
          ),
      ],
    );
  }
}

void _showRulesDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) => const _RulesDialog(),
  );
}

class _RulesDialog extends StatelessWidget {
  const _RulesDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 460),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF232A59), Color(0xFF151A3C)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFFD45A).withValues(alpha: 0.34),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xCC000000),
                offset: Offset(0, 12),
                blurRadius: 28,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.rule, color: Color(0xFFFFD45A), size: 24),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Aturan Main',
                        style: TextStyle(
                          color: Color(0xFFFFD45A),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: Navigator.of(context).pop,
                      icon: const Icon(Icons.close),
                      color: const Color(0xFFFFD45A),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _RuleComboTile(
                          title: 'Single',
                          note: 'Satu kartu. Lawan dengan single lebih tinggi.',
                          cards: [
                            GameCard.standard(
                              rank: Rank.seven,
                              suit: Suit.heart,
                              deckIndex: 0,
                            ),
                          ],
                        ),
                        _RuleComboTile(
                          title: 'Pair',
                          note: '2 kartu sama rank. Contoh: dua 8.',
                          cards: [
                            GameCard.standard(
                              rank: Rank.eight,
                              suit: Suit.spade,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.eight,
                              suit: Suit.heart,
                              deckIndex: 0,
                            ),
                          ],
                        ),
                        _RuleComboTile(
                          title: 'Triple',
                          note: '3 kartu sama rank. Contoh: tiga 9.',
                          cards: [
                            GameCard.standard(
                              rank: Rank.nine,
                              suit: Suit.spade,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.nine,
                              suit: Suit.club,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.nine,
                              suit: Suit.heart,
                              deckIndex: 0,
                            ),
                          ],
                        ),
                        _RuleComboTile(
                          title: 'Kawal',
                          note:
                              '3 kartu sama + 2 kartu sama. Rank triple jadi penentu.',
                          cards: [
                            GameCard.standard(
                              rank: Rank.queen,
                              suit: Suit.spade,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.queen,
                              suit: Suit.club,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.queen,
                              suit: Suit.heart,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.five,
                              suit: Suit.diamond,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.five,
                              suit: Suit.heart,
                              deckIndex: 1,
                            ),
                          ],
                        ),
                        _RuleComboTile(
                          title: 'Straight',
                          note:
                              'Minimal 5 rank berurutan. Kartu 2 tidak ikut urutan.',
                          cards: [
                            GameCard.standard(
                              rank: Rank.five,
                              suit: Suit.spade,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.six,
                              suit: Suit.club,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.seven,
                              suit: Suit.diamond,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.eight,
                              suit: Suit.heart,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.nine,
                              suit: Suit.spade,
                              deckIndex: 1,
                            ),
                          ],
                        ),
                        _RuleComboTile(
                          title: 'Urutan Pair',
                          note: 'Minimal 3 pair berurutan. Contoh: 33 44 55.',
                          cards: [
                            GameCard.standard(
                              rank: Rank.three,
                              suit: Suit.spade,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.three,
                              suit: Suit.heart,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.four,
                              suit: Suit.spade,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.four,
                              suit: Suit.heart,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.five,
                              suit: Suit.spade,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.five,
                              suit: Suit.heart,
                              deckIndex: 0,
                            ),
                          ],
                        ),
                        _RuleComboTile(
                          title: 'Bomb',
                          note:
                              '4 kartu sama rank. Bomb bisa menimpa regular play.',
                          cards: [
                            GameCard.standard(
                              rank: Rank.king,
                              suit: Suit.spade,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.king,
                              suit: Suit.club,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.king,
                              suit: Suit.diamond,
                              deckIndex: 0,
                            ),
                            GameCard.standard(
                              rank: Rank.king,
                              suit: Suit.heart,
                              deckIndex: 0,
                            ),
                          ],
                        ),
                        _RuleComboTile(
                          title: 'Joker',
                          note:
                              'Joker set menimpa combo regular dengan jumlah kartu sama.',
                          cards: [
                            GameCard.joker(0),
                            GameCard.joker(2),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Rank: 3 paling rendah, 2 paling tinggi. Suit: Spade < Club < Diamond < Heart.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RuleComboTile extends StatelessWidget {
  const _RuleComboTile({
    required this.title,
    required this.note,
    required this.cards,
  });

  final String title;
  final String note;
  final List<GameCard> cards;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 418,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF171B3D),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(
            children: [
              SizedBox(
                width: 150,
                height: 58,
                child: _RuleCardSpread(cards: cards),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFFFD45A),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      note,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleCardSpread extends StatelessWidget {
  const _RuleCardSpread({required this.cards});

  final List<GameCard> cards;

  @override
  Widget build(BuildContext context) {
    final overlap = cards.length <= 4 ? 26.0 : 19.0;
    final cardWidth = cards.length <= 4 ? 36.0 : 31.0;
    final cardHeight = cards.length <= 4 ? 52.0 : 46.0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 0; i < cards.length; i++)
          Positioned(
            left: i * overlap,
            top: i.isEven ? 0 : 5,
            child: Transform.rotate(
              angle: (i - (cards.length - 1) / 2) * 0.035,
              child: _PlayingCard(
                card: cards[i],
                width: cardWidth,
                height: cardHeight,
                selected: false,
                shown: false,
                enabled: false,
                onTap: () {},
                onDoubleTap: () {},
              ),
            ),
          ),
      ],
    );
  }
}

String _targetProgressText(GameSnapshot snapshot) {
  final targetWins = snapshot.targetWins;
  if (targetWins <= 0) return 'Target: bebas';

  final leadingWins = snapshot.players.fold<int>(
    0,
    (highest, player) {
      final wins = snapshot.winsByPlayerId[player.id] ?? 0;
      return wins > highest ? wins : highest;
    },
  );
  final remainingWins = (targetWins - leadingWins).clamp(0, targetWins);
  return 'Target: $leadingWins/$targetWins win | Sisa: $remainingWins';
}

bool _isMatchFinished(GameSnapshot snapshot) {
  final winnerId = snapshot.winnerPlayerId;
  if (winnerId == null || snapshot.targetWins <= 0) return false;
  return (snapshot.winsByPlayerId[winnerId] ?? 0) >= snapshot.targetWins;
}

void _playSnapshotAudio(GameSnapshot? previous, GameSnapshot next) {
  if (previous == null) return;

  if (previous.winnerPlayerId != next.winnerPlayerId &&
      next.winnerPlayerId != null) {
    _GameAudio.playEffect('win');
    return;
  }

  if (next.lastPlayCards.isEmpty) return;
  final previousIds = previous.lastPlayCards.map((card) => card.id).join(',');
  final nextIds = next.lastPlayCards.map((card) => card.id).join(',');
  if (previous.lastPlayPlayerId == next.lastPlayPlayerId &&
      previousIds == nextIds) {
    return;
  }

  if ((next.lastPlayLabel ?? '').contains('Bomb')) {
    _GameAudio.playEffect('bomb');
  } else {
    _GameAudio.playEffect('drop');
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.setupStyle = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool setupStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: setupStyle ? 44 : 42,
      height: setupStyle ? 44 : 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: setupStyle
                ? const [Color(0xFF232A59), Color(0xFF151A3C)]
                : const [Color(0xFFFFD45A), Color(0xFFC57C1D)],
          ),
          border: Border.all(
            color: setupStyle
                ? const Color(0xFFFFD45A).withValues(alpha: 0.50)
                : const Color(0xFF05080D).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            const BoxShadow(
              color: Color(0x99000000),
              offset: Offset(0, 3),
              blurRadius: 8,
            ),
            if (setupStyle)
              BoxShadow(
                color: const Color(0xFFFFD45A).withValues(alpha: 0.12),
                blurRadius: 14,
              ),
          ],
        ),
        child: IconButton(
          tooltip: setupStyle ? 'Kembali' : null,
          padding: EdgeInsets.zero,
          color: setupStyle ? const Color(0xFFFFD45A) : const Color(0xFF231307),
          onPressed: onPressed,
          icon: Icon(icon, size: setupStyle ? 24 : 22),
        ),
      ),
    );
  }
}

class _FinishedMatchActions extends StatelessWidget {
  const _FinishedMatchActions({
    required this.onContinue,
    required this.onExit,
  });

  final VoidCallback? onContinue;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC07121A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Lanjut'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD45A),
                foregroundColor: const Color(0xFF231307),
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onExit,
              icon: const Icon(Icons.logout, size: 16),
              label: const Text('Exit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFFD45A),
                side: BorderSide(
                  color: const Color(0xFFFFD45A).withValues(alpha: 0.60),
                ),
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchInfoPanel extends StatelessWidget {
  const _MatchInfoPanel({
    required this.title,
    required this.value,
    required this.stake,
  });

  final String title;
  final String value;
  final String stake;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD45A), Color(0xFFC57C1D)],
        ),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF231307),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              stake,
              style: const TextStyle(
                color: Color(0xFF231307),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableArena extends StatefulWidget {
  const _TableArena({
    required this.snapshot,
    required this.selectedCardIds,
    required this.canAct,
    required this.onToggleCard,
    required this.onAction,
    this.waitingConnectedCount,
    this.waitingExpectedCount,
  });

  final GameSnapshot snapshot;
  final Set<String> selectedCardIds;
  final bool canAct;
  final ValueChanged<GameCard> onToggleCard;
  final ValueChanged<String> onAction;
  final int? waitingConnectedCount;
  final int? waitingExpectedCount;

  @override
  State<_TableArena> createState() => _TableArenaState();
}

class _TableArenaState extends State<_TableArena> {
  static const _dealStepDuration = Duration(milliseconds: 42);

  Timer? _dealTimer;
  String? _lastDealKey;
  int _dealStep = 0;
  bool _isDealing = false;

  @override
  void initState() {
    super.initState();
    _syncDealAnimation();
  }

  @override
  void didUpdateWidget(covariant _TableArena oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDealAnimation();
  }

  @override
  void dispose() {
    _dealTimer?.cancel();
    super.dispose();
  }

  void _syncDealAnimation() {
    final waitingForPlayers = widget.waitingConnectedCount != null &&
        widget.waitingExpectedCount != null;
    if (!_shouldShowDealAnimation(widget.snapshot, waitingForPlayers)) {
      _dealTimer?.cancel();
      _dealTimer = null;
      if (_isDealing) {
        _isDealing = false;
        _dealStep = 0;
      }
      return;
    }

    final key = _dealKeyFor(widget.snapshot);
    if (_lastDealKey == key) return;

    _lastDealKey = key;
    _dealTimer?.cancel();
    _dealStep = 0;
    _isDealing = true;
    final sequence = _dealSequenceFor(widget.snapshot);
    if (sequence.isEmpty) {
      _isDealing = false;
      return;
    }

    _dealTimer = Timer.periodic(_dealStepDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _dealStep++;
        if (_dealStep >= sequence.length) {
          _isDealing = false;
          _dealStep = sequence.length;
          timer.cancel();
          _dealTimer = null;
        }
      });
    });
  }

  Map<String, int>? get _dealCounts {
    if (!_isDealing) return null;
    final counts = {for (final player in widget.snapshot.players) player.id: 0};
    final sequence = _dealSequenceFor(widget.snapshot);
    final dealtCount = _dealStep.clamp(0, sequence.length);
    for (var i = 0; i < dealtCount; i++) {
      final playerId = sequence[i];
      counts[playerId] = (counts[playerId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final handHeight =
            (constraints.maxHeight * 0.29).clamp(118.0, 178.0).toDouble();
        final waitingForPlayers = widget.waitingConnectedCount != null &&
            widget.waitingExpectedCount != null;
        final dealCounts = _dealCounts;
        return Stack(
          children: [
            Positioned.fill(
              child: _RoundTable(
                snapshot: widget.snapshot,
                dealCounts: dealCounts,
                dealStep: _isDealing ? _dealStep : null,
                waitingConnectedCount: widget.waitingConnectedCount,
                waitingExpectedCount: widget.waitingExpectedCount,
              ),
            ),
            if (!waitingForPlayers)
              Positioned(
                left: 0,
                right: 0,
                bottom: (constraints.maxHeight * 0.018).clamp(4.0, 12.0),
                height: handHeight,
                child: _HandPanel(
                  snapshot: widget.snapshot,
                  selectedCardIds: widget.selectedCardIds,
                  visibleHandCount: dealCounts?[widget.snapshot.viewerPlayerId],
                  canAct: widget.canAct && !_isDealing,
                  onToggleCard: widget.onToggleCard,
                  onAction: widget.onAction,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RoundTable extends StatelessWidget {
  const _RoundTable({
    required this.snapshot,
    this.dealCounts,
    this.dealStep,
    this.waitingConnectedCount,
    this.waitingExpectedCount,
  });

  final GameSnapshot snapshot;
  final Map<String, int>? dealCounts;
  final int? dealStep;
  final int? waitingConnectedCount;
  final int? waitingExpectedCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final seatWidth = (width * 0.15).clamp(88.0, 138.0).toDouble();
        final seatHeight = (height * 0.18).clamp(64.0, 88.0).toDouble();
        final tableSideInset = (width * 0.008).clamp(6.0, 12.0).toDouble();
        final tableTop = (height * 0.075).clamp(28.0, 46.0).toDouble();
        final tableBottom = (height * 0.11).clamp(66.0, 96.0).toDouble();
        final opponents = snapshot.players
            .where((player) => player.id != snapshot.viewerPlayerId)
            .toList();
        final seatPositions = _seatPositionsFor(opponents.length);
        final waitingForPlayers =
            waitingConnectedCount != null && waitingExpectedCount != null;

        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DarkFloorPainter())),
            Positioned(
              left: tableSideInset,
              right: tableSideInset,
              top: tableTop,
              bottom: tableBottom,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFB85B1C),
                      Color(0xFF6F2C0D),
                      Color(0xFF2A1207),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(86),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xAA000000),
                      offset: Offset(0, 18),
                      blurRadius: 32,
                    ),
                    BoxShadow(
                      color: Color(0x5536F3B9),
                      offset: Offset(0, -2),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(72),
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0C7A5B),
                            Color(0xFF086348),
                            Color(0xFF04382D),
                          ],
                        ),
                      ),
                      child: CustomPaint(
                        painter: _TableSurfacePainter(),
                        child: _TableCenter(
                          snapshot: snapshot,
                          waitingConnectedCount: waitingConnectedCount,
                          waitingExpectedCount: waitingExpectedCount,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (dealStep != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: _DealAnimationOverlay(
                    snapshot: snapshot,
                    cardIndex: dealStep!,
                  ),
                ),
              ),
            if (!waitingForPlayers)
              for (var i = 0; i < opponents.length; i++)
                Positioned(
                  left: width * seatPositions[i].dx - seatWidth / 2,
                  top: height * seatPositions[i].dy - seatHeight / 2,
                  width: seatWidth,
                  height: seatHeight,
                  child: _SeatBadge(
                    player: opponents[i],
                    isActive: opponents[i].id == snapshot.activePlayerId,
                    isViewer: false,
                    displayHandCount: dealCounts?[opponents[i].id],
                    openingCardsVisible: snapshot.status != GameStatus.opening,
                    alignRight: seatPositions[i].dx > 0.5,
                  ),
                ),
          ],
        );
      },
    );
  }
}

bool _shouldShowDealAnimation(GameSnapshot snapshot, bool waitingForPlayers) {
  if (waitingForPlayers || snapshot.winnerPlayerId != null) return false;
  if (snapshot.lastPlayCards.isNotEmpty ||
      snapshot.openingDiscardPile.isNotEmpty) {
    return false;
  }
  return snapshot.status == GameStatus.opening ||
      snapshot.status == GameStatus.playing;
}

String _dealKeyFor(GameSnapshot snapshot) {
  final counts = snapshot.players
      .map((player) => '${player.id}:${player.handCount}')
      .join(',');
  return '${snapshot.roundNumber}|${snapshot.viewerPlayerId}|$counts';
}

List<String> _dealSequenceFor(GameSnapshot snapshot) {
  final remaining = {
    for (final player in snapshot.players) player.id: player.handCount,
  };
  final sequence = <String>[];
  while (remaining.values.any((count) => count > 0)) {
    for (final player in snapshot.players) {
      final count = remaining[player.id] ?? 0;
      if (count <= 0) continue;
      sequence.add(player.id);
      remaining[player.id] = count - 1;
    }
  }
  return sequence;
}

Offset _dealTargetOffsetFor(GameSnapshot snapshot, String playerId) {
  if (playerId == snapshot.viewerPlayerId) {
    return const Offset(0.50, 0.86);
  }

  final opponents = snapshot.players
      .where((player) => player.id != snapshot.viewerPlayerId)
      .toList();
  final index = opponents.indexWhere((player) => player.id == playerId);
  if (index == -1) return const Offset(0.50, 0.16);
  return _seatPositionsFor(opponents.length)[index];
}

class _DealAnimationOverlay extends StatefulWidget {
  const _DealAnimationOverlay({
    required this.snapshot,
    required this.cardIndex,
  });

  final GameSnapshot snapshot;
  final int cardIndex;

  @override
  State<_DealAnimationOverlay> createState() => _DealAnimationOverlayState();
}

class _DealAnimationOverlayState extends State<_DealAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _TableArenaState._dealStepDuration,
    )..forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant _DealAnimationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardIndex != widget.cardIndex) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final center = Offset(width * 0.50, height * 0.43);
        final sequence = _dealSequenceFor(widget.snapshot);
        if (sequence.isEmpty || widget.cardIndex >= sequence.length) {
          return const SizedBox.shrink();
        }
        final targetOffset = _dealTargetOffsetFor(
          widget.snapshot,
          sequence[widget.cardIndex],
        );
        final target =
            Offset(targetOffset.dx * width, targetOffset.dy * height);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(_controller.value);
            final position = Offset(
              center.dx + (target.dx - center.dx) * t,
              center.dy + (target.dy - center.dy) * t,
            );
            final angle =
                math.atan2(target.dy - center.dy, target.dx - center.dx);
            return Stack(
              children: [
                Positioned(
                  left: center.dx - 19,
                  top: center.dy - 26,
                  child: const _DealDeckStack(),
                ),
                Positioned(
                  left: position.dx - 18,
                  top: position.dy - 25,
                  child: Transform.rotate(
                    angle: angle * 0.16,
                    child: const _FlyingDealCardBack(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DealDeckStack extends StatelessWidget {
  const _DealDeckStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 54,
      child: Stack(
        children: [
          for (var i = 3; i >= 0; i--)
            Positioned(
              left: i * 2,
              top: i * 2,
              child: const _FlyingDealCardBack(),
            ),
        ],
      ),
    );
  }
}

class _FlyingDealCardBack extends StatelessWidget {
  const _FlyingDealCardBack();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
        ),
        borderRadius: BorderRadius.circular(5),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.84), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x77000000),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SizedBox(
        width: 34,
        height: 48,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.62),
                width: 1,
              ),
            ),
            child: const SizedBox(width: 22, height: 32),
          ),
        ),
      ),
    );
  }
}

class _TableCenter extends StatelessWidget {
  const _TableCenter({
    required this.snapshot,
    this.waitingConnectedCount,
    this.waitingExpectedCount,
  });

  final GameSnapshot snapshot;
  final int? waitingConnectedCount;
  final int? waitingExpectedCount;

  @override
  Widget build(BuildContext context) {
    final isWaiting =
        waitingConnectedCount != null && waitingExpectedCount != null;
    if (isWaiting) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: _WaitingProgress(
              connectedCount: waitingConnectedCount!,
              expectedCount: waitingExpectedCount!,
            ),
          ),
        ),
      );
    }

    final lastPlayer = snapshot.lastPlayPlayerId == null
        ? null
        : snapshot.players
            .firstWhere((player) => player.id == snapshot.lastPlayPlayerId)
            .name;
    final matchFinished = _isMatchFinished(snapshot);
    final winner = !matchFinished || snapshot.winnerPlayerId == null
        ? null
        : snapshot.players
            .firstWhere((player) => player.id == snapshot.winnerPlayerId);
    final hasOpeningCards = snapshot.status == GameStatus.opening &&
        snapshot.players.any((player) => player.openingCards.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      child: Stack(
        children: [
          if (hasOpeningCards)
            Positioned.fill(child: _OpeningDiscardBoard(snapshot: snapshot)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (snapshot.lastPlayCards.isEmpty)
                  if (hasOpeningCards)
                    _OpeningStatusPanel(snapshot: snapshot)
                  else
                    Column(
                      children: [
                        Icon(
                          Icons.style,
                          size: 34,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snapshot.status == GameStatus.playing ||
                                  snapshot.status == GameStatus.opening
                              ? '${snapshot.activePlayer.name} jalan'
                              : 'Meja kosong',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                else ...[
                  Text(
                    '$lastPlayer - ${snapshot.lastPlayLabel}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      shadows: [
                        Shadow(
                          color: Color(0x99000000),
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 126,
                    child: Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: snapshot.lastPlayCards.length > 5 ? -10 : 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0;
                              i < snapshot.lastPlayCards.length;
                              i++)
                            Transform.rotate(
                              angle: (i -
                                      (snapshot.lastPlayCards.length - 1) / 2) *
                                  0.055,
                              child: _PlayingCard(
                                card: snapshot.lastPlayCards[i],
                                width: 78,
                                height: 112,
                                selected: false,
                                shown: false,
                                enabled: false,
                                onTap: () {},
                                onDoubleTap: () {},
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (snapshot.openingText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    snapshot.openingText!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
                if (snapshot.pendingText != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(
                      snapshot.pendingText!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
                if (winner != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${winner.name} menang match',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      shadows: const [
                        Shadow(
                          color: Color(0x99000000),
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpeningStatusPanel extends StatelessWidget {
  const _OpeningStatusPanel({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC041F17),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x55FFD45A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            offset: Offset(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PEMBUANGAN KARTU 3',
              style: TextStyle(
                color: Color(0xFFFFD45A),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${snapshot.activePlayer.name} jalan',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpeningDiscardBoard extends StatelessWidget {
  const _OpeningDiscardBoard({required this.snapshot});

  final GameSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final player in snapshot.players)
              if (player.openingCards.isNotEmpty)
                Positioned(
                  left: constraints.maxWidth *
                          _openingCardsOffsetFor(snapshot, player.id).dx -
                      56,
                  top: constraints.maxHeight *
                          _openingCardsOffsetFor(snapshot, player.id).dy -
                      32,
                  width: 112,
                  child: _OpeningCardGroup(player: player),
                ),
          ],
        );
      },
    );
  }
}

class _OpeningCardGroup extends StatelessWidget {
  const _OpeningCardGroup({required this.player});

  final PlayerSnapshot player;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          player.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Color(0xCC000000),
                offset: Offset(0, 1),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final card in player.openingCards)
              _MiniCard(card: card, width: 30, height: 42),
          ],
        ),
      ],
    );
  }
}

Offset _openingCardsOffsetFor(GameSnapshot snapshot, String playerId) {
  if (playerId == snapshot.viewerPlayerId) return const Offset(0.50, 0.72);

  final opponents = snapshot.players
      .where((player) => player.id != snapshot.viewerPlayerId)
      .toList();
  final index = opponents.indexWhere((player) => player.id == playerId);
  if (index == -1) return const Offset(0.50, 0.30);

  final seat = _seatPositionsFor(opponents.length)[index];
  if (seat.dx < 0.30) return const Offset(0.24, 0.48);
  if (seat.dx > 0.70) return const Offset(0.76, 0.48);
  if (seat.dy < 0.35) return const Offset(0.50, 0.26);
  return Offset(seat.dx, 0.62);
}

class _SeatBadge extends StatelessWidget {
  const _SeatBadge({
    required this.player,
    required this.isActive,
    required this.isViewer,
    required this.openingCardsVisible,
    this.displayHandCount,
    this.alignRight = false,
  });

  final PlayerSnapshot player;
  final bool isActive;
  final bool isViewer;
  final bool openingCardsVisible;
  final int? displayHandCount;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final handCount = displayHandCount ?? player.handCount;
    final tableCards = [
      if (openingCardsVisible) ...player.openingCards,
      ...player.shownCards,
    ];
    final avatar = _PlayerAvatar(
      name: player.name,
      active: isActive,
    );
    final details = Expanded(
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              if (alignRight && isActive)
                const Icon(
                  Icons.arrow_circle_down,
                  size: 15,
                  color: Color(0xFFF0B43D),
                ),
              if (alignRight && isActive) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isViewer ? '${player.name} (Kamu)' : player.name,
                  textAlign: alignRight ? TextAlign.end : TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    shadows: [
                      Shadow(
                        color: Color(0xCC000000),
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              if (!alignRight && isActive)
                const Icon(
                  Icons.arrow_circle_down,
                  size: 15,
                  color: Color(0xFFF0B43D),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Wrap(
            alignment: alignRight ? WrapAlignment.end : WrapAlignment.start,
            spacing: 5,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _CardBack(count: handCount),
              Text(
                '$handCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Color(0xCC000000),
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (tableCards.isNotEmpty) ...[
            const SizedBox(height: 3),
            SizedBox(
              height: 36,
              child: ListView(
                reverse: alignRight,
                scrollDirection: Axis.horizontal,
                children: [
                  for (final card in tableCards) ...[
                    _MiniCard(card: card),
                    const SizedBox(width: 3),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: alignRight
            ? [details, const SizedBox(width: 5), avatar]
            : [avatar, const SizedBox(width: 5), details],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.name, required this.active});

  final String name;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [Color(0xFFFFFFFF), Color(0xFFF0B43D)]
              : const [Color(0xFFF8D66D), Color(0xFFC57C1D)],
        ),
      ),
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: Color(0xFF24140B),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final visible = count <= 0 ? 1 : count.clamp(1, 3);
    return SizedBox(
      width: 28,
      height: 18,
      child: Stack(
        children: [
          for (var i = 0; i < visible; i++)
            Positioned(
              left: i * 5,
              top: i * 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const SizedBox(width: 15, height: 17),
              ),
            ),
        ],
      ),
    );
  }
}

class _HandPanel extends StatelessWidget {
  const _HandPanel({
    required this.snapshot,
    required this.selectedCardIds,
    required this.canAct,
    required this.onToggleCard,
    required this.onAction,
    this.visibleHandCount,
  });

  final GameSnapshot snapshot;
  final Set<String> selectedCardIds;
  final bool canAct;
  final ValueChanged<GameCard> onToggleCard;
  final ValueChanged<String> onAction;
  final int? visibleHandCount;

  @override
  Widget build(BuildContext context) {
    final canPlayPhase = canAct && snapshot.status == GameStatus.playing;
    final canOpeningPhase = canAct && snapshot.status == GameStatus.opening;
    final canShowCards =
        snapshot.status == GameStatus.playing && selectedCardIds.isNotEmpty;
    final viewerOpeningCards = snapshot.status == GameStatus.opening
        ? const <GameCard>[]
        : snapshot.viewer.openingCards;
    final shownCardIds =
        snapshot.viewer.shownCards.map((card) => card.id).toSet();
    final selectedShown = selectedCardIds.isNotEmpty &&
        selectedCardIds.every((id) => shownCardIds.contains(id));
    return LayoutBuilder(
      builder: (context, constraints) {
        const actionRailWidth = 72.0;
        final visibleCount = math
            .min(visibleHandCount ?? snapshot.viewer.hand.length,
                snapshot.viewer.hand.length)
            .clamp(0, snapshot.viewer.hand.length)
            .toInt();
        final visibleHand =
            snapshot.viewer.hand.take(visibleCount).toList(growable: false);
        final handCount = visibleHand.length;
        final handCardHeight =
            (constraints.maxHeight - 78).clamp(70.0, 104.0).toDouble();
        final handCardWidth = handCardHeight * 0.67;
        final availableWidth = constraints.maxWidth - actionRailWidth - 12;
        final preferredOverlap = handCardWidth * 0.50;
        final minOverlap = handCardWidth * 0.36;
        final fittedOverlap = handCount <= 1
            ? 0.0
            : ((availableWidth - handCardWidth) / (handCount - 1))
                .clamp(minOverlap, preferredOverlap)
                .toDouble();
        final actualHandWidth = handCount <= 1
            ? handCardWidth
            : handCardWidth + (handCount - 1) * fittedOverlap;
        final handContentWidth =
            actualHandWidth < availableWidth ? availableWidth : actualHandWidth;
        final startOffset = actualHandWidth < availableWidth
            ? (availableWidth - actualHandWidth) / 2
            : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (viewerOpeningCards.isNotEmpty)
              Positioned(
                left: actionRailWidth,
                top: 0,
                width: 180,
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final card in viewerOpeningCards) ...[
                      _MiniCard(card: card),
                      const SizedBox(width: 3),
                    ],
                  ],
                ),
              ),
            Positioned(
              left: 22,
              bottom: 8,
              child: Wrap(
                spacing: 6,
                children: [
                  _SmallActionButton(
                    tooltip: selectedShown ? 'Tutup kartu' : 'Pamer kartu',
                    icon:
                        selectedShown ? Icons.visibility_off : Icons.visibility,
                    enabled: canShowCards,
                    onPressed: () => onAction(selectedShown ? 'hide' : 'show'),
                  ),
                ],
              ),
            ),
            if (canPlayPhase || canOpeningPhase)
              Positioned(
                left: actionRailWidth,
                right: 28,
                top: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canOpeningPhase)
                      _HandActionButton(
                        tooltip: 'Buang kartu 3',
                        icon: Icons.filter_3,
                        label: 'Buang 3',
                        enabled: true,
                        onPressed: () => onAction('opening'),
                      )
                    else ...[
                      _HandActionButton(
                        tooltip: 'Mainkan kartu',
                        icon: Icons.play_arrow,
                        label: 'Play',
                        enabled: selectedCardIds.isNotEmpty,
                        onPressed: () => onAction('play'),
                      ),
                      if (snapshot.lastPlayCards.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _HandActionButton(
                          tooltip: 'Skip giliran',
                          icon: Icons.skip_next,
                          label: 'Skip',
                          enabled: true,
                          onPressed: () => onAction('pass'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            Positioned(
              left: actionRailWidth,
              right: 4,
              bottom: 0,
              top: 16,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.fromLTRB(0, 18, 10, 0),
                child: SizedBox(
                  width: handContentWidth,
                  height: handCardHeight + 34,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < handCount; i++)
                        Positioned(
                          left: startOffset + i * fittedOverlap,
                          bottom: _handCardArcOffset(i, handCount),
                          child: Transform.rotate(
                            angle: _handCardAngle(i, handCount),
                            child: _PlayingCard(
                              card: visibleHand[i],
                              width: handCardWidth,
                              height: handCardHeight,
                              selected:
                                  selectedCardIds.contains(visibleHand[i].id),
                              shown: snapshot.viewer.shownCards.any(
                                (shownCard) =>
                                    shownCard.id == visibleHand[i].id,
                              ),
                              enabled: canAct,
                              onTap: () => onToggleCard(visibleHand[i]),
                              onDoubleTap: () {},
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

double _handCardAngle(int index, int count) {
  if (count <= 1) return 0;
  final center = (count - 1) / 2;
  return ((index - center) / center) * 0.075;
}

double _handCardArcOffset(int index, int count) {
  if (count <= 1) return 0;
  final center = (count - 1) / 2;
  final distance = ((index - center) / center).abs();
  return (1 - distance) * 9;
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: enabled
              ? const [Color(0xFFFFD45A), Color(0xFFC57C1D)]
              : const [Color(0xFF232A59), Color(0xFF151A3C)],
        ),
        border: Border.all(
          color: const Color(0xFF05080D).withValues(alpha: 0.35),
        ),
      ),
      child: SizedBox(
        width: 38,
        height: 38,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          onPressed: enabled ? onPressed : null,
          icon: Icon(
            icon,
            size: 22,
            color: enabled
                ? const Color(0xFF231307)
                : Colors.white.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _HandActionButton extends StatelessWidget {
  const _HandActionButton({
    required this.tooltip,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 30,
        child: FilledButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFD45A),
            foregroundColor: const Color(0xFF231307),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            minimumSize: const Size(0, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayingCard extends StatelessWidget {
  const _PlayingCard({
    required this.card,
    required this.width,
    required this.height,
    required this.selected,
    required this.shown,
    required this.enabled,
    required this.onTap,
    required this.onDoubleTap,
  });

  final GameCard card;
  final double width;
  final double height;
  final bool selected;
  final bool shown;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final color = _cardColor(card);
    final isRed = card.suit == Suit.heart || card.suit == Suit.diamond;
    return Transform.translate(
      offset: Offset(0, selected ? -10 : 0),
      child: InkWell(
        onTap: enabled ? onTap : null,
        onDoubleTap: enabled ? onDoubleTap : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: width,
          height: height,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: card.isJoker
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: card.isRedJoker
                        ? const [Color(0xFFFFFFFF), Color(0xFFFFE4E6)]
                        : const [Color(0xFFFFFFFF), Color(0xFFE5E7EB)],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isRed
                        ? const [Color(0xFFFFFFFF), Color(0xFFFFE4E6)]
                        : const [Color(0xFFFFFFFF), Color(0xFFEFF6FF)],
                  ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
                offset: Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Stack(
            children: [
              if (selected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x22FFD45A),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              if (shown)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(Icons.visibility, color: color, size: 14),
                ),
              Positioned(
                left: 0,
                top: 0,
                child: _CardCorner(card: card, color: color),
              ),
              Center(
                child: card.isJoker
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: color, size: width * 0.32),
                          Text(
                            'JOKER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w900,
                              fontSize: width * 0.18,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            card.suit!.symbol,
                            style: TextStyle(
                              color: color.withValues(alpha: 0.12),
                              fontSize: width * 0.78,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            card.suit!.symbol,
                            style: TextStyle(
                              color: color,
                              fontSize: width * 0.40,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardCorner extends StatelessWidget {
  const _CardCorner({required this.card, required this.color});

  final GameCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (card.isJoker) {
      return Text(
        'J',
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          card.rank!.label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 0.9,
          ),
        ),
        Text(
          card.suit!.symbol,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 0.9,
          ),
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.card,
    this.width = 24,
    this.height = 34,
  });

  final GameCard card;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = _cardColor(card);
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFEFF6FF)],
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.24)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 0,
                child: Text(
                  card.isJoker ? 'J' : card.rank!.label,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.34,
                    fontWeight: FontWeight.w900,
                    height: 0.9,
                  ),
                ),
              ),
              Center(
                child: Text(
                  card.isJoker ? 'J' : card.suit!.symbol,
                  style: TextStyle(
                    color: color,
                    fontSize: width * 0.54,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkFloorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF07121A), Color(0xFF02070B)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    final linePaint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 128) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (var y = 0.0; y < size.height; y += 58) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TableSurfacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x22FFFFFF);

    for (var i = 1; i <= 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: size.width * (0.34 + i * 0.17),
          height: size.height * (0.32 + i * 0.16),
        ),
        linePaint,
      );
    }

    final glow = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.72,
        colors: [
          Colors.white.withValues(alpha: 0.10),
          Colors.transparent,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawOval(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _cardColor(GameCard card) {
  if (card.isJoker) {
    return card.isRedJoker ? const Color(0xFFB91C1C) : const Color(0xFF111827);
  }
  if (card.suit == Suit.heart || card.suit == Suit.diamond) {
    return const Color(0xFFB91C1C);
  }
  return const Color(0xFF0F172A);
}

List<Offset> _seatPositionsFor(int opponentCount) {
  const positions = [
    Offset(0.50, 0.16),
    Offset(0.14, 0.50),
    Offset(0.86, 0.50),
    Offset(0.28, 0.17),
    Offset(0.72, 0.17),
    Offset(0.13, 0.32),
    Offset(0.87, 0.32),
    Offset(0.13, 0.68),
    Offset(0.87, 0.68),
  ];
  return positions.take(opponentCount).toList(growable: false);
}

String _shortError(Object error) {
  final text = error.toString();
  return text
      .replaceFirst('Bad state: ', '')
      .replaceFirst('Invalid argument(s): ', '')
      .replaceFirst('StateError: ', '')
      .replaceFirst('ArgumentError: ', '');
}

Future<String> _findLocalIp() async {
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (!address.isLoopback) return address.address;
    }
  }
  return '127.0.0.1';
}
