import 'package:flutter/material.dart';
import '../models/item.dart';

class EditItemDialog extends StatefulWidget {
  final Item item;
  final Function(String name, double? price, int quantity, String? unit) onSave;

  const EditItemDialog({super.key, required this.item, required this.onSave});

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late final TextEditingController nameController;
  late final TextEditingController priceController;
  late final TextEditingController quantityController;
  String? selectedUnit;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item.name);
    priceController = TextEditingController(
      text: widget.item.price?.toString() ?? '',
    );
    quantityController = TextEditingController(
      text: widget.item.quantity.toString(),
    );
    selectedUnit = widget.item.unit;
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
          _buildNameField(),
          const SizedBox(height: 16),
          _buildPriceField(),
          const SizedBox(height: 16),
          _buildQuantityAndUnitRow(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _saveChanges, child: const Text('Salvar')),
      ],
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: nameController,
      decoration: InputDecoration(
        labelText: 'Nome do Item',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textCapitalization: TextCapitalization.sentences,
    );
  }

  Widget _buildPriceField() {
    return TextField(
      controller: priceController,
      decoration: InputDecoration(
        labelText: 'Preço Unitário',
        prefixText: 'R\$ ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildQuantityAndUnitRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: quantityController,
            decoration: InputDecoration(
              labelText: 'Quantidade',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: _buildUnitDropdown()),
      ],
    );
  }

  Widget _buildUnitDropdown() {
    final units = ['kg', 'g', 'L', 'ml', 'un'];

    return DropdownButtonFormField<String>(
      value: selectedUnit,
      decoration: InputDecoration(
        labelText: 'Unidade',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Selecionar')),
        ...units.map(
          (unit) => DropdownMenuItem(value: unit, child: Text(unit)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          selectedUnit = value;
        });
      },
    );
  }

  void _saveChanges() {
    final name = nameController.text.trim();
    if (name.isEmpty) return;

    final price = double.tryParse(priceController.text.replaceAll(',', '.'));
    final quantity = int.tryParse(quantityController.text) ?? 1;

    widget.onSave(name, price, quantity, selectedUnit);
    Navigator.pop(context);
  }
}
