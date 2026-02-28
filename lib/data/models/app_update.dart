class AppUpdate {
  final String title;
  final String changeLogs;
  final String latestVersion;
  final String minSupportedVersion;
  final bool forceUpdate;
  final String storeUrl;
  final String iosStoreUrl;

  const AppUpdate({
    required this.title,
    required this.changeLogs,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.forceUpdate,
    required this.storeUrl,
    required this.iosStoreUrl,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      title: json['title'] as String? ?? '',
      changeLogs: json['change_logs'] as String? ?? '',
      latestVersion: json['latest_version'] as String? ?? '',
      minSupportedVersion: json['min_supported_version'] as String? ?? '',
      forceUpdate: json['force_update'] as bool? ?? false,
      storeUrl: json['store_url'] as String? ?? '',
      iosStoreUrl: json['ios_store_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'change_logs': changeLogs,
      'latest_version': latestVersion,
      'min_supported_version': minSupportedVersion,
      'force_update': forceUpdate,
      'store_url': storeUrl,
      'ios_store_url': iosStoreUrl,
    };
  }
}
