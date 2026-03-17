import CoreLocation
import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private var geofencingChannel: FlutterMethodChannel?
  private var geofencingHandler: GeofencingMethodCallHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configurer la clé API Google Maps
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY_IOS") as? String, !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    }

    GeneratedPluginRegistrant.register(with: self)

    // Configuration du channel pour les deep links
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    methodChannel = FlutterMethodChannel(name: "alertcontact/deep_links", binaryMessenger: controller.binaryMessenger)

    methodChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "getInitialLink":
        result(self?.getInitialLink())
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Configuration du channel pour le géofencing
    geofencingChannel = FlutterMethodChannel(name: "com.alertcontacts/geofencing", binaryMessenger: controller.binaryMessenger)
    geofencingHandler = GeofencingMethodCallHandler(binaryMessenger: controller.binaryMessenger)
    geofencingChannel?.setMethodCallHandler(geofencingHandler?.handleMethodCall)

    // Restaurer la géolocalisation en arrière-plan si elle était active
    geofencingHandler?.restoreBackgroundLocationIfNeeded()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Gestion des deep links quand l'app est fermée
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    if url.scheme == "alertcontact" {
      methodChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
      return true
    }
    return super.application(app, open: url, options: options)
  }

  // Gestion des deep links quand l'app est en arrière-plan
  override func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    if let url = userActivity.webpageURL, url.scheme == "alertcontact" {
      methodChannel?.invokeMethod("onDeepLink", arguments: url.absoluteString)
      return true
    }
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }

  private func getInitialLink() -> String? {
    // Pour iOS, on ne peut pas facilement récupérer le lien initial
    // Cette fonctionnalité est gérée par les méthodes ci-dessus
    return nil
  }
}
