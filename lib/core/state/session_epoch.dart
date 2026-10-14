import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An epoch counter that increments whenever a user signs out.
/// Watching this provider ensures that providers caching user-specific data
/// (like ApiClient or repositories) will be destroyed and recreated when
/// the session changes, preventing cross-user data leaks.
final sessionEpochProvider = StateProvider<int>((ref) => 0);
