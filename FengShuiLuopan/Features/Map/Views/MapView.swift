// MapView.swift
// 地图视图 - SwiftUI封装
// 见 PHASE_V0_SPEC.md, PHASE_V1_SPEC.md, PHASE_V2_SPEC.md

import SwiftUI
import MAMapKit
import AMapFoundationKit

/// 地图视图（SwiftUI）
struct MapView: View {

    @ObservedObject var viewModel: MapViewModel
    @StateObject private var locationService = LocationService()
    @State private var mapController: GaodeMapController?

    var body: some View {
        ZStack {
            // 地图容器
            MapContainerView(mapController: $mapController)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    // 初始化高德SDK
                    AMapServices.shared().apiKey = "16d5c89d0a14758cae55c218e2bd3322"

                    // 设置地图控制器
                    if let controller = mapController {
                        viewModel.setMapController(controller)
                    }

                    // 设置位置服务（GPS原点）
                    viewModel.setupLocationService(locationService)

                    // 请求定位权限
                    locationService.requestLocationPermission()
                }

            // 屏幕中心十字指示
            CrosshairView()

            // 生活圈横幅（Phase 4）— 显示在地图顶部
            if viewModel.isInLifeCircleMode {
                VStack {
                    LifeCircleBanner(
                        lifeCircleViewModel: viewModel.lifeCircleViewModel,
                        mapViewModel: viewModel
                    )
                    .padding(.top, 44)  // 留出状态栏高度
                    Spacer()
                }
                .edgesIgnoringSafeArea(.top)
            }

            // 解锁模式下的罗盘（屏幕中心）
            if viewModel.compassMode == .unlocked {
                CompassOverlayView()
            }

            // 右侧控制按钮区
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 16) {
                        // 加号按钮（添加原点/终点）
                        ControlButton(icon: "plus", backgroundColor: .blue) {
                            handleAddButtonTap()
                        }

                        // 放大按钮
                        ControlButton(icon: "plus.magnifyingglass", backgroundColor: .gray) {
                            viewModel.zoomIn()
                        }

                        // 缩小按钮
                        ControlButton(icon: "minus.magnifyingglass", backgroundColor: .gray) {
                            viewModel.zoomOut()
                        }

                        // 地图类型切换按钮
                        ControlButton(
                            icon: viewModel.mapType == .standard ? "map" : "globe.asia.australia",
                            backgroundColor: .gray
                        ) {
                            viewModel.toggleMapType()
                        }

                        // 定位按钮（Phase 1）
                        ControlButton(icon: "location.fill", backgroundColor: .green) {
                            viewModel.moveToCurrentLocation(userLocation: locationService.currentLocation)
                        }

                        // 罗盘模式切换按钮（Phase 1）
                        ControlButton(
                            icon: viewModel.compassMode == .locked ? "lock.fill" : "lock.open.fill",
                            backgroundColor: .orange
                        ) {
                            viewModel.toggleCompassMode()
                        }

                        // 原点按钮（Phase 2）
                        ControlButton(icon: "mappin.circle.fill", backgroundColor: .red) {
                            viewModel.showOriginSelectorDialog()
                        }

                        // 终点按钮（Phase 2）
                        ControlButton(icon: "mappin", backgroundColor: .blue) {
                            viewModel.showDestinationSelectorDialog()
                        }

                        // 清除按钮
                        ControlButton(icon: "trash", backgroundColor: .red) {
                            viewModel.clearAll()
                        }

                        // 扇形搜索按钮（Phase 3）
                        ControlButton(icon: "circle.dashed", backgroundColor: .purple) {
                            viewModel.sectorSearchViewModel.restoreLastConfig()
                            viewModel.showSectorSearch = true
                        }

                        // 更多菜单按钮（Phase 4 + Phase 5）
                        Menu {
                            Button(action: {
                                viewModel.showLifeCircleWizard = true
                            }) {
                                Label("生活圈模式", systemImage: "house.circle")
                            }

                            Divider()

                            Button(action: {
                                viewModel.showSettings = true
                            }) {
                                Label("设置", systemImage: "gear")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                                .frame(width: 50, height: 50)
                                .background(Color.gray.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                    }
                    .padding()
                }
                Spacer()
            }

            // 连线信息面板（Phase 2：支持多连线）
            if viewModel.showConnectionPanel, !viewModel.connections.isEmpty, !viewModel.isCrosshairMode {
                VStack {
                    Spacer()
                    MultiConnectionInfoPanel(
                        connections: viewModel.connections,
                        onClose: {
                            viewModel.showConnectionPanel = false
                        }
                    )
                    .padding()
                }
            }

            // 十字准心保存面板（Phase 3）
            if viewModel.isCrosshairMode {
                VStack {
                    Spacer()
                    CrosshairSavePanel(
                        mapViewModel: viewModel,
                        onSave: {
                            // 保存成功后自动退出
                        },
                        onCancel: {
                            viewModel.exitCrosshairMode()
                        }
                    )
                }
            }

            // 扇形搜索结果消息（Phase 3）
            if let message = viewModel.sectorSearchMessage {
                VStack {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.blue.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.top, 50)
                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        viewModel.sectorSearchMessage = nil
                    }
                }
            }

            // 加点对话框（Phase 2）
            if viewModel.showAddPointDialog {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        viewModel.showAddPointDialog = false
                    }
            }

            // 原点选择器（Phase 2）
            if viewModel.showOriginSelector {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        viewModel.showOriginSelector = false
                    }
            }

            // 终点选择器（Phase 2）
            if viewModel.showDestinationSelector {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        viewModel.showDestinationSelector = false
                    }
            }

            // 终点信息覆盖层（Phase 2：支持多终点）
            ForEach(Array(viewModel.connections.enumerated()), id: \.offset) { index, connection in
                DestinationOverlay(
                    destination: connection.destination,
                    connection: connection,
                    mapController: mapController
                )
            }

            // 权限提示
            if locationService.authorizationStatus == .denied ||
               locationService.authorizationStatus == .restricted {
                VStack {
                    Text("需要位置权限才能使用定位功能")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.top, 50)
                    Spacer()
                }
            }

            // 错误提示（Phase 2）
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.top, 50)
                    Spacer()
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        viewModel.clearError()
                    }
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddPointDialog) {
            AddPointDialog(
                coordinate: viewModel.mapCenterCoordinate ?? WGS84Coordinate(latitude: 39.9, longitude: 116.4),
                cases: viewModel.getAllCases(),
                onAdd: { name, caseId, pointType in
                    viewModel.addPoint(name: name, caseId: caseId, pointType: pointType)
                }
            )
        }
        .sheet(isPresented: $viewModel.showOriginSelector) {
            OriginSelectorView(
                origins: viewModel.getOriginsForCurrentCase(),
                onSelect: { origin in
                    viewModel.selectOrigin(origin)
                }
            )
        }
        .sheet(isPresented: $viewModel.showDestinationSelector) {
            DestinationSelectorView(
                destinations: viewModel.getDestinationsForCurrentCase(),
                onConfirm: { destinations, origin in
                    viewModel.selectDestinations(destinations, origin: origin)
                },
                origins: viewModel.getOriginsForCurrentCase()
            )
        }
        .sheet(isPresented: $viewModel.showSectorSearch) {
            SectorSearchView(
                viewModel: viewModel.sectorSearchViewModel,
                mapViewModel: viewModel,
                poiService: viewModel.poiSearchService
            )
        }
        // 生活圈向导：多选原点（Phase 4）
        .sheet(isPresented: $viewModel.showLifeCircleWizard) {
            LifeCircleOriginSelectorView(
                lifeCircleViewModel: viewModel.lifeCircleViewModel,
                mapViewModel: viewModel
            )
        }
        // 生活圈角色分配对话框（Phase 4）
        .sheet(isPresented: $viewModel.showRoleAssignmentSheet) {
            RoleAssignmentDialog(
                lifeCircleViewModel: viewModel.lifeCircleViewModel,
                mapViewModel: viewModel
            )
        }
        // 设置页面（Phase 5）
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
    }

    /// 处理加号按钮点击（Phase 2）
    private func handleAddButtonTap() {
        viewModel.showAddPoint()
    }
}

