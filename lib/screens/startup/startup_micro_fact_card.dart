import 'package:flutter/material.dart';

import '../../models/micro_learning/micro_fact.dart';

class StartupMicroFactCard extends StatelessWidget {
  const StartupMicroFactCard({
    super.key,
    required this.fact,
    this.highContrast = false,
  });

  final MicroFact fact;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final text = fact.display.shortVariant?.trim().isNotEmpty == true
        ? fact.display.shortVariant!.trim()
        : fact.display.displayText.trim();
    final category = _categoryLabel(fact.category);

    return Semantics(
      label: 'Quick CSP insight. $text',
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: highContrast ? 0.15 : 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: highContrast ? 0.55 : 0.18,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: highContrast ? 0.16 : 0.08,
                      ),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QUICK INSIGHT · $category',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: highContrast
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.9,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                height: 1.28,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String value) {
    switch (value) {
      case 'safety_insight':
        return 'SAFETY';
      case 'ih_insight':
        return 'INDUSTRIAL HYGIENE';
      case 'process_safety_insight':
        return 'PROCESS SAFETY';
      case 'fire_electrical_insight':
        return 'FIRE & ELECTRICAL';
      case 'management_insight':
        return 'MANAGEMENT';
      case 'environmental_insight':
        return 'ENVIRONMENT';
      case 'emergency_insight':
        return 'EMERGENCY';
      case 'transport_insight':
        return 'TRANSPORT';
      case 'csp_tip':
        return 'CSP TIP';
      case 'learning_tip':
        return 'LEARNING';
      case 'quick_recall':
        return 'QUICK RECALL';
      case 'think_about_it':
        return 'THINK ABOUT IT';
      default:
        return 'CSP11';
    }
  }
}
