import 'package:flutter/material.dart';

class Lab1000StudioScreen extends StatelessWidget {
  const Lab1000StudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'LAB1000 Studio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _StudioPanel(
              icon: Icons.data_object_rounded,
              title: 'JSON-first LAB authoring',
              body:
                  'One portable LAB JSON package is the authoritative version representation. L1 establishes the shell and contracts. Import, exhaustive validation, preview, review and immutable publish are completed in L2.',
            ),
            const SizedBox(height: 14),
            _StudioPanel(
              icon: Icons.account_tree_rounded,
              title: 'Deterministic runtime contract',
              body:
                  'Scene → Decision → Option → Consequence → State Mutation → Story Gate → Next Scene / Event / Ending. Runtime LLM branching and executable JSON are forbidden.',
            ),
            const SizedBox(height: 14),
            _StudioPanel(
              icon: Icons.verified_user_rounded,
              title: 'L1 boundary',
              body:
                  'LAB-0 through LAB-3 only: contracts, navigation shells, typed state, consequence engine and all six Story Gate types. Session persistence and publishing remain outside this step.',
            ),
          ],
        ),
      ),
    );
  }
}

class _StudioPanel extends StatelessWidget {
  const _StudioPanel({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: const Color(0xFF315EAA)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(body, style: const TextStyle(height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
