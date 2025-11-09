import Flutter
import UIKit
import CoreLocation
import UserNotifications

class GeofencingMethodCallHandler: NSObject, CLLocationManagerDelegate {
    private let binaryMessenger: FlutterBinaryMessenger
    private var locationManager: CLLocationManager?
    private var isBackgroundLocationEnabled = false
    
    init(binaryMessenger: FlutterBinaryMessenger) {
        self.binaryMessenger = binaryMessenger
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = 15 // 15 mètres
    }
    
    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startBackgroundLocation":
            startBackgroundLocation(result: result)
        case "stopBackgroundLocation":
            stopBackgroundLocation(result: result)
        case "isBackgroundLocationEnabled":
            result(isBackgroundLocationEnabled)
        case "requestLocationPermissions":
            requestLocationPermissions(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startBackgroundLocation(result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            result(FlutterError(code: "LOCATION_MANAGER_ERROR", message: "Location manager not initialized", details: nil))
            return
        }
        
        // Vérifier les permissions
        let authorizationStatus = locationManager.authorizationStatus
        guard authorizationStatus == .authorizedAlways else {
            result(FlutterError(code: "PERMISSION_DENIED", message: "Always location permission required", details: nil))
            return
        }
        
        // Démarrer la localisation en arrière-plan
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
        
        isBackgroundLocationEnabled = true
        
        // Sauvegarder l'état dans UserDefaults
        UserDefaults.standard.set(true, forKey: "background_location_enabled")
        
        print("iOS GeofencingHandler: Background location started")
        result(true)
    }
    
    private func stopBackgroundLocation(result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            result(FlutterError(code: "LOCATION_MANAGER_ERROR", message: "Location manager not initialized", details: nil))
            return
        }
        
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        
        isBackgroundLocationEnabled = false
        
        // Sauvegarder l'état dans UserDefaults
        UserDefaults.standard.set(false, forKey: "background_location_enabled")
        
        print("iOS GeofencingHandler: Background location stopped")
        result(true)
    }
    
    private func requestLocationPermissions(result: @escaping FlutterResult) {
        guard let locationManager = locationManager else {
            result(FlutterError(code: "LOCATION_MANAGER_ERROR", message: "Location manager not initialized", details: nil))
            return
        }
        
        let authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
            result("requested")
        case .denied, .restricted:
            result("denied")
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
            result("when_in_use")
        case .authorizedAlways:
            result("always")
        @unknown default:
            result("unknown")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Envoyer la position à Flutter
        let locationData: [String: Any] = [
            "latitude": location.coordinate.latitude,
            "longitude": location.coordinate.longitude,
            "accuracy": location.horizontalAccuracy,
            "timestamp": location.timestamp.timeIntervalSince1970 * 1000, // en millisecondes
            "speed": location.speed,
            "heading": location.course
        ]
        
        let channel = FlutterMethodChannel(name: "com.alertcontacts/location_updates", binaryMessenger: binaryMessenger)
        channel.invokeMethod("onLocationUpdate", arguments: locationData)
        
        print("iOS GeofencingHandler: Location update sent - \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("iOS GeofencingHandler: Location error - \(error.localizedDescription)")
        
        let channel = FlutterMethodChannel(name: "com.alertcontacts/location_updates", binaryMessenger: binaryMessenger)
        channel.invokeMethod("onLocationError", arguments: error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("iOS GeofencingHandler: Authorization status changed to \(status.rawValue)")
        
        let statusString: String
        switch status {
        case .notDetermined:
            statusString = "not_determined"
        case .denied, .restricted:
            statusString = "denied"
        case .authorizedWhenInUse:
            statusString = "when_in_use"
        case .authorizedAlways:
            statusString = "always"
        @unknown default:
            statusString = "unknown"
        }
        
        let channel = FlutterMethodChannel(name: "com.alertcontacts/location_updates", binaryMessenger: binaryMessenger)
        channel.invokeMethod("onAuthorizationChanged", arguments: statusString)
        
        // Si on avait la permission "always" et qu'elle a été révoquée, arrêter le service
        if isBackgroundLocationEnabled && status != .authorizedAlways {
            stopBackgroundLocation { _ in }
        }
    }
    
    // Restaurer l'état après redémarrage de l'app
    func restoreBackgroundLocationIfNeeded() {
        let wasEnabled = UserDefaults.standard.bool(forKey: "background_location_enabled")
        if wasEnabled && locationManager?.authorizationStatus == .authorizedAlways {
            startBackgroundLocation { result in
                print("iOS GeofencingHandler: Background location restored after app restart")
            }
        }
    }
}