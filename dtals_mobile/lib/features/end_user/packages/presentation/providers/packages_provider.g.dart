// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'packages_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PackagesNotifier)
final packagesProvider = PackagesNotifierProvider._();

final class PackagesNotifierProvider
    extends $AsyncNotifierProvider<PackagesNotifier, List<NtripPackage>> {
  PackagesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'packagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$packagesNotifierHash();

  @$internal
  @override
  PackagesNotifier create() => PackagesNotifier();
}

String _$packagesNotifierHash() => r'8ed198a055793638367f07fe81acf70f01b3a2a8';

abstract class _$PackagesNotifier extends $AsyncNotifier<List<NtripPackage>> {
  FutureOr<List<NtripPackage>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<NtripPackage>>, List<NtripPackage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<NtripPackage>>, List<NtripPackage>>,
              AsyncValue<List<NtripPackage>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
