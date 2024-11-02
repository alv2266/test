
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../profile/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await getUserData(user.uid);
      }
    } catch (e) {
      print('Error getting current user: $e');
      rethrow;
    }
    return null;
  }

  // Get user data
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot userSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (userSnapshot.exists) {
        return UserModel.fromMap(userSnapshot.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
    return null;
  }

  // Save user data
  Future<void> saveUserData(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  // Update meditation session
  Future<void> updateMeditationSession(String uid, int minutes) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final userData = UserModel.fromMap(userDoc.data()!);
        final updatedUser = userData.addMeditationSession(minutes);

        // Check streak
        final now = DateTime.now();
        final lastMeditation = userData.lastMeditation;
        final dayDifference = now.difference(lastMeditation).inDays;
        
        final updatedWithStreak = updatedUser.updateStreak(dayDifference <= 1);

        // Create activity log
        final activity = ActivityLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'meditation',
          title: 'Meditation Session',
          description: 'Completed a $minutes minute meditation',
          timestamp: now,
          duration: minutes,
        );

        final updatedActivities = [
          activity.toMap(),
          ...userData.recentActivity.take(9).map((a) => a.toMap()),
        ];

        // Update the document
        transaction.update(userRef, {
          ...updatedWithStreak.toMap(),
          'recentActivity': updatedActivities,
        });
      });
    } catch (e) {
      print('Error updating meditation session: $e');
      rethrow;
    }
  }

  // Update user settings
  Future<void> updateSettings(String uid, UserSettings settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .update({'settings': settings.toMap()});
    } catch (e) {
      print('Error updating settings: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    required String uid,
    String? name,
    String? profilePicture,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (profilePicture != null) 'profilePicture': profilePicture,
        'lastLogin': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
  }

  // Complete challenge
  Future<void> completeChallenge(String uid, String challengeId) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final userData = UserModel.fromMap(userDoc.data()!);
        final updatedUser = userData.completeChallenge(challengeId);

        final activity = ActivityLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'challenge',
          title: 'Challenge Completed',
          description: 'Completed a mindfulness challenge',
          timestamp: DateTime.now(),
        );

        final updatedActivities = [
          activity.toMap(),
          ...userData.recentActivity.take(9).map((a) => a.toMap()),
        ];

        transaction.update(userRef, {
          ...updatedUser.toMap(),
          'recentActivity': updatedActivities,
        });
      });
    } catch (e) {
      print('Error completing challenge: $e');
      rethrow;
    }
  }

  // Toggle favorite meditation
  Future<void> toggleFavoriteMeditation(String uid, String meditationId) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('User not found');
        }

        final userData = UserModel.fromMap(userDoc.data()!);
        final updatedUser = userData.updateFavoriteMeditations(meditationId);

        final actionType = updatedUser.favoriteMeditations.contains(meditationId)
            ? 'Added to favorites'
            : 'Removed from favorites';

        final activity = ActivityLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'favorite',
          title: actionType,
          description: '$actionType: Meditation session',
          timestamp: DateTime.now(),
        );

        final updatedActivities = [
          activity.toMap(),
          ...userData.recentActivity.take(9).map((a) => a.toMap()),
        ];

        transaction.update(userRef, {
          ...updatedUser.toMap(),
          'recentActivity': updatedActivities,
        });
      });
    } catch (e) {
      print('Error toggling favorite meditation: $e');
      rethrow;
    }
  }

  // Get user stats
  Future<Map<String, dynamic>> getUserStats(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = UserModel.fromMap(userDoc.data()!);
      
      return {
        'totalMinutes': userData.totalMeditationMinutes,
        'totalSessions': userData.totalSessions,
        'currentStreak': userData.streakCount,
        'completedChallenges': userData.completedChallenges.length,
        'achievements': userData.achievements.length,
        'weeklyProgress': userData.getWeeklyStats(),
        'completionRate': userData.completionRate,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      rethrow;
    }
  }

  // Update post count
  Future<void> updatePostCount(String uid, bool increment) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'postCount': FieldValue.increment(increment ? 1 : -1),
      });
    } catch (e) {
      print('Error updating post count: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteUserAccount(String uid) async {
    try {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(uid).delete();
      
      // Delete user authentication
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }
}