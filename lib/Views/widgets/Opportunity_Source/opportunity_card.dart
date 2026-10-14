import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:stardy_app/features/opportunities/models/opportunity_models.dart';
import 'package:stardy_app/Views/widgets/color_codes.dart';
import 'apply_bottom_sheet.dart';

class OpportunityCard extends ConsumerWidget {
  final OpportunitySummary opp;
  final VoidCallback onApplied;

  const OpportunityCard({
    super.key,
    required this.opp,
    required this.onApplied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeLabel = opp.type == 'INTERNSHIP' ? 'Internship' : 'Freelance';
    final label = opp.isPaid ? 'PAID ${typeLabel.toUpperCase()}' : typeLabel.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP TAGS + AVATAR STACK
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (opp.location != null && opp.location!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          opp.location!,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _avatarStack(),
            ],
          ),

          const SizedBox(height: 18),

          // TITLE
          Text(
            opp.title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 6),

          // COMPANY
          Text(
            opp.company,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),

          const SizedBox(height: 18),

          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: opp.logoUrl != null && opp.logoUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: opp.logoUrl!,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 130,
                      width: double.infinity,
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => _fallbackImage(opp),
                  )
                : _fallbackImage(opp),
          ),

          const SizedBox(height: 20),

          // APPLY BUTTON
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: opp.hasApplied ? Colors.grey : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: opp.hasApplied
                  ? null
                  : () => _openApplyBottomSheet(context),
              child: Text(
                opp.hasApplied ? 'Applied' : 'Apply Now',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _fallbackImage(OpportunitySummary opp) {
    return Container(
      height: 130,
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Icon(
        opp.category == 'DESIGN'
            ? Icons.palette_outlined
            : Icons.business_center_outlined,
        color: AppColors.primary,
        size: 36,
      ),
    );
  }

  Widget _avatarStack() {
    return SizedBox(
      width: 70,
      height: 28,
      child: Stack(
        children: [
          for (int i = 0; i < 3; i++)
            Positioned(
              left: i * 16.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primary.withValues(
                    alpha: 0.7 - (i * 0.15),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 48,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '+12',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openApplyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ApplyBottomSheet(
          opportunity: opp,
          onApplied: onApplied,
        );
      },
    );
  }
}
