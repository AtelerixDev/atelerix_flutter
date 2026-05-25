// ios/Runner/AppDelegate.swift
import UIKit
import Flutter
import UserNotifications

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // تسجيل جميع الـ Plugins
        GeneratedPluginRegistrant.register(with: self)
        
        // إعداد Push Notifications
        setupPushNotifications(application)
        
        // ✅ إعداد Method Channel
        setupMethodChannel()
        
        // ✅ مسح الـ badge عند فتح التطبيق
        clearBadge()
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // ✅ إعداد Method Channel
    private func setupMethodChannel() {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "atelerix/notifications",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            if call.method == "clearBadge" {
                self?.clearBadge()
                result(nil)
            }
        }
    }
    
    // ✅ مسح الـ badge
    private func clearBadge() {
        // الطريقة الجديدة (iOS 16+)
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("❌ Error clearing badge: \(error)")
            } else {
                print("✅ Badge cleared successfully")
            }
        }
        
        // الطريقة القديمة (لضمان المسح)
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        // مسح جميع الإشعارات المعروضة
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // ✅ إعداد Push Notifications
    private func setupPushNotifications(_ application: UIApplication) {
        // تعيين الـ delegate للتحكم في الإشعارات
        UNUserNotificationCenter.current().delegate = self
        
        // طلب الأذونات
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { granted, error in
                if let error = error {
                    print("❌ Notification authorization error: \(error.localizedDescription)")
                    return
                }
                
                if granted {
                    print("✅ Notification permission granted")
                    // التسجيل للحصول على Device Token
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    print("⚠️ Notification permission denied")
                }
            }
        )
    }
    
    // ✅ استقبال Device Token من APNs (نجح)
    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // تحويل Device Token من Data إلى String
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        print("✅ Device Token: \(token)")
        
        // حفظ التوكن في Plugin
        AtelerixPlugin.setDeviceToken(token)
        
        // إرسال التوكن إلى Flutter
        notifyFlutter(token: token)
    }
    
    // ❌ فشل التسجيل للحصول على Device Token
    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
        
        // مسح التوكن في حالة الفشل
        AtelerixPlugin.setDeviceToken(nil)
    }
    
    // ✅ إرسال التوكن إلى Flutter عبر Method Channel
    private func notifyFlutter(token: String) {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            print("⚠️ FlutterViewController not found")
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "atelerix/notifications",
            binaryMessenger: controller.binaryMessenger
        )
        
        channel.invokeMethod("onDeviceTokenReceived", arguments: token)
    }
    
    // ✅ مسح الـ badge عند عودة التطبيق للمقدمة
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        clearBadge()
    }
}

// ✅ معالجة الإشعارات
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // عند استلام notification والتطبيق في المقدمة (foreground)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        print("📬 Notification received in foreground: \(userInfo)")
        
        // عرض الإشعار حتى لو التطبيق مفتوح
        completionHandler([.banner, .sound, .badge])
    }
    
    // عند الضغط على الإشعار
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        print("👆 Notification tapped: \(userInfo)")
        
        // ✅ مسح الـ badge عند الضغط على الإشعار
        clearBadge()
        
        // يمكنك إرسال البيانات إلى Flutter هنا
        notifyFlutterNotificationTapped(userInfo: userInfo)
        
        completionHandler()
    }
    
    // إرسال معلومات الإشعار المضغوط إلى Flutter
    private func notifyFlutterNotificationTapped(userInfo: [AnyHashable: Any]) {
        guard let controller = window?.rootViewController as? FlutterViewController else {
            return
        }
        
        let channel = FlutterMethodChannel(
            name: "atelerix/notifications",
            binaryMessenger: controller.binaryMessenger
        )
        
        // تحويل userInfo إلى Dictionary
        let data = userInfo.reduce(into: [String: Any]()) { result, item in
            if let key = item.key as? String {
                result[key] = item.value
            }
        }
        
        channel.invokeMethod("onNotificationTapped", arguments: data)
    }
}