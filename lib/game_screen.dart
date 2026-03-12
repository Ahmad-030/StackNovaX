import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const StackNovaXApp());
}

class StackNovaXApp extends StatelessWidget {
  const StackNovaXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StackNovaX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'monospace'),
      home: const GameScreen(),
    );
  }
}

// ─── Constants ────────────────────────────────────────────────────────────────

const double kBlockHeight = 26.0;
const double kMinBlockWidth = 20.0;
const double kInitialBlockWidth = 180.0;
const double kBaseSpeed = 220.0; // px per second
const int kSpeedIncreaseEvery = 5;
const double kSpeedIncrement = 30.0;
const double kPerfectTolerance = 5.0;
const int kPerfectBonus = 2;

final List<Color> kBlockColors = [
  const Color(0xFF00E5FF),
  const Color(0xFF1DE9B6),
  const Color(0xFF40C4FF),
  const Color(0xFF64FFDA),
  const Color(0xFF18FFFF),
  const Color(0xFF84FFFF),
  const Color(0xFF80D8FF),
  const Color(0xFFB2EBF2),
  const Color(0xFF00BCD4),
  const Color(0xFF00ACC1),
];

// ─── Data Models ──────────────────────────────────────────────────────────────

class StackBlock {
  final double x;
  final double width;
  final Color color;
  final int index;

  const StackBlock({
    required this.x,
    required this.width,
    required this.color,
    required this.index,
  });
}

class FallingPiece {
  double x;
  double y;
  final double width;
  final Color color;
  double opacity;

  FallingPiece({
    required this.x,
    required this.y,
    required this.width,
    required this.color,
    this.opacity = 1.0,
  });
}

enum GameState { playing, gameOver }

