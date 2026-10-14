class Page<T> {
  final List<T> items;
  final String? nextCursor;

  const Page({required this.items, this.nextCursor});

  factory Page.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    if (json['items'] is! List) {
      throw const FormatException('items is not a list');
    }

    final itemsList = json['items'] as List;
    final parsedItems = <T>[];

    for (var item in itemsList) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('item is not a Map<String, dynamic>');
      }
      parsedItems.add(fromJsonT(item));
    }

    String? cursor;
    if (json.containsKey('nextCursor') && json['nextCursor'] != null) {
      if (json['nextCursor'] is String) {
        cursor = json['nextCursor'] as String;
      } else {
        throw const FormatException('nextCursor is not a string');
      }
    }

    return Page<T>(items: parsedItems, nextCursor: cursor);
  }
}
