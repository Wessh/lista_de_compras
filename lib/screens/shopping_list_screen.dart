import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/shopping_list.dart';
import '../providers/shopping_list_provider.dart';

class ShoppingListScreen extends StatefulWidget {
  final ShoppingList list;

  const ShoppingListScreen({super.key, required this.list});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  TextEditingController _itemController = TextEditingController();
  FocusNode _itemFocusNode = FocusNode();

  @override
  void dispose() {
    _itemController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAddItemField() {
    return Consumer<ShoppingListProvider>(
      builder: (context, provider, _) {
        return Autocomplete<Item>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Item>.empty();
            }
            final query = textEditingValue.text.toLowerCase();
            return provider.frequentItems.where((item) {
              final itemName = item.name.toLowerCase();
              if (itemName.startsWith(query)) return true;
              final queryWords = query.split(' ');
              return queryWords.every((word) => itemName.contains(word));
            });
          },
          displayStringForOption: (Item item) => item.name,
          onSelected: (Item selectedItem) {
            final existingItem = widget.list.items.firstWhere(
              (item) =>
                  item.name.toLowerCase() == selectedItem.name.toLowerCase(),
              orElse: () => Item(name: '', id: ''),
            );

            if (existingItem.name.isNotEmpty) {
              _updateItemQuantity(existingItem, existingItem.quantity + 1);
            } else {
              final newItem = Item(
                name: selectedItem.name,
                price: selectedItem.price,
                quantity: 1,
              );
              setState(() {
                widget.list.items.add(newItem);
                final provider = context.read<ShoppingListProvider>();
                provider.updateList(widget.list);
              });
            }
            _itemController.clear();
            _itemFocusNode.requestFocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            _itemController = controller;
            _itemFocusNode = focusNode;
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Adicionar item...',
                prefixIcon: const Icon(Icons.add_shopping_cart),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  _addItem();
                }
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        title: Text(option.name),
                        subtitle: option.price != null
                            ? Text(
                                'R\$ ${option.price!.toStringAsFixed(2)}',
                                style: TextStyle(color: Colors.grey.shade400),
                              )
                            : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'list_${widget.list.id}',
      child: Scaffold(
        appBar: AppBar(title: Text(widget.list.name), elevation: 0),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total da Lista',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'R\$ ${widget.list.total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: widget.list.isOverBudget
                                  ? Colors.red.shade300
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (widget.list.budgetLimit != null) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Disponível',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'R\$ ${widget.list.remainingBudget.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: widget.list.isOverBudget
                                    ? Colors.red.shade300
                                    : Colors.green.shade300,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (widget.list.budgetLimit != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: widget.list.total / widget.list.budgetLimit!,
                        backgroundColor: Colors.grey.shade800,
                        valueColor: AlwaysStoppedAnimation(
                          widget.list.isOverBudget
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Consumer<ShoppingListProvider>(
                builder: (context, provider, child) {
                  final items = widget.list.items;
                  if (items.isEmpty) {
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
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicione itens usando o campo abaixo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return AnimatedList(
                    padding: const EdgeInsets.all(16),
                    initialItemCount: items.length,
                    itemBuilder: (context, index, animation) {
                      final item = items[index];
                      return SlideTransition(
                        position: animation.drive(
                          Tween(
                            begin: const Offset(1, 0),
                            end: const Offset(0, 0),
                          ),
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: _buildAddItemField()),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addItem() {
    final name = _itemController.text.trim();
    if (name.isEmpty) return;

    final existingItem = widget.list.items.firstWhere(
      (item) => item.name.toLowerCase() == name.toLowerCase(),
      orElse: () => Item(name: '', id: ''),
    );

    if (existingItem.name.isNotEmpty) {
      _updateItemQuantity(existingItem, existingItem.quantity + 1);
    } else {
      _showPriceAndQuantityDialog(name);
    }

    _itemController.clear();
    _itemFocusNode.requestFocus();
  }

  void _removeItem(Item item) {
    final provider = context.read<ShoppingListProvider>();
    setState(() {
      widget.list.items.remove(item);
      provider.updateList(widget.list);
    });
  }

  void _updateItemQuantity(Item item, int quantity) {
    final provider = context.read<ShoppingListProvider>();
    setState(() {
      item.quantity = quantity;
      provider.updateList(widget.list);
    });
  }

  void _showPriceAndQuantityDialog(String name) {
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Detalhes do Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Preço Unitário',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final price = double.tryParse(
                priceController.text.replaceAll(',', '.'),
              );
              final quantity = int.tryParse(quantityController.text) ?? 1;

              final provider = context.read<ShoppingListProvider>();
              final item = Item(name: name, price: price, quantity: quantity);

              setState(() {
                widget.list.items.add(item);
                if (price != null) {
                  provider.addFrequentItem(item);
                }
                provider.updateList(widget.list);
              });

              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(Item item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(
      text: item.price?.toString() ?? '',
    );
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Editar Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nome do Item',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Preço Unitário',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              final price = double.tryParse(
                priceController.text.replaceAll(',', '.'),
              );
              final quantity = int.tryParse(quantityController.text) ?? 1;

              final provider = context.read<ShoppingListProvider>();
              setState(() {
                item.name = name;
                item.price = price;
                item.quantity = quantity;
                provider.updateList(widget.list);
                if (price != null) {
                  provider.addFrequentItem(item);
                }
              });

              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class ShoppingListItemTile extends StatelessWidget {
  final Item item;
  final VoidCallback? onTap;
  final Function(int) onUpdateQuantity;
  final VoidCallback onDelete;

  const ShoppingListItemTile({
    super.key,
    required this.item,
    this.onTap,
    required this.onUpdateQuantity,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Dismissible(
              key: Key(item.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                color: Colors.red.shade300,
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (_) => onDelete(),
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: item.price != null
                      ? Text(
                          'R\$ ${(item.price! * item.quantity).toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.grey.shade400),
                        )
                      : null,
                  trailing: item.price != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: item.quantity > 1
                                  ? () => onUpdateQuantity(item.quantity - 1)
                                  : null,
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  onUpdateQuantity(item.quantity + 1),
                            ),
                          ],
                        )
                      : null,
                  onTap: onTap,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
