// SKModelGenerator.swift
// SKGenerateModelTool
//
// Created by shangkun on 2023/11/09.
// Copyright © 2023 wushangkun. All rights reserved.
//

import Foundation

/// 模型生成器
class SKModelGenerator {
    let config: SKCodeBuilderConfig
    var handleDicts = [String: Any]()
    var propertyGenericClassDicts = [String: String]()
    var handlePropertyMapper = [String: String]()
    var allKeys = [String]()
    let blankSpace = "   "
    let blankSpace2 = "  "
    
    /// JSON文件的注释
    var commentDicts: [String: String]?
    
    /// Dart语言特定
    var fromJsonString = NSMutableString()
    var toJsonString = NSMutableString()
    
    var fileType: String {
        config.codeType.fileExtension
    }
    
    init(config: SKCodeBuilderConfig, commentDicts: [String: String]?) {
        self.config = config
        self.commentDicts = commentDicts
    }
    
    /// 生成代码
    func generateCode(with jsonObj: Any, complete: BuildComplete?) {
        // 重置状态
        resetState()
        
        let hString = NSMutableString()
        let mString = NSMutableString()
        let fileName = (config.codeType == .dart) ? config.rootModelName.underscore_name : config.rootModelName
        
        // 处理JSON数据
        handleDictValue(dictValue: jsonObj, key: "", hString: hString, mString: mString)
        
        // 添加导入语句和注释
        addImportsAndComments(hString: hString, mString: mString, fileName: fileName)
        
        if let handler = complete {
            handler(hString, mString)
        }
    }
}

private extension SKModelGenerator {
    /// 重置状态
    func resetState() {
        allKeys.removeAll()
        fromJsonString = NSMutableString()
        toJsonString = NSMutableString()
        handleDicts.removeAll()
        propertyGenericClassDicts.removeAll()
        handlePropertyMapper.removeAll()
    }
    
    /// 添加导入语句和注释
    func addImportsAndComments(hString: NSMutableString, mString: NSMutableString, fileName: String) {
        // 添加导入语句
        addImports(hString: hString, mString: mString, fileName: fileName)
        
        // 添加文件头注释
        addFileComments(hString: hString, mString: mString, fileName: fileName)
    }
   
    /// 处理字典值
    func handleDictValue(dictValue: Any, key: String, hString: NSMutableString, mString: NSMutableString) {
        // 生成类声明
        generateClassDeclaration(dictValue: dictValue, key: key, hString: hString, mString: mString)
        
        // 处理不同类型的值
        switch dictValue {
        case let array as [Any]:
            handleArrayValue(arrayValue: array, key: "dataList", hString: hString)
            
        case let dict as [String: Any]:
            for (key, value) in dict {
                switch value {
                case let num as NSNumber:
                    handleIdNumberValue(numValue: num, key: key, hString: hString, ignoreIdValue: config.jsonType == .none)
                    
                case let str as String:
                    handleIdStringValue(idValue: str, key: key, hString: hString, ignoreIdValue: config.jsonType == .none)
                    
                case let subDict as [String: Any]:
                    let key = handleMaybeSameKey(key)
                    let modelName = modelClassName(with: key)
                    generatePropertyForDict(key: key, modelName: modelName, hString: hString)
                    handleDicts[key] = subDict
                    
                case let arr as [Any]:
                    handleArrayValue(arrayValue: arr, key: key, hString: hString)
                    
                default:
                    // 识别不出类型处理
                    generateUnknownTypeProperty(key: key, hString: hString)
                }
            }

        default:
            closeClassDeclaration(hString: hString, mString: mString)
            return
        }
        // 结束当前模型定义
        closeDeclarationComplete(hString: hString, mString: mString, key: key)
        
        propertyGenericClassDicts.removeAll()
        handlePropertyMapper.removeAll()
        
        if !handleDicts.isEmpty {
            if let firstKey = handleDicts.keys.first,
               let firstObject = handleDicts[firstKey]
            {
                handleDictValue(dictValue: firstObject, key: firstKey, hString: hString, mString: mString)
            }
        }
    }
}
