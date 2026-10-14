import 'package:flutter/material.dart';
import '../../Views/widgets/color_codes.dart';
import '../network/api_client.dart';

String safeErrorText(Object? error) {
  if (error is ServerFailure || error is NetworkFailure) {
    return 'Something went wrong. Please try again.';
  }
  if (error is ApiFailure) {
    final msg = error.message;
    return msg.length > 200 ? '${msg.substring(0, 197)}...' : msg;
  }
  return 'Something went wrong. Please try again.';
}

class ErrorView extends StatefulWidget {
  final String message;
  final VoidCallback onRetry;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.actionLabel,
    this.onAction,
  });

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  bool _isRetrying = false;

  void _handleRetry() {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    widget.onRetry();
    // Re-enable after a short delay to prevent double-tap
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.primary, size: 48),
            const SizedBox(height: 16),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isRetrying ? null : _handleRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onAction,
                child: Text(
                  widget.actionLabel!,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
