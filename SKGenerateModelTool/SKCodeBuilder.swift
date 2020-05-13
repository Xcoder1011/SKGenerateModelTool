//
//  SKCodeBuilder.swift
//  SKGenerateModelTool
//
//  Created by KUN on 2020/5/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

enum SKCodeBuilderCodeType: Int {
    case OC = 1
    case Swift
    case Java
}

enum SKCodeBuilderJSONModelType: Int {
    case None = 0
    case YYModel
    case MJExtension
    case HandyJSON
}

typealias BuildComplete = (NSMutableString, NSMutableString) -> ()
typealias GenerateFileComplete = (Bool, String) -> ()

class SKCodeBuilder: NSObject {

    var config = SKCodeBuilderConfig()
    lazy var handleDicts = NSMutableDictionary()
    lazy var yymodelPropertyGenericClassDicts = NSMutableDictionary()
    lazy var handlePropertyMapper = NSMutableDictionary()

    // MARK: - Public

    func build_OC_code(with jsonObj:Any, complete:BuildComplete?){
        let hString = NSMutableString()
        let mString = NSMutableString()
        handleDictValue(dictValue: jsonObj, key: "", hString: hString, mString: mString)
        if config.superClassName == "NSObject" {
            hString.insert("\n#import <Foundation/Foundation.h>\n\n", at: 0)
        } else {
            hString.insert("\n#import \"\(config.superClassName).h\"\n\n", at: 0)
        }
        mString.insert("\n#import \"\(config.rootModelName).h\"\n\n", at: 0)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let time = dateFormatter.string(from: Date())
        let year = time.components(separatedBy: "/").first ?? "2020"
       
        let hCommentString =
        """
        //
        //  \(config.rootModelName).h
        //  SKCodeBuilder
        //
        //  Created by \(config.authorName) on \(time).
        //  Copyright © \(year) SKCodeBuilder. All rights reserved.
        //\n
        """
        
        let mCommentString =
        """
        //
        //  \(config.rootModelName).m
        //  SKCodeBuilder
        //
        //  Created by \(config.authorName) on \(time).
        //  Copyright © \(year) SKCodeBuilder. All rights reserved.
        //\n
        """
        
        hString.insert(hCommentString, at: 0)
        mString.insert(mCommentString, at: 0)

        if let handler = complete  {
            handler(hString, mString)
        }
    }
    
