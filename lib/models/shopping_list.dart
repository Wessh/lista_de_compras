import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'item.dart';

part 'shopping_list.g.dart';

@HiveType(typeId: 1)
class ShoppingList extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<Item> items;

  @HiveField(3)
  double? budgetLimit;

  ShoppingList({
    String? id,
    required this.name,
    List<Item>? items,
    this.budgetLimit,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [];

  double get total => items.fold(0, (sum, item) => sum + item.total);
  
  double get remainingBudget => (budgetLimit ?? double.infinity) - total;

  bool get isOverBudget => budgetLimit != null && total > budgetLimit!;
}
