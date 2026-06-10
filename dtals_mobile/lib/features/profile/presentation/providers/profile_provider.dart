import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/profile_repository.dart';
import '../../data/models/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final profileProvider = FutureProvider<UserModel>((ref) async {
  final authState = ref.watch(authProvider);
  if (authState.status != AuthStatus.authenticated) {
    throw StateError('Not authenticated');
  }
  final repository = ProfileRepository();
  return repository.getProfile();
});
