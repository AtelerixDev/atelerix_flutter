enum Routes {
  createIssue("/plugin/issues/create"),
  initApp("/plugin/init/ping"),
  registerUser("/plugin/init/register-user"),
  sendBug("/plugin/bugs/create"),
  registerNotification("/plugin/notifications/register-token"),
  getSenderId("/plugin/notifications/sender-id");

  const Routes(this.route);
  final String route;
}
