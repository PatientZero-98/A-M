import 'package:flutter/material.dart';
import '../core/Services/audio_service.dart';

class AudioControls extends StatefulWidget {
  const AudioControls({super.key});

  @override
  State<AudioControls> createState() => _AudioControlsState();
}

class _AudioControlsState extends State<AudioControls> with TickerProviderStateMixin {
  final AudioService _audioService = AudioService();
  bool _isPlaying = false;
  int _currentTrackIndex = -1;
  late AnimationController _playPauseController;
    // Helper method to build fantasy-themed control buttons
  Widget _buildControlButton({
    IconData? icon,
    Widget? child,
    required double size,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
    required Color backgroundColor,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() {}),
          onExit: (_) => setState(() {}),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
              // Use a radial gradient for a magical glow effect
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.2),
                  backgroundColor,
                ],
                stops: const [0.0, 0.7],
              ),
            ),            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(size / 2),
                onTap: onPressed,
                splashColor: color.withOpacity(0.4),
                hoverColor: color.withOpacity(0.15),
                child: Center(
                  child: Tooltip(
                    message: tooltip,
                    child: child ?? Icon(
                      icon,
                      color: color,
                      size: size * 0.6,
                      // Use a shadow for the icon too
                      shadows: [
                        Shadow(
                          color: color.withOpacity(0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  void initState() {
    super.initState();
    
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _audioService.player.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
        if (_isPlaying) {
          _playPauseController.forward();
        } else {
          _playPauseController.reverse();
        }
      });
    });
    
    // Listen to current index changes to update track information
    _audioService.player.currentIndexStream.listen((index) {
      if (index != null && index != _currentTrackIndex) {
        setState(() {
          _currentTrackIndex = index;
          _updateCurrentTrack();
        });
      }
    });
  }
  void _updateCurrentTrack() {
    // Just update the current track index, we'll use the service getter directly in the build method
    setState(() {});
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    super.dispose();
  }  @override
  Widget build(BuildContext context) {
    // Define colors for our fantasy-themed audio controls
    final backgroundColor = Colors.black87;
      return Container(
      height: 80, // Increased height for better visual appeal
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
        // Create a fantasy-themed backdrop with a parchment and wood texture effect
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A2E), // Deep blue-black
            const Color(0xFF16213E), // Navy blue
            const Color(0xFF0F3460).withOpacity(0.9), // Midnight blue with opacity
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        // Add a subtle border at the top
        border: Border(
          top: BorderSide(
            color: Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),      child: Row(
        children: [
          const SizedBox(width: 16),
          
          // Current Track Information with improved styling - MOVED TO LEFT SIDE
          Expanded(
            child: StreamBuilder<int?>(
              stream: _audioService.player.currentIndexStream,
              builder: (context, snapshot) {
                // Get the current track using the AudioService's getter
                final currentTrack = _audioService.currentTrack;
                
                if (currentTrack == null) {
                  return const Text(
                    'No track playing',
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                }
                  return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Track title with fantasy styling
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.amber[300]!,
                          Colors.amber[100]!,
                        ],
                        stops: const [0.4, 1.0],
                      ).createShader(bounds),
                      child: Text(
                        currentTrack.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 3,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Card name with a subtle separator
                    Row(
                      children: [
                        Icon(
                          Icons.library_music,
                          size: 12,
                          color: Colors.amber[100]?.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _audioService.currentCard?.name ?? "Unknown",
                            style: TextStyle(
                              color: Colors.amber[100]?.withOpacity(0.7) ?? Colors.white70, 
                              fontSize: 12,
                              letterSpacing: 0.3,
                              fontStyle: FontStyle.italic,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),                  ],
                );
              },
            ),
          ),
          
          // CENTERED playback control buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous Track Button
              _buildControlButton(
                icon: Icons.skip_previous,
                size: 40,
                tooltip: 'Previous Track',
                onPressed: _audioService.previous,
                color: Colors.amber[200]!,
                backgroundColor: Colors.indigo[900]!.withOpacity(0.6),
              ),
              
              const SizedBox(width: 12),
                // Play/Pause Button (larger, primary button)
              _buildControlButton(
                size: 55,
                tooltip: _isPlaying ? 'Pause' : 'Play',
                onPressed: () {
                  if (_isPlaying) {
                    _audioService.pause();
                  } else {
                    _audioService.player.play();
                  }
                },
                color: Colors.amber,
                backgroundColor: Colors.indigo[700]!.withOpacity(0.6),
                child: Center(
                  child: AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: _playPauseController,
                    color: Colors.amber[200]!, // Lighter color for the icon
                    size: 40,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Next Track Button
              _buildControlButton(
                icon: Icons.skip_next,
                size: 40,
                tooltip: 'Next Track',
                onPressed: _audioService.next,
                color: Colors.amber[200]!,
                backgroundColor: Colors.indigo[900]!.withOpacity(0.6),
              ),
              
              const SizedBox(width: 12),
              
              // Stop Button
              _buildControlButton(
                icon: Icons.stop,
                size: 40,
                tooltip: 'Stop Playback',
                onPressed: _audioService.stop,
                color: Colors.amber[200]!,
                backgroundColor: Colors.indigo[900]!.withOpacity(0.6),
              ),
            ],
          ),
          
          // Empty expanded container for right side to balance the layout
          Expanded(child: Container()),
          
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}