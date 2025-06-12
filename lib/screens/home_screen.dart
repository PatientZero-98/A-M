import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
  
  // Request storage permissions for Android
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // If permissions are permanently denied, direct user to app settings
        await openAppSettings();
      }
      return false;
    }
    return true; // Non-Android platforms don't need this permission
  }
  
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
                      'Dungeons & Music',
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
            ),            _buildDrawerItem(
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
              icon: Icons.file_download_outlined,
              title: 'Import',
              onTap: () {
                Navigator.pop(context);
                _importData(context);
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
  }  // Export functionality
  void _exportData(BuildContext context) async {
    try {
      String? selectedDirectory;
      
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage permission is required to export data.'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }
      
      // Use FilePicker to select directory
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        selectedDirectory = await FilePicker.platform.getDirectoryPath();
      } else {
        // For mobile platforms, use the Android media directory
        try {
          final mediaDir = Directory('/storage/emulated/0/Android/media/music4dnd/files');
          
          // Debug info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Creating directory at: ${mediaDir.path}'),
              backgroundColor: Colors.blue[700],
              duration: const Duration(seconds: 2),
            ),
          );
          
          if (!await mediaDir.exists()) {
            await mediaDir.create(recursive: true);
          }
          final exportDir = Directory('${mediaDir.path}/Music4DnD_Export');
          if (!await exportDir.exists()) {
            await exportDir.create(recursive: true);
          }
          selectedDirectory = exportDir.path;
        } catch (dirError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating directory: $dirError'),
              backgroundColor: Colors.red[700],
            ),
          );
          return;
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
        try {
        // Use our ExportService to handle the export
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Starting export to $selectedDirectory'),
            backgroundColor: Colors.blue[700],
            duration: const Duration(seconds: 2),
          ),
        );
        
        final result = await ExportService.exportData(selectedDirectory);
        
        // Close progress dialog if context is still mounted
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        
        // Get a safe context to use for snackbars
        BuildContext? snackbarContext = context.mounted ? context : null;
        if (snackbarContext == null && _scaffoldKey.currentContext != null) {
          snackbarContext = _scaffoldKey.currentContext;
        }
        
        if (snackbarContext == null) {
          print("Error: No valid context available for feedback");
          return;
        }
        
        if (result.success) {
          // Show success message with export details
          ScaffoldMessenger.of(snackbarContext).showSnackBar(
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
          // Show error message
          ScaffoldMessenger.of(snackbarContext).showSnackBar(
            SnackBar(
              content: Text('Export failed: ${result.error}'),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (exportError) {
        // Close progress dialog if context is still mounted
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Export failed with error: $exportError'),
              backgroundColor: Colors.red[700],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }} catch (e) {
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
  // Import functionality
  void _importData(BuildContext context) async {
    try {
      String? selectedDirectory;
      
      // Request storage permission
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage permission is required to import data.'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }
      
      // Use FilePicker to select directory
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        selectedDirectory = await FilePicker.platform.getDirectoryPath();
      } else {
        // For mobile platforms, check the media folder
        try {
          final mediaDir = Directory('/storage/emulated/0/Android/media/music4dnd/files');
          
          // Debug info
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Accessing directory at: ${mediaDir.path}'),
              backgroundColor: Colors.blue[700],
              duration: const Duration(seconds: 2),
            ),
          );
          
          if (!await mediaDir.exists()) {
            await mediaDir.create(recursive: true);
          }
          final importDir = Directory('${mediaDir.path}/Music4DnD_Import');
          if (!await importDir.exists()) {
            await importDir.create(recursive: true);
            // Show message about where to place files
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please place your cards.json, tracks folder, and images folder in: ${importDir.path}'),
                backgroundColor: Colors.blue[700],
                duration: const Duration(seconds: 8),
              ),
            );
            return;
          }
          selectedDirectory = importDir.path;
        } catch (dirError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error accessing directory: $dirError'),
              backgroundColor: Colors.red[700],
            ),
          );
          return;
        }
      }
      
      if (selectedDirectory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Import cancelled or no directory selected.'),
            backgroundColor: Colors.red[700],
          ),
        );
        return;
      }
      
      // Validate that the selected directory has the correct structure
      final cardsFile = File('$selectedDirectory/cards.json');
      final tracksDir = Directory('$selectedDirectory/tracks');
      final imagesDir = Directory('$selectedDirectory/images');
      
      if (!await cardsFile.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Selected directory does not contain a cards.json file.'),
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
                    'Importing data...',
                    style: TextStyle(color: Colors.amber[100]),
                  ),
                ],
              ),
            ),
          );
        },
      );
      
      // Get application support directory
      final appDir = await getApplicationSupportDirectory();
      final appTracksDir = Directory('${appDir.path}/tracks');
      final appCardsFile = File('${appDir.path}/cards.json');
      
      // Create tracks directory if it doesn't exist
      if (!await appTracksDir.exists()) {
        await appTracksDir.create(recursive: true);
      }
      
      // Track metrics
      int tracksCopied = 0;
      int imagesCopied = 0;
      
      // Read cards data
      final content = await cardsFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      
      // Process and copy tracks
      if (await tracksDir.exists()) {
        for (final cardData in jsonList) {
          final tracks = cardData['tracks'] as List;
          for (final track in tracks) {
            final trackPath = track['filePath'];
            if (trackPath != null) {
              // Extract filename from the path
              final filename = trackPath.split('/').last;
              final sourceFile = File('$selectedDirectory/$trackPath');
              final destFile = File('${appTracksDir.path}/$filename');
              
              if (await sourceFile.exists() && !(await destFile.exists())) {
                await sourceFile.copy(destFile.path);
                tracksCopied++;
              }
              
              // Update the track path to use the app's file structure
              track['filePath'] = '${appTracksDir.path}/$filename';
            }
          }
        }
      }
      
      // Process and copy images
      if (await imagesDir.exists()) {
        for (final cardData in jsonList) {
          final bgImagePath = cardData['backgroundImagePath'];
          if (bgImagePath != null) {
            // Extract filename from the path
            final filename = bgImagePath.split('/').last;
            final sourceFile = File('$selectedDirectory/$bgImagePath');
            final destFile = File('${appDir.path}/$filename');
            
            if (await sourceFile.exists()) {
              await sourceFile.copy(destFile.path);
              imagesCopied++;
            }
            
            // Update the image path to use the app's file structure
            cardData['backgroundImagePath'] = '${appDir.path}/$filename';
          }
        }
      }
      
      // Write the updated card data to the app
      await appCardsFile.writeAsString(jsonEncode(jsonList));
      
      // Store a safe context reference
      final BuildContext scaffoldContext = _scaffoldKey.currentContext!;
      
      // Close progress dialog if context is still mounted
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      // Show success message
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
          content: Text(
            'Import successful! Imported $tracksCopied tracks, '
            '${jsonList.length} cards, and $imagesCopied images.'
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 5),
        ),
      );
      
    } catch (e) {
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
            content: Text('Import failed: ${e.toString()}'),
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
