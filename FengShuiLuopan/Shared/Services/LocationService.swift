// LocationService.swift
// 定位服务 - GPS权限请求和位置管理
// 见 PHASE_V0_SPEC.md 1.1节

import Foundation
import CoreLocation
import Combine

/// 定位服务
class LocationService: NSObject, ObservableObject {

    // MARK: - Published Properties

    /// 当前位置
    @Published var currentLocation: WGS84Coordinate?

    /// 定位权限状态
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// 是否正在定位
    @Published var isLocating: Bool = false

    // MARK: - Private Properties

    private let locationManager: CLLocationManager

    // MARK: - Initialization

    override init() {
        self.locationManager = CLLocationManager()
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // 10米更新一次

        // 获取当前权限状态
        if #available(iOS 14.0, *) {
            authorizationStatus = locationManager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }
    }

    // MARK: - Public Methods

    /// 请求定位权限
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 开始定位
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            // 权限未授予，请求权限
            requestLocationPermission()
            return
        }

        isLocating = true
        locationManager.startUpdatingLocation()
    }

    /// 停止定位
    func stopUpdatingLocation() {
        isLocating = false
        locationManager.stopUpdatingLocation()
    }

    /// 获取一次位置
    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }

        locationManager.requestLocation()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    /// 权限状态变化
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            authorizationStatus = manager.authorizationStatus
        } else {
            authorizationStatus = CLLocationManager.authorizationStatus()
        }

        // 权限授予后自动开始定位
        if authorizationStatus == .authorizedWhenInUse ||
           authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }

    /// 位置更新
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        currentLocation = WGS84Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    /// 定位失败
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("定位失败: \(error.localizedDescription)")
        isLocating = false
    }
}
