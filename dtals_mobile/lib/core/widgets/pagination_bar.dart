import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalItems;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalItems,
    this.pageSize = 20,
    required this.onPageChanged,
  });

  int get totalPages => (totalItems / pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    if (totalItems <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tổng: $totalItems',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                visualDensity: VisualDensity.compact,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$currentPage / $totalPages',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
