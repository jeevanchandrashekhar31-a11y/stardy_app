import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/career_path_models.dart';
import '../repository/career_paths_repository.dart';

final careerPathDetailProvider = FutureProvider.family<CareerPathDetail, String>((ref, pathId) async {
  final repo = ref.watch(careerPathsRepositoryProvider);
  final res = await repo.getCareerPath(pathId);
  if (res is Ok<CareerPathDetail>) {
    return res.data;
  } else {
    throw (res as Err).error.message;
  }
});

final careerPathProjectProvider = FutureProvider.family<CareerPathProjectResponse, String>((ref, pathId) async {
  final repo = ref.watch(careerPathsRepositoryProvider);
  final res = await repo.getProject(pathId);
  if (res is Ok<CareerPathProjectResponse>) {
    return res.data;
  } else {
    throw (res as Err).error.message;
  }
});
