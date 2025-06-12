import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'item.g.dart';

@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  double? price;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  bool isFrequent;

  @HiveField(5)
  String? unit;

  Item({
    String? id,
    required this.name,
    this.price,
    this.quantity = 1,
    this.isFrequent = false,
    this.unit,
  }) : id = id ?? const Uuid().v4();

  double get total => (price ?? 0) * quantity;

  Item copyWith({
    String? name,
    double? price,
    int? quantity,
    bool? isFrequent,
    String? unit,
  }) {
    return Item(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isFrequent: isFrequent ?? this.isFrequent,
      unit: unit ?? this.unit,
    );
  }
}
