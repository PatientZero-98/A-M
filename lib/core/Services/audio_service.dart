import 'dart:io';
import 'package:just_audio/just_audio.dart';
import '../../models/card_model.dart';
import '../../models/track_model.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();

  factory AudioService() => _instance;
  AudioService._internal() {
    // Configure crossfade
    _setupCrossfade();
  }
    // Initialize player
  final AudioPlayer _player = AudioPlayer();
  CardPlaylistModel? _currentCard;
  int _currentIndex = 0;
  List<TrackModel>? _currentTracks;
  
  // Duration for crossfade between tracks
  final Duration _crossfadeDuration = const Duration(seconds: 5);
  bool get isPlaying => _player.playing;
  Stream<PlayerState> get playerState => _player.playerStateStream;
  AudioPlayer get player => _player;
  CardPlaylistModel? get currentCard => _currentCard;
  
  // Get current index with protection against out of bounds
  int get currentIndex => _currentIndex;
  
  // Get current track safely
  TrackModel? get currentTrack {
    if (_currentTracks == null || _currentTracks!.isEmpty || _currentIndex >= _currentTracks!.length) {
      return null;
    }
    return _currentTracks![_currentIndex];
  }
  
  // Setup automatic crossfade between tracks in a playlist
  void _setupCrossfade() {
    // Configure player to automatically transition between tracks
    _player.setAutomaticallyWaitsToMinimizeStalling(true);
    
    // Listen for current index changes to update our tracking
    _player.currentIndexStream.listen((index) {
      if (index != null && _currentTracks != null && index < _currentTracks!.length) {
        _currentIndex = index;
      }
    });
    
    // Listen for end of track and handle transitions
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.ready) {
        // When a new track starts, apply volume fade in
        _applyFadeIn();
      } else if (state == ProcessingState.completed) {
        // Let the looping listener handle this case
      }
    });
    
    // Setup position tracking for crossfade
    _player.positionStream.listen((position) {
      try {
        if (_player.playing && _player.duration != null) {
          // If we're approaching the end of the track, start fading out
          final timeRemaining = _player.duration! - position;
          if (timeRemaining < _crossfadeDuration) {
            final fadeOutProgress = 1 - (timeRemaining.inMilliseconds / _crossfadeDuration.inMilliseconds);
            _player.setVolume(1 - fadeOutProgress);
          }
        }
      } catch (e) {
        // Ignore any errors that occur during crossfade
      }
    });
  }
    // Apply fade in effect when starting a new track
  void _applyFadeIn() async {
    try {
      // Start with low volume
      _player.setVolume(0);
      
      // Log the fade-in start (helpful for debugging)
      print('Starting fade-in for track ${currentTrack?.name ?? "unknown"}');
      
      // Gradually increase volume over the crossfade duration
      final fadeStep = 0.05;
      for (double vol = 0; vol < 1; vol += fadeStep) {
        await Future.delayed(Duration(milliseconds: 
            (_crossfadeDuration.inMilliseconds * fadeStep).round()));
        _player.setVolume(vol);
      }
      
      // Ensure final volume is exactly 1
      _player.setVolume(1);
      print('Fade-in complete for track ${currentTrack?.name ?? "unknown"}');
    } catch (e) {
      // If any error occurs, ensure volume is set to 1
      print('Error during fade-in: $e');
      _player.setVolume(1);
    }
  }
  // Add support for playing a card with a custom track order (for random/shuffle)
  List<String>? _customOrderPaths;
    Future<void> playCard(CardPlaylistModel card) async {
    if (card.tracks.isEmpty) return;

    _currentCard = card;
    _currentTracks = List<TrackModel>.from(card.tracks);
    _currentIndex = 0;
    
    // Check if we're already playing something and need to transition
    final bool isCurrentlyPlaying = _player.playing;
    
    if (isCurrentlyPlaying) {
      // Fade out current audio before switching to the new track
      await _fadeOutCurrentTrack();
    }
    
    try {
      // Verify the file exists first
      final track = card.tracks[_currentIndex];
      final file = File(track.filePath);
      
      if (!await file.exists()) {
        print('Error: Track file not found: ${track.filePath}');
        return;
      }
      
      // Create a single audio source for the track
      final audioSource = AudioSource.uri(Uri.file(track.filePath));
      await _player.setAudioSource(audioSource);
      _player.play();
      _applyFadeIn();
    } catch (e) {
      print('Error playing card: $e');
      _player.stop();
    }
  }

  bool _loopingListenerAttached = false;
    void _ensureLoopingListener() {
    if (_loopingListenerAttached) return;
    _loopingListenerAttached = true;
    _player.playerStateStream.listen((state) async {
      // Check if we've reached the end of all tracks in a card
      if (_currentCard != null && 
          state.processingState == ProcessingState.completed) {
        // Reshuffle and restart playback
        final tracks = List<TrackModel>.from(_currentCard!.tracks);
        tracks.shuffle();
        
        // Filter out tracks with invalid files
        final validTracks = <TrackModel>[];
        for (final track in tracks) {
          final file = File(track.filePath);
          if (await file.exists()) {
            validTracks.add(track);
          } else {
            print('Warning: Track file not found while reshuffling: ${track.filePath}');
          }
        }
        
        if (validTracks.isEmpty) {
          print('Error: No valid tracks found while reshuffling card ${_currentCard!.name}');
          return;
        }
        
        // Store the custom order for reference
        _customOrderPaths = validTracks.map((t) => t.filePath).toList();
        _currentIndex = 0;
        
        try {
          // Create a playlist from the shuffled valid tracks for better crossfade
          final playlist = ConcatenatingAudioSource(
            useLazyPreparation: true,
            children: validTracks.map((track) => 
              AudioSource.uri(Uri.file(track.filePath))
            ).toList(),
          );
          
          // If we have stored paths, ensure they match our shuffled order
          if (_customOrderPaths != null && _customOrderPaths!.isNotEmpty) {
            print("Reshuffling with ${_customOrderPaths!.length} valid tracks");
          }
          
          await _player.setAudioSource(playlist, initialIndex: 0);
          _player.play();
          _applyFadeIn();
        } catch (e) {
          print('Error during reshuffling: $e');
          // Only stop if there's a critical error
        }
      }
    });
  }  Future<void> playCardWithOrder(CardPlaylistModel card, List<TrackModel> order) async {
    if (order.isEmpty) return;
    
    print('Playing card ${card.name} with ${order.length} tracks');
    _currentCard = card;
    _currentTracks = List<TrackModel>.from(order); // Store the tracks order
    _currentIndex = 0;
    
    // Store the custom order paths for reshuffling
    _customOrderPaths = order.map((t) => t.filePath).toList();
    
    // Check if we're already playing something and need to transition
    final bool isCurrentlyPlaying = _player.playing;
    
    if (isCurrentlyPlaying) {
      print('Transitioning from previous audio with fade-out');
      // Fade out current audio before switching to the new playlist
      await _fadeOutCurrentTrack();
    }
    
    try {
      // Filter out tracks with invalid files first
      final validTracks = <TrackModel>[];
      for (final track in order) {
        final file = File(track.filePath);
        if (await file.exists()) {
          validTracks.add(track);
        } else {
          print('Warning: Track file not found: ${track.filePath}');
        }
      }
      
      if (validTracks.isEmpty) {
        print('Error: No valid tracks found in card ${card.name}');
        return;
      }
      
      // Update current tracks list with only valid tracks
      _currentTracks = validTracks;
      
      // Build playlist for crossfade with valid tracks
      final playlist = ConcatenatingAudioSource(
        // Enable useLazyPreparation for better performance with many tracks
        useLazyPreparation: true,
        shuffleOrder: DefaultShuffleOrder(),
        children: validTracks.map((t) => AudioSource.uri(Uri.file(t.filePath))).toList(),
      );
      
      // Set the audio source and start playback
      print('Setting up new playlist with ${validTracks.length} valid tracks');
      await _player.setAudioSource(playlist, initialIndex: 0);
      await _player.play();
      _applyFadeIn();
      _ensureLoopingListener();
    } catch (e) {
      print('Error playing card: $e');
      // Reset player and show error
      _player.stop();
    }
  }
  // Gradually fade out and pause playback
  Future<void> pause() async {
    // Store original volume to restore later
    final originalVolume = _player.volume;
    
    // Gradual fade out for pause
    final fadeStep = 0.1;
    for (double vol = originalVolume; vol > 0; vol -= fadeStep) {
      _player.setVolume(vol);
      await Future.delayed(const Duration(milliseconds: 30));
    }
    
    // Pause playback
    _player.pause();
    
    // Restore volume for when playback resumes
    _player.setVolume(originalVolume);
  }
  
  // Stop playback with fade out
  Future<void> stop() async {
    // Fade out if playing
    if (_player.playing) {
      _fadeOutAndStop();
    } else {
      _player.stop();
    }
    _customOrderPaths = null;
    _currentCard = null;
    _currentIndex = 0;
    // Do not reset _loopingListenerAttached so only one listener is ever attached
  }
  
  // Helper method to fade out and stop playback
  Future<void> _fadeOutAndStop() async {
    try {
      // Store original volume to restore later
      final originalVolume = _player.volume;
      
      // Gradually decrease volume
      final fadeStep = 0.05;
      for (double vol = originalVolume; vol > 0; vol -= fadeStep) {
        _player.setVolume(vol);
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // Stop playback
      _player.stop();
      
      // Restore volume for next playback
      _player.setVolume(originalVolume);
    } catch (e) {
      // If any error occurs, just stop playback
      _player.stop();
      _player.setVolume(1);
    }
  }

  // Navigate to next track with crossfade
  Future<void> next() async {
    // Fade out current track
    await _fadeOutCurrentTrack();
    
    // Go to next track and play
    if (_player.hasNext) {
      await _player.seekToNext();
      
      // Update current index
      int? newIndex = _player.currentIndex;
      if (newIndex != null && _currentTracks != null && newIndex < _currentTracks!.length) {
        _currentIndex = newIndex;
      }
      
      _player.play();
      // Apply fade in effect
      _applyFadeIn();
    }
  }

  // Navigate to previous track with crossfade
  Future<void> previous() async {
    // Fade out current track
    await _fadeOutCurrentTrack();
    
    // Go to previous track and play
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      
      // Update current index
      int? newIndex = _player.currentIndex;
      if (newIndex != null && _currentTracks != null && newIndex < _currentTracks!.length) {
        _currentIndex = newIndex;
      }
      
      _player.play();
      // Apply fade in effect
      _applyFadeIn();
    }
  }
  // Fade out current track before transition
  Future<void> _fadeOutCurrentTrack() async {
    try {
      if (_player.playing) {
        // Store original volume
        final originalVolume = _player.volume;
        
        // Log fade out beginning (helpful for debugging)
        print('Starting fade-out for track ${currentTrack?.name ?? "unknown"}');
        
        // Calculate step duration based on crossfade duration
        // Use half the crossfade duration for card transitions to keep it responsive
        final transitionDuration = _crossfadeDuration.inMilliseconds ~/ 2;
        final fadeSteps = 20; // More steps for smoother transition
        final stepDelay = transitionDuration ~/ fadeSteps;
        
        // Gradually decrease volume
        for (int i = fadeSteps; i >= 0; i--) {
          final volume = (i / fadeSteps) * originalVolume;
          _player.setVolume(volume);
          await Future.delayed(Duration(milliseconds: stepDelay));
        }
        
        // Reset volume for next track
        _player.setVolume(originalVolume);
        print('Fade-out complete');
      }
    } catch (e) {
      // Ensure volume is reset
      print('Error during fade-out: $e');
      _player.setVolume(1);
    }
  }
}
