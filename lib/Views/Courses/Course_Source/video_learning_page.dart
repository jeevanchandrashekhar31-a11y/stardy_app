import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../../widgets/color_codes.dart';
import '../Course_SUB_Pages/quiz_page.dart';
import '../../../features/courses/models/quiz_models.dart';
import '../../../features/courses/repository/course_repository.dart';
import '../../../features/courses/dto/course_dto.dart';
import '../../../features/courses/models/course_enums.dart';
import '../../../core/ui/progress_feedback.dart';
import '../../../core/network/api_client.dart';

class VideoLearningPage extends ConsumerStatefulWidget {
  final String moduleId;
  final String title;

  const VideoLearningPage({
    super.key,
    required this.moduleId,
    required this.title,
  });

  @override
  ConsumerState<VideoLearningPage> createState() => _VideoLearningPageState();
}

class _VideoLearningPageState extends ConsumerState<VideoLearningPage> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  ModuleContent? _content;
  bool _isLoading = true;
  String? _error;
  bool _hasCompleted = false;
  final String _idempotencyKey = const Uuid().v4();
  Duration _savedPosition = Duration.zero;
  Duration _lastKnownPosition = Duration.zero;
  Duration _cumulativePlayed = Duration.zero;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchContent();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _controller?.pause();
    }
  }

  Future<void> _fetchContent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(courseRepositoryProvider);
    final res = await repo.getModuleContent(widget.moduleId);

    if (!mounted) return;

    if (res is Ok<ModuleContent>) {
      _content = res.data;
      if (_content!.contentType == ContentType.video || _content!.contentType == ContentType.audio) {
        await _initPlayer(_content!.url);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _error = (res as Err).error.message;
      });
    }
  }

  Future<void> _initPlayer(String? urlString) async {
    if (urlString == null) {
      setState(() {
        _error = 'No URL provided';
        _isLoading = false;
      });
      return;
    }

    final uri = Uri.tryParse(urlString);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      setState(() {
        _error = 'Invalid or non-HTTPS URL';
        _isLoading = false;
      });
      return;
    }

    await _controller?.dispose();
    _controller = VideoPlayerController.networkUrl(uri);

    try {
      await _controller!.initialize();
      if (_savedPosition > Duration.zero) {
        await _controller!.seekTo(_savedPosition);
      }
      _controller!.addListener(_playerListener);
      await _controller!.play();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize player';
          _isLoading = false;
        });
      }
    }
  }

  void _playerListener() {
    if (!mounted || _controller == null) return;
    
    final value = _controller!.value;
    if (value.hasError) {
      // 403 or other playback error
      _handleExpirationOrError();
      return;
    }

    _savedPosition = value.position;

    // Check expiration
    if (_content?.expiresAt != null) {
      final expires = DateTime.tryParse(_content!.expiresAt!);
      if (expires != null) {
        final remaining = expires.difference(DateTime.now());
        if (remaining.inSeconds <= 30) {
          _handleExpirationOrError();
          return;
        }
      }
    }

    if (value.isPlaying) {
      final diff = value.position - _lastKnownPosition;
      if (diff > Duration.zero && diff < const Duration(seconds: 2)) {
        _cumulativePlayed += diff;
      }
    }
    _lastKnownPosition = value.position;

    // Check completion (90% AND 50% cumulative playback)
    if (!_hasCompleted && value.duration.inMilliseconds > 0) {
      final progress = value.position.inMilliseconds / value.duration.inMilliseconds;
      final playedRatio = _cumulativePlayed.inMilliseconds / value.duration.inMilliseconds;
      
      if (progress >= 0.9 && playedRatio >= 0.5) {
        _markComplete();
      }
    }

    // Force UI rebuild for progress bar
    setState(() {});
  }

  bool _isRefetching = false;
  void _handleExpirationOrError() async {
    if (_isRefetching) return;
    _isRefetching = true;
    _controller?.removeListener(_playerListener);
    
    // Fetch new url
    final repo = ref.read(courseRepositoryProvider);
    final res = await repo.getModuleContent(widget.moduleId);
    
    if (mounted && res is Ok<ModuleContent>) {
      _content = res.data;
      await _initPlayer(_content!.url);
    } else if (mounted) {
      setState(() {
        _error = 'Session expired. Failed to resume.';
      });
    }
    _isRefetching = false;
  }

  void _markComplete() async {
    if (_hasCompleted || _isSubmitting) return;
    _hasCompleted = true;
    _isSubmitting = true;

    final repo = ref.read(courseRepositoryProvider);
    final res = await repo.completeModule(widget.moduleId, _idempotencyKey);

    if (mounted && res is Ok<CompleteModuleResult>) {
      ref.invalidate(courseDetailProvider);
      
      if (res.data.gamification != null) {
        showProgressFeedback(context, ref, res.data.gamification!);
      }
    }
    
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
    } else {
      _controller!.play();
    }
    setState(() {});
  }

  void _skipForward() {
    if (_controller == null) return;
    final pos = _controller!.value.position;
    _controller!.seekTo(pos + const Duration(seconds: 10));
  }

  void _skipBackward() {
    if (_controller == null) return;
    final pos = _controller!.value.position;
    _controller!.seekTo(pos - const Duration(seconds: 10));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black),
        ),
        actions: [
          IconButton(
            tooltip: 'Next step',
            icon: const Icon(Icons.arrow_forward, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizPage(target: ModuleQuiz(widget.moduleId, widget.title)),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
            ElevatedButton(
              onPressed: _fetchContent,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_content == null) {
      return const Center(child: Text('No content'));
    }

    switch (_content!.contentType) {
      case ContentType.video:
        return _buildVideoPlayer();
      case ContentType.audio:
        return _buildAudioPlayer();
      case ContentType.text:
        return _buildTextContent();
      default:
        return const Center(child: Text('Unsupported content type'));
    }
  }

  Widget _buildVideoPlayer() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        ),
        VideoProgressIndicator(
          _controller!,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          colors: const VideoProgressColors(
            playedColor: AppColors.primary,
            backgroundColor: Colors.black12,
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.audiotrack, size: 100, color: AppColors.primaryDark),
          const SizedBox(height: 32),
          VideoProgressIndicator(
            _controller!,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            colors: const VideoProgressColors(
              playedColor: AppColors.primary,
              backgroundColor: Colors.black12,
            ),
          ),
          const SizedBox(height: 16),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _skipBackward,
          icon: const Icon(Icons.replay_10, color: Colors.black),
        ),
        IconButton(
          onPressed: _togglePlayPause,
          icon: Icon(
            _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: AppColors.primary,
            size: 40,
          ),
        ),
        IconButton(
          onPressed: _skipForward,
          icon: const Icon(Icons.forward_10, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildTextContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            _content!.textContent ?? 'No text provided.',
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasCompleted ? Colors.green : AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _hasCompleted || _isSubmitting ? null : _markComplete,
              icon: Icon(_hasCompleted ? Icons.check : Icons.done_all, color: Colors.white),
              label: Text(
                _hasCompleted ? 'Completed' : 'Mark Complete',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