    func generate_OC_File(with filePath:String?, hString:NSMutableString, mString:NSMutableString, complete:GenerateFileComplete?) {
        if hString.length > 0 && mString.length > 0 {

            var filePath = filePath
            var success = false
            
            if filePath == nil {
                if let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, false).last {
                    let path = desktopPath.appending("/SKGenerateModelToolFiles")
                    print("path = \(path)")
                    var isDir = ObjCBool.init(false)
                    let isExists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
                    if isDir.boolValue && isExists {
                       filePath = path
                    } else {
                        do {
                            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
                            filePath = path
                        } catch let error {
                            print("createDirectory error = \(error)")
                            success = false
                        }
                    }
                }
            }
            
            let fileNameH = filePath?.appending("/\(config.rootModelName).h")
            let fileNameM = filePath?.appending("/\(config.rootModelName).m")

            do {
                try hString.write(toFile: fileNameH!, atomically: true, encoding: String.Encoding.utf8.rawValue)
                try mString.write(toFile: fileNameM!, atomically: true, encoding: String.Encoding.utf8.rawValue)
                success = true
            } catch  {
                success = false
            }
            
            print("fileNameH = \(fileNameH!)")
            print("fileNameM = \(fileNameM!)")

            if let complete = complete {
                complete(success, filePath!)
            }
        }
    }
    
    // MARK: - Private Handler

    private func handleDictValue(dictValue:Any, key:String, hString:NSMutableString, mString:NSMutableString) {
        
        if key.isBlank { // Root model
            hString.append("\n@interface \(self.config.rootModelName) : \(self.config.superClassName)\n\n")
            mString.append("\n@implementation \(self.config.rootModelName)\n\n")
            
        } else { // sub model
            let modeName = modelClassName(with: key)
            hString.insert("@class \(modeName);\n", at: 0)
            hString.append("\n@interface \(modeName) : \(self.config.superClassName)\n\n")
            mString.append("\n@implementation \(modeName)\n\n")
        }
        
        switch dictValue {
            
        case let array as [Any]:
            
            handleArrayValue(arrayValue: array, key: "dataList", hString: hString)
            
        case let dict as [String:Any]:
            
            dict.forEach { (key, value) in
                
                switch value {
                    
                case _ as NSNumber:
                    
                    handleIdNumberValue(numValue: value as! NSNumber , key: key, hString: hString, ignoreIdValue: config.jsonType == .none)
                    
                case _ as String:
                    
                    handleIdStringValue(idValue: value as! String, key: key, hString: hString, ignoreIdValue: config.jsonType == .none)
                    
                case _ as [String:Any]:
                    
                    let modelName = modelClassName(with: key)
                    hString.append("/** \(key) */\n@property (nonatomic, strong) \(modelName) *\(key);\n")
                    
                    self.yymodelPropertyGenericClassDicts.setValue(modelName, forKey: key)
                    self.handleDicts.setValue(value, forKey: key)
                    
                case let arr as [Any]:
                    
                    handleArrayValue(arrayValue: arr, key: key, hString: hString)
                    
                default:
                    // 识别不出类型
                    hString.append("/** <识别不出类型#> */\n@property (nonatomic, strong) id \(key);\n")
                }
            }
            
        default:
            hString.append("\n@end\n\n")
            mString.append("\n@end\n\n")
            return
        }
        
        hString.append("\n@end\n\n")
        
        handleJsonType(hString: hString, mString: mString)
        
        if !key.isBlank {
            self.handleDicts.removeObject(forKey: key)
        }
        mString.append("\n@end\n\n")

        self.yymodelPropertyGenericClassDicts.removeAllObjects()
        self.handlePropertyMapper.removeAllObjects()
        
        if self.handleDicts.count > 0 {
            let firstKey = self.handleDicts.allKeys.first as! String
            if let firstObject = self.handleDicts.value(forKey: firstKey) {
                handleDictValue(dictValue: firstObject, key: firstKey, hString: hString, mString: mString)
            }
        }
    }
    
    private func handleArrayValue(arrayValue:[Any], key:String, hString:NSMutableString) {
        
        guard arrayValue.count > 0 else {
            return
        }
        if let firstObject = arrayValue.first  {
            
            if firstObject is String {
                // String 类型
                hString.append("/** \(key) */\n@property (nonatomic, strong) NSArray <NSString *> *\(key);\n")
            }
            else if (firstObject is [String:Any]) {
                // Dictionary 类型
                let modeName = modelClassName(with: key)
                self.handleDicts.setValue(firstObject, forKey: key)
                self.yymodelPropertyGenericClassDicts.setValue(modeName, forKey: key)
                hString.append("/** \(key) */\n@property (nonatomic, strong) NSArray <\(modeName) *> *\(key);\n")
            }
            else if (firstObject is [Any]) {
                // Array 类型
                handleArrayValue(arrayValue: firstObject as! [Any] , key: key, hString: hString)
            }
            else {
                hString.append("/** \(key) */\n@property (nonatomic, strong) NSArray *\(key);\n")
            }
        }
    }
    
    private func handleIdNumberValue(numValue:NSNumber, key:String, hString:NSMutableString, ignoreIdValue:Bool) {
        
        // let type = numValue.objCType
        
        let numType = CFNumberGetType(numValue as CFNumber)
        
        switch numType {
            
        case .doubleType, .floatType, .float32Type, .float64Type, .cgFloatType:
            /// 浮点型
            hString.append("/** eg. \(numValue) */\n@property (nonatomic, assign) CGFloat \(key);\n")
       
        case .charType:
            if numValue.int32Value == 0 || numValue.int32Value == 1 {
                /// Bool 类型
                hString.append("/** eg. \(numValue) */\n@property (nonatomic, assign) BOOL \(key);\n")

            } else {
                handleIdStringValue(idValue: numValue.stringValue, key: key, hString: hString, ignoreIdValue: ignoreIdValue)
            }
            
        case .longType, .longLongType:
            /// Int
            hString.append("/** eg. \(numValue) */\n@property (nonatomic, assign) NSInteger \(key);\n")

            /// Int
        case .shortType, .intType, .sInt32Type, .nsIntegerType:
                      
            hString.append("/** eg. \(numValue) */\n@property (nonatomic, assign) NSInteger itemId;\n")

        default:
            /// Int
            if key == "id" && !ignoreIdValue {
                self.handlePropertyMapper.setValue("id", forKey: "itemId")
                hString.append("/** eg. \(numValue) */\n@property (nonatomic, assign) NSInteger itemId;\n")

            } else {
                hString.append("/** eg. \(numValue) */\n@property (nonatomic, assign) NSInteger \(key);\n")
            }
        }
    }
    
    private func handleIdStringValue(idValue: String, key:String, hString:NSMutableString, ignoreIdValue:Bool) {
        
        if key == "id" && !ignoreIdValue {
            self.handlePropertyMapper.setValue("id", forKey: "itemId")
            hString.append("/** eg. \(idValue) */\n@property (nonatomic, copy) NSString itemId;\n")
        } else {
            if hString.length > 12 {
                hString.append("/** eg. \(key) */\n@property (nonatomic, assign) NSInteger \(key);\n")
            } else {
                hString.append("/** eg. \(idValue) */\n@property (nonatomic, assign) NSInteger \(key);\n")
            }
        }
    }
    
     /// 处理json解析

    private func handleJsonType(hString:NSMutableString, mString:NSMutableString) {
        
        switch config.jsonType {
        case .YYModel:
            // 适配YYModel
            
            /// 1.The generic class mapper for container properties.
            
            var needLineBreak = false;
            if (self.yymodelPropertyGenericClassDicts.count > 0) {
                mString.append("+ (NSDictionary<NSString *,id> *)modelContainerPropertyGenericClass\n")
                mString.append("{\n     return @{\n")
                for (key, obj) in self.yymodelPropertyGenericClassDicts {
                    mString.append("              @\"\(key)\" : \(obj).class,\n")
                }
                mString.append("             };")
                mString.append("\n}\n")
                needLineBreak = true;
            }
            
            /// 2.Custom property mapper.
            
            if (self.handlePropertyMapper.count > 0) {
                if (needLineBreak) {
                    mString.append("\n")
                }
                
                mString.append("+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper\n")
                mString.append("{\n     return @{\n")
                for (key, obj) in self.handlePropertyMapper {
                    mString.append("              @\"\(key)\" : @\"\(obj)\",\n")
                }
                mString.append("             };")
                mString.append("\n}\n")
            }
            
        case .MJExtension:
            // 适配MJExtension
            
            /// 1.The generic class mapper for container properties.
            
            var needLineBreak = false;
            if (self.yymodelPropertyGenericClassDicts.count > 0) {
                mString.append("+ (NSDictionary *)mj_objectClassInArray\n")
                mString.append("{\n     return @{\n")
                for (key, obj) in self.yymodelPropertyGenericClassDicts {
                    mString.append("              @\"\(key)\" : \(obj).class,\n")
                }
                mString.append("             };")
                mString.append("\n}\n")
                needLineBreak = true;
            }
            
            /// 2.Custom property mapper.
            
            if (self.handlePropertyMapper.count > 0) {
                if (needLineBreak) {
                    mString.append("\n")
                }
                
                mString.append("+ (NSDictionary *)mj_replacedKeyFromPropertyName\n")
                mString.append("{\n     return @{\n")
                for (key, obj) in self.handlePropertyMapper {
                    mString.append("              @\"\(key)\" : @\"\(obj)\",\n")
                }
                mString.append("             };")
                mString.append("\n}\n")
            }
            
        default:
            break
        }
    }
    
    /// 生成类名
    
    private func modelClassName(with key:String) -> String {
        if key.isBlank { return config.rootModelName }
        let firstCharacterIndex = key.index(key.startIndex, offsetBy: 1)
        var firstCharacter = String(key[..<firstCharacterIndex])
        firstCharacter = firstCharacter.uppercased()
        let start = String.Index.init(utf16Offset: 0, in: key)
        let end = String.Index.init(utf16Offset: 1, in: key)
        var modelName = key.replacingCharacters(in: start..<end, with: firstCharacter)
        if !modelName.hasPrefix(config.modelNamePrefix) {
            modelName = config.modelNamePrefix + modelName
        }
        return modelName
    }
}

// MARK: - Config

class SKCodeBuilderConfig: NSObject {
    var superClassName = "NSObject"
    var rootModelName = "NSRootModel"
    var modelNamePrefix = "NS"
    var authorName = "SKGenerateModelTool"
    var codeType: SKCodeBuilderCodeType = .OC
    var jsonType: SKCodeBuilderJSONModelType = .None
}

extension String {
    
    var isBlank: Bool {
        let trimmedStr = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedStr.isEmpty
    }
    
    /// url 编码
    func urlEncoding() -> String {
        if self.isBlank { return self }
        if let encodeUrl = self.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            return encodeUrl
        }
        return self
    }
    
    /// string -> jsonObj
    func _toJsonObj() -> Any? {
        if self.isBlank { return nil }
        if let jsonData = self.data(using: String.Encoding.utf8) {
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
                return jsonObj
            } catch let error {
                print(error)
            }
        }
        return nil
    }
}

