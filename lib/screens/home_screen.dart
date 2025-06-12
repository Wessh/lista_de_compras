import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_provider.dart';
import '../models/shopping_list.dart';
import 'shopping_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Listas de Compras')),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.lists.length,
            itemBuilder: (context, index) {
              final list = provider.lists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(list.name),
                  subtitle: Text(
                    'Total: R\$ ${list.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: list.isOverBudget ? Colors.red : Colors.white70,
                    ),
                  ),
                  trailing: list.budgetLimit != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Limite: R\$ ${list.budgetLimit!.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Restante: R\$ ${list.remainingBudget.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: list.isOverBudget
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShoppingListScreen(list: list),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewListDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNewListDialog(BuildContext context) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Lista de Compras'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da Lista',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: budgetController,
              decoration: const InputDecoration(
                labelText: 'Limite de Gastos (opcional)',
                border: OutlineInputBorder(),
                prefixText: 'R\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
              if (nameController.text.isNotEmpty) {
                final budget = budgetController.text.isNotEmpty
                    ? double.tryParse(
                        budgetController.text.replaceAll(',', '.'),
                      )
                    : null;

                final newList = ShoppingList(
                  name: nameController.text,
                  budgetLimit: budget,
                );

                context.read<ShoppingListProvider>().addList(newList);
                Navigator.pop(context);
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}
