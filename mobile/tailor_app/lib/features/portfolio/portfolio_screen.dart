import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../data/mock_tailor_data.dart';
import '../../models/portfolio_item.dart';

// Renders against local mock data — no portfolio upload endpoint exists yet
// (AWS_S3_BUCKET/CLOUDINARY_URL are Phase 11, see docs/ROADMAP.md). Picking
// a photo works for real via image_picker; it just isn't persisted anywhere.
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late final List<PortfolioItem> _items = List.of(mockPortfolio);
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final category = await _promptForCategory();
    if (category == null || category.isEmpty || !mounted) return;

    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _items.insert(0, PortfolioItem(id: DateTime.now().microsecondsSinceEpoch.toString(), category: category, imageBytes: bytes));
    });
  }

  Future<String?> _promptForCategory() async {
    _categoryController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add portfolio piece'),
        content: TextField(
          controller: _categoryController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category, e.g. Suits'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_categoryController.text.trim()),
            child: const Text('Choose Photo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add_a_photo_outlined),
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No work uploaded yet', style: TextStyle(color: DittoColors.mutedInk)))
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _items.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) => _PortfolioTile(item: _items[index]),
            ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.item});

  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: DittoColors.brown.withValues(alpha: 0.08),
          image: item.imageBytes != null
              ? DecorationImage(image: MemoryImage(item.imageBytes!), fit: BoxFit.cover)
              : null,
        ),
        child: item.imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, color: DittoColors.brown.withValues(alpha: 0.5)),
                  const SizedBox(height: 4),
                  Text(item.category, style: const TextStyle(fontSize: 11, color: DittoColors.mutedInk)),
                ],
              )
            : Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Text(
                    item.category,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
      ),
    );
  }
}
