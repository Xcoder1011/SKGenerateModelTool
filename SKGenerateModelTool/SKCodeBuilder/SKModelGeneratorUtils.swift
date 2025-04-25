// SKModelGeneratorUtils.swift
// SKGenerateModelTool
//
// Created by shangkun on 2023/11/09.
// Copyright © 2023 wushangkun. All rights reserved.
//

import Foundation

extension SKModelGenerator {
    /// 生成类声明
    func generateClassDeclaration(dictValue: Any, key: String, hString: NSMutableString, mString: NSMutableString) {
        if config.codeType == .objectiveC {
            if key.isEmpty { // Root model
                if config.jsonType == .yyModel, config.superClassName.compare("NSObject") == .orderedSame {
                    hString.append("\n@interface \(config.rootModelName): \(config.superClassName) <YYModel>\n")
                } else {
                    hString.append("\n@interface \(config.rootModelName): \(config.superClassName)\n")
                }
                mString.append("\n@implementation \(config.rootModelName)\n")
            } else { // sub model
                let modelName = modelClassName(with: key)
                hString.insert("@class \(modelName);\n", at: 0)
                if config.jsonType == .yyModel, config.superClassName.compare("NSObject") == .orderedSame {
                    hString.append("\n@interface \(modelName): \(config.superClassName) <YYModel>\n")
                } else {
                    hString.append("\n@interface \(modelName): \(config.superClassName)\n")
                }
                mString.append("\n@implementation \(modelName)\n")
            }
        } else if config.codeType == .swift {
            if key.isEmpty { // Root model
                hString.append("\nstruct \(config.rootModelName): \(config.superClassName) {\n")
            } else { // sub model
                let modelName = modelClassName(with: key)
                hString.append("\nstruct \(modelName): \(config.superClassName) {\n")
            }
        } else if config.codeType == .dart {
            var modelName = config.rootModelName
            if key.isEmpty { // Root model
                if config.superClassName.isEmpty {
                    hString.append("class \(config.rootModelName) {\n")
                } else {
                    hString.append("class \(config.rootModelName) extends \(config.superClassName) {\n")
                }
            } else { // sub model
                modelName = modelClassName(with: key)
                if config.superClassName.isEmpty {
                    hString.append("\nclass \(modelName) {\n")
                } else {
                    hString.append("\nclass \(modelName) extends \(config.superClassName) {\n")
                }
            }
            fromJsonString.append("\n\(modelName) _$\(modelName)FromJson(Map<String, dynamic> json, \(modelName) instance) {\n")
            toJsonString.append("\nMap<String, dynamic> _$\(modelName)ToJson(\(modelName) instance) {\n")
            toJsonString.append("   final Map<String, dynamic> json = <String, dynamic>{};\n")
        } else if config.codeType == .typeScript {
            if key.isEmpty { // Root model
                hString.append("\nexport interface \(config.rootModelName) {\n")
            } else { // sub model
                let modelName = modelClassName(with: key)
                hString.append("\n\nexport interface \(modelName) {\n")
            }
        }
    }
   
    /// 为字典类型生成属性
    func generatePropertyForDict(key: String, modelName: String, hString: NSMutableString) {
        switch config.codeType {
        case .objectiveC:
            hString.append("\(ocCommentName(key, "", false))@property (nonatomic, strong) \(modelName) *\(key);\n")
            propertyGenericClassDicts[key] = modelName
        case .swift:
            hString.append("    var \(key): \(modelName)?\n")
        case .dart:
            hString.append("   \(modelName)? \(key);\n")
            propertyGenericClassDicts[key] = modelName
            
            let fString =
                """
                \(blankSpace)if(json['\(key)'] != null) {
                \(blankSpace)\(blankSpace2)instance.\(key) = \(modelName)().fromJson(json['\(key)']);
                \(blankSpace)}
                
                """
            fromJsonString.append(fString)
            
            let tString =
                """
                \(blankSpace)json['\(key)'] = instance.\(key)?.toJson();
                
                """
            toJsonString.append(tString)
        case .typeScript:
            hString.append("   \(key): \(modelName);\n")
        }
    }
        
