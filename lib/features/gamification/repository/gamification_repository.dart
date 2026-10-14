import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../dto/gamification_me_dto.dart';
import '../dto/gamification_badge_dto.dart';
import '../dto/certificate_dto.dart';
import '../../../core/models/page.dart' as model;
import '../../../core/state/paged_notifier.dart';
import '../../profile/repository/profile_repository.dart';

import '../../dashboard/repository/dashboard_repository.dart';

import '../../grades/providers/grades_provider.dart';
import '../../../core/data/ttl_cache.dart';
final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return GamificationRepository(apiClient);
});

final gamificationProvider = FutureProvider.autoDispose<GamificationMeDto>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);

  ref.cacheFor(const Duration(seconds: 30));

  final result = await repo.getMe();
  if (result is Ok<GamificationMeDto>) {
    return result.data;
  } else {
    throw (result as Err).error;
  }
});

final badgesProvider = FutureProvider.autoDispose<List<GamificationBadgeDto>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);

  ref.cacheFor(const Duration(seconds: 30));

  final result = await repo.getBadges();
  if (result is Ok<List<GamificationBadgeDto>>) {
    return result.data;
  } else {
    throw (result as Err).error;
  }
});

class CertificatesNotifier extends PagedNotifier<CertificateDto> {
  final GamificationRepository repo;

  CertificatesNotifier(this.repo) {
    loadFirst();
  }

  @override
  Future<model.Page<CertificateDto>> fetchPage({String? cursor, int limit = 20}) async {
    final result = await repo.getCertificates(cursor: cursor, limit: limit);
    if (result is Ok<model.Page<CertificateDto>>) {
      return result.data;
    } else {
      throw (result as Err).error;
    }
  }
}

final certificatesProvider = StateNotifierProvider.autoDispose<CertificatesNotifier, PagedState<CertificateDto>>((ref) {
  final repo = ref.watch(gamificationRepositoryProvider);
  return CertificatesNotifier(repo);
});

void invalidateAfterProgress(void Function(ProviderOrFamily) invalidate) {
  invalidate(gamificationProvider);
  invalidate(meProvider);
  invalidate(homeProvider);
  invalidate(gradesProvider);
  invalidate(badgesProvider);
  invalidate(certificatesProvider);
}

class GamificationRepository {
  final ApiClient _apiClient;

  GamificationRepository(this._apiClient);

  Future<Result<GamificationMeDto>> getMe() async {
    final res = await _apiClient.get<Map<String, dynamic>>('/gamification/me');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final dto = GamificationMeDto.fromJson(res.data);
        return Ok(dto);
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse gamification data'));
      }
    } else {
      return Err((res as Err).error);
    }
  }

  Future<Result<List<GamificationBadgeDto>>> getBadges() async {
    final res = await _apiClient.get<Map<String, dynamic>>('/gamification/badges');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final list = res.data['items'] as List<dynamic>;
        final dtos = list.map((e) => GamificationBadgeDto.fromJson(e)).toList();
        return Ok(dtos);
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse badges data'));
      }
    } else {
      return res as Err<List<GamificationBadgeDto>>;
    }
  }

  Future<Result<model.Page<CertificateDto>>> getCertificates({String? cursor, int limit = 20}) async {
    final q = <String>[];
    if (cursor != null) q.add('cursor=$cursor');
    if (limit > 0) q.add('limit=$limit');
    final queryStr = q.isNotEmpty ? '?${q.join('&')}' : '';

    final res = await _apiClient.get<Map<String, dynamic>>('/certificates$queryStr');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final list = res.data['items'] as List<dynamic>;
        final dtos = list.map((e) => CertificateDto.fromJson(e)).toList();
        final nextCursor = res.data['nextCursor'] as String?;
        return Ok(model.Page<CertificateDto>(items: dtos, nextCursor: nextCursor));
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse certificates data'));
      }
    } else {
      return res as Err<model.Page<CertificateDto>>;
    }
  }
}
