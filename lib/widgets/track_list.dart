import 'dart:io';
import 'dart:convert' as json;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/track_model.dart';
import '../models/card_model.dart';
import '../core/Services/event_bus_service.dart';

class TrackList extends StatefulWidget {
  const TrackList({super.key});

  @override
  State<TrackList> createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {
  List<TrackModel> userTracks = [];
  bool loading = true;
  final EventBusService _eventBus = EventBusService();

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final dir = await getApplicationSupportDirectory();
    final tracksDir = Directory('${dir.path}/tracks');
    if (await tracksDir.exists()) {
      final files = tracksDir.listSync().whereType<File>().toList();
      setState(() {
        userTracks = files.map((f) => TrackModel(name: f.uri.pathSegments.last, filePath: f.path)).toList();
        loading = false;
      });
    } else {
      setState(() {
        userTracks = [];
        loading = false;
      });
    }
  }

  // Get cards file to update when deleting tracks
  Future<File> _getCardsFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/cards.json');
  }
  
  // Load cards to check for track references
  Future<List<CardPlaylistModel>> _loadCards() async {
    final file = await _getCardsFile();
    if (await file.exists()) {      final content = await file.readAsString();
      final List<dynamic> jsonList = json.jsonDecode(content);
      return jsonList.map((e) => CardPlaylistModel(
        name: e['name'],
        tracks: (e['tracks'] as List).map((t) => TrackModel(name: t['name'], filePath: t['filePath'])).toList(),
        backgroundImagePath: e['backgroundImagePath'],
      )).toList();
    }
    return [];
  }
  
  // Save updated cards after removing tracks
  Future<void> _saveCards(List<CardPlaylistModel> cards) async {
    final file = await _getCardsFile();
    final List<Map<String, dynamic>> jsonList = cards.map((c) => {
      'name': c.name,
      'tracks': c.tracks.map((t) => {'name': t.name, 'filePath': t.filePath}).toList(),
      'backgroundImagePath': c.backgroundImagePath,
    }).toList();
    await file.writeAsString(json.jsonEncode(jsonList));
  }
  // Delete a track and remove it from all cards
  Future<void> _deleteTrack(TrackModel track) async {
    // Delete the physical file
    final file = File(track.filePath);
    if (await file.exists()) {
      await file.delete();
    }
    
    // Remove track from cards
    final cards = await _loadCards();
    int affectedCards = 0;
    
    for (final card in cards) {
      if (card.containsTrack(track)) {
        card.removeTrack(track);
        affectedCards++;
      }
    }
    
    // Save updated cards if needed
    if (affectedCards > 0) {
      await _saveCards(cards);
      // Notify other widgets that cards have been updated
      _eventBus.fire(AppEvents.cardsUpdated);
    }
    
    // Update track list UI
    setState(() {
      userTracks.removeWhere((t) => t.filePath == track.filePath);
    });    // Show success message with additional info if cards were modified
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            affectedCards > 0 
              ? 'Track "${track.name}" deleted and removed from ${affectedCards} ${affectedCards == 1 ? 'card' : 'cards'}'
              : 'Track "${track.name}" deleted'
          ),
          backgroundColor: Colors.amber.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _importTracks() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final dir = await getApplicationSupportDirectory();
      final tracksDir = Directory('${dir.path}/tracks');
      if (!await tracksDir.exists()) {
        await tracksDir.create(recursive: true);
      }
      for (final file in result.files) {
        if (file.path != null) {
          final newFile = File('${tracksDir.path}/${file.name}');
          await File(file.path!).copy(newFile.path);
        }
      }
      await _loadTracks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${result.files.length} track(s)')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Colors.amber[300],
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading tracks...",
              style: TextStyle(
                color: Colors.amber[100],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF161625), // Dark blue for fantasy theme
            const Color(0xFF0F111A), // Even darker blue/black
          ],
        ),
        border: const Border(
          bottom: BorderSide(
            color: Color(0xFFD4AF37), // Gold color for fantasy border
            width: 0.5,
          ),
        ),
      ),
      child: userTracks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.music_note,
                      size: 30,
                      color: Colors.amber[300],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "No tracks available",
                    style: TextStyle(
                      color: Colors.amber[100],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Import audio tracks to assign to Moods",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: Icon(Icons.file_upload, color: Colors.amber[100]),
                    label: Text('Import Tracks', style: TextStyle(color: Colors.amber[100])),
                    onPressed: _importTracks,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Colors.amber.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Fantasy-styled header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.3),
                      width: 0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.library_music,
                            color: Colors.amber[300],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Music Tracks",
                            style: TextStyle(
                              color: Colors.amber[200],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${userTracks.length} track${userTracks.length != 1 ? 's' : ''}",
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Tracks grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 50,
                    childAspectRatio: 13,
                    children: [                      for (final track in userTracks)
                        Draggable<TrackModel>(
                          data: track,
                          feedback: Material(
                            elevation: 8,
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 220,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4D2E1E), // Fantasy parchment brown
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.6),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.music_note,
                                    color: Colors.amber[300],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      track.name,
                                      style: TextStyle(
                                        color: Colors.amber[100],
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.4,
                            child: TrackTile(track, dense: true),
                          ),
                          child: TrackTile(
                            track, 
                            dense: true,
                            onDelete: _deleteTrack,
                          ),
                        ),
                      
                      // Import more tracks button
                      Builder(
                        builder: (context) => Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.amber.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          color: Colors.amber.withOpacity(0.1),
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            onTap: _importTracks,
                            splashColor: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 32,
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.file_upload,
                                      color: Colors.amber[300],
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Import Tracks',
                                      style: TextStyle(
                                        color: Colors.amber[100],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class TrackTile extends StatelessWidget {
  final TrackModel track;
  final bool dense;
  final Function(TrackModel)? onDelete;

  const TrackTile(this.track, {
    super.key, 
    this.dense = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Colors.amber.withOpacity(0.2),
          width: 1,
        ),
      ),
      elevation: 2,
      color: const Color(0xFF1F2937), // Deep slate for fantasy theme
      child: InkWell(
        onLongPress: () {
          if (onDelete != null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
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
                    'Delete Track',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold, 
                      fontSize: 20,
                    ),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Are you sure you want to delete "${track.name}"?',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This track will also be removed from any cards it was assigned to.',
                      style: TextStyle(
                        color: Colors.amber[100],
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                    ),
                    onPressed: () {
                      onDelete!(track);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'DELETE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF272E3F), // Dark slate blue
                const Color(0xFF1F2937), // Deep slate
              ],
            ),
          ),
          child: ListTile(
            dense: dense,
            minVerticalPadding: 0,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber.withOpacity(0.15),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.music_note,
                color: Colors.amber[300],
                size: 18,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            title: Text(
              track.name,
              style: TextStyle(
                fontSize: dense ? 14 : 16,
                color: Colors.amber[50],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 2,
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete,
                  color: Colors.amber.withOpacity(0.4),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.drag_indicator,
                  color: Colors.amber.withOpacity(0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),  );
  }
}
