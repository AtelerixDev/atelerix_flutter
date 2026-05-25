import Flutter
import UIKit
import atelerix

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ✅ سطرين فقط لدعم الإشعارات!
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceData: Data
  ) {
    atelerix_didRegisterForRemoteNotifications(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceData)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    atelerix_didFailToRegisterForRemoteNotifications(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
