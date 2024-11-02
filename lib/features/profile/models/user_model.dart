import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<String> completedChallenges;
  final int totalMeditationMinutes;
  final List<String> favoriteMeditations;
  final DateTime lastMeditation;
  final Map<String, int> weeklyProgress;
  final int postCount;
  final List<Achievement> achievements;
  final int streakCount;
  final int totalSessions;
  final Map<String, dynamic> stats;
  final List<ActivityLog> recentActivity;
  final UserSettings settings;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.profilePicture,
    required this.createdAt,
    required this.lastLogin,
    List<String>? completedChallenges,
    this.totalMeditationMinutes = 0,
    List<String>? favoriteMeditations,
    DateTime? lastMeditation,
    Map<String, int>? weeklyProgress,
    this.postCount = 0,
    List<Achievement>? achievements,
    this.streakCount = 0,
    this.totalSessions = 0,
    Map<String, dynamic>? stats,
    List<ActivityLog>? recentActivity,
    UserSettings? settings,
  }) : 
    this.completedChallenges = completedChallenges ?? [],
    this.favoriteMeditations = favoriteMeditations ?? [],
    this.lastMeditation = lastMeditation ?? DateTime.now(),
    this.weeklyProgress = weeklyProgress ?? {},
    this.achievements = achievements ?? [],
    this.stats = stats ?? {
      'totalMinutes': 0,
      'avgSessionLength': 0,
      'longestStreak': 0,
      'currentStreak': 0,
      'completionRate': 0.0,
      'favoriteTimeOfDay': 'morning',
    },
    this.recentActivity = recentActivity ?? [],
    this.settings = settings ?? UserSettings();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'profilePicture': profilePicture,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'completedChallenges': completedChallenges,
      'totalMeditationMinutes': totalMeditationMinutes,
      'favoriteMeditations': favoriteMeditations,
      'lastMeditation': Timestamp.fromDate(lastMeditation),
      'weeklyProgress': weeklyProgress,
      'postCount': postCount,
      'achievements': achievements.map((a) => a.toMap()).toList(),
      'streakCount': streakCount,
      'totalSessions': totalSessions,
      'stats': stats,
      'recentActivity': recentActivity.map((a) => a.toMap()).toList(),
      'settings': settings.toMap(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      name: map['name'] as String,
      profilePicture: map['profilePicture'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: (map['lastLogin'] as Timestamp).toDate(),
      completedChallenges: List<String>.from(map['completedChallenges'] ?? []),
      totalMeditationMinutes: map['totalMeditationMinutes'] ?? 0,
      favoriteMeditations: List<String>.from(map['favoriteMeditations'] ?? []),
      lastMeditation: map['lastMeditation'] != null 
        ? (map['lastMeditation'] as Timestamp).toDate() 
        : null,
      weeklyProgress: Map<String, int>.from(map['weeklyProgress'] ?? {}),
      postCount: map['postCount'] ?? 0,
      achievements: (map['achievements'] as List<dynamic>?)
          ?.map((a) => Achievement.fromMap(a as Map<String, dynamic>))
          .toList() ?? [],
      streakCount: map['streakCount'] ?? 0,
      totalSessions: map['totalSessions'] ?? 0,
      stats: Map<String, dynamic>.from(map['stats'] ?? {}),
      recentActivity: (map['recentActivity'] as List<dynamic>?)
          ?.map((a) => ActivityLog.fromMap(a as Map<String, dynamic>))
          .toList() ?? [],
      settings: map['settings'] != null 
          ? UserSettings.fromMap(map['settings'] as Map<String, dynamic>)
          : UserSettings(),
    );
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<String>? completedChallenges,
    int? totalMeditationMinutes,
    List<String>? favoriteMeditations,
    DateTime? lastMeditation,
    Map<String, int>? weeklyProgress,
    int? postCount,
    List<Achievement>? achievements,
    int? streakCount,
    int? totalSessions,
    Map<String, dynamic>? stats,
    List<ActivityLog>? recentActivity,
    UserSettings? settings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      totalMeditationMinutes: totalMeditationMinutes ?? this.totalMeditationMinutes,
      favoriteMeditations: favoriteMeditations ?? this.favoriteMeditations,
      lastMeditation: lastMeditation ?? this.lastMeditation,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      postCount: postCount ?? this.postCount,
      achievements: achievements ?? this.achievements,
      streakCount: streakCount ?? this.streakCount,
      totalSessions: totalSessions ?? this.totalSessions,
      stats: stats ?? this.stats,
      recentActivity: recentActivity ?? this.recentActivity,
      settings: settings ?? this.settings,
    );
  }

  // Utility methods
  UserModel addMeditationSession(int minutes) {
    final now = DateTime.now();
    final weekKey = '${now.year}-${now.weekOfYear}';
    final newWeeklyProgress = Map<String, int>.from(weeklyProgress);
    newWeeklyProgress[weekKey] = (newWeeklyProgress[weekKey] ?? 0) + minutes;
    
    return copyWith(
      totalMeditationMinutes: totalMeditationMinutes + minutes,
      totalSessions: totalSessions + 1,
      lastMeditation: now,
      weeklyProgress: newWeeklyProgress,
    );
  }

  UserModel updateFavoriteMeditations(String meditationId) {
    final newFavorites = List<String>.from(favoriteMeditations);
    if (newFavorites.contains(meditationId)) {
      newFavorites.remove(meditationId);
    } else {
      newFavorites.add(meditationId);
    }
    return copyWith(favoriteMeditations: newFavorites);
  }

  UserModel completeChallenge(String challengeId) {
    if (!completedChallenges.contains(challengeId)) {
      return copyWith(
        completedChallenges: [...completedChallenges, challengeId],
      );
    }
    return this;
  }

  UserModel updateStreak(bool maintained) {
    if (maintained) {
      return copyWith(streakCount: streakCount + 1);
    }
    return copyWith(streakCount: 0);
  }

  bool get hasStreak {
    if (lastMeditation == null) return false;
    final now = DateTime.now();
    return now.difference(lastMeditation).inDays < 1;
  }

  double get completionRate {
    if (totalSessions == 0) return 0;
    return completedChallenges.length / totalSessions * 100;
  }

  List<ActivityLog> getRecentActivities([int limit = 5]) {
    return recentActivity
        .sorted((a, b) => b.timestamp.compareTo(a.timestamp))
        .take(limit)
        .toList();
  }

  // Add these methods just before the `hasStreak` getter in the UserModel class

  // Get comprehensive weekly statistics
  Map<String, dynamic> getWeeklyStats() {
    final now = DateTime.now();
    // Get the current week's key
    final currentWeekKey = '${now.year}-${now.weekOfYear}';
    
    // Get the previous week's key
    final previousWeek = now.subtract(const Duration(days: 7));
    final previousWeekKey = '${previousWeek.year}-${previousWeek.weekOfYear}';
    
    return {
      'currentWeek': weeklyProgress[currentWeekKey] ?? 0,
      'previousWeek': weeklyProgress[previousWeekKey] ?? 0,
      'total': weeklyProgress.values.fold(0, (sum, minutes) => sum + minutes),
      'averagePerWeek': weeklyProgress.isEmpty 
          ? 0 
          : (weeklyProgress.values.fold(0, (sum, minutes) => sum + minutes) / 
             weeklyProgress.length).round(),
      'weeksTracked': weeklyProgress.length,
      'weeklyData': getRawWeeklyStats(),
      'trend': _calculateWeeklyTrend(),
    };
  }

  // Get raw weekly progress data
  Map<String, int> getRawWeeklyStats() {
    final sortedKeys = weeklyProgress.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, weeklyProgress[key]!))
    );
  }

  // Get stats for specific week
  int getWeekStats(DateTime date) {
    final weekKey = '${date.year}-${date.weekOfYear}';
    return weeklyProgress[weekKey] ?? 0;
  }

  // Get stats for current week
  int getCurrentWeekStats() {
    final now = DateTime.now();
    return getWeekStats(now);
  }

  // Get stats for last n weeks
  Map<String, int> getLastWeeksStats(int numberOfWeeks) {
    final now = DateTime.now();
    final result = <String, int>{};
    
    for (var i = 0; i < numberOfWeeks; i++) {
      final date = now.subtract(Duration(days: i * 7));
      final weekKey = '${date.year}-${date.weekOfYear}';
      result[weekKey] = weeklyProgress[weekKey] ?? 0;
    }
    
    return Map.fromEntries(
      result.entries.toList()
        ..sort((a, b) => b.key.compareTo(a.key))
    );
  }

  // Calculate weekly trend (positive or negative)
  double _calculateWeeklyTrend() {
    if (weeklyProgress.length < 2) return 0;

    final sortedWeeks = weeklyProgress.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    if (sortedWeeks.length >= 2) {
      final currentWeek = sortedWeeks[0].value;
      final previousWeek = sortedWeeks[1].value;

      if (previousWeek == 0) return 100;
      return ((currentWeek - previousWeek) / previousWeek) * 100;
    }

    return 0;
  }

  // Get daily average for current week
  double getCurrentWeekDailyAverage() {
    final currentWeekMinutes = getCurrentWeekStats();
    final now = DateTime.now();
    final daysIntoWeek = now.weekday;
    
    if (daysIntoWeek == 0) return 0;
    return currentWeekMinutes / daysIntoWeek;
  }

  // Get weekly average for last n weeks
  double getWeeklyAverage(int numberOfWeeks) {
    final lastWeeks = getLastWeeksStats(numberOfWeeks);
    if (lastWeeks.isEmpty) return 0;

    final total = lastWeeks.values.fold(0, (sum, minutes) => sum + minutes);
    return total / lastWeeks.length;
  }

  // Update weekly progress
  UserModel updateWeeklyProgress(DateTime date, int minutes) {
    final weekKey = '${date.year}-${date.weekOfYear}';
    final newWeeklyProgress = Map<String, int>.from(weeklyProgress);
    newWeeklyProgress[weekKey] = (newWeeklyProgress[weekKey] ?? 0) + minutes;

    return copyWith(
      weeklyProgress: newWeeklyProgress,
      stats: {
        ...stats,
        'lastUpdated': date.toIso8601String(),
        'weeklyAverage': getWeeklyAverage(4),
      },
    );
  }

  // Check if user has meditated today
  bool hasMeditatedToday() {
    if (lastMeditation == null) return false;
    final now = DateTime.now();
    return lastMeditation.year == now.year &&
           lastMeditation.month == now.month &&
           lastMeditation.day == now.day;
  }

  // Get meditation streak status
  Map<String, dynamic> getStreakStatus() {
    return {
      'current': streakCount,
      'longest': stats['longestStreak'] ?? streakCount,
      'active': hasStreak,
      'lastMeditation': lastMeditation.toIso8601String(),
      'daysUntilNextMilestone': _getNextStreakMilestone(),
    };
  }

  // Calculate days until next streak milestone
  int _getNextStreakMilestone() {
    final milestones = [7, 14, 21, 30, 60, 90, 180, 365];
    for (final milestone in milestones) {
      if (streakCount < milestone) {
        return milestone - streakCount;
      }
    }
    return 365 - (streakCount % 365); // Next year milestone
  }

  // Get progress overview
  Map<String, dynamic> getProgressOverview() {
    return {
      'totalMinutes': totalMeditationMinutes,
      'totalSessions': totalSessions,
      'averageSessionLength': totalSessions > 0 
          ? (totalMeditationMinutes / totalSessions).round() 
          : 0,
      'currentStreak': streakCount,
      'weeklyStats': getWeeklyStats(),
      'completedChallenges': completedChallenges.length,
      'achievementCount': achievements.length,
      'lastActivity': recentActivity.isNotEmpty 
          ? recentActivity.first.timestamp.toIso8601String() 
          : null,
    };
  }
}



