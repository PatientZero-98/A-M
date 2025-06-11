import 'package:hive/hive.dart';
import 'track_model.dart';

part 'card_model.g.dart';

@HiveType(typeId: 1)
class CardPlaylistModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<TrackModel> tracks;

  @HiveField(2)
  String? backgroundImagePath;

  CardPlaylistModel({
    required this.name,
    List<TrackModel>? tracks,
    this.backgroundImagePath,
  }) : tracks = tracks != null ? List<TrackModel>.from(tracks) : [];

  factory CardPlaylistModel.fromHive(
    String name,
    List<TrackModel> tracks,
    String? backgroundImagePath,
  ) {
    return CardPlaylistModel(
      name: name,
      tracks: List<TrackModel>.from(tracks),
      backgroundImagePath: backgroundImagePath,
    );
  }

  bool containsTrack(TrackModel track) {
    return tracks.any((t) => t.filePath == track.filePath);
  }

  void addTrack(TrackModel track) {
    if (!containsTrack(track)) {
      tracks.add(track);
    }
  }

  void removeTrack(TrackModel track) {
    tracks.removeWhere((t) => t.filePath == track.filePath);
  }
}
