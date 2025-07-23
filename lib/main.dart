import 'package:flutter/material.dart';
import 'conteudo_dashbord.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turmalina',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ConteudoDashboard(),
    );
  }
}