class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'icon': icon,
    'unlockedAt': Timestamp.fromDate(unlockedAt),
  };

  factory Achievement.fromMap(Map<String, dynamic> map) => Achievement(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String,
    icon: map['icon'] as String,
    unlockedAt: (map['unlockedAt'] as Timestamp).toDate(),
  );
}

class ActivityLog {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final int? duration;

  ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.duration,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'description': description,
    'timestamp': Timestamp.fromDate(timestamp),
    'duration': duration,
  };

  factory ActivityLog.fromMap(Map<String, dynamic> map) => ActivityLog(
    id: map['id'] as String,
    type: map['type'] as String,
    title: map['title'] as String,
    description: map['description'] as String,
    timestamp: (map['timestamp'] as Timestamp).toDate(),
    duration: map['duration'] as int?,
  );
}

class UserSettings {
  final bool notificationsEnabled;
  final bool darkModeEnabled;
  final String preferredMeditationTime;
  final bool soundEnabled;
  final Map<String, bool> reminderDays;

  UserSettings({
    this.notificationsEnabled = true,
    this.darkModeEnabled = false,
    this.preferredMeditationTime = '08:00',
    this.soundEnabled = true,
    Map<String, bool>? reminderDays,
  }) : this.reminderDays = reminderDays ?? {
    'monday': true,
    'tuesday': true,
    'wednesday': true,
    'thursday': true,
    'friday': true,
    'saturday': true,
    'sunday': true,
  };

