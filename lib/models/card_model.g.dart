// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CardPlaylistModelAdapter extends TypeAdapter<CardPlaylistModel> {
  @override
  final int typeId = 1;

  @override
  CardPlaylistModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CardPlaylistModel(
      name: fields[0] as String,
      tracks: List<TrackModel>.from((fields[1] as List).cast<TrackModel>()),
      backgroundImagePath: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CardPlaylistModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.tracks)
      ..writeByte(2)
      ..write(obj.backgroundImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardPlaylistModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
