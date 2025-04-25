// SKFileManager.swift
// SKGenerateModelTool
//
// Created by shangkun on 2023/11/09.
// Copyright © 2023 wushangkun. All rights reserved.
//

import Foundation

enum SKFileError: Error {
    case emptyContent
    case invalidPath
    case createDirectoryFailed(Error)
    case writeFileFailed(Error)
}

class SKFileManager {
    /// 配置项
    private let config: SKCodeBuilderConfig
    
    /// 文件管理器
    private let fileManager = FileManager.default
    
    /// 默认文件夹名称
    private let defaultFolderName = "SKGenerateModelToolFiles"
        
    init(config: SKCodeBuilderConfig) {
        self.config = config
    }
    
    // MARK: - Public Method
    
    /// 同步生成文件
    func generateFile(with filePath: String?, hString: NSMutableString, mString: NSMutableString, complete: GenerateFileComplete?) {
        do {
            let resultPath = try generateFileSync(with: filePath, hString: hString, mString: mString)
            complete?(true, resultPath)
        } catch {
            print("生成文件失败: \(error)")
            complete?(false, filePath ?? "")
        }
    }
    
    /// 异步生成文件
    func generateFileAsync(with filePath: String?, hString: NSMutableString, mString: NSMutableString) async throws -> String {
        return try await Task {
            try generateFileSync(with: filePath, hString: hString, mString: mString)
        }.value
    }
    
    // MARK: - Private Method

    /// 同步生成文件
    private func generateFileSync(with filePath: String?, hString: NSMutableString, mString: NSMutableString) throws -> String {
        guard hString.length > 0, mString.length > 0 else {
            throw SKFileError.emptyContent
        }
        
        let outputPath = try filePath ?? createDefaultDirectory()
        
        try writeFiles(to: outputPath, hString: hString, mString: mString)
        
        return outputPath
    }
    
    /// 创建默认目录
    private func createDefaultDirectory() throws -> String {
        guard let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, false).last else {
            throw SKFileError.invalidPath
        }
        
        let path = desktopPath.appending("/\(defaultFolderName)")
        var isDir = ObjCBool(false)
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        
        if !exists || !isDir.boolValue {
            do {
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                throw SKFileError.createDirectoryFailed(error)
            }
        }
        
        return path
    }
    
    /// 写入文件
    private func writeFiles(to filePath: String, hString: NSMutableString, mString: NSMutableString) throws {
        let fileName = (config.codeType == .dart) ? config.rootModelName.underscore_name : config.rootModelName
        
        // 根据代码类型确定文件路径
        let (fileNameH, fileNameM) = getFilePathsForCurrentCodeType(basePath: filePath, fileName: fileName)
        
        do {
            // 写入头文件
            if !fileNameH.isEmpty {
                try hString.write(toFile: fileNameH, atomically: true, encoding: String.Encoding.utf8.rawValue)
            }
            
            // 写入实现文件 (如果有)
            if !fileNameM.isEmpty {
                try mString.write(toFile: fileNameM, atomically: true, encoding: String.Encoding.utf8.rawValue)
            }
        } catch {
            throw SKFileError.writeFileFailed(error)
        }
    }
    
    /// 根据代码类型获取文件路径
    private func getFilePathsForCurrentCodeType(basePath: String, fileName: String) -> (String, String) {
        var fileNameH = ""
        var fileNameM = ""
        
        switch config.codeType {
        case .objectiveC:
            fileNameH = basePath.appending("/\(fileName).h")
            fileNameM = basePath.appending("/\(fileName).m")
        case .swift:
            fileNameH = basePath.appending("/\(fileName).swift")
        case .dart:
            fileNameH = basePath.appending("/\(fileName).dart")
            fileNameM = basePath.appending("/\(fileName).m.dart")
        case .typeScript:
            fileNameH = basePath.appending("/\(fileName).ts")
        }
        
        return (fileNameH, fileNameM)
    }
}
