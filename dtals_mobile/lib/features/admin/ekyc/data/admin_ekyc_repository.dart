import '../../../../core/network/api_client.dart';

class AdminEkycRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<dynamic>> listSubmissions({String? search, String? status}) async {
    final response = await _apiClient.dio.get('/ekyc/admin/submissions', queryParameters: {
      if (search != null) 'search': search,
      if (status != null) 'status': status,
    });
    // Backend may return {data: [...], meta: {...}} or directly a List
    final responseData = response.data;
    if (responseData is List) return responseData;
    if (responseData is Map) return responseData['data'] ?? responseData['items'] ?? [];
    return [];
  }

  Future<void> reviewSubmission(String id, bool approved, String? note) async {
    await _apiClient.dio.put('/ekyc/admin/submissions/$id/review', data: {
      'status': approved ? 'APPROVED' : 'REJECTED',
      'reviewNote': note ?? '',
    });
  }

  Future<dynamic> getSubmissionDetail(String id) async {
    return null;
  }
}
