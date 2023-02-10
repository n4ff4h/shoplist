import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'item_model.freezed.dart';
part 'item_model.g.dart';

@freezed
abstract class Item implements _$Item {
  const Item._();

  const factory Item({
    // This is nullable because Firestore will generate an id for us and we don need it right of the bat.
    String? id,
    required String name,
    @Default(false) bool obtained,
  }) = _Item;

  factory Item.empty() => const Item(name: '');

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  factory Item.fromDocument(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return Item.fromJson(data).copyWith(id: snapshot.id);
  }

  Map<String, dynamic> toDocument() => toJson()..remove('id');
}
