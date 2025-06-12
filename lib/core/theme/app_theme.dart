import 'package:flutter/material.dart';

/// A class that defines the color palette and styling for the entire app.
/// Any color or style used in multiple places should be defined here.
class AppTheme {
  // Primary colors
  static const Color primaryBackground = Color(0xFF121426);
  static const Color secondaryBackground = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFFD4AF37); // Gold color
  
  // Gradient colors
  static const Color deepBlueBlack = Color(0xFF1A1A2E);
  static const Color midnightBlue = Color(0xFF0F3460);
  
  // Text colors
  static const Color goldText = Color(0xFFFFD700);
  static const Color beigeText = Color(0xFFF5F5DC);
  static const Color lightText = Colors.white;
  static const Color amberLightText = Color(0xFFFFE082);
  
  // Amber shades (for buttons, highlights, etc.)
  static Color amber100 = Colors.amber[100]!;
  static Color amber300 = Colors.amber[300]!;
  
  // Status colors
  static Color successColor = Colors.green[700]!;
  static Color errorColor = Colors.red[700]!;
  static Color infoColor = Colors.blue[700]!;
  
  // Shadows
  static BoxShadow standardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.5),
    blurRadius: 6,
    offset: const Offset(0, 2),
  );
  
  static BoxShadow lightShadow = BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 3,
    offset: const Offset(0, 1),
  );
  
  // Gradients
  static LinearGradient appBarGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [deepBlueBlack, midnightBlue],
  );
  
  static LinearGradient drawerGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [deepBlueBlack, midnightBlue],
  );
  
  static LinearGradient goldTextGradient = const LinearGradient(
    colors: [goldText, beigeText, goldText],
    stops: [0.1, 0.5, 0.9],
  );
  
  static LinearGradient amberTextGradient = LinearGradient(
    colors: [amber300, amber100],
  );
  
  // Border styles
  static BorderSide goldBorder = const BorderSide(
    color: accentColor,
    width: 1.5,
  );
  
  static BorderSide amberBorder = BorderSide(
    color: amber300.withOpacity(0.5),
    width: 1.0,
  );
  
  // Dialog styles
  static ShapeBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: amber300.withOpacity(0.5)),
  );
  
  // Button styles
  static ButtonStyle amberButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.amber.withOpacity(0.2),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: amber300.withOpacity(0.4)),
    ),
  );
  
  static ButtonStyle redButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red.withOpacity(0.2),
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(color: Colors.red.withOpacity(0.4)),
    ),
  );
  
  // Common text styles
  static TextStyle titleTextStyle = const TextStyle(
    color: lightText,
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
  );
  
  static TextStyle drawerItemTextStyle = TextStyle(
    color: amber100,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  
  static TextStyle appTitleTextStyle = const TextStyle(
    color: lightText,
    fontWeight: FontWeight.bold,
    fontSize: 24,
    letterSpacing: 1.2,
  );
  
  static TextStyle drawerSubtitleTextStyle = TextStyle(
    color: amber100,
    fontSize: 16,
  );
  
  // Drawer styles
  static EdgeInsets drawerHeaderPadding = EdgeInsets.zero;
  
  static BoxDecoration drawerHeaderDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [midnightBlue, deepBlueBlack],
    ),
    border: Border(
      bottom: BorderSide(
        color: amber300.withOpacity(0.5),
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
  );
  
  static BoxDecoration drawerItemDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.amber.withOpacity(0.2), width: 0.5),
  );
  
  static ListTileStyle drawerItemStyle = ListTileStyle.drawer;
  
  static EdgeInsets drawerItemMargin = const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
  
  static Color drawerItemIconColor = amber300;
  
  static double drawerItemIconSize = 24;
  
  static BoxDecoration drawerBackgroundDecoration = BoxDecoration(
    gradient: drawerGradient,
    border: const Border(
      left: BorderSide(
        color: Color(0x4DFFD700), // 30% opacity gold
        width: 1.0,
      ),
    ),
  );
  
  // Divider style
  static Divider drawerDivider = Divider(
    color: Colors.amber,
    thickness: 0.2,
    indent: 16,
    endIndent: 16,
  );
  
  // AppBar styles
  static AppBarTheme appBarTheme = AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: amber300),
  );
  
  // Create a MaterialColor from our accent color
  static MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
  
  // Full app theme
  static ThemeData getAppTheme() {
    return ThemeData(
      scaffoldBackgroundColor: primaryBackground,
      primarySwatch: createMaterialColor(accentColor),
      primaryColor: accentColor,
      appBarTheme: appBarTheme,
      textTheme: TextTheme(
        headlineLarge: titleTextStyle,
        bodyLarge: drawerItemTextStyle,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: amberButtonStyle,
      ),
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: amber300,
        surface: secondaryBackground,
        background: primaryBackground,
        error: errorColor,
      ),
    );
  }
}
