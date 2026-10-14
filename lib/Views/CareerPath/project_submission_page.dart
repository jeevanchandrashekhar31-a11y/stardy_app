import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../widgets/color_codes.dart';
import 'submission_received_page.dart';
import '../../core/upload/upload_service.dart';
import '../../core/network/api_client.dart';
import '../../features/career_paths/repository/career_paths_repository.dart';
import '../../core/models/gamification_result.dart';

class ProjectSubmissionPage extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectSubmissionPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectSubmissionPage> createState() => _ProjectSubmissionPageState();
}

class _ProjectSubmissionPageState extends ConsumerState<ProjectSubmissionPage> {
  final TextEditingController _linkController = TextEditingController();
  PlatformFile? _attachedFile;
  
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _idempotencyKey;
  CancellationToken? _cancelToken;

  @override
  void dispose() {
    _linkController.dispose();
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _pasteLink() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      setState(() => _linkController.text = data!.text!);
    }
  }

  Future<void> _browseFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'zip', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _attachedFile = result.files.first;
        _errorMessage = null;
      });
    }
  }

  bool _validateLink(String link) {
    if (link.isEmpty) return true; // valid if empty, since it's optional
    if (link.length > 500) {
      _errorMessage = 'Link must be 500 characters or less';
      return false;
    }
    final uri = Uri.tryParse(link);
    if (uri == null || uri.host.isEmpty || uri.scheme != 'https') {
      _errorMessage = 'Must be a valid https:// URL';
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final link = _linkController.text.trim();
    if (link.isEmpty && _attachedFile == null) {
      setState(() => _errorMessage = 'Attach a file or add a link before submitting');
      return;
    }

    if (!_validateLink(link)) {
      setState(() {});
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _idempotencyKey ??= const Uuid().v4();
    });

    String? objectKey;
    if (_attachedFile != null) {
      _cancelToken = CancellationToken();
      final uploadService = ref.read(uploadServiceProvider);
      final uploadRes = await uploadService.upload(
        purpose: 'PROJECT_FILE',
        targetId: widget.projectId,
        file: _attachedFile!,
        cancelToken: _cancelToken,
      );

      if (uploadRes is Err) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = (uploadRes as Err).error.message;
          });
        }
        return;
      }
      objectKey = (uploadRes as Ok<String>).data;
    }

    if (!mounted) return;

    final repo = ref.read(careerPathsRepositoryProvider);
    final submitRes = await repo.submitProject(
      widget.projectId,
      _idempotencyKey!,
      linkUrl: link.isNotEmpty ? link : null,
      objectKey: objectKey,
      fileName: _attachedFile?.name,
      sizeBytes: _attachedFile?.size,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (submitRes is Ok<Map<String, dynamic>>) {
        final data = submitRes.data;
        GamificationResult? gamification;
        if (data['gamification'] != null) {
          gamification = GamificationResult.fromJson(data['gamification']);
        }
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SubmissionReceivedPage(
              projectId: widget.projectId,
              gamification: gamification,
            ),
          ),
        );
      } else {
        setState(() => _errorMessage = (submitRes as Err).error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xff9A9A9A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _isSubmitting ? null : Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.chevron_left, color: Colors.black),
                      ),
                    ),
                    const Icon(Icons.notifications_none, color: AppColors.primaryDark),
                  ],
                ),
                const SizedBox(height: 24),

                // LINK INPUT
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _linkController,
                                enabled: !_isSubmitting,
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'https://...',
                                  hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isSubmitting ? null : _pasteLink,
                      child: Text(
                        'Paste here',
                        style: TextStyle(
                          color: _isSubmitting ? Colors.grey : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // FILE DROP ZONE
                GestureDetector(
                  onTap: _isSubmitting ? null : _browseFiles,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _attachedFile == null
                                ? Icons.upload_outlined
                                : Icons.insert_drive_file_outlined,
                            size: 36,
                            color: _isSubmitting ? Colors.grey : Colors.black,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _attachedFile?.name ?? '( Drop or browse your files )',
                            style: TextStyle(
                              color: _isSubmitting ? Colors.grey : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Please submit your assignment. Browse or attach a link to your files',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
