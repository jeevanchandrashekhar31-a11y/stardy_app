import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/color_codes.dart';
import '../../CareerPath/submission_received_page.dart';
import 'quiz_page.dart';
import '../../../features/courses/models/quiz_models.dart';
import '../../../features/courses/models/assignment_models.dart';
import '../../../features/courses/repository/assignment_repository.dart';
import '../../../core/upload/upload_service.dart';
import '../../../core/network/api_client.dart';

class AssignmentPage extends ConsumerStatefulWidget {
  final String assignmentId;
  final String title;

  const AssignmentPage({super.key, required this.assignmentId, required this.title});

  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends ConsumerState<AssignmentPage> {
  AssignmentDetails? _assignment;
  bool _isLoading = true;
  String? _error;

  PlatformFile? _pickedFile;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  CancellationToken? _cancelToken;
  String? _uploadedObjectKey;

  final String _idempotencyKey = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _fetchAssignment();
  }

  Future<void> _fetchAssignment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(assignmentRepositoryProvider);
    final result = await repo.getAssignment(widget.assignmentId);
    
    if (!mounted) return;

    if (result is Ok<AssignmentDetails>) {
      setState(() {
        _assignment = result.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = (result as Err).error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty) return;
    setState(() => _pickedFile = result.files.single);
  }

  void _cancelUpload() {
    _cancelToken?.cancel();
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
      _uploadedObjectKey = null;
    });
  }

  Future<void> _submitAssignment() async {
    final file = _pickedFile;
    if (file == null || file.path == null) return;

    setState(() {
      _isUploading = true;
      if (_uploadedObjectKey == null) _uploadProgress = 0.0;
    });

    String? objectKey = _uploadedObjectKey;

    if (objectKey == null) {
      _cancelToken = CancellationToken();
      final uploadService = ref.read(uploadServiceProvider);
      
      final uploadResult = await uploadService.upload(
        purpose: 'ASSIGNMENT_FILE',
        targetId: widget.assignmentId,
        file: file,
        onProgress: (progress) {
          if (mounted) setState(() => _uploadProgress = progress);
        },
        cancelToken: _cancelToken,
      );

      if (!mounted) return;

      if (uploadResult is Err) {
        if (_cancelToken?.isCancelled == true) return;
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${(uploadResult as Err).error.message}')),
        );
        return;
      }
      objectKey = (uploadResult as Ok<String>).data;
      _uploadedObjectKey = objectKey;
    }

    final repo = ref.read(assignmentRepositoryProvider);
    
    final submitResult = await repo.submitFile(
      widget.assignmentId,
      _idempotencyKey,
      objectKey,
      file.name,
      file.size,
    );

    if (!mounted) return;
    
    setState(() => _isUploading = false);

    if (submitResult is Ok<AssignmentFileSubmissionResponse>) {
      _uploadedObjectKey = null; // Clear on success
      await Navigator.push(
        context,
        MaterialPageRoute(
        builder: (_) => SubmissionReceivedPage(projectId: widget.assignmentId),
        ),
      );
      await _fetchAssignment(); // Refresh assignment when returning
    } else {
      final err = (submitResult as Err).error;
      if (err is ConflictFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already submitted.')),
        );
        await _fetchAssignment(); // Refresh to see the conflict
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission confirmation failed: ${err.message}')),
        );
      }
    }
  }

  String _fileSizeLabel(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'No deadline';
    try {
      final date = DateTime.parse(isoString).toLocal();
      const monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final day = date.day.toString().padLeft(2, '0');
      final month = monthNames[date.month - 1];
      final year = date.year;
      return '$day $month $year';
    } catch (_) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(width),
      bottomNavigationBar: _assignment != null ? _buildBottomNav() : null,
    );
  }

  Widget _buildBody(double width) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchAssignment, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_assignment == null) return const SizedBox();

    final details = _assignment!;
    final fileSub = details.fileSubmission;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(width * 0.05),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  details.title,
                  style: TextStyle(
                    fontSize: width * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                if (fileSub != null) ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _statusChip(
                        fileSub.status == 'PENDING_REVIEW' ? 'Pending Review' : (fileSub.status == 'REVIEWED' ? 'Reviewed + feedback' : fileSub.status),
                        fileSub.status == 'PENDING_REVIEW' ? Colors.orange : (fileSub.status == 'REVIEWED' ? Colors.green : AppColors.primary),
                        fileSub.status == 'PENDING_REVIEW' ? Icons.access_time : Icons.check_circle_outline,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                ],

                if (details.instructions != null && details.instructions!.isNotEmpty) ...[
                  Text(
                    details.instructions!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                if (details.topics.isNotEmpty) ...[
                  const Text(
                    "Topics Included",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  ...details.topics.map((t) => _topicTile(t)),
                  const SizedBox(height: 30),
                ],

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Submission Deadline",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(details.dueAt),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (fileSub?.feedback != null) ...[
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Review Notes",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fileSub!.feedback!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (fileSub == null) ...[
                  const SizedBox(height: 25),
                  const Text(
                    "Attachment",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: _isUploading ? null : _pickFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _pickedFile == null
                            ? Colors.grey.withValues(alpha: 0.08)
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _pickedFile == null
                              ? Colors.grey.withValues(alpha: 0.4)
                              : AppColors.primary,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _pickedFile == null
                                ? Icons.upload_file
                                : Icons.insert_drive_file,
                            color: _pickedFile == null ? Colors.grey : AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pickedFile?.name ?? "Tap to attach a file",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _pickedFile == null
                                        ? Colors.grey.shade700
                                        : Colors.black,
                                  ),
                                ),
                                if (_pickedFile != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _fileSizeLabel(_pickedFile!.size),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_pickedFile != null && !_isUploading)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setState(() => _pickedFile = null),
                            ),
                          if (_isUploading)
                            IconButton(
                              icon: const Icon(Icons.stop_circle_outlined, size: 24, color: Colors.red),
                              onPressed: _cancelUpload,
                            )
                        ],
                      ),
                    ),
                  ),
                  if (_isUploading) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: _uploadProgress),
                  ]
                ],
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final quizSub = _assignment!.quizSubmission;
    final fileSub = _assignment!.fileSubmission;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 55,
                child: OutlinedButton(
                  onPressed: quizSub != null ? null : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QuizPage(target: AssignmentQuiz(widget.assignmentId, widget.title)),
                      ),
                    );
                    await _fetchAssignment();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: quizSub != null ? Colors.grey : AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: FittedBox(
                    child: Text(
                      quizSub != null ? "Quiz submitted: ${quizSub.score}%" : "Take Quiz",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: quizSub != null ? Colors.grey : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: (fileSub == null && _pickedFile != null && !_isUploading)
                      ? _submitAssignment
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const FittedBox(
                          child: Text(
                            "Submit Assignment",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicTile(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
