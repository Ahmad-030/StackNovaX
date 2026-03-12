
import 'package:flutter/material.dart';
import 'package:stacknovax/app_theme.dart';
import 'package:stacknovax/storage_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// About Screen
// ─────────────────────────────────────────────────────────────────────────────

class AboutScreen extends StatefulWidget {
  final bool showPrivacy;
  const AboutScreen({super.key, this.showPrivacy = false});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        decoration: TextDecoration.none,
        fontFamily: 'DM Sans',
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildAppCard(),
            const SizedBox(height: 20),
            _buildSection('HOW TO PLAY', _howToPlayItems()),
            const SizedBox(height: 16),
            _buildSection('LEVELS', _levelsInfo()),
            const SizedBox(height: 16),
            _buildSection('SCORING', _scoringInfo()),
            const SizedBox(height: 16),
            _buildSection('DEVELOPER', _developerInfo()),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAppCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2040), Color(0xFF081830)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '▲',
                style: TextStyle(
                  fontSize: 28,
                  color: Color(0xFF030814),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'StackNovaX',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Block Stacking Arcade',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary.withOpacity(0.7),
              letterSpacing: 2,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 16),
          Text(
            'A precision arcade game where you stack blocks as high as possible. '
                'Time your taps perfectly for PERFECT bonuses and reach legendary scores.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              height: 1.6,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 14),
          Text(
            'LIAME LLC HUB',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary.withOpacity(0.6),
              letterSpacing: 3,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'geraldedwardhines1@gmail.com',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.35),
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: AppColors.primary.withOpacity(0.8),
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  List<Widget> _howToPlayItems() {
    final steps = [
      ('TAP TO STACK', 'Tap the screen to drop the moving block onto the stack.'),
      ('ALIGN PRECISELY', 'The overhanging part gets cut off — narrowing your block.'),
      ('PERFECT BONUS', 'Land within ±5px of perfect alignment for +2 bonus points.'),
      ("DON'T FALL", 'If the remaining width is too thin, your tower collapses.'),
    ];
    return steps.asMap().entries.map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary]),
              ),
              child: Center(
                child: Text(
                  '${e.key + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF030814),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.value.$1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.value.$2,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.45),
                      height: 1.4,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _levelsInfo() {
    return StorageService.levels.map((level) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${level.level}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF030814),
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    level.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${level.speed.toInt()} px/s',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary.withOpacity(0.6),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _scoringInfo() {
    final items = [
      ('Stack a block', '+1 point'),
      ('PERFECT placement', '+3 pts (+2 bonus)'),
      ('Speed increases', 'Every 5 blocks'),
    ];
    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.$1,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.6),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                item.$2,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _developerInfo() {
    return [
      _devRow('Developer', 'LIAME LLC HUB'),
      _devRow('Contact', 'geraldedwardhines1@gmail.com'),

    ];
  }

  Widget _devRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.35),
                decoration: TextDecoration.none,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}