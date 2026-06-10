import '../../../../../core/network/api_client.dart';
import '../../../admin/ntrip/data/models/ntrip_package.dart';

class PackagesRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<NtripPackage>> getActivePackages() async {
    final response = await _apiClient.dio.get('/ntrip-packages/active');
    final resData = response.data;
    final List data = (resData is Map) ? (resData['items'] ?? resData['data'] ?? []) : (resData as List? ?? []);
    return data.map((item) => NtripPackage.fromJson(item)).toList();
  }
}
