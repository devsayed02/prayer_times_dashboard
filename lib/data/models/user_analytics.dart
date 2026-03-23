class UserAnalytics {
  final int totalUsers;
  final ActiveUsers activeUsers;
  final NotificationStats notificationStats;
  final List<DistributionItem> platformDistribution;
  final List<DistributionItem> appVersionDistribution;
  final List<DistributionItem> brandDistribution;
  final List<TrendItem> registrationTrend;

  const UserAnalytics({
    required this.totalUsers,
    required this.activeUsers,
    required this.notificationStats,
    required this.platformDistribution,
    required this.appVersionDistribution,
    required this.brandDistribution,
    required this.registrationTrend,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      totalUsers: json['totalUsers'] as int? ?? 0,
      activeUsers: ActiveUsers.fromJson(
        json['activeUsers'] as Map<String, dynamic>? ?? {},
      ),
      notificationStats: NotificationStats.fromJson(
        json['notificationStats'] as Map<String, dynamic>? ?? {},
      ),
      platformDistribution: (json['platformDistribution'] as List<dynamic>?)
              ?.map((e) => DistributionItem.fromJson(
                  e as Map<String, dynamic>, 'platform'))
              .toList() ??
          [],
      appVersionDistribution:
          (json['appVersionDistribution'] as List<dynamic>?)
                  ?.map((e) => DistributionItem.fromJson(
                      e as Map<String, dynamic>, 'version'))
                  .toList() ??
              [],
      brandDistribution: (json['brandDistribution'] as List<dynamic>?)
              ?.map((e) => DistributionItem.fromJson(
                  e as Map<String, dynamic>, 'brand'))
              .toList() ??
          [],
      registrationTrend: (json['registrationTrend'] as List<dynamic>?)
              ?.map((e) => TrendItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ActiveUsers {
  final int last24h;
  final int last7d;
  final int last30d;

  const ActiveUsers({
    required this.last24h,
    required this.last7d,
    required this.last30d,
  });

  factory ActiveUsers.fromJson(Map<String, dynamic> json) {
    return ActiveUsers(
      last24h: json['last24h'] as int? ?? 0,
      last7d: json['last7d'] as int? ?? 0,
      last30d: json['last30d'] as int? ?? 0,
    );
  }
}

class NotificationStats {
  final int total;
  final int success;
  final int fail;

  const NotificationStats({
    required this.total,
    required this.success,
    required this.fail,
  });

  factory NotificationStats.fromJson(Map<String, dynamic> json) {
    return NotificationStats(
      total: json['total'] as int? ?? 0,
      success: json['success'] as int? ?? 0,
      fail: json['fail'] as int? ?? 0,
    );
  }

  double get successRate => total > 0 ? (success / total) * 100 : 0;
  double get failRate => total > 0 ? (fail / total) * 100 : 0;
}

class DistributionItem {
  final String label;
  final int count;

  const DistributionItem({required this.label, required this.count});

  factory DistributionItem.fromJson(
      Map<String, dynamic> json, String labelKey) {
    return DistributionItem(
      label: json[labelKey] as String? ?? 'unknown',
      count: json['count'] as int? ?? 0,
    );
  }
}

class TrendItem {
  final String date;
  final int count;

  const TrendItem({required this.date, required this.count});

  factory TrendItem.fromJson(Map<String, dynamic> json) {
    return TrendItem(
      date: json['date'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}
