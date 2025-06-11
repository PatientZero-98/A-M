import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardEditorModal extends StatefulWidget {
  final CardPlaylistModel card;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const CardEditorModal({
    super.key,
    required this.card,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<CardEditorModal> createState() => _CardEditorModalState();
}

class _CardEditorModalState extends State<CardEditorModal> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.card.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E), // Deep blue-black
              const Color(0xFF16213E), // Navy blue
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fantasy-themed title
              Center(
                child: Text(
                  "Edit Card",
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Card name section
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Card Name",
                      style: TextStyle(
                        color: Colors.amber[300],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Enter card name",
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        fillColor: Colors.black26,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.amber.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.amber[700]!),
                        ),
                      ),
                      onChanged: (value) {
                        widget.card.name = value;
                        widget.onUpdate();
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black26,
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.2),
                        ),
                      ),
                      child: widget.card.backgroundImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(widget.card.backgroundImagePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.amber.withOpacity(0.4),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "No image selected",
                                    style: TextStyle(
                                      color: Colors.amber.withOpacity(0.4),
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),                    const SizedBox(height: 12),
                    Center(                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.image, color: Colors.amber[100]),
                            label: Text(
                              "Choose Image",
                              style: TextStyle(color: Colors.amber[100]),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.amber.withOpacity(0.4),
                                ),
                              ),
                            ),                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.image,
                              );
                              if (result != null) {
                                widget.card.backgroundImagePath =
                                    result.files.single.path!;
                                widget.onUpdate();
                                setState(() {});
                              }
                            },
                          ),
                          if (widget.card.backgroundImagePath != null) ...[
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              icon: Icon(Icons.delete, color: Colors.amber[100]),
                              label: Text(
                                "Remove Image",
                                style: TextStyle(color: Colors.amber[100]),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: Colors.red.withOpacity(0.4),
                                  ),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  widget.card.backgroundImagePath = null;
                                  widget.onUpdate();
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card tracks with fantasy styling
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tracks",
                          style: TextStyle(
                            color: Colors.amber[300],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "${widget.card.tracks.length} tracks",
                          style: TextStyle(
                            color: Colors.amber.withOpacity(0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.card.tracks.length,
                      itemBuilder: (context, index) {
                        final track = widget.card.tracks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              track.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.remove_circle,
                                color: Colors.red[300],
                              ),
                              onPressed: () {
                                setState(() {
                                  widget.card.tracks.removeAt(index);
                                  widget.onUpdate();
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.card.tracks.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "No tracks added yet",
                            style: TextStyle(
                              color: Colors.amber.withOpacity(0.4),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Delete card option
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.amber.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.15),
                      foregroundColor: Colors.red[300],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text(
                      "Delete Card",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: widget.onDelete,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
