import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacknovax/app_theme.dart';
import 'package:stacknovax/storage_service.dart';

class LevelSelectScreen extends StatefulWidget {
  final void Function(int) onLevelSelected;

  const LevelSelectScreen({super.key, required this.onLevelSelected});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  Map<int, int> _highScores = {};
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadScores();
  }

  Future<void> _loadScores() async {
    final scores = await _storage.getHighScores();
    if (mounted) setState(() => _highScores = scores);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: StorageService.levels.length,
                  itemBuilder: (context, index) {
                    final delay = index * 0.12;
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (_, child) {
                        final progress = ((_controller.value - delay) / (1 - delay))
                            .clamp(0.0, 1.0);
                        return Opacity(
                          opacity: progress,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - progress)),
                            child: child,
                          ),
                        );
                      },
                      child: _buildLevelCard(StorageService.levels[index]),
                    );
                  },
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.primary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'SELECT LEVEL',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(GameLevel level) {
    final highScore = _highScores[level.level] ?? 0;
    final isUnlocked = level.level == 1 || (_highScores[level.level - 1] ?? 0) > 0;

    return GestureDetector(
      onTap: () {
        if (!isUnlocked) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Complete level ${level.level - 1} to unlock!'),
              backgroundColor: AppColors.bgLight,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        widget.onLevelSelected(level.level);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [AppColors.surface, AppColors.surfaceLight]
                : [
              AppColors.bgDark.withValues(alpha: 0.8),
              AppColors.bgDark.withValues(alpha: 0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
          ),
          boxShadow: isUnlocked
              ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            // Level badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isUnlocked
                    ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                )
                    : null,
                color: isUnlocked ? null : Colors.white.withValues(alpha: 0.05),
                boxShadow: isUnlocked
                    ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ]
                    : null,
              ),
              child: Center(
                child: isUnlocked
                    ? Text(
                  '${level.level}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF030814),
                  ),
                )
                    : Icon(
                  Icons.lock_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 22,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isUnlocked ? Colors.white : Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnlocked
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  if (isUnlocked && highScore > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.emoji_events_rounded,
                            size: 13, color: AppColors.gold.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          'Best: $highScore',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gold.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Speed indicator
            if (isUnlocked)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SPEED',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: AppColors.primary.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildSpeedDots(level.level),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDots(int level) {
    return Row(
      children: List.generate(5, (i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < level
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.15),
            boxShadow: i < level
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 4)]
                : null,
          ),
        );
      }),
    );
  }
}