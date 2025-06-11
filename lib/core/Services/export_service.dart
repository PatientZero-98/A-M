import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../../models/track_model.dart';
import '../../models/card_model.dart';

class ExportService {
  /// Export all app data (tracks, cards, background images) to the specified directory
  static Future<ExportResult> exportData(String destinationPath) async {
    try {
      // Create base directory structure
      final exportDir = Directory(destinationPath);
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      // Create subdirectories
      final tracksDir = Directory('$destinationPath/tracks');
      final imagesDir = Directory('$destinationPath/images');
      await tracksDir.create();
      await imagesDir.create();
      
      // Get app support directory for source files
      final appDir = await getApplicationSupportDirectory();
      final appTracksDir = Directory('${appDir.path}/tracks');
      final cardsFile = File('${appDir.path}/cards.json');
      
      // Track metrics
      int tracksCopied = 0;
      int imagesCopied = 0;
      List<CardPlaylistModel> cards = [];
      
      // Copy tracks
      if (await appTracksDir.exists()) {
        final tracks = appTracksDir.listSync().whereType<File>().toList();
        
        for (final track in tracks) {
          final filename = track.path.split(Platform.pathSeparator).last;
          final destFile = File('${tracksDir.path}/$filename');
          await track.copy(destFile.path);
          tracksCopied++;
        }
      }
      
      // Export cards data and copy background images
      if (await cardsFile.exists()) {
        final content = await cardsFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        cards = jsonList.map((e) => CardPlaylistModel(
          name: e['name'],
          tracks: (e['tracks'] as List).map((t) => TrackModel(name: t['name'], filePath: t['filePath'])).toList(),
          backgroundImagePath: e['backgroundImagePath'],
        )).toList();
        
        // Create a list to store the modified card data for export
        final List<Map<String, dynamic>> exportCards = [];
        
        for (final card in cards) {
          final Map<String, dynamic> exportCard = {
            'name': card.name,
            'tracks': card.tracks.map((t) {
              // Extract track filename for the export
              final trackFilename = t.filePath.split(Platform.pathSeparator).last;
              return {
                'name': t.name,
                'filePath': 'tracks/$trackFilename'
              };
            }).toList(),
          };
          
          // Copy and update background image if it exists
          if (card.backgroundImagePath != null) {
            final bgFile = File(card.backgroundImagePath!);
            if (await bgFile.exists()) {
              final bgFilename = bgFile.path.split(Platform.pathSeparator).last;
              final destBgFile = File('${imagesDir.path}/$bgFilename');
              await bgFile.copy(destBgFile.path);
              exportCard['backgroundImagePath'] = 'images/$bgFilename';
              imagesCopied++;
            }
          }
          
          exportCards.add(exportCard);
        }
        
        // Write the modified card data to the export directory
        final exportCardsFile = File('$destinationPath/cards.json');
        await exportCardsFile.writeAsString(jsonEncode(exportCards));
      }
      
      // Create a README file with export information
      final readmeFile = File('$destinationPath/README.txt');
      await readmeFile.writeAsString(
        'Music4DnD Export\n'
        'Date: ${DateTime.now().toString()}\n\n'
        'Contents:\n'
        '- $tracksCopied tracks\n'
        '- ${cards.length} cards\n'
        '- $imagesCopied background images\n\n'
        'This export can be imported into another instance of Music4DnD.'
      );
      
      return ExportResult(
        success: true,
        tracksExported: tracksCopied,
        cardsExported: cards.length,
        imagesExported: imagesCopied,
      );
      
    } catch (e) {
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

class ExportResult {
  final bool success;
  final int tracksExported;
  final int cardsExported;
  final int imagesExported;
  final String? error;
  
  ExportResult({
    required this.success,
    this.tracksExported = 0,
    this.cardsExported = 0,
    this.imagesExported = 0,
    this.error,
  });
}
