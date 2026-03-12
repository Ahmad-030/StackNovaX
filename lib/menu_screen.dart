import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacknovax/app_theme.dart';
import 'package:stacknovax/storage_service.dart';
import 'game_screen.dart';
import 'level_select_screen.dart';
import 'highscore_screen.dart';
import 'about_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late AnimationController _floatController;
  late AnimationController _glowController;
  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;
  bool _hasSavedGame = false;
  final Random _rng = Random();
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();

    _stars = List.generate(
      80,
          (_) => _Star(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        size: _rng.nextDouble() * 2 + 0.5,
        opacity: _rng.nextDouble() * 0.6 + 0.2,
      ),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _glowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(_glowController);

    _checkSavedGame();
  }

  Future<void> _checkSavedGame() async {
    final has = await _storage.hasSavedGame();
    if (mounted) setState(() => _hasSavedGame = has);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _startNewGame([int level = 1]) {
    _storage.clearSavedGame();
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => GameScreen(level: level, isContinue: false),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => _checkSavedGame());
  }

  void _continueGame() async {
    final data = await _storage.loadGame();
    if (data != null && mounted) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              GameScreen(level: data['level'] ?? 1, isContinue: true),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ).then((_) => _checkSavedGame());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
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
                  color: Colors.white.withValues(alpha: s.opacity),
                  shape: BoxShape.circle,
                ),
              ),
            )),

            // Glow orbs
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Positioned(
                top: -80,
                left: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary
                            .withValues(alpha: 0.06 * _glowAnim.value),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildVersionTag(),
                  const Spacer(),
                  _buildMenuButtons(),
                  const SizedBox(height: 20),
                  _buildBottomLinks(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnim.value),
        child: child,
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D2040), Color(0xFF081830)],
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary
                        .withValues(alpha: 0.25 * _glowAnim.value),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...[0, 1, 2].map((i) {
                      final w = 36.0 - i * 8;
                      final colors = AppColors.blockColors;
                      return Container(
                        width: w,
                        height: 7,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: BoxDecoration(
                          color: colors[i].withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                                color: colors[i].withValues(alpha: 0.5),
                                blurRadius: 4),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                    Text(
                      '▲',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF1DE9B6), Colors.white],
            ).createShader(bounds),
            child: const Text(
              'STACKNOVAX',
              style: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        'BLOCK STACKING ARCADE  •  v1.0',
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 3,
          color: AppColors.primary.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMenuButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          if (_hasSavedGame) ...[
            _buildPrimaryButton(
              label: 'CONTINUE GAME',
              icon: Icons.play_arrow_rounded,
              onTap: _continueGame,
              gradient: const LinearGradient(
                colors: [Color(0xFF1DE9B6), Color(0xFF00E5FF)],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildPrimaryButton(
            label: 'NEW GAME',
            icon:
            _hasSavedGame ? Icons.refresh_rounded : Icons.play_arrow_rounded,
            onTap: () => _startNewGame(1),
            gradient: _hasSavedGame
                ? const LinearGradient(
              colors: [Color(0xFF0D2040), Color(0xFF081830)],
            )
                : AppGradients.primaryButton,
            outlined: _hasSavedGame,
          ),
          const SizedBox(height: 12),
          _buildSecondaryButton(
            label: 'SELECT LEVEL',
            icon: Icons.layers_rounded,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(
              builder: (_) =>
                  LevelSelectScreen(onLevelSelected: _startNewGame),
            ))
                .then((_) => _checkSavedGame()),
          ),
          const SizedBox(height: 12),
          _buildSecondaryButton(
            label: 'HIGH SCORES',
            icon: Icons.emoji_events_rounded,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HighScoreScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Gradient gradient,
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: outlined ? null : gradient,
          borderRadius: BorderRadius.circular(14),
          border: outlined
              ? Border.all(
              color: AppColors.primary.withValues(alpha: 0.4), width: 1.5)
              : null,
          boxShadow: outlined
              ? null
              : [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: outlined ? AppColors.primary : const Color(0xFF030814),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: outlined ? AppColors.primary : const Color(0xFF030814),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1F3C), Color(0xFF0A1A30)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: AppColors.primary.withValues(alpha: 0.8), size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FIXED: proper styled buttons instead of plain text links ──────────────
  Widget _buildBottomLinks() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoButton(
              label: 'ABOUT',
              icon: Icons.info_outline_rounded,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoButton(
              label: 'PRIVACY',
              icon: Icons.shield_outlined,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const AboutScreen(showPrivacy: true)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
          color: AppColors.primary.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: AppColors.primary.withValues(alpha: 0.6), size: 15),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Star {
  final double x, y, size, opacity;
  const _Star(
      {required this.x,
        required this.y,
        required this.size,
        required this.opacity});
}