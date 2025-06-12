import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/item.dart';
import '../models/shopping_list.dart';

class ShoppingListProvider with ChangeNotifier {
  List<ShoppingList> _lists = [];
  List<Item> _frequentItems = [];
  Box<ShoppingList>? _listsBox;
  Box<Item>? _frequentItemsBox;

  List<ShoppingList> get lists => _lists;
  List<Item> get frequentItems => _frequentItems;

  Future<void> init() async {
    _listsBox = await Hive.openBox<ShoppingList>('shopping_lists');
    _frequentItemsBox = await Hive.openBox<Item>('frequent_items');
    _lists = _listsBox!.values.toList();
    _frequentItems = _frequentItemsBox!.values.toList();
    notifyListeners();
  }

  Future<void> addList(ShoppingList list) async {
    await _listsBox?.add(list);
    _lists.add(list);
    notifyListeners();
  }

  Future<void> updateList(ShoppingList list) async {
    final index = _lists.indexWhere((l) => l.id == list.id);
    if (index != -1) {
      await list.save();
      _lists[index] = list;
      notifyListeners();
    }
  }

  Future<void> deleteList(ShoppingList list) async {
    await list.delete();
    _lists.removeWhere((l) => l.id == list.id);
    notifyListeners();
  }

  Future<void> addItemToList(ShoppingList list, Item item) async {
    list.items.add(item);
    await updateList(list);
    if (!_frequentItems.any(
      (i) => i.name.toLowerCase() == item.name.toLowerCase(),
    )) {
      final frequentItem = item.copyWith(isFrequent: true);
      await _frequentItemsBox?.add(frequentItem);
      _frequentItems.add(frequentItem);
    }
  }

  Future<void> updateItem(ShoppingList list, Item oldItem, Item newItem) async {
    final index = list.items.indexWhere((i) => i.id == oldItem.id);
    if (index != -1) {
      list.items[index] = newItem;
      await updateList(list);
    }
  }

  Future<void> removeItem(ShoppingList list, Item item) async {
    list.items.removeWhere((i) => i.id == item.id);
    await updateList(list);
  }

  Future<void> addFrequentItem(Item item) async {
    final existingItem = _frequentItems.firstWhere(
      (i) => i.name.toLowerCase() == item.name.toLowerCase(),
      orElse: () => Item(name: '', id: ''),
    );

    if (existingItem.name.isEmpty) {
      final newItem = Item(name: item.name, price: item.price, quantity: 1);
      await _frequentItemsBox?.add(newItem);
      _frequentItems.add(newItem);
      notifyListeners();
    } else if (existingItem.price != item.price) {
      existingItem.price = item.price;
      await existingItem.save();
      notifyListeners();
    }
  }
}
