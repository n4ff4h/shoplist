import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoplist/controllers/auth_controller.dart';
import 'package:shoplist/controllers/item_list_controller.dart';
import 'package:shoplist/models/item_model.dart';
import 'package:shoplist/repositories/custom_exception.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(
    child: ShoplistApp(),
  ));
}

class ShoplistApp extends StatelessWidget {
  const ShoplistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shoplist',
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authControllerState = ref.watch(authControllerProvider);

    ref.listen<CustomException?>(
      itemListExceptionProvider,
      (prevException, newException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(newException!.message!),
          ),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        leading: authControllerState != null
            ? IconButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout),
              )
            : null,
      ),
      body: const ItemList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddItemDialog.show(context, Item.empty()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ItemList extends HookConsumerWidget {
  const ItemList({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemList = ref.watch(itemListControllerProvider);

    return itemList.when(
      data: (items) => items.isEmpty
          ? const Center(
              child: Text(
                'Tap + to add an item',
                style: TextStyle(fontSize: 22.0),
              ),
            )
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (BuildContext context, int index) {
                final item = items[index];

                return ListTile(
                  // Key used here to ensure check box animation does not rebuild when the list updates.
                  key: ValueKey(item.id),
                  title: Text(item.name),
                  trailing: Checkbox(
                    value: item.obtained,
                    onChanged: (val) => ref
                        .read(itemListControllerProvider.notifier)
                        .updateItem(
                            updatedItem:
                                item.copyWith(obtained: !item.obtained)),
                  ),
                  onTap: () => AddItemDialog.show(context, item),
                  onLongPress: () => ref
                      .read(itemListControllerProvider.notifier)
                      .deleteItem(itemId: item.id!),
                );
              },
            ),
      error: (error, _) => ItemListError(
        message:
            error is CustomException ? error.message! : 'Something went wrong!',
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class ItemListError extends HookConsumerWidget {
  final String message;

  const ItemListError({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 20.0),
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: () => ref
                .read(itemListControllerProvider.notifier)
                .retrieveItems(isRefreshing: true),
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }
}

class AddItemDialog extends HookConsumerWidget {
  final Item item;

  const AddItemDialog({super.key, required this.item});

  bool get isUpdating => item.id != null;

  static void show(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(item: item),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = useTextEditingController(text: item.name);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Item name'),
            ),
            const SizedBox(height: 12.0),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUpdating
                      ? Colors.orange
                      : Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  isUpdating
                      ? ref
                          .read(itemListControllerProvider.notifier)
                          .updateItem(
                            updatedItem: item.copyWith(
                              name: textController.text.trim(),
                              obtained: item.obtained,
                            ),
                          )
                      : ref
                          .read(itemListControllerProvider.notifier)
                          .addItem(name: textController.text.trim());

                  Navigator.of(context).pop();
                },
                child: Text(isUpdating ? 'Update' : 'Add'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
