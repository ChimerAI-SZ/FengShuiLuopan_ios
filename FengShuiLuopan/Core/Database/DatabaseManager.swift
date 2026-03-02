// DatabaseManager.swift
// 数据库管理器
// 见 ARCHITECTURE.md 第6节, PHASE_V2_SPEC.md

import Foundation
import SQLite

/// 数据库管理器（单例）
class DatabaseManager {

    // MARK: - Singleton

    static let shared = DatabaseManager()

    // MARK: - Properties

    private var db: SQLite.Connection?

    // MARK: - Initialization

    private init() {
        do {
            try setupDatabase()
        } catch {
            print("❌ 数据库初始化失败: \(error)")
        }
    }

    // MARK: - Setup

    /// 设置数据库
    private func setupDatabase() throws {
        // 获取数据库路径
        let path = try getDatabasePath()

        // 创建连接
        db = try SQLite.Connection(path)

        // 启用外键约束
        try db?.execute("PRAGMA foreign_keys = ON")

        // 创建表
        guard let db = db else {
            throw DatabaseError.connectionFailed
        }
        try DatabaseSchema.createTables(in: db)

        print("✅ 数据库初始化成功: \(path)")
    }

    /// 获取数据库路径
    private func getDatabasePath() throws -> String {
        let fileManager = FileManager.default

        // 获取Documents目录
        guard let documentsPath = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw DatabaseError.pathNotFound
        }

        // 数据库文件路径
        let dbPath = documentsPath.appendingPathComponent("fengshuiluopan.db").path
        return dbPath
    }

    // MARK: - Public Methods

    /// 获取数据库连接
    func getConnection() throws -> SQLite.Connection {
        guard let db = db else {
            throw DatabaseError.connectionFailed
        }
        return db
    }

    /// 重置数据库（仅用于测试）
    func resetDatabase() throws {
        let path = try getDatabasePath()
        let fileManager = FileManager.default

        // 删除数据库文件
        if fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }

        // 重新初始化
        try setupDatabase()
    }
}

// MARK: - Database Errors

enum DatabaseError: Error {
    case connectionFailed
    case pathNotFound
    case queryFailed(String)
    case insertFailed(String)
    case updateFailed(String)
    case deleteFailed(String)

    var localizedDescription: String {
        switch self {
        case .connectionFailed:
            return "数据库连接失败"
        case .pathNotFound:
            return "数据库路径未找到"
        case .queryFailed(let message):
            return "查询失败: \(message)"
        case .insertFailed(let message):
            return "插入失败: \(message)"
        case .updateFailed(let message):
            return "更新失败: \(message)"
        case .deleteFailed(let message):
            return "删除失败: \(message)"
        }
    }
}
