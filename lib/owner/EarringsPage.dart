import 'package:flutter/material.dart';

class EarringsPage extends StatelessWidget {
  const EarringsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Earrings")),
      body: const Center(
        child: Text("All Earrings Products Here"),
      ),
    );
  }
}