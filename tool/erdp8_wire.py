from pathlib import Path

screen = Path('lib/features/exam_readiness/screens/todays_plan_screen.dart')
source = screen.read_text()

import_anchor = "import '../services/ultra_hard_availability_service.dart';\n"
import_line = "import '../widgets/daily_plan_task_card.dart';\n"
if import_line not in source:
    if import_anchor not in source:
        raise SystemExit('ERDP-8 import anchor missing')
    source = source.replace(import_anchor, import_anchor + import_line, 1)

if '_PlanBlockCard(' not in source:
    raise SystemExit('ERDP-8 card usage anchor missing')
source = source.replace('_PlanBlockCard(', 'DailyPlanTaskCard(', 1)

start_marker = 'class _PlanBlockCard extends StatelessWidget {'
end_marker = 'class _WhyThisPlan extends StatelessWidget {'
start = source.find(start_marker)
end = source.find(end_marker, start)
if start < 0 or end < 0:
    raise SystemExit('ERDP-8 private card block anchors missing')
source = source[:start] + source[end:]
screen.write_text(source)

widget = Path('lib/features/exam_readiness/widgets/daily_plan_task_card.dart')
widget_source = widget.read_text()
old = "      child: Opacity(opacity: subdued ? 0.72 : 1, child: card),\n"
new = "      child: Opacity(\n        key: ValueKey('erdp8-card-opacity-$index'),\n        opacity: subdued ? 0.72 : 1.0,\n        child: card,\n      ),\n"
if old not in widget_source:
    raise SystemExit('ERDP-8 opacity anchor missing')
widget.write_text(widget_source.replace(old, new, 1))

test = Path('test/features/exam_readiness/erdp/erdp8_daily_plan_ux_test.dart')
test_source = test.read_text()
old = "        final opacity = tester.widget<Opacity>(find.byType(Opacity).first);\n"
new = "        final opacity = tester.widget<Opacity>(\n          find.byKey(const ValueKey('erdp8-card-opacity-0')),\n        );\n"
if old not in test_source:
    raise SystemExit('ERDP-8 test opacity anchor missing')
test.write_text(test_source.replace(old, new, 1))
