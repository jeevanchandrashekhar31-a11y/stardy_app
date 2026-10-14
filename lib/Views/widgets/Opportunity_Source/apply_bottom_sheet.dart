import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/features/opportunities/models/opportunity_models.dart';
import 'package:stardy_app/features/opportunities/repository/opportunity_repository.dart';
import 'package:stardy_app/features/opportunities/providers/opportunity_provider.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/core/url/safe_launcher.dart';
import 'package:stardy_app/Views/widgets/color_codes.dart';
import 'package:uuid/uuid.dart';

class ApplyBottomSheet extends ConsumerStatefulWidget {
  final OpportunitySummary opportunity;
  final VoidCallback onApplied;

  const ApplyBottomSheet({
    super.key,
    required this.opportunity,
    required this.onApplied,
  });

  @override
  ConsumerState<ApplyBottomSheet> createState() => _ApplyBottomSheetState();
}

class _ApplyBottomSheetState extends ConsumerState<ApplyBottomSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitApply() async {
    if (_isSubmitting) return;

    if (_noteController.text.length > 1000) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover note must be max 1000 chars.')),
        );
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final idempotencyKey = const Uuid().v4();
    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();
    
    final res = await ref.read(opportunityRepositoryProvider).apply(
      widget.opportunity.id,
      idempotencyKey,
      coverNote: note,
    );

    if (!mounted) return;

    if (res is Ok) {
      widget.onApplied();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted!')),
      );
    } else {
      final err = (res as Err).error;
      if (err is ConflictFailure) {
        // 409 means already applied
        widget.onApplied();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already applied.')),
        );
      } else if (err is RateLimitedFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Too many requests. Please wait and try again.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message)),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(opportunityDetailProvider(widget.opportunity.id));
    final MediaQueryData mq = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.only(
        bottom: mq.viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Apply to ${widget.opportunity.company}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),

              detailAsync.when(
                data: (detail) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.description,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      if (detail.applyUrl != null && detail.applyUrl!.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            SafeLauncher.launchSafe(context, detail.applyUrl);
                          },
                          child: const Text('View original posting'),
                        ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _noteController,
                        maxLines: 4,
                        maxLength: 1000,
                        enabled: !_isSubmitting,
                        decoration: InputDecoration(
                          hintText: 'Why are you a great fit? (Optional)',
                          hintStyle: const TextStyle(color: Colors.black45),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          counterStyle: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _submitApply,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Confirm Apply',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Could not load details',
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
