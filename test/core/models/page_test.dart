import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/models/page.dart' as model;

class DummyItem {
  final String id;
  DummyItem(this.id);
  factory DummyItem.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String) throw const FormatException('id is not string');
    return DummyItem(json['id'] as String);
  }
}

void main() {
  group('Page model', () {
    test('valid parses correctly', () {
      final json = {
        'items': [
          {'id': '1'},
          {'id': '2'},
        ],
        'nextCursor': 'abc',
      };
      final page = model.Page.fromJson(json, DummyItem.fromJson);
      expect(page.items.length, 2);
      expect(page.items[0].id, '1');
      expect(page.nextCursor, 'abc');
    });

    test('missing nextCursor parsed as null', () {
      final json = {
        'items': [
          {'id': '1'},
        ],
      };
      final page = model.Page.fromJson(json, DummyItem.fromJson);
      expect(page.items.length, 1);
      expect(page.nextCursor, isNull);
    });

    test('items not a list throws FormatException', () {
      final json = {'items': 'not a list'};
      expect(
        () => model.Page.fromJson(json, DummyItem.fromJson),
        throwsFormatException,
      );
    });

    test('item with wrong type throws FormatException', () {
      final json = {
        'items': ['not a map'],
      };
      expect(
        () => model.Page.fromJson(json, DummyItem.fromJson),
        throwsFormatException,
      );
    });

    test('item fields wrong type throws FormatException', () {
      final json = {
        'items': [
          {'id': 123}, // expected string
        ],
      };
      expect(
        () => model.Page.fromJson(json, DummyItem.fromJson),
        throwsFormatException,
      );
    });
  });
}
