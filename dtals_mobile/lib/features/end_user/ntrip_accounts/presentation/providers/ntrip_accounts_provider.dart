import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/ntrip_account_repository.dart';
import '../../data/models/ntrip_account.dart';

final ntripAccountsProvider = FutureProvider<List<NtripAccount>>((ref) async {
  final repository = NtripAccountRepository();
  return repository.getMyAccounts();
});
