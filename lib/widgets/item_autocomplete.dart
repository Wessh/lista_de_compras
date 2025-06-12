import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../providers/shopping_list_provider.dart';

class ItemAutoComplete extends StatefulWidget {
  final void Function(Item) onItemSelected;
  final void Function(String) onItemSubmitted;
  final void Function(TextEditingController)? onControllerCreated;

  const ItemAutoComplete({
    super.key,
    required this.onItemSelected,
    required this.onItemSubmitted,
    this.onControllerCreated,
  });

  @override
  State<ItemAutoComplete> createState() => _ItemAutoCompleteState();
}

class _ItemAutoCompleteState extends State<ItemAutoComplete> {
  @override
  Widget build(BuildContext context) {
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
              if (itemName.contains(query)) return true;
              return queryWords.every((word) => itemName.contains(word));
            }).toList()..sort((a, b) {
              final aName = a.name.toLowerCase();
              final bName = b.name.toLowerCase();
              if (aName.startsWith(query) && !bName.startsWith(query)) {
                return -1;
              }
              if (!aName.startsWith(query) && bName.startsWith(query)) return 1;
              if (aName.contains(query) && !bName.contains(query)) return -1;
              if (!aName.contains(query) && bName.contains(query)) return 1;
              return aName.compareTo(bName);
            });
          },
          displayStringForOption: (Item item) => item.name,
          onSelected: widget.onItemSelected,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            if (widget.onControllerCreated != null) {
              widget.onControllerCreated!(controller);
            }
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Adicionar item...',
                prefixIcon: const Icon(Icons.add_shopping_cart),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          focusNode.requestFocus();
                        },
                      )
                    : null,
              ),
              onSubmitted: widget.onItemSubmitted,
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            if (options.isEmpty) {
              return const SizedBox.shrink();
            }

            return _buildOptionsContainer(context, options, onSelected);
          },
        );
      },
    );
  }

  Widget _buildOptionsContainer(
    BuildContext context,
    Iterable<Item> options,
    AutocompleteOnSelected<Item> onSelected,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        shadowColor: Colors.black26,
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: _buildOptionsList(context, options, onSelected),
        ),
      ),
    );
  }

  Widget _buildOptionsList(
    BuildContext context,
    Iterable<Item> options,
    AutocompleteOnSelected<Item> onSelected,
  ) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: options.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.shade800),
      itemBuilder: (_, index) {
        final option = options.elementAt(index);
        return _buildOptionItem(context, option, onSelected);
      },
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    Item option,
    AutocompleteOnSelected<Item> onSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSelected(option),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildItemIcon(context),
              const SizedBox(width: 12),
              _buildItemInfo(context, option),
              const Icon(Icons.add_circle_outline, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.shopping_bag_outlined,
        color: Theme.of(context).colorScheme.primary,
        size: 20,
      ),
    );
  }

  Widget _buildItemInfo(BuildContext context, Item option) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            option.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (option.price != null)
            Text(
              'R\$ ${option.price!.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
