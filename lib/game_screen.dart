import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacknovax/app_theme.dart';
import 'package:stacknovax/storage_service.dart';


// ─── Constants ───────────────────────────────────────────────────────────────

const double kBlockHeight       = 26.0;
const double kMinBlockWidth     = 18.0;
const double kInitialBlockWidth = 180.0;
const int    kSpeedIncreaseEvery = 5;
const double kSpeedIncrement    = 25.0;
const int    kPerfectBonus      = 2;

// ─── Models ───────────────────────────────────────────────────────────────────

class StackBlock {
  final double x, width;
  final Color color;
  final int index;
  const StackBlock({required this.x, required this.width,
    required this.color, required this.index});
}

class FallingPiece {
  double x, y, opacity;
  final double width;
  final Color color;
  FallingPiece({required this.x, required this.y,
    required this.width, required this.color, this.opacity = 1.0});
}

enum GameState { playing, paused, gameOver }

// ─── Game Screen ─────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  final int level;
  final bool isContinue;
  const GameScreen({super.key, required this.level, required this.isContinue});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final StorageService _storage = StorageService();

  // Layout
  late double _gameWidth, _gameHeight;
  static const double _bottomPadding   = 60.0;
  static const double _stackAreaHeight = 520.0;

  // Game state
  GameState _gameState   = GameState.playing;
  int _score             = 0;
  int _highScore         = 0;
  int _perfectStreak     = 0;
  late GameLevel _levelData;

  // Next-level unlock
  bool _nextLevelUnlocked = false;

  // Stack
  List<StackBlock> _stack = [];

  // Moving block
  double _movingX     = 0.0;
  double _movingWidth = kInitialBlockWidth;
  bool   _movingRight = true;
  double _currentSpeed = 160.0;

  // Falling pieces
  final List<FallingPiece> _fallingPieces = [];

  // Animations
  late AnimationController _movingController;
  AnimationController?     _scorePopController;
  Animation<double>?       _scorePopAnimation;
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;
  late AnimationController _shakeController;
  late Animation<double>   _shakeAnim;

  // Bonus text
  String? _bonusText;
  Timer?  _bonusTimer;
  DateTime _lastTick = DateTime.now();

  // Stars
  late List<_Star> _stars;
  final Random _rng = Random();

  bool _isNewHighScore = false;

  @override
  void initState() {
    super.initState();
    _levelData    = StorageService.levels[widget.level - 1];
    _currentSpeed = _levelData.speed;

    _stars = List.generate(70, (_) => _Star(
      x: _rng.nextDouble(), y: _rng.nextDouble(),
      size: _rng.nextDouble() * 2 + 0.5,
      opacity: _rng.nextDouble() * 0.6 + 0.2,
    ));

    _movingController = AnimationController(vsync: this,
        duration: const Duration(seconds: 100));

    _pulseController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _shakeController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0,  end: -8), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -8, end:  8), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 8,  end: -6), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: -6, end:  6), weight: 2),
      TweenSequenceItem(tween: Tween<double>(begin: 6,  end:  0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) => _initGame());
  }

  Future<void> _initGame() async {
    final size = MediaQuery.of(context).size;
    _gameWidth  = size.width;
    _gameHeight = size.height;
    _highScore  = await _storage.getHighScore(widget.level);

    final baseX = (_gameWidth - kInitialBlockWidth) / 2;

    if (widget.isContinue) {
      final savedData = await _storage.loadGame();
      if (savedData != null && mounted) {
        _score        = savedData['score'] ?? 0;
        _currentSpeed = (savedData['speed'] as num?)?.toDouble() ?? _levelData.speed;
        final savedBlocks = savedData['blocks'] as List<dynamic>?;
        if (savedBlocks != null) {
          _stack = savedBlocks.map((b) => StackBlock(
            x:     (b['x']  as num).toDouble(),
            width: (b['w']  as num).toDouble(),
            color: AppColors.blockColors[b['ci'] as int],
            index: b['idx'] as int,
          )).toList();
          _movingWidth = _stack.last.width;
          setState(() {});
          _startMovingBlock();
          return;
        }
      }
    }

    _stack = [StackBlock(x: baseX, width: kInitialBlockWidth,
        color: AppColors.blockColors[0], index: 0)];
    _movingWidth = kInitialBlockWidth;
    _movingX     = 0.0;
    _movingRight = true;
    _score       = 0;
    _perfectStreak = 0;
    _fallingPieces.clear();
    _gameState   = GameState.playing;

    await _storage.incrementTotalGames();

    // ✅ Save which level the player is on — persists through game overs
    // so Continue on the menu always returns to this level.
    await _storage.saveLastLevel(widget.level);

    _startMovingBlock();
    setState(() {});
  }

  void _startMovingBlock() {
    _movingController.stop();
    _movingController.dispose();
    _movingController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 16));
    _movingController.addListener(_updateMovingBlock);
    _movingController.repeat();
    _lastTick = DateTime.now();
  }

  void _updateMovingBlock() {
    if (_gameState != GameState.playing) return;
    final now = DateTime.now();
    final dt  = now.difference(_lastTick).inMilliseconds / 1000.0;
    _lastTick = now;

    double newX = _movingX + (_movingRight ? 1 : -1) * _currentSpeed * dt;
    if (newX + _movingWidth >= _gameWidth) {
      newX = _gameWidth - _movingWidth; _movingRight = false;
    } else if (newX <= 0) {
      newX = 0; _movingRight = true;
    }
    setState(() => _movingX = newX);
  }

  void _onTap() {
    if (_gameState != GameState.playing) return;
    HapticFeedback.lightImpact();
    _placeBlock();
  }

  void _placeBlock() {
    final top         = _stack.last;
    final leftOverlap = _movingX + _movingWidth - top.x;
    final rightOverlap = top.x + top.width - _movingX;
    final overlap      = min(leftOverlap, rightOverlap);

    if (overlap <= 0) { _triggerGameOver(); return; }

    final newX      = max(_movingX, top.x);
    final newWidth  = overlap;
    final isPerfect = (_movingX - top.x).abs() <= _levelData.tolerance;

    if (!isPerfect) {
      _perfectStreak = 0;
      double cutX, cutWidth;
      if (_movingX < top.x) {
        cutX = _movingX; cutWidth = top.x - _movingX;
      } else {
        cutX = top.x + top.width;
        cutWidth = _movingX + _movingWidth - (top.x + top.width);
      }
      if (cutWidth > 0) {
        _fallingPieces.add(FallingPiece(
          x: cutX, y: _stackBottomY + _stack.length * kBlockHeight,
          width: cutWidth,
          color: AppColors.blockColors[_stack.length % AppColors.blockColors.length],
        ));
        _animateFallingPieces();
      }
    } else {
      _perfectStreak++;
    }

    if (newWidth < kMinBlockWidth) { _triggerGameOver(); return; }

    final bonus    = isPerfect ? (kPerfectBonus + (_perfectStreak > 2 ? 1 : 0)) : 0;
    final newScore = _score + 1 + bonus;
    final newIndex = _stack.length;

    setState(() {
      _stack.add(StackBlock(
        x:     isPerfect ? top.x    : newX,
        width: isPerfect ? top.width : newWidth,
        color: AppColors.blockColors[newIndex % AppColors.blockColors.length],
        index: newIndex,
      ));
      _score       = newScore;
      _movingWidth = isPerfect ? top.width : newWidth;
      _movingX     = isPerfect ? top.x    : newX;
      if (isPerfect) {
        _bonusText = _perfectStreak >= 3
            ? '⚡ STREAK x$_perfectStreak  +${bonus + 1}'
            : '✦ PERFECT  +$bonus';
      }
    });

    if (isPerfect) {
      HapticFeedback.mediumImpact();
      _bonusTimer?.cancel();
      _bonusTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _bonusText = null);
      });
    }

    if (_stack.length % kSpeedIncreaseEvery == 0) _currentSpeed += kSpeedIncrement;

    _triggerScorePop();
    _saveGame();
    _storage.addBlocks(1);
  }

  Future<void> _saveGame() async {
    await _storage.saveGame({
      'level': widget.level,
      'score': _score,
      'speed': _currentSpeed,
      'blocks': _stack.map((b) => {
        'x': b.x, 'w': b.width,
        'ci': AppColors.blockColors.indexOf(b.color),
        'idx': b.index,
      }).toList(),
    });
  }

  void _triggerScorePop() {
    _scorePopController?.dispose();
    _scorePopController = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 300));
    _scorePopAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _scorePopController!, curve: Curves.easeOut));
    _scorePopController!.forward();
  }

  void _animateFallingPieces() {
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) { timer.cancel(); return; }
      bool anyActive = false;
      setState(() {
        for (final p in _fallingPieces) {
          if (p.opacity > 0) { p.y -= 3; p.opacity -= 0.04; anyActive = true; }
        }
        if (!anyActive) { _fallingPieces.clear(); timer.cancel(); }
      });
    });
  }

  Future<void> _triggerGameOver() async {
    HapticFeedback.heavyImpact();
    _shakeController.forward(from: 0);
    _movingController.stop();

    final oldHigh    = await _storage.getHighScore(widget.level);
    _isNewHighScore  = _score > oldHigh;
    await _storage.saveHighScore(widget.level, _score);
    await _storage.clearSavedGame();

    // ✅ Next level unlocks only if the player scored 30+ on this level.
    // Uses the freshly saved high score so a new record is counted immediately.
    final nextLevel = widget.level + 1;
    bool nextUnlocked = false;
    if (nextLevel <= StorageService.levels.length) {
      final updatedHigh = max(_score, oldHigh);
      nextUnlocked = updatedHigh >= StorageService.unlockScoreRequired;
    }

    if (mounted) {
      setState(() {
        _gameState          = GameState.gameOver;
        _highScore          = max(_score, oldHigh);
        _nextLevelUnlocked  = nextUnlocked;
      });
    }
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_gameState == GameState.playing) {
        _gameState = GameState.paused;
        _movingController.stop();
      } else if (_gameState == GameState.paused) {
        _gameState = GameState.playing;
        _lastTick  = DateTime.now();
        _movingController.repeat();
      }
    });
  }

  void _restart() {
    _storage.clearSavedGame();
    setState(() {
      _gameState = GameState.playing; _score = 0; _perfectStreak = 0;
      _isNewHighScore = false; _nextLevelUnlocked = false;
      _fallingPieces.clear(); _bonusText = null;
    });
    _currentSpeed = _levelData.speed;
    _initGame();
  }

  void _goToNextLevel() {
    HapticFeedback.mediumImpact();
    _storage.clearSavedGame();
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) =>
          GameScreen(level: widget.level + 1, isContinue: false),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  void _goToMenu() {
    if (_gameState != GameState.gameOver) _saveGame();
    Navigator.of(context).pop();
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
    _shakeController.dispose();
    _bonusTimer?.cancel();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: _onTap,
        child: Container(
          decoration: const BoxDecoration(gradient: AppGradients.background),
          child: AnimatedBuilder(
            animation: _shakeAnim,
            builder: (_, child) => Transform.translate(
                offset: Offset(_shakeAnim.value, 0), child: child),
            child: Stack(children: [
              ..._stars.map((s) => Positioned(
                left: s.x * MediaQuery.of(context).size.width,
                top:  s.y * MediaQuery.of(context).size.height,
                child: Container(width: s.size, height: s.size,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: s.opacity),
                        shape: BoxShape.circle)),
              )),
              Positioned.fill(child: CustomPaint(painter: _GridPainter())),
              SafeArea(child: Column(children: [
                _buildTopBar(),
                Expanded(child: Stack(clipBehavior: Clip.none, children: [
                  _buildStackArea(),
                  if (_gameState == GameState.paused)   _buildPauseOverlay(),
                  if (_gameState == GameState.gameOver) _buildGameOverOverlay(),
                ])),
                _buildBottomHint(),
              ])),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildStatBox('BEST', '$_highScore'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Text('LVL ${widget.level}  •  ${_levelData.name}',
                  style: const TextStyle(fontSize: 9, letterSpacing: 2,
                      color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ]),

          AnimatedBuilder(
            animation: _scorePopAnimation ?? const AlwaysStoppedAnimation(1.0),
            builder: (_, child) => Transform.scale(
                scale: _scorePopAnimation?.value ?? 1.0, child: child),
            child: Column(children: [
              Text('$_score', style: const TextStyle(
                fontSize: 54, fontWeight: FontWeight.w900, color: Colors.white,
                height: 1.0, letterSpacing: -2,
                shadows: [Shadow(color: AppColors.primary, blurRadius: 20),
                  Shadow(color: AppColors.primary, blurRadius: 40)],
              )),
              Text('SCORE', style: TextStyle(fontSize: 10, letterSpacing: 4,
                  color: AppColors.primary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600)),
            ]),
          ),

          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            GestureDetector(
              onTap: _togglePause,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  color: AppColors.primary.withValues(alpha: 0.05),
                ),
                child: Icon(
                    _gameState == GameState.paused
                        ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    color: AppColors.primary, size: 18),
              ),
            ),
            const SizedBox(height: 4),
            Text('SPD ${_currentSpeed.toInt()}', style: TextStyle(
                fontSize: 9, letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.3),
                fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(10),
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: Colors.white, height: 1.0)),
        Text(label, style: TextStyle(fontSize: 8, letterSpacing: 2,
            color: Colors.white.withValues(alpha: 0.35), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _buildStackArea() {
    return LayoutBuilder(builder: (context, constraints) {
      final areaHeight  = constraints.maxHeight;
      final visibleStart = _visibleStackStart;
      final visibleStack = _stack.sublist(visibleStart);

      return Stack(clipBehavior: Clip.hardEdge, children: [
        ...visibleStack.asMap().entries.map((e) {
          final vi     = e.key;
          final block  = e.value;
          return Positioned(
            left: block.x,
            bottom: _bottomPadding + vi * kBlockHeight,
            child: _buildBlock(width: block.width, color: block.color,
                isTop: vi == visibleStack.length - 1),
          );
        }),

        ..._fallingPieces.map((p) => Positioned(
          left: p.x, top: areaHeight - p.y,
          child: Opacity(opacity: p.opacity.clamp(0.0, 1.0),
            child: Container(width: p.width, height: kBlockHeight,
                decoration: BoxDecoration(
                    color: p.color.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4))),
          ),
        )),

        if (_gameState == GameState.playing)
          Positioned(
            left: _movingX,
            bottom: _bottomPadding + visibleStack.length * kBlockHeight,
            child: _buildMovingBlock(),
          ),

        if (_bonusText != null)
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 20)],
            ),
            child: Text(_bonusText!, style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: Color(0xFF030814), letterSpacing: 1)),
          )),
      ]);
    });
  }

  Widget _buildBlock({required double width, required Color color, bool isTop = false}) {
    return Container(
      width: width, height: kBlockHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.75)]),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          if (isTop) BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 16, spreadRadius: 1),
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 3)),
        ],
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1)),
      ),
    );
  }

  Widget _buildMovingBlock() {
    final color = AppColors.blockColors[_stack.length % AppColors.blockColors.length];
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, __) => Container(
        width: _movingWidth, height: kBlockHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0.98), color.withValues(alpha: 0.78)]),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [BoxShadow(
              color: color.withValues(alpha: 0.8 * _pulseAnimation.value),
              blurRadius: 20 * _pulseAnimation.value, spreadRadius: 2)],
          border: Border(top: BorderSide(
              color: Colors.white.withValues(alpha: 0.45), width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildBottomHint() {
    if (_gameState != GameState.playing) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 6),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, __) => Opacity(
          opacity: 0.4 + 0.4 * _pulseAnimation.value,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 5, height: 5,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            const Text('TAP TO STACK', style: TextStyle(
                fontSize: 11, letterSpacing: 5,
                color: AppColors.primary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Container(width: 5, height: 5,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle)),
          ]),
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: const Color(0xFF030814).withValues(alpha: 0.85),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 72, height: 72,
            decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                color: AppColors.primary.withValues(alpha: 0.05)),
            child: const Center(child: Icon(Icons.pause_rounded,
                color: AppColors.primary, size: 32))),
        const SizedBox(height: 20),
        const Text('PAUSED', style: TextStyle(fontSize: 28,
            fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6)),
        const SizedBox(height: 40),
        _buildOverlayButton(label: 'RESUME',
            icon: Icons.play_arrow_rounded, onTap: _togglePause, primary: true),
        const SizedBox(height: 12),
        _buildOverlayButton(label: 'MAIN MENU',
            icon: Icons.home_rounded, onTap: _goToMenu, primary: false),
      ])),
    );
  }

  Widget _buildGameOverOverlay() {
    final nextLevel     = widget.level + 1;
    final hasNextLevel  = nextLevel <= StorageService.levels.length;
    final nextLevelData = hasNextLevel ? StorageService.levels[nextLevel - 1] : null;
    final showNextLevel = _nextLevelUnlocked && hasNextLevel && nextLevelData != null;

    // ✅ How far the player is from unlocking the next level
    final scoreNeeded   = StorageService.unlockScoreRequired - _highScore;
    final showProgress  = !showNextLevel && hasNextLevel && scoreNeeded > 0;

    return Container(
      color: const Color(0xFF030814).withValues(alpha: 0.90),
      child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

          Container(width: 72, height: 72,
              decoration: BoxDecoration(shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
                  color: AppColors.primary.withValues(alpha: 0.05)),
              child: const Center(child: Text('✦', style: TextStyle(fontSize: 28)))),

          const SizedBox(height: 20),

          const Text('GAME OVER', style: TextStyle(fontSize: 30,
              fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6,
              shadows: [Shadow(color: AppColors.primary, blurRadius: 20)])),

          const SizedBox(height: 6),
          Text('Tower collapsed at block $_score',
              style: TextStyle(fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.4))),

          // New high score badge
          if (_isNewHighScore) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA000)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 16)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.emoji_events_rounded, color: Color(0xFF030814), size: 16),
                SizedBox(width: 6),
                Text('NEW HIGH SCORE!', style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w900, color: Color(0xFF030814),
                    letterSpacing: 2)),
              ]),
            ),
          ],

          // ✅ Next level unlocked badge
          if (showNextLevel) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.secondary.withValues(alpha: 0.08),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_open_rounded, color: AppColors.secondary, size: 15),
                const SizedBox(width: 8),
                Text('LVL $nextLevel  •  ${nextLevelData.name}  UNLOCKED',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.secondary, letterSpacing: 1.5)),
              ]),
            ),
          ],

          // ✅ Progress hint — "Score X more to unlock Level N"
          if (showProgress) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.lock_rounded,
                    color: AppColors.primary.withValues(alpha: 0.5), size: 14),
                const SizedBox(width: 8),
                Text(
                  'Score $scoreNeeded more to unlock LVL $nextLevel',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AppColors.primary.withValues(alpha: 0.6),
                      letterSpacing: 0.5),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 28),

          // Score card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D1F3C), Color(0xFF0A1A30)]),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _buildResultStat('SCORE', '$_score'),
              Container(width: 1, height: 40,
                  color: Colors.white.withValues(alpha: 0.1),
                  margin: const EdgeInsets.symmetric(horizontal: 24)),
              _buildResultStat('BEST', '$_highScore'),
            ]),
          ),

          const SizedBox(height: 32),

          // ✅ Next Level button — primary, only when unlocked
          if (showNextLevel) ...[
            _buildOverlayButton(
                label: 'NEXT  ›  LVL $nextLevel  ${nextLevelData.name}',
                icon: Icons.arrow_forward_rounded,
                onTap: _goToNextLevel, primary: true),
            const SizedBox(height: 12),
          ],

          _buildOverlayButton(
              label: 'PLAY AGAIN',
              icon: Icons.refresh_rounded,
              onTap: _restart,
              primary: !showNextLevel),
          const SizedBox(height: 12),
          _buildOverlayButton(
              label: 'MAIN MENU',
              icon: Icons.home_rounded,
              onTap: _goToMenu, primary: false),

          const SizedBox(height: 20),
        ]),
      )),
    );
  }

  Widget _buildOverlayButton({
    required String label, required IconData icon,
    required VoidCallback onTap, required bool primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          gradient: primary ? AppGradients.primaryButton : null,
          border: primary ? null
              : Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(14),
          boxShadow: primary ? [BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20)] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon,
              color: primary ? const Color(0xFF030814) : AppColors.primary,
              size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
              color: primary ? const Color(0xFF030814) : AppColors.primary,
              letterSpacing: 3)),
        ]),
      ),
    );
  }

  Widget _buildResultStat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900,
          color: Colors.white, height: 1.0)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 9, letterSpacing: 4,
          color: AppColors.primary.withValues(alpha: 0.8),
          fontWeight: FontWeight.w600)),
    ]);
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, size, opacity;
  const _Star({required this.x, required this.y,
    required this.size, required this.opacity});
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.025)
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