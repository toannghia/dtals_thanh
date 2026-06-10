import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/packages_repository.dart';
import '../../../../admin/ntrip/data/models/ntrip_package.dart';

part 'packages_provider.g.dart';

@riverpod
class PackagesNotifier extends _$PackagesNotifier {
  late final PackagesRepository _repository;

  @override
  FutureOr<List<NtripPackage>> build() async {
    _repository = PackagesRepository();
    return _fetchPackages();
  }

  Future<List<NtripPackage>> _fetchPackages() async {
    return await _repository.getActivePackages();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPackages());
  }
}