// MARK: - Compass Overlay View (Unlocked Mode)

/// 解锁模式下的罗盘覆盖层（固定在屏幕中心）
struct CompassOverlayView: View {
    var body: some View {
        Image(uiImage: CompassImageGenerator.generateCompassImage(size: 200))
            .resizable()
            .frame(width: 200, height: 200)
            .opacity(0.7)
    }
}

// MARK: - Crosshair View

/// 屏幕中心十字指示
struct CrosshairView: View {
    var body: some View {
        ZStack {
            // 水平线
            Rectangle()
                .fill(Color.red)
                .frame(width: 40, height: 2)

            // 垂直线
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: 40)

            // 中心圆
            Circle()
                .stroke(Color.red, lineWidth: 2)
                .frame(width: 8, height: 8)
        }
    }
}

// MARK: - Control Button

/// 控制按钮
struct ControlButton: View {
    let icon: String
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 20))
                .frame(width: 50, height: 50)
                .background(backgroundColor.opacity(0.8))
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
}

// MARK: - Map Container (UIViewRepresentable)

/// 地图容器视图（UIKit桥接）
struct MapContainerView: UIViewRepresentable {

    @Binding var mapController: GaodeMapController?

    func makeUIView(context: Context) -> MAMapView {
        let mapView = MAMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none

        // 创建控制器
        let controller = GaodeMapController(mapView: mapView)
        DispatchQueue.main.async {
            self.mapController = controller
        }

        return mapView
    }

