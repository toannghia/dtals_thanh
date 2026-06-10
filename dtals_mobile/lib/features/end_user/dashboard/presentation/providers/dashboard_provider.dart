import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';
import '../../data/models/dashboard_overview.dart';

class DashboardState {
  final bool isLoading;
  final DashboardOverview data;
  final String? error;

  DashboardState({
    required this.isLoading,
    required this.data,
    this.error,
  });

  factory DashboardState.initial() => DashboardState(
        isLoading: true,
        data: DashboardOverview.initial(),
      );
}

class DashboardNotifier extends Notifier<DashboardState> {
  final DashboardRepository _repository = DashboardRepository();

  @override
  DashboardState build() {
    Future.microtask(() => loadData());
    return DashboardState.initial();
  }

  Future<void> loadData() async {
    state = DashboardState(isLoading: true, data: state.data);
    try {
      final data = await _repository.getDashboardData();
      state = DashboardState(isLoading: false, data: data);
    } catch (e) {
      state = DashboardState(isLoading: false, data: state.data, error: e.toString());
    }
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(() {
  return DashboardNotifier();
});
