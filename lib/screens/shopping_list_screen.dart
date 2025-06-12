import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/shopping_list.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/edit_item_dialog.dart';
import '../widgets/item_autocomplete.dart';
import '../widgets/list_header_widget.dart';
import '../widgets/shopping_list_item_tile.dart';

class ShoppingListScreen extends StatefulWidget {
  final ShoppingList list;

  const ShoppingListScreen({super.key, required this.list});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late TextEditingController _currentController;

  void _handleItemSelected(Item selectedItem) {
    final existingItem = widget.list.items.firstWhere(
      (item) => item.name.toLowerCase() == selectedItem.name.toLowerCase(),
      orElse: () => Item(name: '', id: ''),
    );

    if (existingItem.name.isNotEmpty) {
      _updateItemQuantity(existingItem, existingItem.quantity + 1);
    } else {
      _addNewItem(
        name: selectedItem.name,
        price: selectedItem.price,
        unit: selectedItem.unit ?? 'un',
      );
    }
  }

  void _handleItemSubmitted(String value) {
    if (value.isEmpty) return;

    final name = value.trim();
    final existingItem = widget.list.items.firstWhere(
      (item) => item.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Item(name: '', id: ''),
    );

    if (existingItem.name.isNotEmpty) {
      _updateItemQuantity(existingItem, existingItem.quantity + 1);
    } else {
      _addNewItem(name: name);
    }
  }

  void _addNewItem({required String name, double? price, String unit = 'un'}) {
    final newItem = Item(name: name, price: price, quantity: 1, unit: unit);

    setState(() {
      final insertIndex = widget.list.items.length;
      widget.list.items.add(newItem);
      _listKey.currentState?.insertItem(insertIndex);
      final provider = context.read<ShoppingListProvider>();
      provider.updateList(widget.list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.name),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditListDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          ListHeaderWidget(
            total: widget.list.total,
            isOverBudget: widget.list.isOverBudget,
            budgetLimit: widget.list.budgetLimit,
            remainingBudget: widget.list.remainingBudget,
          ),
          Expanded(child: _buildItemsList()),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ItemAutoComplete(
                    onItemSelected: _handleItemSelected,
                    onItemSubmitted: _handleItemSubmitted,
                    onControllerCreated: (controller) {
                      _currentController = controller;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () =>
                      _handleItemSubmitted(_currentController.text),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Consumer<ShoppingListProvider>(
      builder: (context, provider, child) {
        final items = widget.list.items;
        if (items.isEmpty) {
          return _buildEmptyState();
        }

        return AnimatedList(
          key: _listKey,
          padding: const EdgeInsets.all(16),
          initialItemCount: items.length,
          itemBuilder: (context, index, animation) {
            final item = items[index];
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: const Offset(0, 0)),
              ),
              child: FadeTransition(
                opacity: animation,
                child: ShoppingListItemTile(
                  item: item,
                  onTap: () => _showEditItemDialog(item),
                  onUpdateQuantity: (quantity) =>
                      _updateItemQuantity(item, quantity),
                  onDelete: () => _removeItem(item),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 64,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum item na lista',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione itens usando o campo abaixo',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  void _removeItem(Item item) {
    final provider = context.read<ShoppingListProvider>();
    final index = widget.list.items.indexOf(item);
    if (index >= 0) {
      setState(() {
        widget.list.items.removeAt(index);
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1, 0), end: const Offset(0, 0)),
            ),
            child: FadeTransition(
              opacity: animation,
              child: ShoppingListItemTile(
                item: item,
                onTap: () => _showEditItemDialog(item),
                onUpdateQuantity: (quantity) =>
                    _updateItemQuantity(item, quantity),
                onDelete: () => _removeItem(item),
              ),
            ),
          ),
        );
        provider.updateList(widget.list);
      });
    }
  }

  void _updateItemQuantity(Item item, int quantity) {
    final provider = context.read<ShoppingListProvider>();
    setState(() {
      item.quantity = quantity;
      provider.updateList(widget.list);
    });
  }

  void _showEditItemDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(
        item: item,
        onSave: (name, price, quantity, unit) {
          final provider = context.read<ShoppingListProvider>();
          setState(() {
            item.name = name;
            item.price = price;
            item.quantity = quantity;
            item.unit = unit;
            provider.updateList(widget.list);
            if (price != null) {
              provider.addFrequentItem(item);
            }
          });
        },
      ),
    );
  }

  void _showEditListDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.list.name);
    final budgetController = TextEditingController(
      text: widget.list.budgetLimit?.toStringAsFixed(2) ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Editar Lista',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome da Lista',
                  prefixIcon: const Icon(Icons.shopping_basket),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira um nome para a lista';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: budgetController,
                decoration: InputDecoration(
                  labelText: 'Limite de Gastos (opcional)',
                  prefixIcon: const Icon(Icons.attach_money),
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final budget = double.tryParse(value.replaceAll(',', '.'));
                    if (budget == null || budget <= 0) {
                      return 'Por favor, insira um valor válido';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final provider = context.read<ShoppingListProvider>();
                final name = nameController.text.trim();
                double? budget;

                if (budgetController.text.isNotEmpty) {
                  budget = double.parse(
                    budgetController.text.replaceAll(',', '.'),
                  );
                }

                setState(() {
                  widget.list.name = name;
                  widget.list.budgetLimit = budget;
                  provider.updateList(widget.list);
                });

                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