// ─── Game Screen ──────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  // Layout
  late double _gameWidth;
  late double _gameHeight;
  static const double _bottomPadding = 60.0;
  static const double _stackAreaHeight = 500.0;

  // Game state
  GameState _gameState = GameState.playing;
  int _score = 0;
  int _highScore = 0;

  // Stack
  List<StackBlock> _stack = [];

  // Moving block
  double _movingX = 0.0;
  double _movingWidth = kInitialBlockWidth;
  bool _movingRight = true;
  double _currentSpeed = kBaseSpeed;

  // Falling pieces (cut-off bits)
  final List<FallingPiece> _fallingPieces = [];

  // Animations
  late AnimationController _movingController;
  late Animation<double> _movingAnimation;
  AnimationController? _scorePopController;
  Animation<double>? _scorePopAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Perfect text
  String? _bonusText;
  Timer? _bonusTimer;

  // Stars
  late List<_Star> _stars;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _stars = List.generate(
      70,
          (_) => _Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 2 + 0.5,
        opacity: _rng.nextDouble() * 0.6 + 0.2,
      ),
    );

    _movingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 100), // we use tick-based movement
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Delay until layout is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGame());
  }

  void _initGame() {
    final size = MediaQuery.of(context).size;
    _gameWidth = size.width;
    _gameHeight = size.height;

    final baseX = (_gameWidth - kInitialBlockWidth) / 2;

    _stack = [
      StackBlock(
        x: baseX,
        width: kInitialBlockWidth,
        color: kBlockColors[0],
        index: 0,
      ),
    ];

    _movingWidth = kInitialBlockWidth;
    _movingX = 0.0;
    _movingRight = true;
    _currentSpeed = kBaseSpeed;
    _score = 0;
    _fallingPieces.clear();
    _gameState = GameState.playing;

    _startMovingBlock();
    setState(() {});
  }

  void _startMovingBlock() {
    _movingController.stop();
    _movingController.dispose();

    _movingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    _movingController.addListener(_updateMovingBlock);
    _movingController.repeat();
  }

  DateTime _lastTick = DateTime.now();

  void _updateMovingBlock() {
    if (_gameState != GameState.playing) return;

    final now = DateTime.now();
    final dt = now.difference(_lastTick).inMilliseconds / 1000.0;
    _lastTick = now;

    double newX = _movingX + (_movingRight ? 1 : -1) * _currentSpeed * dt;

    if (newX + _movingWidth >= _gameWidth) {
      newX = _gameWidth - _movingWidth;
      _movingRight = false;
    } else if (newX <= 0) {
      newX = 0;
      _movingRight = true;
    }

    setState(() {
      _movingX = newX;
    });
  }

  void _onTap() {
    if (_gameState == GameState.gameOver) return;
    HapticFeedback.lightImpact();
    _placeBlock();
  }

  void _placeBlock() {
    final top = _stack.last;

    final leftOverlap = _movingX + _movingWidth - top.x;
    final rightOverlap = top.x + top.width - _movingX;
    final overlap = min(leftOverlap, rightOverlap);

    if (overlap <= 0) {
      // Completely missed
      _triggerGameOver();
      return;
    }

    final newX = max(_movingX, top.x);
    final newWidth = overlap;

    // Check perfect
    final isPerfect = (_movingX - top.x).abs() <= kPerfectTolerance;

    // Cut piece
    if (!isPerfect) {
      double cutX;
      double cutWidth;
      if (_movingX < top.x) {
        // Left overhang
        cutX = _movingX;
        cutWidth = top.x - _movingX;
      } else {
        // Right overhang
        cutX = top.x + top.width;
        cutWidth = _movingX + _movingWidth - (top.x + top.width);
      }

      if (cutWidth > 0) {
        _fallingPieces.add(FallingPiece(
          x: cutX,
          y: _stackBottomY + _stack.length * kBlockHeight,
          width: cutWidth,
          color: kBlockColors[(_stack.length) % kBlockColors.length],
        ));
        _animateFallingPieces();
      }
    }

    if (newWidth < kMinBlockWidth) {
      _triggerGameOver();
      return;
    }

    final newScore = _score + 1 + (isPerfect ? kPerfectBonus : 0);
    final newIndex = _stack.length;

    setState(() {
      _stack.add(StackBlock(
        x: isPerfect ? top.x : newX,
        width: isPerfect ? top.width : newWidth,
        color: kBlockColors[newIndex % kBlockColors.length],
        index: newIndex,
      ));
      _score = newScore;
      _movingWidth = isPerfect ? top.width : newWidth;
      _movingX = isPerfect ? top.x : newX;

      if (isPerfect) {
        _bonusText = '✦ PERFECT +$kPerfectBonus';
      }
    });

    if (isPerfect) {
      HapticFeedback.mediumImpact();
      _bonusTimer?.cancel();
      _bonusTimer = Timer(const Duration(milliseconds: 1200), () {
        setState(() => _bonusText = null);
      });
    }

    // Speed increase every N stacks
    if (_stack.length % kSpeedIncreaseEvery == 0) {
      _currentSpeed += kSpeedIncrement;
    }

    _triggerScorePop();
  }

  void _triggerScorePop() {
    _scorePopController?.dispose();
    _scorePopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scorePopAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _scorePopController!,
      curve: Curves.easeOut,
    ));
    _scorePopController!.forward();
  }

  void _animateFallingPieces() {
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      bool anyActive = false;
      setState(() {
        for (final p in _fallingPieces) {
          if (p.opacity > 0) {
            p.y -= 3;
            p.opacity -= 0.04;
            anyActive = true;
          }
        }
        if (!anyActive) {
          _fallingPieces.clear();
          timer.cancel();
        }
      });
    });
  }

  void _triggerGameOver() {
    HapticFeedback.heavyImpact();
    _movingController.stop();
    setState(() {
      _gameState = GameState.gameOver;
      if (_score > _highScore) _highScore = _score;
    });
  }

  void _restart() {
    _initGame();
  }

  double get _stackBottomY => _bottomPadding;

  int get _visibleStackStart {
    final maxVisible = (_stackAreaHeight / kBlockHeight).floor();
    return max(0, _stack.length - maxVisible);
  }

  @override
  void dispose() {
    _movingController.dispose();
    _scorePopController?.dispose();
    _pulseController.dispose();
    _bonusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _onTap,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF030814),
                Color(0xFF050D20),
                Color(0xFF061228),
                Color(0xFF040A18),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Stars
              ..._stars.map((s) => Positioned(
                left: s.x * MediaQuery.of(context).size.width,
                top: s.y * MediaQuery.of(context).size.height,
                child: Container(
                  width: s.size,
                  height: s.size,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(s.opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              )),

              // Nebula glow background
              Positioned(
                top: -100,
                left: -50,
                right: -50,
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E5FF).withOpacity(0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildStackArea(),
                          if (_gameState == GameState.gameOver)
                            _buildGameOverOverlay(),
                        ],
                      ),
                    ),
                    _buildBottomHint(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // High score
          _buildStatBox('BEST', _highScore.toString()),

          // Main score
          AnimatedBuilder(
            animation: _scorePopAnimation ?? const AlwaysStoppedAnimation(1.0),
            builder: (context, child) {
              final scale = _scorePopAnimation?.value ?? 1.0;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Column(
              children: [
                Text(
                  _score.toString(),
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: -2,
                    shadows: [
                      Shadow(color: Color(0xFF00E5FF), blurRadius: 20),
                      Shadow(color: Color(0xFF00E5FF), blurRadius: 40),
                    ],
                  ),
                ),
                const Text(
                  'SCORE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 4,
                    color: Color(0xFF00E5FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Level indicator
          _buildStatBox('LVL', ((_score ~/ kSpeedIncreaseEvery) + 1).toString()),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFF00E5FF).withOpacity(0.05),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 3,
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackArea() {
    return LayoutBuilder(builder: (context, constraints) {
      final areaWidth = constraints.maxWidth;
      final areaHeight = constraints.maxHeight;
      final visibleStart = _visibleStackStart;
      final visibleStack = _stack.sublist(visibleStart);

      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Grid lines (subtle)
          CustomPaint(
            size: Size(areaWidth, areaHeight),
            painter: _GridPainter(),
          ),

          // Stacked blocks
          ...visibleStack.asMap().entries.map((e) {
            final visualIndex = e.key;
            final block = e.value;
            final bottomOffset = _bottomPadding + visualIndex * kBlockHeight;

            return Positioned(
              left: block.x,
              bottom: bottomOffset,
              child: _buildBlock(
                width: block.width,
                color: block.color,
                isTop: visualIndex == visibleStack.length - 1,
              ),
            );
          }),

          // Falling cut pieces
          ..._fallingPieces.map((p) {
            final adjustedY = areaHeight - p.y;
            return Positioned(
              left: p.x,
              top: adjustedY,
              child: Opacity(
                opacity: p.opacity.clamp(0.0, 1.0),
                child: Container(
                  width: p.width,
                  height: kBlockHeight,
                  decoration: BoxDecoration(
                    color: p.color.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            );
          }),

          // Moving block (only if playing)
          if (_gameState == GameState.playing)
            Positioned(
              left: _movingX,
              bottom: _bottomPadding +
                  visibleStack.length * kBlockHeight,
              child: _buildMovingBlock(),
            ),

          // Perfect bonus text
          if (_bonusText != null)
            Center(
              child: AnimatedOpacity(
                opacity: _bonusText != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF1DE9B6)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withOpacity(0.5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Text(
                    _bonusText!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF030814),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildBlock({
    required double width,
    required Color color,
    bool isTop = false,
  }) {
    return Container(
      width: width,
      height: kBlockHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.95),
            color.withOpacity(0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          if (isTop)
            BoxShadow(
              color: color.withOpacity(0.7),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildMovingBlock() {
    final color = kBlockColors[_stack.length % kBlockColors.length];
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: _movingWidth,
          height: kBlockHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.98),
                color.withOpacity(0.78),
              ],
            ),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.8 * _pulseAnimation.value),
                blurRadius: 20 * _pulseAnimation.value,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
              ),
            ],
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.45),
                width: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomHint() {
    if (_gameState == GameState.gameOver) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, top: 8),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (ctx, _) => Opacity(
          opacity: 0.4 + 0.4 * _pulseAnimation.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'TAP TO STACK',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 5,
                  color: Color(0xFF00E5FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF00E5FF),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: const Color(0xFF030814).withOpacity(0.88),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.4),
                  width: 1.5,
                ),
                color: const Color(0xFF00E5FF).withOpacity(0.05),
              ),
              child: const Center(
                child: Text('✦', style: TextStyle(fontSize: 30)),
              ),
            ),

            const SizedBox(height: 24),

            // Game Over text
            const Text(
              'GAME OVER',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 6,
                shadows: [
                  Shadow(color: Color(0xFF00E5FF), blurRadius: 20),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Tower collapsed at block $_score',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.4),
                letterSpacing: 1,
              ),
            ),

            const SizedBox(height: 36),

            // Score display
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF00E5FF).withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF00E5FF).withOpacity(0.08),
                    const Color(0xFF1DE9B6).withOpacity(0.04),
                  ],
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildResultStat('SCORE', _score.toString()),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                  ),
                  _buildResultStat('BEST', _highScore.toString()),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Play Again button
            GestureDetector(
              onTap: _restart,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 48, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF1DE9B6)],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withOpacity(0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Text(
                  'PLAY AGAIN',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF030814),
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {}, // navigate to menu
              child: Text(
                'MAIN MENU',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 3,
                  color: Colors.white.withOpacity(0.35),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 4,
            color: const Color(0xFF00E5FF).withOpacity(0.8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, size, opacity;
  const _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
  });
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withOpacity(0.03)
      ..strokeWidth = 1;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}