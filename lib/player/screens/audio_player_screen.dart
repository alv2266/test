import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../widgets/seek_bar.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String title;
  final String description;
  final String audioUrl;
  final String imageUrl;

  const AudioPlayerScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.imageUrl,
  }) : super(key: key);

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _player;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<bool> _validateAudioUrl(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      debugPrint('Response status code: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('URL validation error: $e');
      return false;
    }
  }

  Future<void> _initAudioPlayer() async {
    try {
      debugPrint('Initializing audio player...');
      debugPrint('Audio URL: ${widget.audioUrl}');

      final isValidUrl = await _validateAudioUrl(widget.audioUrl);
      if (!isValidUrl) {
        throw Exception('Invalid or inaccessible audio URL');
      }

      await _player.setUrl(widget.audioUrl);
      _player.playerStateStream.listen((state) {
        debugPrint('Player state changed: $state');
        setState(() {
          _isLoading = false;
          if (state.processingState == ProcessingState.completed) {
            _player.seek(Duration.zero);
          }
        });
      });

      _player.durationStream.listen((newDuration) {
        setState(() {
          _duration = newDuration ?? Duration.zero;
        });
      });

      _player.positionStream.listen((newPosition) {
        setState(() {
          _position = newPosition;
        });
      });
    } catch (e) {
      debugPrint('Error in _initAudioPlayer: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Unable to play audio. Please try again later.';
      });
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: _hasError
            ? _buildErrorState()
            : _isLoading
                ? _buildLoadingState()
                : _buildPlayerUI(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load audio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _initAudioPlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C89FF),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C89FF)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading audio...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerUI() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'Now Playing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // Show options menu
                },
              ),
            ],
          ),
        ),

        // Cover Art
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C89FF)),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.music_note, color: Colors.white, size: 64),
                ),
              ),
            ),
          ),
        ),

        // Title and Description
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        // Progress Bar
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SeekBar(
                duration: _duration,
                position: _position,
                onChangeEnd: (newPosition) {
                  _player.seek(newPosition);
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            bottom: 36.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white, size: 32),
                onPressed: () {
                  final newPosition = _position - const Duration(seconds: 10);
                  _player.seek(newPosition);
                },
              ),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final playing = playerState?.playing ?? false;

                  if (playing) {
                    return IconButton(
                      icon: const Icon(
                        Icons.pause_circle_filled,
                        color: Colors.white,
                        size: 64,
                      ),
                      onPressed: () {
                        _player.pause();
                      },
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 64,
                      ),
                      onPressed: () {
                        _player.play();
                      },
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white, size: 32),
                onPressed: () {
                  final newPosition = _position + const Duration(seconds: 10);
                  _player.seek(newPosition);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
