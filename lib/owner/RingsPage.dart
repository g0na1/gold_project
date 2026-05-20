import 'package:flutter/material.dart';

class RingsPage extends StatelessWidget {
  const RingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rings")),
      body: const Center(
        child: Text("All Rings Products Here"),
      ),
    );
  }
}