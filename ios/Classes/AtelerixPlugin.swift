import Flutter
import UIKit
import Foundation
import UserNotifications

public class AtelerixPlugin: NSObject, FlutterPlugin, UNUserNotificationCenterDelegate {

    // ✅ تخزين Device Token
    private static var deviceToken: String?
    private static var permissionGranted: Bool = false
    private static var flutterChannel: FlutterMethodChannel?
    private static var pendingTokenCallbacks: [FlutterResult] = []

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "atelerix/system",
            binaryMessenger: registrar.messenger()
        )

        // Notifications channel
        let notificationsChannel = FlutterMethodChannel(
            name: "atelerix/notifications",
            binaryMessenger: registrar.messenger()
        )

        let instance = AtelerixPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: notificationsChannel)

        // ✅ حفظ الـ channel لإرسال الإشعارات للـ Flutter
        flutterChannel = notificationsChannel

        // ✅ تعيين الـ delegate تلقائياً
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().delegate = instance
        }
    }

    // ✅ معالجة الإشعارات عندما يكون التطبيق مفتوح
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // إرسال بيانات الإشعار للـ Flutter
        AtelerixPlugin.flutterChannel?.invokeMethod("onNotificationReceived", arguments: userInfo)

        // عرض الإشعار حتى لو كان التطبيق مفتوح
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }

    // ✅ معالجة النقر على الإشعار
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // إرسال بيانات الإشعار للـ Flutter
        AtelerixPlugin.flutterChannel?.invokeMethod("onNotificationTapped", arguments: userInfo)

        completionHandler()
    }

    // ✅ تعيين Device Token من AppDelegate
  public static func setDeviceToken(_ token: String?) {
    deviceToken = token
    
    guard let token = token else { return }
    
    print("🔍 [DEBUG] Setting token: \(token.prefix(20))...")
    print("🔍 [DEBUG] Pending callbacks count: \(pendingTokenCallbacks.count)")
    
    DispatchQueue.main.async {
        for (index, callback) in pendingTokenCallbacks.enumerated() {
            print("🔍 [DEBUG] Calling callback #\(index)")
            callback(token)
        }
        print("🔍 [DEBUG] All callbacks executed")
        pendingTokenCallbacks.removeAll()
    }
}

    // ✅ الحصول على Device Token
    public static func getDeviceToken() -> String? {
        return deviceToken
    }

    // ✅ طلب صلاحيات الإشعارات فقط (بدون انتظار token)
    private func requestPermissionsOnly(result: @escaping FlutterResult) {
        let center = UNUserNotificationCenter.current()

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ [Atelerix] Permission error: \(error.localizedDescription)")
                result(false)
                return
            }

            AtelerixPlugin.permissionGranted = granted

            if granted {
                print("✅ [Atelerix] Notification permissions granted")

                // التسجيل للإشعارات
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }

                result(true)
            } else {
                print("⚠️ [Atelerix] Notification permissions denied")
                result(false)
            }
        }
    }

    // ✅ طلب صلاحيات الإشعارات وتسجيل الجهاز والحصول على Token
private func requestNotificationPermissions(result: @escaping FlutterResult) {
    let center = UNUserNotificationCenter.current()

    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error = error {
            result(FlutterError(
                code: "PERMISSION_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
            return
        }

        AtelerixPlugin.permissionGranted = granted

        guard granted else {
            result(FlutterError(
                code: "PERMISSION_DENIED",
                message: "User denied notification permissions",
                details: nil
            ))
            return
        }

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }

        // ✅ لو التوكن موجود رجّعه فوراً
        if let token = AtelerixPlugin.getDeviceToken() {
            result(token)
        } else {
            // ✅ انتظر وصول التوكن (بدون error)
            AtelerixPlugin.pendingTokenCallbacks.append(result)
        }
    }
}

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "getPlatformVersion":
            result(UIDevice.current.systemVersion)

        case "getAppID":
            if let bundleId = Bundle.main.bundleIdentifier {
                result(bundleId)
            } else {
                result(FlutterError(
                    code: "NO_BUNDLE_ID",
                    message: "Bundle ID not found",
                    details: nil
                ))
            }

        // ✅ طلب صلاحيات الإشعارات فقط
        case "requestPermissions":
            requestPermissionsOnly(result: result)

        // ✅ طلب صلاحيات الإشعارات والحصول على Token
        case "getDeviceToken":
                     requestNotificationPermissions(result: result)
        // ✅ التحقق من حالة صلاحيات الإشعارات
        case "checkNotificationPermission":
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let status: String
                switch settings.authorizationStatus {
                case .authorized:
                    status = "authorized"
                case .denied:
                    status = "denied"
                case .notDetermined:
                    status = "notDetermined"
                case .provisional:
                    status = "provisional"
                case .ephemeral:
                    status = "ephemeral"
                @unknown default:
                    status = "unknown"
                }
                result(status)
            }

        // ✅ مسح badge counter
        case "clearBadge":
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
                result(nil)
            }

        // ✅ Vendor Identifier (UUID - مختلف تماماً عن Device Token)
        case "getVendorIdentifier":
            if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
                result(vendorId)
            } else {
                result(FlutterError(
                    code: "NO_VENDOR_ID",
                    message: "Vendor identifier not available",
                    details: nil
                ))
            }

        case "getMemorySize":
            let memorySize = ProcessInfo.processInfo.physicalMemory
            result(Int64(memorySize))

        case "getArch":
            var utsnameInstance = utsname()
            uname(&utsnameInstance)
            let machineMirror = Mirror(reflecting: utsnameInstance.machine)
            let identifier = machineMirror.children.reduce("") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return identifier }
                return identifier + String(UnicodeScalar(UInt8(value)))
            }
            result(identifier)

        case "getSystemName":
            result(UIDevice.current.systemName)

        case "getDeviceName":
            result(UIDevice.current.name)

        case "getCountryCode":
            let country = Locale.current.regionCode ?? "Unknown"
            result(country)

        case "getTimeZone":
            let timezone = TimeZone.current.identifier
            result(timezone)

        case "getFreeMemory":
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            do {
                let values = try fileURL.resourceValues(
                    forKeys: [.volumeAvailableCapacityForImportantUsageKey]
                )
                if let capacity = values.volumeAvailableCapacityForImportantUsage {
                    result(Int64(capacity))
                } else {
                    result(FlutterError(
                        code: "NO_CAPACITY",
                        message: "Capacity unavailable",
                        details: nil
                    ))
                }
            } catch {
                result(FlutterError(
                    code: "IO_ERROR",
                    message: error.localizedDescription,
                    details: nil
                ))
            }

        // ✅ Register device (no-op for iOS, required for Android compatibility)
        case "register":
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

// ✅ Extension لـ FlutterAppDelegate لتبسيط التكامل
extension FlutterAppDelegate {

    /// يجب استدعاء هذه الدالة في AppDelegate لتمرير الـ device token
    @objc open func atelerix_didRegisterForRemoteNotifications(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceData: Data
    ) {
        let token = deviceData.map { String(format: "%02.2hhx", $0) }.joined()
        AtelerixPlugin.setDeviceToken(token)
    }

    /// يجب استدعاء هذه الدالة في AppDelegate عند فشل التسجيل
    @objc open func atelerix_didFailToRegisterForRemoteNotifications(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ [Atelerix] Failed to register for remote notifications: \(error.localizedDescription)")
    }
}