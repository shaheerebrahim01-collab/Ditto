import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/auth_repository.dart';
import '../../core/theme.dart';
import '../../models/rental_item.dart';

// Inventory CRUD against GET/POST /rental-shops/me/items and
// PATCH/DELETE /rental-shops/me/items/:id — all real endpoints.
class RentalShopInventoryScreen extends StatefulWidget {
  const RentalShopInventoryScreen({super.key});

  @override
  State<RentalShopInventoryScreen> createState() => _RentalShopInventoryScreenState();
}

class _RentalShopInventoryScreenState extends State<RentalShopInventoryScreen> {
  final _api = ApiClient();
  List<RentalItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      final items = await _api.listMyRentalItems(accessToken);
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load inventory');
    }
  }

  Future<void> _openItemForm({RentalItem? existing}) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemFormSheet(accessToken: accessToken, api: _api, existing: existing),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(RentalItem item) async {
    final accessToken = context.read<AuthRepository>().accessToken;
    if (accessToken == null) return;
    try {
      await _api.deleteRentalItem(accessToken, item.id);
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.statusCode == 409 ? 'Cannot delete an item with existing bookings' : 'Failed to delete';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openItemForm(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: DittoColors.mutedInk)));
    }
    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items!.isEmpty) {
      return const Center(child: Text('No items yet', style: TextStyle(color: DittoColors.mutedInk)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _items!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items![index];
        return _ItemCard(
          item: item,
          onEdit: () => _openItemForm(existing: item),
          onDelete: () => _delete(item),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.onEdit, required this.onDelete});

  final RentalItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DittoColors.brown.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(item.category, style: const TextStyle(color: DittoColors.mutedInk, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '\$${item.pricePerDay.toStringAsFixed(0)}/day · \$${item.depositAmount.toStringAsFixed(0)} deposit',
                  style: const TextStyle(color: DittoColors.brown, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onDelete),
        ],
      ),
    );
  }
}

class _ItemFormSheet extends StatefulWidget {
  const _ItemFormSheet({required this.accessToken, required this.api, this.existing});

  final String accessToken;
  final ApiClient api;
  final RentalItem? existing;

  @override
  State<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends State<_ItemFormSheet> {
  late final _nameController = TextEditingController(text: widget.existing?.name ?? '');
  late final _categoryController = TextEditingController(text: widget.existing?.category ?? '');
  late final _priceController = TextEditingController(
    text: widget.existing != null ? widget.existing!.pricePerDay.toStringAsFixed(0) : '',
  );
  late final _depositController = TextEditingController(
    text: widget.existing != null ? widget.existing!.depositAmount.toStringAsFixed(0) : '',
  );
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final deposit = double.tryParse(_depositController.text.trim());
    if (name.isEmpty || category.isEmpty || price == null || deposit == null) {
      setState(() => _error = 'Fill in every field with a valid value');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      if (widget.existing == null) {
        await widget.api.createRentalItem(
          widget.accessToken,
          name: name,
          category: category,
          pricePerDay: price,
          depositAmount: deposit,
        );
      } else {
        await widget.api.updateRentalItem(
          widget.accessToken,
          widget.existing!.id,
          name: name,
          category: category,
          pricePerDay: price,
          depositAmount: deposit,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Failed to save item');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: DittoColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Add item' : 'Edit item',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(hintText: 'Name')),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(hintText: 'Category, e.g. Tuxedo'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Price per day'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _depositController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Deposit amount'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFFB3452C))),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: Text(_submitting ? 'Saving...' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
