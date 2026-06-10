import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/station_repository.dart';
import '../../data/models/station.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/search_header.dart';

final stationsProvider = FutureProvider<List<Station>>((ref) async {
  final repository = StationRepository();
  return repository.listStations();
});

class StationListScreen extends ConsumerStatefulWidget {
  const StationListScreen({super.key});

  @override
  ConsumerState<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends ConsumerState<StationListScreen> {
  String _search = '';
  String? _statusFilter;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stationsAsync = ref.watch(stationsProvider);

    return Column(
      children: [
        SearchHeader(
          controller: _searchController,
          hintText: 'Tìm theo tên trạm...',
          onSearch: (v) => setState(() => _search = v.trim()),
        ),
        _buildFilterChips(),
        Expanded(
          child: stationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Lỗi: $err'),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: () => ref.invalidate(stationsProvider), child: const Text('Thử lại')),
                ],
              ),
            ),
            data: (stations) {
              var filtered = stations.where((s) {
                if (_search.isNotEmpty && !s.name.toLowerCase().contains(_search.toLowerCase()) && !s.code.toLowerCase().contains(_search.toLowerCase())) return false;
                if (_statusFilter != null && s.status.toUpperCase() != _statusFilter) return false;
                return true;
              }).toList();

              if (filtered.isEmpty) return const Center(child: Text('Không có trạm nào'));

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng: ${filtered.length} trạm', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        TextButton.icon(
                          onPressed: () => context.pop(), // Go back to map
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Bản đồ'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _buildStationCard(filtered[index]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          FilterChip(label: const Text('Tất cả'), selected: _statusFilter == null, onSelected: (_) => setState(() => _statusFilter = null)),
          const SizedBox(width: 8),
          FilterChip(label: const Text('Đang chạy'), selected: _statusFilter == 'RUNNING', onSelected: (_) => setState(() => _statusFilter = 'RUNNING')),
          const SizedBox(width: 8),
          FilterChip(label: const Text('Dừng'), selected: _statusFilter == 'STOPPED', onSelected: (_) => setState(() => _statusFilter = 'STOPPED')),
          const SizedBox(width: 8),
          FilterChip(label: const Text('Offline'), selected: _statusFilter == 'OFFLINE', onSelected: (_) => setState(() => _statusFilter = 'OFFLINE')),
        ],
      ),
    );
  }

  Widget _buildStationCard(Station station) {
    final statusColor = _getStatusColor(station.status);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(station.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(station.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(station.name, style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(station.province ?? 'N/A', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 12),
                const Icon(Icons.lan, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${station.ipAddress ?? '0.0.0.0'}:${station.port ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RUNNING': return Colors.green;
      case 'STOPPED': return Colors.orange;
      case 'OFFLINE': return Colors.red;
      default: return Colors.grey;
    }
  }
}
