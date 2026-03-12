import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameLevel {
  final int level;
  final double speed;
  final double tolerance;
  final String name;
  final String description;

  const GameLevel({
    required this.level,
    required this.speed,
    required this.tolerance,
    required this.name,
    required this.description,
  });
}

class StorageService {
  static const String _highScoresKey   = 'high_scores_v2';
  static const String _savedGameKey    = 'saved_game_v2';
  static const String _totalGamesKey   = 'total_games';
  static const String _totalBlocksKey  = 'total_blocks';
  // Persists the last level played — survives game overs
  static const String _lastLevelKey    = 'last_level';

  // ✅ Score threshold required to unlock the next level
  static const int unlockScoreRequired = 30;

  static const List<GameLevel> levels = [
    GameLevel(level: 1, speed: 160, tolerance: 7, name: 'CADET',   description: 'Learn the basics'),
    GameLevel(level: 2, speed: 200, tolerance: 6, name: 'PILOT',   description: 'Getting faster'),
    GameLevel(level: 3, speed: 240, tolerance: 5, name: 'ACE',     description: 'Sharpen your aim'),
    GameLevel(level: 4, speed: 280, tolerance: 4, name: 'VETERAN', description: 'Elite precision'),
    GameLevel(level: 5, speed: 320, tolerance: 3, name: 'LEGEND',  description: 'Maximum speed'),
  ];

  // ── High scores ────────────────────────────────────────────────────────────

  Future<Map<int, int>> getHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_highScoresKey);
    if (data == null) return {};
    final Map<String, dynamic> json = jsonDecode(data);
    return json.map((k, v) => MapEntry(int.parse(k), v as int));
  }

  Future<void> saveHighScore(int level, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = await getHighScores();
    final current = scores[level] ?? 0;
    if (score > current) {
      scores[level] = score;
      final Map<String, dynamic> json =
      scores.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_highScoresKey, jsonEncode(json));
    }
  }

  Future<int> getHighScore(int level) async {
    final scores = await getHighScores();
    return scores[level] ?? 0;
  }

  // ── Mid-game save ──────────────────────────────────────────────────────────

  Future<void> saveGame(Map<String, dynamic> gameState) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedGameKey, jsonEncode(gameState));
  }

  Future<Map<String, dynamic>?> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_savedGameKey);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedGameKey);
  }

  Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_savedGameKey);
  }

  // ── Last played level ──────────────────────────────────────────────────────
  // Saved on every game start. Survives game overs so Continue always
  // returns the player to whichever level they were on.

  Future<void> saveLastLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastLevelKey, level);
  }

  Future<int> getLastLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastLevelKey) ?? 1;
  }

  Future<bool> hasLastLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_lastLevelKey);
  }

  // ── Stats ──────────────────────────────────────────────────────────────────

  Future<void> incrementTotalGames() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalGamesKey) ?? 0;
    await prefs.setInt(_totalGamesKey, current + 1);
  }

  Future<int> getTotalGames() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalGamesKey) ?? 0;
  }

  Future<void> addBlocks(int count) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_totalBlocksKey) ?? 0;
    await prefs.setInt(_totalBlocksKey, current + count);
  }

  Future<int> getTotalBlocks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalBlocksKey) ?? 0;
  }
}