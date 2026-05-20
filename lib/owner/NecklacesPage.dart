import 'package:flutter/material.dart';

class NecklacesPage extends StatelessWidget {
  const NecklacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Necklaces")),
      body: const Center(
        child: Text("All Necklaces Products Here"),
      ),
    );
  }
}