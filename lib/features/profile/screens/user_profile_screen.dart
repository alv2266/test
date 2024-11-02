import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/user_service.dart';
import '../../profile/models/user_model.dart';
import 'user_settings_screen.dart';
import '../../profile/widgets/profile_block.dart'; // Imported ProfileBlock

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String userName = 'Loading...';
  String userEmail = 'No email available';
  String? userAvatar;
  int completedChallenges = 0;
  int totalChallenges = 10;
  int totalMeditations = 0;
  int streakDays = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        UserModel? user = await UserService().getUserData(currentUser.uid);
        if (user != null) {
          setState(() {
            userName = user.name;
            userEmail = user.email;
            userAvatar = user.profilePicture;
            completedChallenges = user.completedChallenges.length;
            streakDays = user.streakCount;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Custom App Bar with Profile Header
                SliverAppBar(
                  expandedHeight: 200.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.deepPurple,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Colors.deepPurple,
                            Colors.deepPurple.shade300,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: userAvatar != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: userAvatar!,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person, size: 50),
                                    ),
                                  )
                                : const Icon(Icons.person, size: 50),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Stats Cards
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          'Streak',
                          '$streakDays days',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Challenges',
                          '$completedChallenges',
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                      ],
                    ),
                  ),
                ),

                // Main Content
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Progress Section
                      ProfileBlock(
                        title: 'My Progress',
                        icon: Icons.trending_up,
                        iconColor: Colors.green,
                        onTap: () {
                          // Handle progress tap action
                        },
                        content:
                            'Keep going! You\'re making great progress on your mindfulness journey.',
                      ),
                      const SizedBox(height: 16),

                      // Activity History
                      ProfileBlock(
                        title: 'Activity History',
                        icon: Icons.history,
                        iconColor: Colors.blue,
                        onTap: () {
                          // Handle activity history tap action
                        },
                        content: 'Track your meditation journey and milestones.',
                      ),
                      const SizedBox(height: 16),

                      // Settings
                      ProfileBlock(
                        title: 'Settings',
                        icon: Icons.settings,
                        iconColor: Colors.grey,
                        onTap: () {
                          print("Settings tapped");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SettingsScreen(),
                            ),
                          );
                        },
                        content: 'Customize your app settings and preferences.',
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