  Map<String, dynamic> toMap() => {
    'notificationsEnabled': notificationsEnabled,
    'darkModeEnabled': darkModeEnabled,
    'preferredMeditationTime': preferredMeditationTime,
    'soundEnabled': soundEnabled,
    'reminderDays': reminderDays,
  };

  factory UserSettings.fromMap(Map<String, dynamic> map) => UserSettings(
    notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    darkModeEnabled: map['darkModeEnabled'] as bool? ?? false,
    preferredMeditationTime: map['preferredMeditationTime'] as String? ?? '08:00',
    soundEnabled: map['soundEnabled'] as bool? ?? true,
    reminderDays: Map<String, bool>.from(map['reminderDays'] ?? {}),
  );
}

extension DateTimeExtension on DateTime {
  int get weekOfYear {
    int dayOfYear = int.parse(DateFormat("D").format(this));
    int woy = ((dayOfYear - weekday + 10) / 7).floor();
    
    if (woy < 1) {
      woy = numOfWeeks(year - 1);
    } else if (woy > numOfWeeks(year)) {
      woy = 1;
    }
    return woy;
  }

  int numOfWeeks(int year) {
    DateTime dec28 = DateTime(year, 12, 28);
    int dayOfDec28 = int.parse(DateFormat("D").format(dec28));
    return ((dayOfDec28 - dec28.weekday + 10) / 7).floor();
  }
}

extension ListExtension<T> on List<T> {
  List<T> sorted(int Function(T a, T b) compare) {
    final List<T> copy = List.from(this);
    copy.sort(compare);
    return copy;
  }
}