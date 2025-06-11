import 'package:flutter/material.dart';

import '../core/Services/audio_service.dart';

class VolumeControl extends StatefulWidget {
  const VolumeControl({super.key});

  @override
  State<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  double _volume = 0.8;
  bool _muted = false;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _audioService.player.setVolume(_volume);
  }

  void _onVolumeChanged(double value) {
    setState(() {
      _volume = value;
      _muted = value == 0;
    });
    _audioService.player.setVolume(_muted ? 0 : _volume);
  }

  void _toggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _audioService.player.setVolume(_muted ? 0 : _volume);
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A2E), // Deep blue-black
            const Color.fromARGB(255, 22, 41, 80), // Navy blue
            const Color(0xFF0F3460).withOpacity(0.9), // Midnight blue with opacity
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFD4AF37), // Gold color for fantasy border
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(-2, 0),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Volume indicator text at the top
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Text(
              "${(_volume * 100).toInt()}%",
              style: TextStyle(
                color: Colors.amber[300],
                fontWeight: FontWeight.bold,
                fontSize: 16,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),          
          Container(  // Vertical slider with fantasy styling
            height: 400, // Doubled from 200 to 400
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(                data: SliderThemeData(
                  trackHeight: 20, // Doubled from 6 to 12
                  activeTrackColor: Colors.amber[400],
                  inactiveTrackColor: Colors.indigo[800]?.withOpacity(0.5),
                  thumbColor: Colors.amber[300],
                  overlayColor: Colors.amber.withOpacity(0.2),
                  thumbShape: SliderComponentShape.noThumb,
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: _muted ? 0 : _volume,
                  onChanged: (value) => _onVolumeChanged(value),
                  min: 0,
                  max: 1,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mute button with fantasy styling
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _muted ? Colors.red.withOpacity(0.2) : Colors.amber.withOpacity(0.15),
              border: Border.all(
                color: _muted ? 
                  Colors.red.withOpacity(0.5) : 
                  Colors.amber.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _muted ? 
                    Colors.red.withOpacity(0.2) : 
                    Colors.amber.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _muted ? Icons.volume_off : Icons.volume_up,
                color: _muted ? Colors.red[300] : Colors.amber[300],
                size: 24,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 3,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              onPressed: _toggleMute,
              tooltip: _muted ? "Unmute" : "Mute",
            ),
          ),
        ],
      ),
    );
  }
}
