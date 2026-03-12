import 'package:flutter/material.dart';
import 'package:stacknovax/app_theme.dart';
import 'package:stacknovax/storage_service.dart';


class HighScoreScreen extends StatefulWidget {
  const HighScoreScreen({super.key});

  @override
  State<HighScoreScreen> createState() => _HighScoreScreenState();
}

class _HighScoreScreenState extends State<HighScoreScreen>
    with SingleTickerProviderStateMixin {
  final StorageService _storage = StorageService();
  Map<int, int> _highScores = {};
  int _totalGames = 0;
  int _totalBlocks = 0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _loadData();
  }

  Future<void> _loadData() async {
    final scores = await _storage.getHighScores();
    final games = await _storage.getTotalGames();
    final blocks = await _storage.getTotalBlocks();
    if (mounted) {
      setState(() {
        _highScores = scores;
        _totalGames = games;
        _totalBlocks = blocks;
      });
    }
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      _buildSectionTitle('LEVEL HIGH SCORES'),
                      const SizedBox(height: 12),
                      ...StorageService.levels.asMap().entries.map((e) {
                        final delay = e.key * 0.1;
                        return AnimatedBuilder(
                          animation: _controller,
                          builder: (_, child) {
                            final progress =
                            ((_controller.value - delay) / (1 - delay))
                                .clamp(0.0, 1.0);
                            return Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(40 * (1 - progress), 0),
                                child: child,
                              ),
                            );
                          },
                          child: _buildScoreRow(e.value),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                color: AppColors.primary.withOpacity(0.05),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: AppColors.primary, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'HIGH SCORES',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          Icon(Icons.emoji_events_rounded,
              color: AppColors.gold.withOpacity(0.7), size: 24),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('GAMES\nPLAYED', '$_totalGames', Icons.sports_esports_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard('BLOCKS\nSTACKED', '$_totalBlocks', Icons.layers_rounded)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary.withOpacity(0.6), size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1,
                  color: Colors.white.withOpacity(0.35),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 3,
            color: Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(GameLevel level) {
    final score = _highScores[level.level] ?? 0;
    final hasScore = score > 0;
    Color medalColor;
    IconData medalIcon;
    switch (level.level) {
      case 1:
        medalColor = AppColors.bronze;
        medalIcon = Icons.military_tech_rounded;
        break;
      case 2:
        medalColor = AppColors.silver;
        medalIcon = Icons.military_tech_rounded;
        break;
      case 3:
        medalColor = AppColors.gold;
        medalIcon = Icons.emoji_events_rounded;
        break;
      default:
        medalColor = AppColors.primary;
        medalIcon = Icons.stars_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppGradients.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasScore
              ? AppColors.primary.withOpacity(0.2)
              : Colors.white.withOpacity(0.04),
        ),
      ),
      child: Row(
        children: [
          // Medal
          Icon(
            medalIcon,
            color: hasScore ? medalColor : Colors.white.withOpacity(0.1),
            size: 26,
          ),
          const SizedBox(width: 14),

          // Level info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LVL ${level.level}  •  ${level.name}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: hasScore ? Colors.white : Colors.white.withOpacity(0.3),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  level.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                hasScore ? '$score' : '---',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: hasScore ? Colors.white : Colors.white.withOpacity(0.15),
                  height: 1.0,
                  shadows: hasScore
                      ? [const Shadow(color: AppColors.primary, blurRadius: 12)]
                      : null,
                ),
              ),
              if (hasScore)
                Text(
                  'BLOCKS',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 2,
                    color: AppColors.primary.withOpacity(0.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}