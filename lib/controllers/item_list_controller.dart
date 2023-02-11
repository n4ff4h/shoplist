import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoplist/controllers/auth_controller.dart';
import 'package:shoplist/models/item_model.dart';
import 'package:shoplist/repositories/custom_exception.dart';
import 'package:shoplist/repositories/item_repository.dart';

final itemListExceptionProvider = StateProvider<CustomException?>((_) => null);

final itemListControllerProvider =
    StateNotifierProvider<ItemListController, AsyncValue<List<Item>>>((ref) {
  final user = ref.watch(authControllerProvider);
  return ItemListController(ref, user?.uid);
});

class ItemListController extends StateNotifier<AsyncValue<List<Item>>> {
  final Ref _ref;
  final String? _userId;

  ItemListController(this._ref, this._userId)
      : super(const AsyncValue.loading()) {
    if (_userId != null) {
      retrieveItems();
    }
  }

  Future<void> retrieveItems({bool isRefreshing = false}) async {
    try {
      if (isRefreshing) state = const AsyncValue.loading();
      final items = await _ref
          .read(itemRepositoryProvider)
          .retrieveItems(userId: _userId!);

      // If the widget tree that the ItemListController is associated with is still attached to the tree.
      if (mounted) {
        state = AsyncValue.data(items);
      }
    } on CustomException catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem({required String name, bool obtained = false}) async {
    try {
      final item = Item(name: name, obtained: obtained);
      final itemId = await _ref
          .read(itemRepositoryProvider)
          .createItem(userId: _userId!, item: item);

      // Only update state when data is available.
      state.whenData((items) =>
          state = AsyncValue.data(items..add(item.copyWith(id: itemId))));
    } on CustomException catch (e) {
      _ref.read(itemListExceptionProvider.notifier).state = e;
    }
  }

  Future<void> updateItem({required Item updatedItem}) async {
    try {
      await _ref
          .read(itemRepositoryProvider)
          .updateItem(userId: _userId!, item: updatedItem);

      // Only update state when data is available.
      state.whenData((items) {
        state = AsyncData([
          for (final item in items)
            item.id == updatedItem.id ? updatedItem : item
        ]);
      });
    } on CustomException catch (e) {
      _ref.read(itemListExceptionProvider.notifier).state = e;
    }
  }

  Future<void> deleteItem({required String itemId}) async {
    try {
      await _ref
          .read(itemRepositoryProvider)
          .deleteItem(userId: _userId!, itemId: itemId);

      // Only update state when data is available.
      state.whenData((items) => state =
          AsyncValue.data(items..removeWhere((item) => item.id == itemId)));
    } on CustomException catch (e) {
      _ref.read(itemListExceptionProvider.notifier).state = e;
    }
  }
}
