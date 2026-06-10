import '../../../../../core/network/api_client.dart';
import 'models/ntrip_account.dart';

class NtripAccountRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<NtripAccount>> getMyAccounts() async {
    List<NtripAccount> accounts = [];
    
    try {
      final response = await _apiClient.dio.get('/ntrip-users', queryParameters: {'page': 1, 'size': 50});
      final resData = response.data;
      final List data = (resData is Map) ? (resData['items'] ?? resData['data'] ?? []) : (resData as List? ?? []);
      accounts = data.map((item) => NtripAccount.fromJson(item)).toList();
    } catch (e) {
      // 403 expected for some roles like END_USER where /ntrip-users is admin-only.
      // Fallback to loading from orders just like the web app.
    }

    try {
      final response = await _apiClient.dio.get('/orders');
      final resData = response.data;
      final List data = (resData is Map) ? (resData['items'] ?? resData['data'] ?? []) : (resData as List? ?? []);
      
      for (var item in data) {
        final statusValue = item['status']?.toString().toUpperCase();
        final enabledValue = item['enabled'];
        final isEnabled = enabledValue == true ||
            enabledValue == 1 ||
            statusValue == 'PAID' ||
            statusValue == 'ACTIVE';

        if (statusValue == 'PENDING' || statusValue == 'PAID') {
          // Check if this account name already exists to avoid duplicates
          final name = item['ntripAccountName'] ?? 'Unknown';
          if (!accounts.any((a) => a.username == name)) {
            accounts.add(NtripAccount(
              id: item['id']?.toString() ?? '0',
              username: name,
              password: '',
              mountpoint: 'RTK',
              status: isEnabled ? 1 : 0,
              packageName: item['packageName'] ?? '',
            ));
          }
        }
      }
    } catch (e) {
      // Ignore
    }

    return accounts;
  }
}
