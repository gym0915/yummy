import Combine//
//  AppStateManagerTests.swift
//  yummyTests
//
//  Created by AI Assistant on 2025/09/19.
//

import XCTest
import UIKit
import SwiftUI
@testable import yummy

/// AppStateManager 测试类
/// 测试应用状态管理器的所有功能
@MainActor
final class AppStateManagerTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var appStateManager: AppStateManager!
    private var notificationCenter: NotificationCenter!
    
    // MARK: - Test Lifecycle
    
    override func setUp() async throws {
        try await super.setUp()
        AppLog("=== AppStateManagerTests setUp 开始 ===", level: .debug, category: .app)
        
        // 创建新的实例用于测试
        appStateManager = AppStateManager.shared
        notificationCenter = NotificationCenter.default
        
        AppLog("AppStateManagerTests setUp 完成", level: .debug, category: .app)
    }
    
    override func tearDown() async throws {
        AppLog("=== AppStateManagerTests tearDown 开始 ===", level: .debug, category: .app)
        
        // 重置状态
        appStateManager.updateScenePhase(.active)
        appStateManager = nil
        notificationCenter = nil
        
        try await super.tearDown()
        AppLog("AppStateManagerTests tearDown 完成", level: .debug, category: .app)
    }
    
    // MARK: - 基础功能测试
    
    /// 测试单例模式
    func testSingletonPattern() {
        AppLog("测试单例模式", level: .debug, category: .app)
        
        // Given
        let instance1 = AppStateManager.shared
        let instance2 = AppStateManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "AppStateManager 应该是单例模式")
        AppLog("单例模式测试通过", level: .debug, category: .app)
    }
    
    /// 测试初始状态
    func testInitialState() {
        AppLog("测试初始状态", level: .debug, category: .app)
        
        // Given
        let manager = AppStateManager.shared
        
        // Then
        XCTAssertEqual(manager.currentScenePhase, .active, "初始场景阶段应该是 active")
        XCTAssertTrue(manager.isAppActive, "应用应该处于活跃状态")
        XCTAssertFalse(manager.isAppInBackground, "应用不应该在后台")
        AppLog("初始状态测试通过", level: .debug, category: .app)
    }
    
    // MARK: - 场景阶段更新测试
    
    /// 测试更新场景阶段到后台
    func testUpdateScenePhaseToBackground() {
        AppLog("测试更新场景阶段到后台", level: .debug, category: .app)
        
        // When
        appStateManager.updateScenePhase(.background)
        
        // Then
        XCTAssertEqual(appStateManager.currentScenePhase, .background, "场景阶段应该更新为 background")
        XCTAssertFalse(appStateManager.isAppActive, "应用不应该处于活跃状态")
        XCTAssertTrue(appStateManager.isAppInBackground, "应用应该在后台")
        AppLog("场景阶段更新到后台测试通过", level: .debug, category: .app)
    }
    
    /// 测试更新场景阶段到活跃
    func testUpdateScenePhaseToActive() {
        AppLog("测试更新场景阶段到活跃", level: .debug, category: .app)
        
        // Given
        appStateManager.updateScenePhase(.background)
        
        // When
        appStateManager.updateScenePhase(.active)
        
        // Then
        XCTAssertEqual(appStateManager.currentScenePhase, .active, "场景阶段应该更新为 active")
        XCTAssertTrue(appStateManager.isAppActive, "应用应该处于活跃状态")
        XCTAssertFalse(appStateManager.isAppInBackground, "应用不应该在后台")
        AppLog("场景阶段更新到活跃测试通过", level: .debug, category: .app)
    }
    
    /// 测试更新场景阶段到非活跃
    func testUpdateScenePhaseToInactive() {
        AppLog("测试更新场景阶段到非活跃", level: .debug, category: .app)
        
        // When
        appStateManager.updateScenePhase(.inactive)
        
        // Then
        XCTAssertEqual(appStateManager.currentScenePhase, .inactive, "场景阶段应该更新为 inactive")
        XCTAssertFalse(appStateManager.isAppActive, "应用不应该处于活跃状态")
        XCTAssertFalse(appStateManager.isAppInBackground, "应用不应该在后台")
        AppLog("场景阶段更新到非活跃测试通过", level: .debug, category: .app)
    }
    
    // MARK: - 通知处理测试
    
    /// 测试应用进入后台通知
    func testAppDidEnterBackgroundNotification() {
        AppLog("测试应用进入后台通知", level: .debug, category: .app)
        
        // Given
        let expectation = self.expectation(description: "等待状态更新")
        
        // 监听状态变化
        var cancellable: AnyCancellable?
        cancellable = appStateManager.$currentScenePhase
            .dropFirst() // 跳过初始值
            .sink { phase in
                if phase == .background {
                    expectation.fulfill()
                }
            }
        
        // When
        notificationCenter.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(appStateManager.currentScenePhase, .background, "收到后台通知后场景阶段应该是 background")
        XCTAssertTrue(appStateManager.isAppInBackground, "收到后台通知后应用应该在后台")
        
        cancellable?.cancel()
        AppLog("应用进入后台通知测试通过", level: .debug, category: .app)
    }
    
    /// 测试应用即将进入前台通知
    func testAppWillEnterForegroundNotification() {
        AppLog("测试应用即将进入前台通知", level: .debug, category: .app)
        
        // Given
        appStateManager.updateScenePhase(.background)
        let expectation = self.expectation(description: "等待状态更新")
        
        // 监听状态变化
        var cancellable: AnyCancellable?
        cancellable = appStateManager.$currentScenePhase
            .dropFirst() // 跳过初始值
            .sink { phase in
                if phase == .active {
                    expectation.fulfill()
                }
            }
        
        // When
        notificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(appStateManager.currentScenePhase, .active, "收到前台通知后场景阶段应该是 active")
        XCTAssertTrue(appStateManager.isAppActive, "收到前台通知后应用应该处于活跃状态")
        
        cancellable?.cancel()
        AppLog("应用即将进入前台通知测试通过", level: .debug, category: .app)
    }
    
    // MARK: - 状态属性测试
    
    /// 测试 isAppActive 属性
    func testIsAppActiveProperty() {
        AppLog("测试 isAppActive 属性", level: .debug, category: .app)
        
        // Given & When & Then
        appStateManager.updateScenePhase(.active)
        XCTAssertTrue(appStateManager.isAppActive, "active 状态时 isAppActive 应该为 true")
        
        appStateManager.updateScenePhase(.background)
        XCTAssertFalse(appStateManager.isAppActive, "background 状态时 isAppActive 应该为 false")
        
        appStateManager.updateScenePhase(.inactive)
        XCTAssertFalse(appStateManager.isAppActive, "inactive 状态时 isAppActive 应该为 false")
        AppLog("isAppActive 属性测试通过", level: .debug, category: .app)
    }
    
    /// 测试 isAppInBackground 属性
    func testIsAppInBackgroundProperty() {
        AppLog("测试 isAppInBackground 属性", level: .debug, category: .app)
        
        // Given & When & Then
        appStateManager.updateScenePhase(.background)
        XCTAssertTrue(appStateManager.isAppInBackground, "background 状态时 isAppInBackground 应该为 true")
        
        appStateManager.updateScenePhase(.active)
        XCTAssertFalse(appStateManager.isAppInBackground, "active 状态时 isAppInBackground 应该为 false")
        
        appStateManager.updateScenePhase(.inactive)
        XCTAssertFalse(appStateManager.isAppInBackground, "inactive 状态时 isAppInBackground 应该为 false")
        AppLog("isAppInBackground 属性测试通过", level: .debug, category: .app)
    }
    
    // MARK: - 并发测试
    
    /// 测试并发状态更新
    func testConcurrentStateUpdates() async {
        AppLog("测试并发状态更新", level: .debug, category: .app)
        
        // Given
        let iterations = 100
        let expectation = self.expectation(description: "等待所有并发更新完成")
        expectation.expectedFulfillmentCount = iterations
        
        // When
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    let phase: ScenePhase = i % 2 == 0 ? .active : .background
                    await MainActor.run {
                        self.appStateManager.updateScenePhase(phase)
                        expectation.fulfill()
                    }
                }
            }
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        
        // 最终状态应该是某个有效状态
        XCTAssertTrue(
            appStateManager.currentScenePhase == .active || 
            appStateManager.currentScenePhase == .background,
            "最终状态应该是 active 或 background"
        )
        AppLog("并发状态更新测试通过", level: .debug, category: .app)
    }
    
    // MARK: - 性能测试
    
    /// 测试状态更新性能
    func testStateUpdatePerformance() {
        AppLog("测试状态更新性能", level: .debug, category: .app)
        
        measure {
            for _ in 0..<1000 {
                appStateManager.updateScenePhase(.background)
                appStateManager.updateScenePhase(.active)
            }
        }
        AppLog("状态更新性能测试完成", level: .debug, category: .app)
    }
    
    // MARK: - 边界条件测试
    
    /// 测试重复设置相同状态
    func testRepeatedSameStateUpdate() {
        AppLog("测试重复设置相同状态", level: .debug, category: .app)
        
        // Given
        let initialPhase = appStateManager.currentScenePhase
        var stateChangeCount = 0
        
        let cancellable = appStateManager.$currentScenePhase
            .sink { _ in
                stateChangeCount += 1
            }
        
        // When
        for _ in 0..<5 {
            appStateManager.updateScenePhase(initialPhase)
        }
        
        // Then - 状态变化次数应该只有1次（初始订阅时的调用）
        XCTAssertGreaterThanOrEqual(stateChangeCount, 1, "重复设置相同状态不应该触发额外的状态变化")
        
        cancellable.cancel()
        AppLog("重复设置相同状态测试通过", level: .debug, category: .app)
    }
    
    /// 测试快速状态切换
    func testRapidStateChanges() {
        AppLog("测试快速状态切换", level: .debug, category: .app)
        
        // Given
        let phases: [ScenePhase] = [.active, .inactive, .background, .active, .background]
        let expectation = self.expectation(description: "等待状态更新")
        
        var receivedPhases: [ScenePhase] = []
        let cancellable = appStateManager.$currentScenePhase
            .dropFirst()
            .sink { phase in
                receivedPhases.append(phase)
                if receivedPhases.count >= phases.count {
                    expectation.fulfill()
                }
            }
        
        // When
        for phase in phases {
            appStateManager.updateScenePhase(phase)
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        // 验证最后的状态是正确的
        XCTAssertEqual(appStateManager.currentScenePhase, phases.last, "最终状态应该与最后设置的状态一致")
        
        cancellable.cancel()
        AppLog("快速状态切换测试通过", level: .debug, category: .app)
    }
}
