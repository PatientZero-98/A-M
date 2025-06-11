import 'package:hive/hive.dart';

part 'track_model.g.dart';

@HiveType(typeId: 0)
class TrackModel extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String filePath;

  TrackModel({
    required this.name,
    required this.filePath,
  });
}