    /// 处理数组类型
    func handleArrayValue(arrayValue: [Any], key: String, hString: NSMutableString) {
        guard arrayValue.count > 0 else {
            return
        }
        if let firstObject = arrayValue.first {
            switch config.codeType {
            case .objectiveC:
                handleOCArrayValue(firstObject: firstObject, key: key, hString: hString)
            case .swift:
                handleSwiftArrayValue(firstObject: firstObject, key: key, hString: hString)
            case .dart:
                handleDartArrayValue(firstObject: firstObject, key: key, hString: hString)
            case .typeScript:
                handleTypeScriptArrayValue(firstObject: firstObject, key: key, hString: hString)
            }
        }
    }
  
    /// 处理数字类型
    func handleIdNumberValue(numValue: NSNumber, key: String, hString: NSMutableString, ignoreIdValue: Bool) {
        let numType = CFNumberGetType(numValue as CFNumber)
        
        switch numType {
        case .doubleType, .floatType, .float32Type, .float64Type, .cgFloatType:
            // 浮点型
            handleFloatValue(numValue: numValue, key: key, hString: hString)
            
        case .charType:
            if numValue.int32Value == 0 || numValue.int32Value == 1 {
                // Bool 类型
                handleBoolValue(numValue: numValue, key: key, hString: hString)
            } else {
                handleIdStringValue(idValue: numValue.stringValue, key: key, hString: hString, ignoreIdValue: ignoreIdValue)
            }
            
        case .shortType, .intType, .sInt32Type, .nsIntegerType, .longType, .longLongType:
            // Int
            handleIdIntValue(intValue: numValue.intValue, key: key, hString: hString, ignoreIdValue: ignoreIdValue)
            
        default:
            // Int
            handleIdIntValue(intValue: numValue.intValue, key: key, hString: hString, ignoreIdValue: ignoreIdValue)
        }
    }
    
    /// 处理整数类型
    func handleIdIntValue(intValue: Int, key: String, hString: NSMutableString, ignoreIdValue: Bool) {
        if key == "id", !ignoreIdValue {
            handlePropertyMapper["id"] = "itemId"
            switch config.codeType {
            case .objectiveC:
                hString.append("\(ocCommentName(key, "\(intValue)"))@property (nonatomic, assign) NSInteger itemId;\n")
            case .swift:
                hString.append("    var itemId: Int = 0 \(singlelineCommentName(key, "\(intValue)"))\n")
            case .dart:
                hString.append("   int? itemId;  \(singlelineCommentName(key, "\(intValue)"))\n")
                generateDartIntJsonParsing(key: "itemId", hString: hString)
            case .typeScript:
                hString.append("   itemId: number;  \(singlelineCommentName(key, "\(intValue)"))\n")
            }
        } else {
            switch config.codeType {
            case .objectiveC:
                hString.append("\(ocCommentName(key, "\(intValue)"))@property (nonatomic, assign) NSInteger \(key);\n")
            case .swift:
                hString.append("    var \(key): Int = 0 \(singlelineCommentName(key, "\(intValue)"))\n")
            case .dart:
                hString.append("   int? \(key);  \(singlelineCommentName(key, "\(intValue)"))\n")
                generateDartIntJsonParsing(key: key, hString: hString)
            case .typeScript:
                hString.append("   \(key): number;  \(singlelineCommentName(key, "\(intValue)"))\n")
            }
        }
    }
    
    /// 处理字符串类型
    func handleIdStringValue(idValue: String, key: String, hString: NSMutableString, ignoreIdValue: Bool) {
        if key == "id", !ignoreIdValue {
            // 字符串id 替换成 itemId
            handlePropertyMapper["id"] = "itemId"
            switch config.codeType {
            case .objectiveC:
                hString.append("\(ocCommentName(key, idValue))@property (nonatomic, copy) NSString *itemId;\n")
            case .swift:
                hString.append("    var itemId: String? \(singlelineCommentName(key, idValue))\n")
            case .dart:
                hString.append("   String? \(key);  \(singlelineCommentName(key, idValue))\n")
                generateDartStringJsonParsing(key: key, hString: hString)
            case .typeScript:
                hString.append("   itemId: string;  \(singlelineCommentName(key, idValue))\n")
            }
        } else {
            switch config.codeType {
            case .objectiveC:
                hString.append("\(ocCommentName(key, idValue))@property (nonatomic, copy) NSString *\(key);\n")
            case .swift:
                if idValue.count > 12 {
                    hString.append("    var \(key): String? \(singlelineCommentName(key, idValue, false))\n")
                } else {
                    hString.append("    var \(key): String? \(singlelineCommentName(key, idValue))\n")
                }
            case .dart:
                hString.append("   String? \(key);  \(singlelineCommentName(key, idValue))\n")
                generateDartStringJsonParsing(key: key, hString: hString)
            case .typeScript:
                hString.append("   \(key): string;  \(singlelineCommentName(key, idValue))\n")
            }
        }
    }

