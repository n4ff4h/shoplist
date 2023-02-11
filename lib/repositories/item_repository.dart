import 'package:firebase_core/firebase_core.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shoplist/extensions/firebase_firestore_extension.dart';
import 'package:shoplist/general_providers.dart';
import 'package:shoplist/models/item_model.dart';
import 'package:shoplist/repositories/custom_exception.dart';

abstract class BaseItemRepository {
  Future<List<Item>> retrieveItems({required String userId});
  // Returns the id of the created item in Firestore collection.
  Future<String> createItem({required String userId, required Item item});
  Future<void> updateItem({required String userId, required Item item});
  Future<void> deleteItem({required String userId, required String itemId});
}

final itemRepositoryProvider =
    Provider<ItemRepository>((ref) => ItemRepository(ref));

class ItemRepository implements BaseItemRepository {
  final Ref _ref;

  ItemRepository(this._ref);

  @override
  Future<List<Item>> retrieveItems({required String userId}) async {
    try {
      final snapshot =
          await _ref.read(firebaseFirestoreProvider).usersListRef(userId).get();
      return snapshot.docs.map((doc) => Item.fromDocument(doc)).toList();
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<String> createItem(
      {required String userId, required Item item}) async {
    try {
      final docRef = await _ref
          .read(firebaseFirestoreProvider)
          .usersListRef(userId)
          .add(item.toDocument());
      return docRef.id;
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<void> updateItem({required String userId, required Item item}) async {
    try {
      await _ref
          .read(firebaseFirestoreProvider)
          .usersListRef(userId)
          .doc(item.id)
          .update(item.toDocument());
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<void> deleteItem(
      {required String userId, required String itemId}) async {
    try {
      await _ref
          .read(firebaseFirestoreProvider)
          .usersListRef(userId)
          .doc(itemId)
          .delete();
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }
}
