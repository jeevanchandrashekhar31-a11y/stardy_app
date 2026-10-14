import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/error_view.dart';
import 'package:uuid/uuid.dart';
import '../widgets/color_codes.dart';
import 'project_submission_page.dart';
import '../../features/career_paths/providers/career_paths_provider.dart';
import '../../features/career_paths/repository/career_paths_repository.dart';
import '../../features/career_paths/models/career_path_models.dart';
import '../../core/network/api_client.dart';

class ProjectAssignmentBriefPage extends ConsumerStatefulWidget {
  final String pathId;

  const ProjectAssignmentBriefPage({super.key, required this.pathId});

  @override
  ConsumerState<ProjectAssignmentBriefPage> createState() => _ProjectAssignmentBriefPageState();
}

class _ProjectAssignmentBriefPageState extends ConsumerState<ProjectAssignmentBriefPage> {
  bool _isGenerating = false;
  String? _idempotencyKey;

  void _generateProject() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _idempotencyKey ??= const Uuid().v4();
    });

    final repo = ref.read(careerPathsRepositoryProvider);
    final res = await repo.generateProject(widget.pathId, _idempotencyKey!);

    setState(() {
      _isGenerating = false;
    });

    if (res is Ok<CareerPathProjectResponse>) {
      ref.invalidate(careerPathProjectProvider(widget.pathId));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((res as Err).error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(careerPathProjectProvider(widget.pathId));

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/texture_dark_grid.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: projectAsync.when(
            data: (data) {
              if (data.project == null) {
                return _buildEmptyState(data);
              }
              return _buildProjectContent(data.project!);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, st) => ErrorView(
              message: safeErrorText(err),
              onRetry: () => ref.invalidate(careerPathProjectProvider(widget.pathId)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(CareerPathProjectResponse data) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white54, size: 64),
            const SizedBox(height: 24),
            if (!data.eligible) ...[
              Text(
                'Unlocks at 50% (you are at ${data.progress}%)',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ] else ...[
              const Text(
                'Ready for your project?',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isGenerating ? null : _generateProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isGenerating
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)),
                            SizedBox(width: 12),
                            Text('Generating AI Project...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : const Text(
                          'Generate my project',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectContent(ProjectDetail project) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            project.title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Project assignment',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
          const SizedBox(height: 28),
          const Icon(
            Icons.workspace_premium,
            color: AppColors.primary,
            size: 150,
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Project description'),
          const SizedBox(height: 10),
          Text(
            project.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          const _SectionTitle('Requirements'),
          const SizedBox(height: 14),
          _TwoColumnList(items: project.requirements),
          
          if (project.deliverables.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _SectionTitle('Deliverables'),
            const SizedBox(height: 14),
            _TwoColumnList(items: project.deliverables),
          ],

          if (project.stretchGoals.isNotEmpty) ...[
            const SizedBox(height: 28),
            const _SectionTitle('Stretch Goals'),
            const SizedBox(height: 14),
            _TwoColumnList(items: project.stretchGoals),
          ],
          
          const SizedBox(height: 32),
          if (project.submission != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Status: ${project.submission!.status}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProjectSubmissionPage(projectId: project.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Submit project',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _TwoColumnList extends StatelessWidget {
  final List<String> items;
  const _TwoColumnList({required this.items});

  @override
  Widget build(BuildContext context) {
    final left = <String>[];
    final right = <String>[];
    for (var i = 0; i < items.length; i++) {
      (i.isEven ? left : right).add(items[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (left.isNotEmpty) Expanded(child: _bulletColumn(left)),
        if (left.isNotEmpty && right.isNotEmpty) const SizedBox(width: 12),
        if (right.isNotEmpty) Expanded(child: _bulletColumn(right)),
      ],
    );
  }

  Widget _bulletColumn(List<String> texts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: texts
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '•  $t',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
