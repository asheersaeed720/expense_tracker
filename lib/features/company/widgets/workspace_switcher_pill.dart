import 'package:flutter/material.dart';

class WorkspaceSwitcherPill extends StatelessWidget {
  const WorkspaceSwitcherPill({
    super.key,
    required this.companyName,
    required this.onCompany,
  });

  final String companyName;
  final VoidCallback onCompany;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<String>(
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          showSelectedIcon: false,
          segments: [
            const ButtonSegment(value: 'personal', label: Text('Personal')),
            ButtonSegment(
              value: 'company',
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(companyName, overflow: TextOverflow.ellipsis),
              ),
              icon: const Icon(Icons.business_outlined, size: 18),
            ),
          ],
          selected: const {'personal'},
          onSelectionChanged: (selection) {
            if (selection.contains('company')) onCompany();
          },
        ),
      ),
    );
  }
}
