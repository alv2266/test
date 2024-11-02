import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/custom_error_widget.dart';
import '../../../core/widgets/custom_loading_widget.dart';
import 'package:mind_sense/player/screens/audio_player_screen.dart';
import 'package:mind_sense/features/dashboard/user_dashboard_screen.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
@override
  void initState() {
    super.initState();
    _checkFirestoreData();
  }

  Future<void> _checkFirestoreData() async {
    try {
      debugPrint('Checking Firestore data...');
      final snapshot = await _firestore.collection('sleep_stories').get();
      debugPrint('Total documents in collection: ${snapshot.docs.length}');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('No documents found in collection');
      } else {
        for (var doc in snapshot.docs) {
          debugPrint('Document ID: ${doc.id}');
          debugPrint('Document data: ${doc.data()}');
          debugPrint('Is Popular: ${doc.data()['isPopular']}');
          debugPrint('Order: ${doc.data()['order']}');
        }
      }
    } catch (e) {
      debugPrint('Error checking Firestore data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            _buildFeaturedMeditation(),
            const SizedBox(height: 24),
            _buildAllMeditationsTitle(),
            _buildMeditationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF2D3142),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserDashboardScreen(), // Updated to UserDashboardScreen
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Guided Meditation',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const Text(
                'Find your inner peace',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildFeaturedMeditation() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('sleep_stories')
          .where('isPopular', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const CustomErrorWidget();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoadingWidget();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final featuredMeditation = snapshot.data!.docs.first;
        final data = featuredMeditation.data() as Map<String, dynamic>;

        return _buildFeaturedCard(data);
      },
    );
  }

  Widget _buildFeaturedCard(Map<String, dynamic> data) {
    final String title = data['title']?.toString() ?? 'Untitled Meditation';
    final String description = data['description']?.toString() ?? '';
    final String imageUrl = data['imageUrl']?.toString() ?? 'https://via.placeholder.com/400x200';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () => _openMeditation(data),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(
              image: CachedNetworkImageProvider(imageUrl),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.3),
                BlendMode.darken,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['duration'] ?? '10 min',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllMeditationsTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'All Meditations',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2D3142),
        ),
      ),
    );
  }

  Widget _buildMeditationsList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('sleep_stories')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const CustomErrorWidget();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CustomLoadingWidget();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No meditations available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final meditation = snapshot.data!.docs[index];
              final data = meditation.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => _openMeditation(data),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/400x200',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['description'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['duration'] ?? '10 min',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Color(0xFF9C89FF),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openMeditation(Map<String, dynamic> meditationData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AudioPlayerScreen(
          title: meditationData['title'] ?? 'Untitled',
          description: meditationData['description'] ?? '',
          audioUrl: meditationData['audioUrl'] ?? '',
          imageUrl: meditationData['imageUrl'] ?? 'https://via.placeholder.com/400x200',
        ),
      ),
    );
  }
}
