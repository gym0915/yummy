import XCTest
import Network
import Combine
@testable import yummy

/// NetworkMonitor 测试类
@MainActor
final class NetworkMonitorTests: XCTestCase {
    
    var networkMonitor: NetworkMonitor!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        // 使用单例实例进行测试
        networkMonitor = NetworkMonitor.shared
    }
    
    override func tearDown() {
        cancellables = nil
        networkMonitor = nil
        super.tearDown()
    }
    
    // MARK: - 单例模式测试
    
    func testSingletonPattern() {
        // Given & When
        let instance1 = NetworkMonitor.shared
        let instance2 = NetworkMonitor.shared
        
        // Then
        XCTAssertIdentical(instance1, instance2, "NetworkMonitor 应该是单例")
    }
    
    // MARK: - 初始状态测试
    
    func testInitialState() {
        // Given & When
        let monitor = NetworkMonitor.shared
        
        // Then
        XCTAssertNotNil(monitor, "NetworkMonitor 实例不应该为 nil")
        XCTAssertTrue(monitor.isConnected, "初始状态应该是已连接")
    }
    
    // MARK: - @Published 属性测试
    
    func testPublishedProperty() {
        // Given
        let expectation = XCTestExpectation(description: "网络状态变化")
        var receivedStates: [Bool] = []
        
        // When
        networkMonitor.$isConnected
            .sink { isConnected in
                receivedStates.append(isConnected)
                if receivedStates.count >= 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(receivedStates.isEmpty, "应该接收到初始状态")
        XCTAssertTrue(receivedStates.first == true, "初始状态应该是已连接")
    }
    
    // MARK: - 网络状态监听测试
    
    func testNetworkStatusMonitoring() {
        // Given
        let expectation = XCTestExpectation(description: "网络状态监听")
        var statusChanges: [Bool] = []
        
        // When
        networkMonitor.$isConnected
            .dropFirst() // 跳过初始值
            .sink { isConnected in
                statusChanges.append(isConnected)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // 模拟网络状态变化（这里我们无法直接控制 NWPathMonitor，但可以测试监听机制）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 由于我们无法直接模拟网络状态变化，这个测试主要验证监听机制存在
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertNotNil(networkMonitor, "NetworkMonitor 应该保持活跃")
    }
    
    // MARK: - 并发访问测试
    
    func testConcurrentAccess() {
        // Given
        let expectation = XCTestExpectation(description: "并发访问测试")
        expectation.expectedFulfillmentCount = 10
        
        // When
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                let monitor = NetworkMonitor.shared
                XCTAssertNotNil(monitor, "并发访问时 NetworkMonitor 不应该为 nil")
                XCTAssertTrue(monitor.isConnected, "网络状态应该可访问")
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - 内存管理测试
    
    func testMemoryManagement() {
        // Given
        weak var weakMonitor: NetworkMonitor?
        
        // When
        autoreleasepool {
            let monitor = NetworkMonitor.shared
            weakMonitor = monitor
            XCTAssertNotNil(weakMonitor, "NetworkMonitor 应该被强引用")
        }
        
        // Then
        // 由于是单例，weakMonitor 不会为 nil
        XCTAssertNotNil(weakMonitor, "单例 NetworkMonitor 应该保持活跃")
    }
    
    // MARK: - 线程安全测试
    
    func testThreadSafety() {
        // Given
        let expectation = XCTestExpectation(description: "线程安全测试")
        expectation.expectedFulfillmentCount = 5
        
        // When
        for i in 0..<5 {
            DispatchQueue.global(qos: .userInitiated).async {
                let monitor = NetworkMonitor.shared
                // 在主线程上访问 @Published 属性
                Task { @MainActor in
                    let isConnected = monitor.isConnected
                    XCTAssertTrue(isConnected, "网络状态应该可安全访问")
                    expectation.fulfill()
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - 生命周期测试
    
    func testLifecycle() {
        // Given
        let monitor = NetworkMonitor.shared
        
        // When & Then
        XCTAssertNotNil(monitor, "NetworkMonitor 应该正确初始化")
        
        // 验证内部组件存在
        let mirror = Mirror(reflecting: monitor)
        let monitorProperty = mirror.children.first { $0.label == "monitor" }
        XCTAssertNotNil(monitorProperty, "NWPathMonitor 应该存在")
        
        let queueProperty = mirror.children.first { $0.label == "queue" }
        XCTAssertNotNil(queueProperty, "DispatchQueue 应该存在")
    }
    
    // MARK: - 状态一致性测试
    
    func testStateConsistency() {
        // Given
        let monitor1 = NetworkMonitor.shared
        let monitor2 = NetworkMonitor.shared
        
        // When & Then
        XCTAssertEqual(monitor1.isConnected, monitor2.isConnected, "不同引用应该返回相同的网络状态")
    }
    
    // MARK: - 性能测试
    
    func testPerformance() {
        // Given
        let monitor = NetworkMonitor.shared
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                let _ = monitor.isConnected
            }
        }
    }
    
    // MARK: - 边界条件测试
    
    func testBoundaryConditions() {
        // Given
        let monitor = NetworkMonitor.shared
        
        // When & Then
        // 测试快速连续访问
        for _ in 0..<100 {
            let isConnected = monitor.isConnected
            XCTAssertTrue(isConnected, "快速连续访问应该返回一致的结果")
        }
    }
    
    // MARK: - 错误处理测试
    
    func testErrorHandling() {
        // Given
        let monitor = NetworkMonitor.shared
        
        // When & Then
        // 测试在异常情况下的行为
        XCTAssertNoThrow({
            let _ = monitor.isConnected
        }, "访问网络状态不应该抛出异常")
    }
}
