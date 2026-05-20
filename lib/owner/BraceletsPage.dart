import 'package:flutter/material.dart';

class BraceletsPage extends StatelessWidget {
  const BraceletsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bracelets")),
      body: const Center(
        child: Text("All Bracelets Products Here"),
      ),
    );
  }
}