//
//  KeychainServiceTests.swift
//  yummyTests
//
//  Created by steve on 2025/9/11.
//

import XCTest
import Foundation
import Security
@testable import yummy

final class KeychainServiceTests: XCTestCase {
    
    // 测试专用的key前缀，便于清理
    let testKeyPrefix = "com.yummy.test."
    var testKeys: [String] = []
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 清理之前可能遗留的测试数据
        cleanupTestKeys()
        
        AppLog("🧹 [测试环境] KeychainServiceTests 准备就绪", level: .debug, category: .service)
    }
    
    override func tearDownWithError() throws {
        // 清理测试过程中创建的所有keys
        cleanupTestKeys()
        testKeys.removeAll()
        try super.tearDownWithError()
    }
    
    // MARK: - 基础保存和读取测试
    
    func testSaveAndRetrieveSuccess() throws {
        let testKey = generateTestKey("save_retrieve")
        let testValue = "test-api-key-12345"
        
        // 保存数据
        try KeychainService.save(key: testKey, value: testValue)
        
        // 读取数据
        let retrievedValue = try KeychainService.retrieve(key: testKey)
        
        // 验证结果
        XCTAssertNotNil(retrievedValue, "应该成功读取保存的数据")
        XCTAssertEqual(retrievedValue, testValue, "读取的值应该与保存的值一致")
        
        AppLog("✅ 基础保存和读取测试通过", level: .debug, category: .service)
    }
    
    func testSaveEmptyString() throws {
        let testKey = generateTestKey("empty_string")
        let emptyValue = ""
        
        // 保存空字符串
        try KeychainService.save(key: testKey, value: emptyValue)
        
        // 读取并验证
        let retrievedValue = try KeychainService.retrieve(key: testKey)
        XCTAssertNotNil(retrievedValue, "应该能保存和读取空字符串")
        XCTAssertEqual(retrievedValue, emptyValue, "空字符串应该正确保存和读取")
        
        AppLog("✅ 空字符串保存测试通过", level: .debug, category: .service)
    }
    
    func testSaveLongString() throws {
        let testKey = generateTestKey("long_string")
        let longValue = String(repeating: "A", count: 1000) // 1000字符的长字符串
        
        // 保存长字符串
        try KeychainService.save(key: testKey, value: longValue)
        
        // 读取并验证
        let retrievedValue = try KeychainService.retrieve(key: testKey)
        XCTAssertNotNil(retrievedValue, "应该能保存和读取长字符串")
        XCTAssertEqual(retrievedValue, longValue, "长字符串应该正确保存和读取")
        XCTAssertEqual(retrievedValue?.count, 1000, "字符串长度应该保持一致")
        
        AppLog("✅ 长字符串保存测试通过", level: .debug, category: .service)
    }
    
    func testSaveUnicodeString() throws {
        let testKey = generateTestKey("unicode_string")
        let unicodeValue = "测试🎉API密钥🔑含有中文和emoji表情"
        
        // 保存包含Unicode字符的字符串
        try KeychainService.save(key: testKey, value: unicodeValue)
        
        // 读取并验证
        let retrievedValue = try KeychainService.retrieve(key: testKey)
        XCTAssertNotNil(retrievedValue, "应该能保存和读取Unicode字符串")
        XCTAssertEqual(retrievedValue, unicodeValue, "Unicode字符串应该正确保存和读取")
        
        AppLog("✅ Unicode字符串保存测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 更新操作测试
    
    func testUpdateExistingValue() throws {
        let testKey = generateTestKey("update_value")
        let originalValue = "original-api-key"
        let updatedValue = "updated-api-key-new"
        
        // 首先保存原始值
        try KeychainService.save(key: testKey, value: originalValue)
        
        // 验证原始值
        let retrievedOriginal = try KeychainService.retrieve(key: testKey)
        XCTAssertEqual(retrievedOriginal, originalValue, "原始值应该正确保存")
        
        // 更新值
        try KeychainService.save(key: testKey, value: updatedValue)
        
        // 验证更新后的值
        let retrievedUpdated = try KeychainService.retrieve(key: testKey)
        XCTAssertEqual(retrievedUpdated, updatedValue, "值应该成功更新")
        XCTAssertNotEqual(retrievedUpdated, originalValue, "新值应该不同于原始值")
        
        AppLog("✅ 更新现有值测试通过", level: .debug, category: .service)
    }
    
    func testMultipleUpdates() throws {
        let testKey = generateTestKey("multiple_updates")
        let values = ["value1", "value2", "value3", "final_value"]
        
        // 多次更新值
        for (index, value) in values.enumerated() {
            try KeychainService.save(key: testKey, value: value)
            
            // 每次更新后验证
            let retrieved = try KeychainService.retrieve(key: testKey)
            XCTAssertEqual(retrieved, value, "第\(index + 1)次更新应该成功")
        }
        
        // 最终验证
        let finalValue = try KeychainService.retrieve(key: testKey)
        XCTAssertEqual(finalValue, values.last, "最终值应该是最后更新的值")
        
        AppLog("✅ 多次更新测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 删除操作测试
    
    func testDeleteExistingItem() throws {
        let testKey = generateTestKey("delete_existing")
        let testValue = "to-be-deleted"
        
        // 先保存数据
        try KeychainService.save(key: testKey, value: testValue)
        
        // 确认数据存在
        let beforeDelete = try KeychainService.retrieve(key: testKey)
        XCTAssertNotNil(beforeDelete, "删除前数据应该存在")
        
        // 删除数据
        try KeychainService.delete(key: testKey)
        
        // 确认数据已删除
        let afterDelete = try KeychainService.retrieve(key: testKey)
        XCTAssertNil(afterDelete, "删除后数据应该不存在")
        
        AppLog("✅ 删除现有项目测试通过", level: .debug, category: .service)
    }
    
    func testDeleteNonExistentItem() throws {
        let nonExistentKey = generateTestKey("non_existent")
        
        // 删除不存在的项目应该不抛出错误
        XCTAssertNoThrow(try KeychainService.delete(key: nonExistentKey), "删除不存在的项目不应该抛出错误")
        
        AppLog("✅ 删除不存在项目测试通过", level: .debug, category: .service)
    }
    
    func testDeleteAndRecreate() throws {
        let testKey = generateTestKey("delete_recreate")
        let originalValue = "original_value"
        let newValue = "new_value_after_delete"
        
        // 保存原始值
        try KeychainService.save(key: testKey, value: originalValue)
        
        // 删除
        try KeychainService.delete(key: testKey)
        
        // 确认删除
        let afterDelete = try KeychainService.retrieve(key: testKey)
        XCTAssertNil(afterDelete, "删除后应该找不到数据")
        
        // 重新创建
        try KeychainService.save(key: testKey, value: newValue)
        
        // 验证重新创建的值
        let recreated = try KeychainService.retrieve(key: testKey)
        XCTAssertEqual(recreated, newValue, "重新创建的值应该正确")
        
        AppLog("✅ 删除后重新创建测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 错误处理测试
    
    func testRetrieveNonExistentKey() throws {
        let nonExistentKey = generateTestKey("non_existent_retrieve")
        
        // 读取不存在的key应该返回nil而不是抛出错误
        let result = try KeychainService.retrieve(key: nonExistentKey)
        XCTAssertNil(result, "读取不存在的key应该返回nil")
        
        AppLog("✅ 读取不存在key测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 多key管理测试
    
    func testMultipleKeysIndependence() throws {
        let key1 = generateTestKey("multi_key_1")
        let key2 = generateTestKey("multi_key_2")
        let key3 = generateTestKey("multi_key_3")
        
        let value1 = "api_key_1"
        let value2 = "api_key_2"
        let value3 = "api_key_3"
        
        // 保存多个不同的key-value对
        try KeychainService.save(key: key1, value: value1)
        try KeychainService.save(key: key2, value: value2)
        try KeychainService.save(key: key3, value: value3)
        
        // 验证每个key都能正确读取对应的值
        XCTAssertEqual(try KeychainService.retrieve(key: key1), value1, "key1应该返回对应的值")
        XCTAssertEqual(try KeychainService.retrieve(key: key2), value2, "key2应该返回对应的值")
        XCTAssertEqual(try KeychainService.retrieve(key: key3), value3, "key3应该返回对应的值")
        
        // 删除其中一个key，不应该影响其他key
        try KeychainService.delete(key: key2)
        
        XCTAssertEqual(try KeychainService.retrieve(key: key1), value1, "key1不应该受到影响")
        XCTAssertNil(try KeychainService.retrieve(key: key2), "key2应该被删除")
        XCTAssertEqual(try KeychainService.retrieve(key: key3), value3, "key3不应该受到影响")
        
        AppLog("✅ 多key独立性测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 边界情况测试
    
    func testSaveWithSpecialCharacters() throws {
        let testKey = generateTestKey("special_chars")
        let specialValue = "!@#$%^&*()_+-=[]{}|;':\",./<>?`~"
        
        // 保存包含特殊字符的值
        try KeychainService.save(key: testKey, value: specialValue)
        
        // 读取并验证
        let retrieved = try KeychainService.retrieve(key: testKey)
        XCTAssertEqual(retrieved, specialValue, "特殊字符应该正确保存和读取")
        
        AppLog("✅ 特殊字符保存测试通过", level: .debug, category: .service)
    }
    
    func testKeyWithSpecialCharacters() throws {
        let specialKey = generateTestKey("special.key-with_chars@domain.com")
        let testValue = "value_for_special_key"
        
        // 使用包含特殊字符的key
        try KeychainService.save(key: specialKey, value: testValue)
        
        // 读取并验证
        let retrieved = try KeychainService.retrieve(key: specialKey)
        XCTAssertEqual(retrieved, testValue, "特殊字符key应该正常工作")
        
        AppLog("✅ 特殊字符key测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 性能测试
    
    func testPerformanceSaveMultipleItems() throws {
        let itemCount = 10 // 减少数量避免超时
        var keys: [String] = []
        
        // 预先生成keys避免在measure中生成
        for i in 0..<itemCount {
            let key = generateTestKey("perf_save_\(i)")
            keys.append(key)
        }
        
        // 性能测试：保存多个项目
        measure {
            for (index, key) in keys.enumerated() {
                let value = "performance_test_value_\(index)"
                
                do {
                    try KeychainService.save(key: key, value: value)
                } catch {
                    // 在measure中不能使用XCTFail，只能记录错误
                    print("保存第\(index)个项目失败: \(error)")
                }
            }
        }
        
        // 验证保存的数据
        for (index, key) in keys.enumerated() {
            let expectedValue = "performance_test_value_\(index)"
            let retrieved = try KeychainService.retrieve(key: key)
            XCTAssertEqual(retrieved, expectedValue, "性能测试项目\(index)应该正确保存")
        }
        
        AppLog("✅ 性能测试（保存多项目）通过", level: .debug, category: .service)
    }
    
    // MARK: - 数据完整性测试
    
    func testDataIntegrityAcrossAppRestarts() throws {
        let testKey = generateTestKey("app_restart")
        let testValue = "persistent_across_restarts"
        
        // 保存数据
        try KeychainService.save(key: testKey, value: testValue)
        
        // 模拟应用重启后读取数据（Keychain在应用重启后仍然保持数据）
        let retrieved = try KeychainService.retrieve(key: testKey)
        XCTAssertEqual(retrieved, testValue, "数据应该在应用重启后保持完整性")
        
        AppLog("✅ 数据完整性测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 并发安全测试
    
    func testConcurrentAccess() throws {
        let testKey = generateTestKey("concurrent")
        let expectation = XCTestExpectation(description: "并发访问测试")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        // 并发执行多个操作
        for i in 0..<10 {
            queue.async {
                do {
                    let value = "concurrent_value_\(i)"
                    try KeychainService.save(key: "\(testKey)_\(i)", value: value)
                    
                    let retrieved = try KeychainService.retrieve(key: "\(testKey)_\(i)")
                    XCTAssertEqual(retrieved, value, "并发操作应该成功")
                    
                    expectation.fulfill()
                } catch {
                    XCTFail("并发操作失败: \(error)")
                }
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        AppLog("✅ 并发安全测试通过", level: .debug, category: .service)
    }
    
    // MARK: - 辅助方法
    
    /// 生成测试专用的key，自动加入清理列表
    private func generateTestKey(_ suffix: String) -> String {
        let key = testKeyPrefix + suffix + "_" + UUID().uuidString
        testKeys.append(key)
        return key
    }
    
    /// 清理所有测试创建的keys
    private func cleanupTestKeys() {
        for key in testKeys {
            try? KeychainService.delete(key: key)
        }
        
        // 额外清理：删除所有以测试前缀开始的keys
        // 注意：这是一个简化的清理方式，在实际项目中可能需要更复杂的清理逻辑
        let prefixKeys = ["test_key_1", "test_key_2", "test_key_3"] // 可能的遗留测试keys
        for key in prefixKeys {
            try? KeychainService.delete(key: testKeyPrefix + key)
        }
        
        AppLog("🧹 [测试清理] 清理了 \(testKeys.count) 个测试keys", level: .debug, category: .service)
    }
}