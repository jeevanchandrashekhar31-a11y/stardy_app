import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand kit colors (Social Media Brand Kit, "Color usage").
class _SubColors {
  _SubColors._();

  static const red = Color(0xFF99131D);
  static const black = Color(0xFF000000);
  static const grey = Color(0xFFD9D9D9);
  static const white = Color(0xFFFFFFFF);
}

/// One purchasable plan. Fill these from your billing provider
/// (e.g. RevenueCat offerings) so prices always match the store.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.priceNote,
    required this.subtitle,
    required this.ctaLabel,
    required this.billingNote,
    this.badge,
  });

  final String id;
  final String name;

  /// Main price text, e.g. `₹499`.
  final String price;

  /// Small text under the price, e.g. `per month`.
  final String priceNote;

  /// Small text under the plan name, e.g. `Billed monthly`.
  final String subtitle;

  /// Button text while this plan is selected, e.g. `Get Pro, ₹499 / month`.
  final String ctaLabel;

  /// Line under the button, e.g. `Billed ₹499 monthly.`
  final String billingNote;

  /// Optional tag on the card. None of the current plans use one.
  final String? badge;
}

class SubscriptionBenefit {
  const SubscriptionBenefit(this.icon, this.text);

  final IconData icon;
  final String text;
}

/// Subscription screen. Plans and benefits follow the product spec:
/// a single Monthly plan at ₹499 that unlocks all courses and adds 1-2-1
/// mentor access.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({
    super.key,
    required this.onPurchase,
    this.onRestore,
    this.onClose,
    this.onTerms,
    this.onPrivacy,
    this.plans = defaultPlans,
    this.benefits = defaultBenefits,
    this.initialPlanIndex = 0,
  });

  /// Called with the selected plan when the user taps the main button.
  final ValueChanged<SubscriptionPlan> onPurchase;
  final VoidCallback? onRestore;
  final VoidCallback? onClose;
  final VoidCallback? onTerms;
  final VoidCallback? onPrivacy;
  final List<SubscriptionPlan> plans;
  final List<SubscriptionBenefit> benefits;
  final int initialPlanIndex;

  static const defaultPlans = [
    SubscriptionPlan(
      id: 'pro_monthly',
      name: 'Monthly',
      price: '₹499',
      priceNote: 'per month',
      subtitle: 'Billed monthly',
      ctaLabel: 'Get Pro, ₹499 / month',
      billingNote: 'Billed ₹499 monthly.',
    ),
  ];

  static const defaultBenefits = [
    SubscriptionBenefit(Icons.menu_book_outlined, 'Unlocks all courses'),
    SubscriptionBenefit(Icons.groups_outlined, '1-2-1 mentor access'),
  ];

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late int _selected = widget.initialPlanIndex.clamp(0, widget.plans.length - 1);

  @override
  Widget build(BuildContext context) {
    final plan = widget.plans[_selected];

    return Scaffold(
      backgroundColor: _SubColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onClose: widget.onClose),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ProTag(),
                    const SizedBox(height: 18),
                    const _Headline(),
                    const SizedBox(height: 16),
                    Text(
                      'Unlock every course and get 1-2-1 time with a mentor.',
                      style: GoogleFonts.robotoMono(
                        fontSize: 15,
                        height: 1.6,
                        color: _SubColors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _BenefitList(benefits: widget.benefits),
                    const SizedBox(height: 28),
                    for (var i = 0; i < widget.plans.length; i++) ...[
                      if (i > 0) const SizedBox(height: 14),
                      _PlanCard(
                        plan: widget.plans[i],
                        selected: i == _selected,
                        single: widget.plans.length == 1,
                        onTap: () => setState(() => _selected = i),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
              child: Column(
                children: [
                  _PrimaryButton(
                    label: plan.ctaLabel,
                    onTap: () => widget.onPurchase(plan),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    plan.billingNote,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      height: 1.5,
                      color: _SubColors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: _SubColors.black, width: 2)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  _FooterLink('RESTORE PURCHASES', widget.onRestore),
                  _FooterLink('TERMS', widget.onTerms),
                  _FooterLink('PRIVACY', widget.onPrivacy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _SubColors.black, width: 2)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 10, 12, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STARDY AI',
              style: GoogleFonts.mukta(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.88,
                color: _SubColors.black,
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 20, color: _SubColors.black),
            ),
          ],
        ),
      );
}

class _ProTag extends StatelessWidget {
  const _ProTag();

  @override
  Widget build(BuildContext context) => Container(
        color: _SubColors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          'PRO',
          style: GoogleFonts.mukta(
            fontSize: 14,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
            color: _SubColors.white,
          ),
        ),
      );
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.mukta(
      fontSize: 40,
      height: 1.3,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.6,
      color: _SubColors.black,
    );
    return Semantics(
      header: true,
      label: 'LEARN WITHOUT LIMITS',
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(style: base, children: [
            const TextSpan(text: 'LEARN WITHOUT '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: Container(
                color: _SubColors.red,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('LIMITS',
                    style: base.copyWith(color: _SubColors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _BenefitList extends StatelessWidget {
  const _BenefitList({required this.benefits});

  final List<SubscriptionBenefit> benefits;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _SubColors.grey,
          border: Border.all(color: _SubColors.black, width: 2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (var i = 0; i < benefits.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: i == benefits.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(color: _SubColors.black)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      color: _SubColors.red,
                      alignment: Alignment.center,
                      child: Icon(benefits[i].icon,
                          size: 20, color: _SubColors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        benefits[i].text,
                        style: GoogleFonts.robotoMono(
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: _SubColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.single = false,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  /// With only one plan there is nothing to choose, so the selection circle
  /// is hidden and the price is shown larger.
  final bool single;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? _SubColors.white : _SubColors.black;
    final bg = selected ? _SubColors.black : _SubColors.white;
    final small = GoogleFonts.robotoMono(fontSize: 13, height: 1.4, color: fg);

    final card = Material(
      color: bg,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: _SubColors.black, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (!single) ...[
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: fg, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle, color: fg),
                        )
                      : null,
                ),
                const SizedBox(width: 14),

              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name.toUpperCase(),
                      style: GoogleFonts.mukta(
                        fontSize: 20,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(plan.subtitle, style: small),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.price,
                    style: GoogleFonts.mukta(
                      fontSize: single ? 34 : 22,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(plan.priceNote, style: small),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: '${plan.name}, ${plan.price}, ${plan.priceNote}',
      child: ExcludeSemantics(
        child: plan.badge == null
            ? card
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  card,
                  Positioned(
                    top: -12,
                    right: 12,
                    child: Container(
                      color: _SubColors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Text(
                        plan.badge!,
                        style: GoogleFonts.mukta(
                          fontSize: 11,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.88,
                          color: _SubColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: Material(
          color: _SubColors.red,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: _SubColors.red, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ExcludeSemantics(
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.mukta(
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.64,
                    color: _SubColors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.text, this.onTap);

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            text,
            style: GoogleFonts.mukta(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: _SubColors.black,
            ),
          ),
        ),
      );
}
