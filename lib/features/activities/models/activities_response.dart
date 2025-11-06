import 'package:equatable/equatable.dart';
import 'user_activity.dart';

class ActivitiesResponse extends Equatable {
  final List<UserActivity> activities;
  final ActivityPagination pagination;

  const ActivitiesResponse({
    required this.activities,
    required this.pagination,
  });

  factory ActivitiesResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    return ActivitiesResponse(
      activities: (data['activities'] as List<dynamic>? ?? [])
          .map((activity) => UserActivity.fromJson(activity as Map<String, dynamic>? ?? {}))
          .toList(),
      pagination: ActivityPagination.fromJson(data['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': {
        'activities': activities.map((activity) => activity.toJson()).toList(),
        'pagination': pagination.toJson(),
      },
    };
  }

  @override
  List<Object?> get props => [activities, pagination];
}

class ActivityPagination extends Equatable {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final bool hasMorePages;

  const ActivityPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    required this.hasMorePages,
  });

  factory ActivityPagination.fromJson(Map<String, dynamic> json) {
    return ActivityPagination(
      currentPage: json['current_page'] as int? ?? 1,
      lastPage: json['last_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      hasMorePages: json['has_more_pages'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      'has_more_pages': hasMorePages,
    };
  }

  @override
  List<Object?> get props => [
        currentPage,
        lastPage,
        perPage,
        total,
        hasMorePages,
      ];
}