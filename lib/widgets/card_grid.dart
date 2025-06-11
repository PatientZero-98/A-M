import 'dart:io';
import 'dart:convert';
import 'dart:async'; // For StreamSubscription
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/card_model.dart';
import '../models/track_model.dart';
import 'card_editor_modal.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:math';
import '../core/Services/audio_service.dart';
import '../core/Services/event_bus_service.dart';
import 'package:just_audio/just_audio.dart';

class CardGrid extends StatefulWidget {
  const CardGrid({super.key});

  @override
  State<CardGrid> createState() => _CardGridState();
}

class _CardGridState extends State<CardGrid> {
  List<CardPlaylistModel> cards = [];
  bool loading = true;

  final AudioService _audioService = AudioService();
  final EventBusService _eventBus = EventBusService();
  int? _playingCardIndex;
  late StreamSubscription _eventSubscription;
  @override
  void initState() {
    super.initState();
    _loadCards();
    // Listen to playback state to update UI when playback changes
    _audioService.player.playerStateStream.listen((state) {
      setState(() {
        // If playback stopped, clear playing card highlight
        if (state.processingState == ProcessingState.completed ||
            state.processingState == ProcessingState.idle) {
          _playingCardIndex = null;
        }
      });
    });
    
    // Listen for card update events (when tracks are deleted)
    _eventSubscription = _eventBus.stream.listen((event) {
      if (event['event'] == AppEvents.cardsUpdated) {
        _loadCards(); // Reload cards when tracks are deleted
      }
    });
  }
  
  @override
  void dispose() {
    _eventSubscription.cancel();
    super.dispose();
  }

