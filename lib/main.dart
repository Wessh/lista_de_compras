import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/item.dart';
import 'models/shopping_list.dart';
import 'providers/shopping_list_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(ShoppingListAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShoppingListProvider()..init(),
      child: MaterialApp(
        title: 'Lista de Compras',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.dark(
            primary: Colors.orange,
            secondary: Colors.orange.shade300,
            surface: Colors.grey.shade900,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey.shade900,
            foregroundColor: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.grey.shade900,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
          cardTheme: CardThemeData(color: Colors.grey.shade800),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
