// SKFileManager.swift
// SKGenerateModelTool
//
// Created by shangkun on 2023/11/09.
// Copyright © 2023 wushangkun. All rights reserved.
//

import Foundation

/// 文件管理类，负责生成和写入文件
class SKFileManager {
    /// 配置项
    private let config: SKCodeBuilderConfig
    
    init(config: SKCodeBuilderConfig) {
        self.config = config
    }
    
    /// 生成文件
    func generateFile(with filePath: String?, hString: NSMutableString, mString: NSMutableString, complete: GenerateFileComplete?) {
        guard hString.length > 0, mString.length > 0 else { return }
        var filePath = filePath
        var success = false
        // 如果没有指定路径，则使用默认路径
        if filePath == nil {
            if let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, false).last {
                let path = desktopPath.appending("/SKGenerateModelToolFiles")
                print("path = \(path)")
                var isDir = ObjCBool(false)
                let isExists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
                if isDir.boolValue, isExists {
                    filePath = path
                } else {
                    do {
                        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                        filePath = path
                    } catch {
                        print("createDirectory error = \(error)")
                        success = false
                    }
                }
            }
        }
        
        if let filePath = filePath {
            success = writeFiles(to: filePath, hString: hString, mString: mString)
        }
        
        if let complete = complete {
            complete(success, filePath ?? "")
        }
    }
    
    /// 写入文件
    private func writeFiles(to filePath: String, hString: NSMutableString, mString: NSMutableString) -> Bool {
        let fileName = (config.codeType == .dart) ? config.rootModelName.underscore_name : config.rootModelName
        var fileNameH = "", fileNameM = ""
        
        switch config.codeType {
        case .objectiveC:
            fileNameH = filePath.appending("/\(fileName).h")
            fileNameM = filePath.appending("/\(fileName).m")
        case .swift:
            fileNameH = filePath.appending("/\(fileName).swift")
        case .dart:
            fileNameH = filePath.appending("/\(fileName).dart")
            fileNameM = filePath.appending("/\(fileName).m.dart")
        case .typeScript:
            fileNameH = filePath.appending("/\(fileName).ts")
        }
        
        do {
            if !fileNameH.isEmpty {
                try hString.write(toFile: fileNameH, atomically: true, encoding: String.Encoding.utf8.rawValue)
            }
            if !fileNameM.isEmpty {
                try mString.write(toFile: fileNameM, atomically: true, encoding: String.Encoding.utf8.rawValue)
            }
            return true
        } catch {
            print("写入文件失败: \(error)")
            return false
        }
    }
}
