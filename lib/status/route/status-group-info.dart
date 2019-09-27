import './status/status-info.dart';

class StatusGroup {
  StatusGroup({
    this.statusCount,
    this.viewCount = 0,
    this.lastStatus = 0,
  });

  final int statusCount;
  int viewCount;
  int lastStatus;
  List<StatusData> statuses;
}