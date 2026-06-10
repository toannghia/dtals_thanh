import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SearchHeader extends StatelessWidget {
  final String hintText;
  final ValueChanged<String> onSearch;
  final VoidCallback? onAdd;
  final String? addLabel;
  final TextEditingController? controller;

  const SearchHeader({
    super.key,
    this.hintText = 'Tìm kiếm...',
    required this.onSearch,
    this.onAdd,
    this.addLabel,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: onSearch,
              onChanged: (v) {
                if (v.isEmpty) onSearch(v);
              },
            ),
          ),
          if (onAdd != null) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(addLabel ?? 'Thêm'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
