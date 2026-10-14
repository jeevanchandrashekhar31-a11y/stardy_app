import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/color_codes.dart';
import '../../../core/url/safe_launcher.dart';
import '../../../core/ui/error_view.dart';
import '../../../features/courses/repository/course_repository.dart';
import '../../../features/courses/models/course_enums.dart';

class ResourcesPage extends ConsumerWidget {
  final String courseId;

  const ResourcesPage({super.key, required this.courseId});

  Future<void> _openUrl(BuildContext context, String url) async {
    await SafeLauncher.launchSafe(context, url);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resourcesState = ref.watch(resourcesProvider(courseId));

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: resourcesState.when(
        data: (resources) {
          if (resources.isEmpty) {
            return const Center(child: Text('No resources available.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: resources.length,
            separatorBuilder: (context, index) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final resource = resources[index];
              final isFile = resource.type == ResourceType.file;
              final icon = isFile ? Icons.insert_drive_file : Icons.link;
              
              return GestureDetector(
                onTap: () => _openUrl(context, resource.url),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 65,
                        width: 65,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          icon,
                          color: AppColors.primary,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resource.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (resource.author != null) ...[
                              const SizedBox(height: 8),
                              Text(resource.author!, style: const TextStyle(color: Colors.grey)),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 20),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorView(
          message: safeErrorText(err),
          onRetry: () => ref.invalidate(resourcesProvider(courseId)),
        ),
      ),
    );
  }
}
