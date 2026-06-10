import '../../../../../core/network/api_client.dart';
import 'models/station.dart';

class StationRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<Station>> listStations({int page = 1, int size = 1000}) async {
    final response = await _apiClient.dio.get(
      '/stations',
      queryParameters: {
        'page': page,
        'size': size,
      },
    );
    
    List data = [];
    if (response.data != null) {
      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map) {
        final map = response.data as Map<String, dynamic>;
        if (map.containsKey('records')) {
          data = map['records'] as List;
        } else if (map.containsKey('data')) {
           if (map['data'] is List) {
              data = map['data'] as List;
           } else if (map['data'] is Map && map['data'].containsKey('records')) {
              data = map['data']['records'] as List;
           }
        }
      }
    }
    
    return data.map((e) => Station.fromJson(e)).toList();
  }

  Future<Station> getDetail(String id) async {
    final response = await _apiClient.dio.get('/stations/$id');
    return Station.fromJson(response.data);
  }
}
