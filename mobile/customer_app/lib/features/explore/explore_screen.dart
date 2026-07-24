import 'package:flutter/material.dart';

// Placeholder — full browse/search experience lands in a later phase.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explore')),
      body: const Center(child: Text('Coming soon', style: TextStyle(color: Colors.grey))),
    );
  }
}
