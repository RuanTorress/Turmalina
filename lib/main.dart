import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/agenda_screen.dart';

void main() {
  runApp(const TurmalinaAgendaApp());
}

class TurmalinaAgendaApp extends StatelessWidget {
  const TurmalinaAgendaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turmalina Agenda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6e4c34), // Primary color from CSS
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          // Ensure AppBar doesn't exceed height constraints
          toolbarHeight: 56.0, // Standard height, well under 88.0 limit
          elevation: 2,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6e4c34),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          toolbarHeight: 56.0, // Consistent height in dark mode
          elevation: 2,
          centerTitle: true,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const AgendaScreen(),
    );
  }
}