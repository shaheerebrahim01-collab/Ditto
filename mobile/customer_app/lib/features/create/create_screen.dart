import 'package:flutter/material.dart';

// Placeholder — order creation flow lands once POST /orders exists.
class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create')),
      body: const Center(child: Text('Coming soon', style: TextStyle(color: Colors.grey))),
    );
  }
}