    func updateUIView(_ uiView: MAMapView, context: Context) {
        // 不需要更新
    }
}

// MARK: - Destination Overlay

/// 终点信息覆盖层（半透明方框）
struct DestinationOverlay: View {
    let destination: GeoPoint
    let connection: Connection
    let mapController: GaodeMapController?

    @State private var screenPosition: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            if let position = screenPosition {
                VStack(alignment: .leading, spacing: 4) {
                    // 24山（最重要，最大字体）
                    Text(connection.mountain.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    // 点位名称
                    Text(destination.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    // 距离和方位
                    Text("\(connection.formattedDistance) · \(connection.formattedBearing)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(12)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
                .position(x: position.x, y: position.y - 40)  // 显示在终点上方
                .onAppear {
                    updatePosition()
                }
            }
        }
    }

    private func updatePosition() {
        guard let controller = mapController else { return }
        screenPosition = controller.coordinateToScreen(destination.coordinate)
    }
}

// MARK: - Connection Info Panel

/// 连线信息面板
struct ConnectionInfoPanel: View {

    let connection: Connection
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Text("连线信息")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }

            Divider()

            // 原点信息
            Text("原点: \(connection.origin.name)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(connection.origin.coordinate.description)
                .font(.caption)
                .foregroundColor(.gray)

            Divider()

            // 终点信息
            Text("终点: \(connection.destination.name)")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(connection.destination.coordinate.description)
                .font(.caption)
                .foregroundColor(.gray)

            Divider()

            // 方位角
            InfoRow(label: "方位角", value: connection.formattedBearing)

            // 距离
            InfoRow(label: "距离", value: connection.formattedDistance)

            // 24山
            InfoRow(label: "24山", value: connection.mountain.name)

            // 八卦
            InfoRow(label: "八卦", value: connection.trigram.name)

            // 五行
            InfoRow(label: "五行", value: connection.wuxing.rawValue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}

/// 信息行
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        MapView(viewModel: MapViewModel())
    }
}
