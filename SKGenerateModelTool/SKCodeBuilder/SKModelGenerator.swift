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
    
    // MARK: - Public Method
    
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
        
        complete?(hString, mString)
    }
}

// MARK: - Private Method

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
        processValue(dictValue, key: key, hString: hString)
        
        // 结束当前模型定义
        closeDeclarationComplete(hString: hString, mString: mString, key: key)
        
        propertyGenericClassDicts.removeAll()
        handlePropertyMapper.removeAll()
        
        // 处理嵌套的字典
        processNextNestedDictionary(hString: hString, mString: mString)
    }
    
    /// 处理值的类型
    func processValue(_ value: Any, key: String, hString: NSMutableString) {
        switch value {
        case let array as [Any]:
            handleArrayValue(arrayValue: array, key: "dataList", hString: hString)
            
        case let dict as [String: Any]:
            processDictionaryProperties(dict, hString: hString)
            
        default:
            break
        }
    }
    
    /// 处理字典中的所有属性
    func processDictionaryProperties(_ dict: [String: Any], hString: NSMutableString) {
        for (key, value) in dict {
            switch value {
            case let num as NSNumber:
                handleIdNumberValue(numValue: num, key: key, hString: hString, ignoreIdValue: config.jsonType == .none)
                
            case let str as String:
                handleIdStringValue(idValue: str, key: key, hString: hString, ignoreIdValue: config.jsonType == .none)
                
            case let subDict as [String: Any]:
                processNestedDictionary(key: key, subDict: subDict, hString: hString)
                
            case let arr as [Any]:
                handleArrayValue(arrayValue: arr, key: key, hString: hString)
                
            default:
                // 识别不出类型处理
                generateUnknownTypeProperty(key: key, hString: hString)
            }
        }
    }
    
    /// 处理嵌套字典
    func processNestedDictionary(key: String, subDict: [String: Any], hString: NSMutableString) {
        let processedKey = handleMaybeSameKey(key)
        let modelName = modelClassName(with: processedKey)
        generatePropertyForDict(key: processedKey, modelName: modelName, hString: hString)
        handleDicts[processedKey] = subDict
    }
    
    /// 处理下一个嵌套字典
    func processNextNestedDictionary(hString: NSMutableString, mString: NSMutableString) {
        guard let firstKey = handleDicts.keys.first,
              let firstObject = handleDicts[firstKey]
        else {
            return
        }
        
        // 移除当前处理的字典
        handleDicts.removeValue(forKey: firstKey)
        
        // 递归处理下一个字典
        handleDictValue(dictValue: firstObject, key: firstKey, hString: hString, mString: mString)
    }
}
