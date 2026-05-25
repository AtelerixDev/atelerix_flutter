enum BugSeverity {
  critical("critical"),
  high("high"),
  medium("medium"),
  low("low"),
  unknown("unknown");

  const BugSeverity(this.type);
  final String type;
}
