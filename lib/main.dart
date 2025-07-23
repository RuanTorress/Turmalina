import 'package:flutter/material.dart';
import 'view/clientes/tabela_clientes.dart';

void main() {
  runApp(const TurmalinaApp());
}

class TurmalinaApp extends StatelessWidget {
  const TurmalinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turmalina - Sistema Odontológico',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TabelaClientes(),
    );
  }
}