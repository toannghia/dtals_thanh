import '../../../../core/network/api_client.dart';
import 'models/ntrip_package.dart';

class NtripPackageRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<NtripPackage>> listPackages() async {
    final response = await _apiClient.dio.get('/ntrip-packages');
    // Backend may return List directly or wrapped {data: [...]}
    final responseData = response.data;
    List items;
    if (responseData is List) {
      items = responseData;
    } else if (responseData is Map) {
      items = responseData['data'] ?? responseData['items'] ?? [];
    } else {
      items = [];
    }
    return items.map((e) => NtripPackage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createPackage(Map<String, dynamic> data) async {
    await _apiClient.dio.post('/ntrip-packages', data: data);
  }

  Future<void> updatePackage(int id, Map<String, dynamic> data) async {
    await _apiClient.dio.put('/ntrip-packages/$id', data: data);
  }

  Future<void> deletePackage(int id) async {
    await _apiClient.dio.delete('/ntrip-packages/$id');
  }
}