  Future<File> _getCardsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/cards.json');
  }

  Future<void> _loadCards() async {
    final file = await _getCardsFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      setState(() {
        cards = jsonList.map((e) => CardPlaylistModel(
          name: e['name'],
          tracks: (e['tracks'] as List).map((t) => TrackModel(name: t['name'], filePath: t['filePath'])).toList(),
          backgroundImagePath: e['backgroundImagePath'],
        )).toList();
        loading = false;
      });
    } else {
      setState(() {
        cards = [];
        loading = false;
      });
    }
  }

  Future<void> _saveCards() async {
    final file = await _getCardsFile();
    final List<Map<String, dynamic>> jsonList = cards.map((c) => {
      'name': c.name,
      'tracks': c.tracks.map((t) => {'name': t.name, 'filePath': t.filePath}).toList(),
      'backgroundImagePath': c.backgroundImagePath,
    }).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  void _addCard(CardPlaylistModel card) {
    setState(() {
      cards.add(card);
    });
    _saveCards();
  }

  void _removeCard(int index) {
    setState(() {
      cards.removeAt(index);
    });
    _saveCards();
  }

  void _updateCard() {
    setState(() {});
    _saveCards();
  }
  Future<void> _playCardTracksRandom(CardPlaylistModel card, int cardIndex) async {
    if (card.tracks.isEmpty) return;
    
    // Immediately update UI to provide visual feedback
    setState(() {
      _playingCardIndex = cardIndex;
    });
    
    final tracks = List<TrackModel>.from(card.tracks);
    tracks.shuffle(Random());
    await _audioService.playCardWithOrder(card, tracks);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cards.isEmpty ? 1 : cards.length + 1, // Only show add button if no cards
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 cards per row
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1, // Square cards
      ),
      itemBuilder: (_, index) {
        if (cards.isEmpty || index == cards.length) {
          // Add Card Button
          return GestureDetector(
            onTap: () async {
              String? cardName;
              String? imagePath;
              await showDialog(
                context: context,
                builder: (context) {
                  TextEditingController nameController = TextEditingController();                  return AlertDialog(
                    backgroundColor: const Color(0xFF1A1A2E), // Deep blue-black
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.amber.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    title: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.amber[400]!,
                          Colors.amber[100]!,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'Create New Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold, 
                          fontSize: 20,
                        ),
                      ),
                    ),
                    content: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black26,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: nameController,
                            cursorColor: Colors.amber,
                            style: TextStyle(color: Colors.amber[50]),
                            decoration: InputDecoration(
                              labelText: 'Card Name',
                              labelStyle: TextStyle(color: Colors.amber[200]),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.amber.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.amber),
                              ),
                              filled: true,
                              fillColor: Colors.black12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          StatefulBuilder(
                            builder: (context, setState) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                  color: Colors.black12,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.black26,
                                        border: Border.all(color: Colors.amber.withOpacity(0.2)),
                                      ),
                                      child: imagePath != null
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.file(
                                                File(imagePath!),
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.image_outlined,
                                                size: 40,
                                                color: Colors.amber.withOpacity(0.5),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.image),
                                      label: const Text('Choose Background'),
                                      onPressed: () async {
                                        final result = await FilePicker.platform.pickFiles(type: FileType.image);
                                        if (result != null) {
                                          imagePath = result.files.single.path;
                                          setState(() {});
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber.withOpacity(0.2),
                                        foregroundColor: Colors.amber[100],
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[400],
                        ),
                        child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          cardName = nameController.text.trim();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.withOpacity(0.2),
                          foregroundColor: Colors.amber[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.amber.withOpacity(0.5)),
                          ),
                        ),
                        child: const Text('Create', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  );
                },
              );
              if (cardName != null && cardName!.isNotEmpty) {
                // Ensure unique card name
                String baseName = cardName!;
                int count = 1;
                final existingNames = cards.map((c) => c.name).toSet();
                String uniqueName = baseName;
                while (existingNames.contains(uniqueName)) {
                  uniqueName = '$baseName (${count++})';
                }
                _addCard(CardPlaylistModel(name: uniqueName, backgroundImagePath: imagePath));
              }
            },            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                color: Colors.amber.withOpacity(0.7),
                dashPattern: [8, 4],
                strokeWidth: 2,
                radius: const Radius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E), // Deep blue-black
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A1A2E), // Deep blue-black
                      const Color(0xFF16213E), // Navy blue
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.amber,
                          size: 30,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 5,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "New Card",
                        style: TextStyle(
                          color: Colors.amber[200],
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          final card = cards[index];
          return DragTarget<TrackModel>(
            onWillAccept: (data) => !card.containsTrack(data!),
            onAccept: (track) {
              setState(() {
                card.addTrack(track);
              });
              _saveCards();
            },
            builder: (context, candidateData, rejectedData) {
              return GestureDetector(
                onTap: () {
                  _playCardTracksRandom(card, index);
                },
                onLongPress: () async {
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.black87,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) => CardEditorModal(
                      card: card,
                      onUpdate: _updateCard,
                      onDelete: () {
                        Navigator.pop(context);
                        _removeCard(index);
                      },
                    ),
                  );
                },                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _playingCardIndex == index
                        ? Colors.amber[900]?.withOpacity(0.0)
                        : candidateData.isNotEmpty
                            ? const Color(0xFF1D6B42) // Fantasy forest green
                            : const Color(0xFF1F2937), // Deep slate for fantasy parchment
                    borderRadius: BorderRadius.circular(16),                    boxShadow: _playingCardIndex == index
                        ? [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.6), // Reduced opacity
                              blurRadius: 24, // Reduced blur
                              spreadRadius: 2, // Reduced spread
                            ),
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.1), // Reduced opacity
                              blurRadius: 36, // Reduced blur
                              spreadRadius: 4, // Reduced spread
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],                    image: card.backgroundImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(card.backgroundImagePath!)),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              _playingCardIndex == index
                                  ? Colors.amber.withOpacity(0.2) // Slight amber tint when playing
                                  : Colors.black.withOpacity(0.55), // Darker overlay for better text contrast
                              BlendMode.darken, // Use darken blend mode for better text visibility
                            ),
                          )
                        : null,
                    border: Border.all(
                      color: _playingCardIndex == index
                          ? Colors.amber
                          : Colors.grey[800]!,
                      width: 2,
                    ),
                    gradient: card.backgroundImagePath == null
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _playingCardIndex == index
                                ? [Colors.amber[900]!, Colors.amber[700]!]
                                : [const Color(0xFF1F2937), const Color(0xFF111827)],
                          )
                        : null,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [                      if (_playingCardIndex == index)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 16,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Card name with semi-transparent background for readability
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            
                            child: Text(
                              card.name,
                              style: TextStyle(
                                color: _playingCardIndex == index
                                    ? Colors.white
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 48, // Increased from 16
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 3,
                                    offset: const Offset(3,3),
                                  ),
                                  // Second shadow for stronger text outline
                                  Shadow(
                                    color: Colors.black.withOpacity(0.8),
                                    blurRadius: 2,
                                    offset: const Offset(3, 3),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: _playingCardIndex == index
                                  ? Colors.amber.withOpacity(0.25)
                                  : Colors.black.withOpacity(0.5), // Darker for better contrast
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _playingCardIndex == index
                                    ? Colors.amber.withOpacity(0.6)
                                    : Colors.grey.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.music_note,
                                  size: 14,
                                  color: _playingCardIndex == index
                                      ? Colors.amber[100]
                                      : Colors.grey[300],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${card.tracks.length} track${card.tracks.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: _playingCardIndex == index
                                        ? Colors.amber[100]
                                        : Colors.grey[300],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
