enum BugType {
  runtimeError("runtime_error"),
  logicBug("logic_bug"),
  uiBug("ui_bug"),
  networkError("network_error"),
  performance("performance"),
  compatibility("compatibility"),
  validationError("validation_error"),
  security("security"),
  crash("crash"),
  unknown("unknown");
  const BugType(this.type);
  final String type;

}