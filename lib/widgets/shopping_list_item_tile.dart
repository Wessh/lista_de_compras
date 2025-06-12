import 'package:flutter/material.dart';
import '../models/item.dart';

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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: item.quantity > 1
                            ? () => onUpdateQuantity(item.quantity - 1)
                            : null,
                      ),
                      Text(
                        item.unit != null
                            ? '${item.quantity} ${item.unit}'
                            : '${item.quantity}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => onUpdateQuantity(item.quantity + 1),
                      ),
                    ],
                  ),
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
