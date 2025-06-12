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
  final TextEditingController _itemController = TextEditingController();
  final FocusNode _itemFocusNode = FocusNode();

  @override
  void dispose() {
    _itemController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Excluir Lista'),
                  content: const Text(
                    'Tem certeza que deseja excluir esta lista?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<ShoppingListProvider>().deleteList(
                          widget.list,
                        );
                        Navigator.pop(context); // Fecha o diálogo
                        Navigator.pop(context); // Volta para a tela anterior
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              if (widget.list.budgetLimit != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey.shade800,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Limite: R\$ ${widget.list.budgetLimit!.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Restante: R\$ ${widget.list.remainingBudget.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.list.isOverBudget
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Total: R\$ ${widget.list.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Autocomplete<Item>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Item>.empty();
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return provider.frequentItems.where((item) {
                      final itemName = item.name.toLowerCase();
                      // Verifica se o nome do item começa com o texto digitado
                      if (itemName.startsWith(query)) return true;

                      // Verifica se todas as palavras digitadas estão contidas no nome do item
                      final queryWords = query.split(' ');
                      return queryWords.every(
                        (word) => itemName.contains(word),
                      );
                    });
                  },
                  displayStringForOption: (item) => item.name,
                  onSelected: (Item item) {
                    _addOrUpdateItem(context, item);
                    _itemController.clear();
                    _itemFocusNode.requestFocus();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: 'Adicionar item',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                if (controller.text.isNotEmpty) {
                                  _showPriceDialog(context, controller.text);
                                  controller.clear();
                                }
                              },
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _showPriceDialog(context, value);
                              controller.clear();
                            }
                          },
                        );
                      },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.list.items.length,
                  itemBuilder: (context, index) {
                    final item = widget.list.items[index];
                    return Card(
                      child: ListTile(
                        title: Text(item.name),
                        subtitle: item.price != null
                            ? Text('R\$ ${item.total.toStringAsFixed(2)}')
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  final updatedItem = item.copyWith(
                                    quantity: item.quantity - 1,
                                  );
                                  provider.updateItem(
                                    widget.list,
                                    item,
                                    updatedItem,
                                  );
                                } else {
                                  provider.removeItem(widget.list, item);
                                }
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                final updatedItem = item.copyWith(
                                  quantity: item.quantity + 1,
                                );
                                provider.updateItem(
                                  widget.list,
                                  item,
                                  updatedItem,
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () => _showPriceDialog(
                          context,
                          item.name,
                          existingItem: item,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPriceDialog(
    BuildContext context,
    String itemName, {
    Item? existingItem,
  }) {
    final priceController = TextEditingController(
      text: existingItem?.price?.toStringAsFixed(2) ?? '',
    );
    final quantityController = TextEditingController(
      text: existingItem?.quantity.toString() ?? '1',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existingItem != null ? 'Editar Item' : 'Adicionar Preço'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Preço Unitário',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantidade',
                border: OutlineInputBorder(),
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
          TextButton(
            onPressed: () {
              final price = priceController.text.isNotEmpty
                  ? double.tryParse(priceController.text.replaceAll(',', '.'))
                  : null;
              final quantity = int.tryParse(quantityController.text) ?? 1;

              final item = Item(
                id: existingItem?.id,
                name: itemName,
                price: price,
                quantity: quantity,
                isFrequent: true,
              );

              if (existingItem != null) {
                context.read<ShoppingListProvider>().updateItem(
                  widget.list,
                  existingItem,
                  item,
                );
              } else {
                _addOrUpdateItem(context, item);
              }

              Navigator.pop(context);
            },
            child: Text(existingItem != null ? 'Salvar' : 'Adicionar'),
          ),
        ],
      ),
    );
  }

  void _addOrUpdateItem(BuildContext context, Item newItem) {
    final provider = context.read<ShoppingListProvider>();
    final existingItem = widget.list.items
        .where((item) => item.name.toLowerCase() == newItem.name.toLowerCase())
        .firstOrNull;

    if (existingItem != null) {
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + (newItem.quantity),
        price: newItem.price ?? existingItem.price,
      );
      provider.updateItem(widget.list, existingItem, updatedItem);
    } else {
      provider.addItemToList(widget.list, newItem);
    }
  }
}
