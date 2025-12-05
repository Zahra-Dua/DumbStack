abstract class ParentDashboardEvent {}

class LoadDashboardData extends ParentDashboardEvent {
  final String childId;
  final String parentId;

  LoadDashboardData({
    required this.childId,
    required this.parentId,
  });
}

class UpdateUrlBlockStatus extends ParentDashboardEvent {
  final String childId;
  final String parentId;
  final String urlId;
  final bool isBlocked;

  UpdateUrlBlockStatus({
    required this.childId,
    required this.parentId,
    required this.urlId,
    required this.isBlocked,
  });
}

class RefreshData extends ParentDashboardEvent {
  final String childId;
  final String parentId;

  RefreshData({
    required this.childId,
    required this.parentId,
  });
}