    /// 未知类型生成属性
    func generateUnknownTypeProperty(key: String, hString: NSMutableString) {
        switch config.codeType {
        case .objectiveC:
            hString.append("\(ocCommentName(key, "<#泛型#>"))@property (nonatomic, strong) id \(key);\n")
        case .swift:
            hString.append("    var \(key): Any? \(singlelineCommentName(key, "<#泛型#>"))\n")
        case .dart:
            hString.append("   dynamic? \(key);  \(singlelineCommentName(key, "<#泛型#>"))\n")
            
            let fString =
                """
                \(blankSpace)if(json['\(key)'] != null) {
                \(blankSpace)\(blankSpace2)instance.\(key) = json['\(key)'];
                \(blankSpace)}
                
                """
            fromJsonString.append(fString)
            
            let tString =
                """
                \(blankSpace)if(instance.\(key) != null) {
                \(blankSpace)\(blankSpace2)json['\(key)'] = instance.\(key);
                \(blankSpace)}
                
                """
            toJsonString.append(tString)
        case .typeScript:
            hString.append("   \(key)?: null;\n")
        }
    }
    
    func closeClassDeclaration(hString: NSMutableString, mString: NSMutableString) {
        if config.codeType == .objectiveC {
            hString.append("@end\n\n")
            mString.append("@end\n\n")
        } else if config.codeType == .swift {
            hString.append("}\n")
        } else if config.codeType == .dart {
            hString.append("}\n")
        } else if config.codeType == .typeScript {
            hString.append("}\n")
        }
    }
    
    func closeDeclarationComplete(hString: NSMutableString, mString: NSMutableString, key: String) {
        if config.codeType == .objectiveC {
            hString.append("@end\n\n")
            handleJsonType(hString: hString, mString: mString)
        } else if config.codeType == .swift {
            handleJsonType(hString: hString, mString: mString)
            hString.append("}\n")
        } else if config.codeType == .dart {
            var modelName = config.rootModelName
            if !key.isBlank {
                modelName = modelClassName(with: key)
            }
            let headerString =
                """
                
                \(blankSpace)\(modelName) fromJson(Map<String, dynamic> json) => _$\(modelName)FromJson(json, this);
                \(blankSpace)Map<String, dynamic> toJson() => _$\(modelName)ToJson(this);
                
                """
            hString.append(headerString)
            hString.append("}\n")
            
            fromJsonString.append("   return instance;\n")
            toJsonString.append("   return json;\n")
        } else if config.codeType == .typeScript {
            hString.append("}")
        }
        // 处理嵌套模型
        if !key.isEmpty {
            handleDicts.removeValue(forKey: key)
        }
        if config.codeType == .dart {
            mString.append(fromJsonString as String)
            mString.append("}\n")
            mString.append(toJsonString as String)
            mString.append("}\n")
            fromJsonString = ""
            toJsonString = ""
        } else {
            mString.append("@end\n\n")
        }
    }

    /// 处理json解析
    func handleJsonType(hString: NSMutableString, mString: NSMutableString) {
        if config.jsonType == .handyJSON {
            generateHandyJSONSupport(hString: hString, mString: mString)
            return
        }
            
        switch config.jsonType {
        case .yyModel:
            generateYYModelSupport(mString: mString)
        case .mjExtension:
            generateMJExtensionSupport(mString: mString)
        default:
            break
        }
    }
    
    /// 添加导入语句
    func addImports(hString: NSMutableString, mString: NSMutableString, fileName: String) {
        switch config.codeType {
        case .objectiveC:
            if config.superClassName == "NSObject" {
                if config.jsonType == .yyModel, config.superClassName.compare("NSObject") == .orderedSame {
                    let string =
                        """
                        \n#if __has_include(<YYModel/YYModel.h>)
                        #import <YYModel/YYModel.h>
                        #else
                        #import "YYModel.h"
                        #endif\n\n
                        """
                    hString.insert(string, at: 0)
                } else {
                    hString.insert("\n#import <Foundation/Foundation.h>\n\n", at: 0)
                }
            } else {
                hString.insert("\n#import \"\(config.superClassName).h\"\n\n", at: 0)
            }
            mString.insert("\n#import \"\(config.rootModelName).h\"\n\n", at: 0)
        case .swift:
            if config.jsonType == .handyJSON {
                hString.insert("\nimport HandyJSON\n", at: 0)
            }
        case .dart:
            hString.insert("\npart '\(fileName).m.dart';\n\n", at: 0)
            mString.insert("\npart of '\(fileName).dart';\n", at: 0)
        default:
            break
        }
    }
    
    /// 添加文件头注释
    func addFileComments(hString: NSMutableString, mString: NSMutableString, fileName: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let time = dateFormatter.string(from: Date())
        let year = time.components(separatedBy: "/").first ?? "2023"
        
        let hCommentString =
            """
            //
            //  \(fileName).\(fileType)
            //  SKGenerateModelTool
            //
            //  Created by \(config.authorName) on \(time).
            //  Copyright © \(year) SKGenerateModelTool. All rights reserved.
            //\n
            """
        
        var fileSuffixName = "m"
        if config.codeType == .dart {
            fileSuffixName = "m.dart"
        } else if config.codeType == .typeScript {
            fileSuffixName = "ts"
        }
        let mCommentString =
            """
            //
            //  \(fileName).\(fileSuffixName)
            //  SKGenerateModelTool
            //
            //  Created by \(config.authorName) on \(time).
            //  Copyright © \(year) SKGenerateModelTool. All rights reserved.
            //\n
            """
        hString.insert(hCommentString, at: 0)
        mString.insert(mCommentString, at: 0)
    }
    
    /// 处理可能出现相同的key的问题
    func handleMaybeSameKey(_ key: String) -> String {
        var tempKey = key
        if allKeys.contains(key) {
            tempKey = "\(key)2"
            handlePropertyMapper[key] = tempKey
        }
        allKeys.append(tempKey)
        return tempKey
    }
    
    /// 生成类名
    func modelClassName(with key: String) -> String {
        if key.isBlank { return config.rootModelName }
        let strings = key.components(separatedBy: "_")
        let mutableString = NSMutableString()
        var modelName: String
        if !strings.isEmpty {
            for str in strings {
                let firstCharacterIndex = str.index(str.startIndex, offsetBy: 1)
                var firstCharacter = String(str[..<firstCharacterIndex])
                firstCharacter = firstCharacter.uppercased()
                let start = String.Index(utf16Offset: 0, in: str)
                let end = String.Index(utf16Offset: 1, in: str)
                let str = str.replacingCharacters(in: start..<end, with: firstCharacter)
                mutableString.append(str)
            }
            modelName = mutableString as String
        } else {
            let firstCharacterIndex = key.index(key.startIndex, offsetBy: 1)
            var firstCharacter = String(key[..<firstCharacterIndex])
            firstCharacter = firstCharacter.uppercased()
            let start = String.Index(utf16Offset: 0, in: key)
            let end = String.Index(utf16Offset: 1, in: key)
            modelName = key.replacingCharacters(in: start..<end, with: firstCharacter)
        }
        // 添加前缀
        if !modelName.hasPrefix(config.modelNamePrefix) {
            modelName = config.modelNamePrefix + modelName
        }
        // 添加后缀
        if config.superClassName.hasSuffix("Item") {
            if !modelName.hasSuffix("Item") {
                modelName = modelName + "Item"
            }
        } else {
            if !modelName.hasSuffix("Model") {
                modelName = modelName + "Model"
            }
        }
        return modelName
    }
}

private extension SKModelGenerator {
    /// 处理浮点类型
    func handleFloatValue(numValue: NSNumber, key: String, hString: NSMutableString) {
        switch config.codeType {
        case .objectiveC:
            hString.append("\(ocCommentName(key, "\(numValue)"))@property (nonatomic, assign) CGFloat \(key);\n")
        case .swift:
            hString.append("    var \(key): Double? \(singlelineCommentName(key, "\(numValue)"))\n")
        case .dart:
            hString.append("   double? \(key);  \(singlelineCommentName(key, "\(numValue)"))\n")
            
            let fString =
                """
                \(blankSpace)if(json['\(key)'] != null) {
                \(blankSpace)\(blankSpace2)final \(key) = json['\(key)'];
                \(blankSpace)\(blankSpace2)if(\(key) is String) {
                \(blankSpace)\(blankSpace2)\(blankSpace2)instance.\(key) = double.parse(\(key));
                \(blankSpace)\(blankSpace2)} else {
                \(blankSpace)\(blankSpace2)\(blankSpace2)instance.\(key) = \(key)?.toDouble();
                \(blankSpace)\(blankSpace2)}
                \(blankSpace)}
                
                """
            fromJsonString.append(fString)
            
            let tString = "\(blankSpace)json['\(key)'] = instance.\(key);\n"
            toJsonString.append(tString)
        case .typeScript:
            hString.append("   \(key): number;  \(singlelineCommentName(key, "\(numValue)"))\n")
        }
    }
        
    /// 处理布尔类型
    func handleBoolValue(numValue: NSNumber, key: String, hString: NSMutableString) {
        switch config.codeType {
        case .objectiveC:
            hString.append("\(ocCommentName(key, "\(numValue)"))@property (nonatomic, assign) BOOL \(key);\n")
        case .swift:
            hString.append("    var \(key): Bool = false \(singlelineCommentName(key, numValue.boolValue == true ? "true" : "false"))\n")
        case .dart:
            hString.append("   bool? \(key);  \(singlelineCommentName(key, numValue.boolValue == true ? "true" : "false"))\n")
            let fString =
                """
                \(blankSpace)if(json['\(key)'] != null) {
                \(blankSpace)\(blankSpace2)instance.\(key) = json['\(key)'];
                \(blankSpace)}
                
                """
            fromJsonString.append(fString)
                
            let tString = "\(blankSpace)json['\(key)'] = instance.\(key);\n"
            toJsonString.append(tString)
        case .typeScript:
            hString.append("   \(key): boolean;  \(singlelineCommentName(key, numValue.boolValue == true ? "true" : "false"))\n")
        }
    }
        
    /// 处理Objective-C数组类型
    func handleOCArrayValue(firstObject: Any, key: String, hString: NSMutableString) {
        if firstObject is String {
            // String 类型
            hString.append("\(ocCommentName(key, "", false))@property (nonatomic, strong) NSArray <NSString *> *\(key);\n")
        } else if firstObject is [String: Any] {
            // Dictionary 类型
            let key = handleMaybeSameKey(key)
            let modeName = modelClassName(with: key)
            handleDicts[key] = firstObject
            propertyGenericClassDicts[key] = modeName
            hString.append("\(ocCommentName(key, "", false))@property (nonatomic, strong) NSArray <\(modeName) *> *\(key);\n")
        } else if let nestedArray = firstObject as? [Any] {
            // Array 类型
            handleArrayValue(arrayValue: nestedArray, key: key, hString: hString)
        } else {
            hString.append("\(ocCommentName(key, "", false))@property (nonatomic, strong) NSArray *\(key);\n")
        }
    }
    
    /// 处理Swift数组类型
    func handleSwiftArrayValue(firstObject: Any, key: String, hString: NSMutableString) {
        if firstObject is String {
            // String 类型
            hString.append("    var \(key): [String]? \(singlelineCommentName(key, "", false))\n")
        } else if firstObject is [String: Any] {
            // Dictionary 类型
            let key = handleMaybeSameKey(key)
            let modeName = modelClassName(with: key)
            handleDicts[key] = firstObject
            hString.append("    var \(key): [\(modeName)]? \(singlelineCommentName(key, "", false))\n")
        } else if let nestedArray = firstObject as? [Any] {
            // Array 类型
            handleArrayValue(arrayValue: nestedArray, key: key, hString: hString)
        } else {
            hString.append("    var \(key): [Any]? \(singlelineCommentName(key, "", false))\n")
        }
    }
    
    /// 处理Dart数组类型
    func handleDartArrayValue(firstObject: Any, key: String, hString: NSMutableString) {
        if firstObject is String {
            // String 类型
            hString.append("   List<String>? \(key);  \(singlelineCommentName(key, "", false))\n")
            
            let fString =
                """
                \(blankSpace)if(json['\(key)'] != null) {
                \(blankSpace)\(blankSpace2)instance.\(key) = <String>[];
                \(blankSpace)\(blankSpace2)instance.\(key) = json['\(key)']?.map((v) => v?.toString())?.toList()?.cast<String>();
                \(blankSpace)}
                
                """
            fromJsonString.append(fString)
            let tString =
                """
                \(blankSpace)if(instance.\(key) != null) {
                \(blankSpace)\(blankSpace2)json['\(key)'] = instance.\(key);
                \(blankSpace)}
                
                """
            toJsonString.append(tString)
        } else if firstObject is [String: Any] {
            // Dictionary 类型
            let key = handleMaybeSameKey(key)
            let modeName = modelClassName(with: key)
            handleDicts[key] = firstObject
            propertyGenericClassDicts[key] = modeName
            hString.append("   List<\(modeName)>? \(key);  \(singlelineCommentName(key, "", false))\n")
            let fString =
                """
                \(blankSpace)if(json['\(key)'] != null) {
                \(blankSpace)\(blankSpace2)instance.\(key) = <\(modeName)>[];
                \(blankSpace)\(blankSpace2)for (var v in (json['\(key)'] as List)) {
                \(blankSpace)\(blankSpace2)\(blankSpace2)instance.\(key)?.add(\(modeName)().fromJson(v));
                \(blankSpace)\(blankSpace2)}
                \(blankSpace)}
                
                """
            fromJsonString.append(fString)
            
            let tString =
                """
                \(blankSpace)json['\(key)'] = instance.\(key)?.map((v) => v.toJson()).toList();
                
                """
            toJsonString.append(tString)
        } else if let nestedArray = firstObject as? [Any] {
            // Array 类型
            handleArrayValue(arrayValue: nestedArray, key: key, hString: hString)
        } else {
            hString.append("   List<dynamic>? \(key);  \(singlelineCommentName(key, "", false))\n")
            
            let fString =
                """
                \(blankSpace)if(json['\(key)'] != null) {
                \(blankSpace)\(blankSpace2)instance.\(key) = <dynamic>[];
                \(blankSpace)\(blankSpace2)instance.\(key).addAll(json['\(key)']);
                \(blankSpace)}
                
                """
            fromJsonString.append(fString)
            
            let tString =
                """
                \(blankSpace)if(instance.\(key) != null) {
                \(blankSpace)\(blankSpace2)json['\(key)'] = [];
                \(blankSpace)}
                
                """
            toJsonString.append(tString)
        }
    }
    
    /// 处理TypeScript数组类型
    func handleTypeScriptArrayValue(firstObject: Any, key: String, hString: NSMutableString) {
        if firstObject is String {
            // String 类型
            hString.append("   \(key)?: string[] | null;  \(singlelineCommentName(key, "", false))\n")
        } else if firstObject is [String: Any] {
            // Dictionary 类型
            let key = handleMaybeSameKey(key)
            let modeName = modelClassName(with: key)
            handleDicts[key] = firstObject
            hString.append("   \(key)?: (\(modeName))[] | null;  \(singlelineCommentName(key, "", false))\n")
        } else if let nestedArray = firstObject as? [Any] {
            // Array 类型
            handleArrayValue(arrayValue: nestedArray, key: key, hString: hString)
        } else {
            hString.append("   \(key)?: (null)[] | null;  \(singlelineCommentName(key, "", false))\n")
        }
    }
        
    /// 生成Dart字符串 JSON解析代码
    private func generateDartStringJsonParsing(key: String, hString: NSMutableString) {
        let fString =
            """
            \(blankSpace)if(json['\(key)'] != null) {
            \(blankSpace)\(blankSpace2)instance.\(key) = json['\(key)']?.toString();
            \(blankSpace)}
            
            """
        fromJsonString.append(fString)
            
        let tString = "\(blankSpace)json['\(key)'] = instance.\(key);\n"
        toJsonString.append(tString)
    }
    
    /// 生成Dart 整数JSON解析代码
    func generateDartIntJsonParsing(key: String, hString: NSMutableString) {
        let fString =
            """
            \(blankSpace)if(json['\(key)'] != null) {
            \(blankSpace)\(blankSpace2)final \(key) = json['\(key)'];
            \(blankSpace)\(blankSpace2)if(\(key) is String) {
            \(blankSpace)\(blankSpace2)\(blankSpace2)instance.\(key) = int.parse(\(key));
            \(blankSpace)\(blankSpace2)} else {
            \(blankSpace)\(blankSpace2)\(blankSpace2)instance.\(key) = \(key)?.toInt();
            \(blankSpace)\(blankSpace2)}
            \(blankSpace)}
            
            """
            
        fromJsonString.append(fString)
        let tString = "\(blankSpace)json['\(key)'] = instance.\(key);\n"
        toJsonString.append(tString)
    }
        
    /// 生成HandyJSON支持代码
    func generateHandyJSONSupport(hString: NSMutableString, mString: NSMutableString) {
        hString.append("\n    required init() {}\n")
        if !handlePropertyMapper.isEmpty {
            hString.append("\n    public func mapping(mapper: HelpingMapper) {")
            for (key, obj) in handlePropertyMapper {
                hString.append("\n        mapper <<< self.\(key) <-- \"\(obj)\"")
            }
            hString.append("\n    }\n")
        }
    }
        
    /// 生成YYModel支持代码
    func generateYYModelSupport(mString: NSMutableString) {
        var needLineBreak = false
        if !propertyGenericClassDicts.isEmpty {
            mString.append("+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass\n")
            mString.append("{\n     return @{\n")
            for (key, obj) in propertyGenericClassDicts {
                mString.append("              @\"\(key)\" : \(obj).class,\n")
            }
            mString.append("             };")
            mString.append("\n}\n")
            needLineBreak = true
        }
            
        if !handlePropertyMapper.isEmpty {
            if needLineBreak { mString.append("\n") }
            mString.append("+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper\n")
            mString.append("{\n     return @{\n")
            for (key, obj) in handlePropertyMapper {
                mString.append("              @\"\(key)\" : @\"\(obj)\",\n")
            }
            mString.append("             };")
            mString.append("\n}\n")
        }
    }
        
    /// 生成MJExtension支持代码
    func generateMJExtensionSupport(mString: NSMutableString) {
        var needLineBreak = false
        if !propertyGenericClassDicts.isEmpty {
            mString.append("+ (NSDictionary *)mj_objectClassInArray\n")
            mString.append("{\n     return @{\n")
            for (key, obj) in propertyGenericClassDicts {
                mString.append("              @\"\(key)\" : \(obj).class,\n")
            }
            mString.append("             };")
            mString.append("\n}\n")
            needLineBreak = true
        }
            
        if !handlePropertyMapper.isEmpty {
            if needLineBreak { mString.append("\n") }
            mString.append("+ (NSDictionary *)mj_replacedKeyFromPropertyName\n")
            mString.append("{\n     return @{\n")
            for (key, obj) in handlePropertyMapper {
                mString.append("              @\"\(key)\" : @\"\(obj)\",\n")
            }
            mString.append("             };")
            mString.append("\n}\n")
        }
    }
    
    /// OC类注释 带有"/** eg.  */"
    func ocCommentName(_ key: String, _ value: String, _ show: Bool = true) -> String {
        var realComment = ""
        let comment = commentName(key, value, show)
        if !comment.isBlank {
            realComment = "/** eg. \(comment) */\n"
        }
        return realComment
    }
    
    /// 生成注释 带有"// "
    func singlelineCommentName(_ key: String, _ value: String, _ show: Bool = true) -> String {
        var lineComment = ""
        let comment = commentName(key, value, show)
        if !comment.isBlank {
            lineComment = "// \(comment)"
        }
        return lineComment
    }
    
    /// 生成注释
    func commentName(_ key: String, _ value: String, _ show: Bool = true) -> String {
        if !config.shouldGenerateComment { return "" }
        var comment = value
        if value.count > 12 {
            comment = ""
        }
        if !show { comment = "" }
        if let commentDict = commentDicts, commentDict.count > 0 {
            if let commentValue = commentDict[key] {
                comment = commentValue
            }
        }
        return comment
    }
}
