import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/track_list.dart';
import '../widgets/card_grid.dart';
import '../widgets/audio_controls.dart';
import '../widgets/volume_control.dart';
import '../core/Services/export_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Build the drawer with fantasy styling
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A1A2E), // Deep blue-black
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A2E), // Deep blue-black
              const Color(0xFF0F3460), // Midnight blue
            ],
          ),
          border: Border(
            left: BorderSide( // Changed from right to left since drawer is now on the right side
              color: Colors.amber.withOpacity(0.3),
              width: 1.0,
            ),
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0F3460), // Midnight blue
                    const Color(0xFF1A1A2E), // Deep blue-black
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.amber.withOpacity(0.5),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [
                        Colors.amber[300]!,
                        Colors.amber[100]!,
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'Ambience 4 DnD',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.amber[100],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context);
                _showSettingsDialog(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.file_upload_outlined,
              title: 'Export',
              onTap: () {
                Navigator.pop(context);
                _exportData(context);
              },
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.delete_outline,
              title: 'Reset',
              onTap: () {
                Navigator.pop(context);
                _showResetConfirmation(context);
              },
            ),
            const Divider(
              color: Colors.amber,
              thickness: 0.2,
              indent: 16,
              endIndent: 16,
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.exit_to_app,
              title: 'Exit',
              onTap: () => _exitApp(),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build styled drawer item
  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withOpacity(0.2), width: 0.5),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.amber[300], size: 24),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.amber[100],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        tileColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  // Show settings dialog (placeholder for future implementation)
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Settings',
          style: TextStyle(color: Colors.amber[300]),
        ),
        content: const Text(
          'Settings functionality will be implemented in a future update.',
          style: TextStyle(color: Colors.white),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.amber.withOpacity(0.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.amber[300])),
          ),
        ],
      ),
    );
  }
  // Export functionality
  void _exportData(BuildContext context) async {
    try {
      String? selectedDirectory;
      
      // Use FilePicker to select directory
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        selectedDirectory = await FilePicker.platform.getDirectoryPath();
      } else {
        // For mobile platforms, create a directory in the external storage
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final exportDir = Directory('${directory.path}/Music4DnD_Export');
          if (!await exportDir.exists()) {
            await exportDir.create(recursive: true);
          }
          selectedDirectory = exportDir.path;
        }
      }
      
      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Export cancelled or no directory selected.'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }
      
      // Show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Exporting data...',
                    style: TextStyle(color: Colors.amber[100]),
                  ),
                ],
              ),
            ),
          );
        },
      );
      
      // Use our ExportService to handle the export
      final result = await ExportService.exportData(selectedDirectory);
        // Store a safe context reference
      final BuildContext scaffoldContext = _scaffoldKey.currentContext!;
      
      // Close progress dialog if context is still mounted
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      if (result.success) {
        // Show success message with export details using scaffoldContext
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text(
              'Export successful! Exported ${result.tracksExported} tracks, '
              '${result.cardsExported} cards, and ${result.imagesExported} images to $selectedDirectory'
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        // Show error message using scaffoldContext
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${result.error}'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }    } catch (e) {
      // Get a safe context reference
      final BuildContext? scaffoldContext = _scaffoldKey.currentContext;
      
      // Close progress dialog if open and context is still mounted
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      // Handle errors using scaffoldContext if available
      if (scaffoldContext != null) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // Show reset confirmation dialog
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(
          'Reset Data',
          style: TextStyle(color: Colors.red[300]),
        ),
        content: const Text(
          'This will delete all tracks and cards. This action cannot be undone. Are you sure you want to continue?',
          style: TextStyle(color: Colors.white),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetData(context);
            },
            child: Text('Reset', style: TextStyle(color: Colors.red[300])),
          ),
        ],
      ),
    );
  }
    // Reset data functionality
  void _resetData(BuildContext context) async {
    try {
      // Show progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: const Color(0xFF1A1A2E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Deleting all data...',
                    style: TextStyle(color: Colors.red[100]),
                  ),
                ],
              ),
            ),
          );
        },
      );
      
      // Get application support directory
      final dir = await getApplicationSupportDirectory();
        // Delete tracks
      final tracksDir = Directory('${dir.path}/tracks');
      if (await tracksDir.exists()) {
        await tracksDir.delete(recursive: true);
      }
      
      // Delete cards file
      final cardsFile = File('${dir.path}/cards.json');
      if (await cardsFile.exists()) {
        await cardsFile.delete();
      }
        await Future.delayed(const Duration(milliseconds: 500));
      
      // Close progress dialog - make sure we check if the context is still mounted
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Brief delay to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Automatically restart the app after deletion
      _exitApp();
    } catch (e) {
      // Get a safe context reference
      final BuildContext? scaffoldContext = _scaffoldKey.currentContext;
      
      // Close progress dialog if open and context is still mounted
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      // Show error message using scaffoldContext if available
      if (scaffoldContext != null) {
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('Reset failed: ${e.toString()}. Restarting app...'),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Brief delay to allow snackbar to be seen
      await Future.delayed(const Duration(seconds: 2));
      
      // Restart app even if there was an error
      _exitApp();
    }
  }
  // Exit app functionality
  void _exitApp() {
    try {
      // Force immediate exit for consistent behavior across platforms
      if (Platform.isAndroid || Platform.isIOS) {
        SystemNavigator.pop();
        // Fallback for mobile platforms if SystemNavigator.pop() doesn't work
        Future.delayed(const Duration(milliseconds: 500), () => exit(0));
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // For desktop platforms, just exit immediately
        exit(0);
      } else {
        // For web or other platforms, system exit might not be available
        // so we would handle that case here
      }
    } catch (e) {
      // Last resort exit if all else fails
      exit(0);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF121426),
      endDrawer: _buildDrawer(context), // Changed from drawer to endDrawer
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove default drawer toggle button
        backgroundColor: const Color(0xFF1A1A2E), // Deep blue-black for fantasy theme
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E), // Deep blue-black
                const Color(0xFF0F3460), // Midnight blue
              ],
            ),
            border: const Border(
              bottom: BorderSide(
                color: Color(0xFFD4AF37), // Gold color for fantasy border
                width: 1.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFD700), // Gold
              Color(0xFFF5F5DC), // Beige
              Color(0xFFFFD700), // Gold again
            ],
            stops: [0.1, 0.5, 0.9],
          ).createShader(bounds),
          child: const Text(
            'Ambience 4 DnD',
            style: TextStyle(
              color: Colors.white, 
              fontWeight: FontWeight.bold,
              fontSize: 22,
              letterSpacing: 1.2,
              shadows: [
                Shadow(
                  color: Color(0xFF000000),
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
        actions: [          Container( // Menu button with a fantasy theme
            margin: const EdgeInsets.only(right: 15),
            child: IconButton(
              icon: Icon(
                Icons.menu,
                color: Colors.amber[300],
                size: 40,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer(); // Changed to openEndDrawer
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 15, // Adjust this value to change the width of the Cards and TracksList
            child: Column(
              children: const [
                Expanded(flex: 3, child: TrackList()),
                Expanded(flex: 6, child: CardGrid()),
              ],
            ),
          ),
          Expanded(
            flex: 1, // Increase this value for more space
            child: VolumeControl(),
          ),
        ],
      ),
      bottomNavigationBar: const AudioControls(),
    );
  }
}
