//
//  SKCodeBuilder.swift
//  SKGenerateModelTool
//
//  Created by KUN on 2020/5/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa
import zlib

enum SKCodeBuilderCodeType: Int {
    case OC = 1
    case Swift
    case Dart
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
    lazy var allKeys = [String]()
    // 适配json文件的注释
    var commentDicts:[String:String]?
    // Dart => FromJson & ToJson
    lazy var fromJsonString = NSMutableString()
    lazy var toJsonString = NSMutableString()

    var fileTye:String {
        get {
            if config.codeType == .Swift { return "swift" }
            else if config.codeType == .Dart { return "dart" }
            return "h"
        }
    }
    
    // MARK: - Public
    
    func generateCode(with jsonObj:Any, complete:BuildComplete?){
        
        allKeys.removeAll()
        fromJsonString = ""
        toJsonString = ""
        let hString = NSMutableString()
        let mString = NSMutableString()
        handleDictValue(dictValue: jsonObj, key: "", hString: hString, mString: mString)
        if config.codeType == .OC {
            if config.superClassName == "NSObject" {
                hString.insert("\n#import <Foundation/Foundation.h>\n\n", at: 0)
            } else {
                hString.insert("\n#import \"\(config.superClassName).h\"\n\n", at: 0)
            }
            mString.insert("\n#import \"\(config.rootModelName).h\"\n\n", at: 0)
        } else if config.codeType == .Swift {
            if (config.jsonType == .HandyJSON) {
                hString.insert("\nimport HandyJSON\n\n", at: 0)
            }
        } else if config.codeType == .Dart {
            hString.insert("\npart '\(config.rootModelName).m.dart';\n\n", at: 0)
            mString.insert("\npart of '\(config.rootModelName).dart';\n\n", at: 0)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let time = dateFormatter.string(from: Date())
        let year = time.components(separatedBy: "/").first ?? "2020"
        
        let hCommentString =
        """
        //
        //  \(config.rootModelName).\(fileTye)
        //  SKGenerateModelTool
        //
        //  Created by \(config.authorName) on \(time).
        //  Copyright © \(year) SKGenerateModelTool. All rights reserved.
        //\n
        """
        
        var fileName = "m"
        if config.codeType == .Dart {
            fileName = "m.dart"
        }
        let mCommentString =
        """
        //
        //  \(config.rootModelName).\(fileName)
        //  SKGenerateModelTool
        //
        //  Created by \(config.authorName) on \(time).
        //  Copyright © \(year) SKGenerateModelTool. All rights reserved.
        //\n
        """
        
        hString.insert(hCommentString, at: 0)
        mString.insert(mCommentString, at: 0)
        if let handler = complete  {
            handler(hString, mString)
        }
    }
    
    func generateFile(with filePath:String?, hString:NSMutableString, mString:NSMutableString, complete:GenerateFileComplete?) {
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
            
            var fileNameH = "", fileNameM = ""
            if let filePath = filePath {
                if config.codeType == .OC {
                    fileNameH = filePath.appending("/\(config.rootModelName).h")
                    fileNameM = filePath.appending("/\(config.rootModelName).m")
                } else if config.codeType == .Swift {
                    fileNameH = filePath.appending("/\(config.rootModelName).swift")
                } else if config.codeType == .Dart {
                    fileNameH = filePath.appending("/\(config.rootModelName).dart")
                    fileNameM = filePath.appending("/\(config.rootModelName).m.dart")
                }
                do {
                    if !fileNameH.isBlank {
                        try hString.write(toFile: fileNameH, atomically: true, encoding: String.Encoding.utf8.rawValue)
                    }
                    if !fileNameM.isBlank {
                        try mString.write(toFile: fileNameM, atomically: true, encoding: String.Encoding.utf8.rawValue)
                    }
                    success = true
                } catch  {
                    success = false
                }
            }
            if let complete = complete {
                complete(success, filePath!)
            }
        }
    }
    
    // MARK: - Private Handler
    
    private func handleDictValue(dictValue:Any, key:String, hString:NSMutableString, mString:NSMutableString) {
        
        if config.codeType == .OC {
            if key.isBlank { // Root model
                hString.append("\n@interface \(config.rootModelName) : \(config.superClassName)\n\n")
                mString.append("\n@implementation \(config.rootModelName)\n\n")
            } else { // sub model
                let modelName = modelClassName(with: key)
                hString.insert("@class \(modelName);\n", at: 0)
                hString.append("\n@interface \(modelName) : \(config.superClassName)\n\n")
                mString.append("\n@implementation \(modelName)\n\n")
            }
        } else if config.codeType == .Swift {
            if key.isBlank { // Root model
                hString.append("\nclass \(config.rootModelName) : \(config.superClassName) {\n\n")
            } else { // sub model
                let modelName = modelClassName(with: key)
                hString.append("\n\nclass \(modelName) : \(config.superClassName) {\n\n")
            }
        } else if config.codeType == .Dart {
            var modelName = config.rootModelName
            if key.isBlank { // Root model
                if config.superClassName.isBlank {
                    hString.append("\nclass \(config.rootModelName) {\n\n")
                } else {
                    hString.append("\nclass \(config.rootModelName) extends \(config.superClassName) {\n\n")
                }
                
            } else { // sub model
                modelName = modelClassName(with: key)
                if config.superClassName.isBlank {
                    hString.append("\nclass \(modelName) {\n\n")
                } else {
                    hString.append("\nclass \(modelName) extends \(config.superClassName) {\n\n")
                }
            }
            fromJsonString.append("\n\(modelName) _$\(modelName)FromJson(Map<String, dynamic> json, \(modelName) instance) {\n")
            toJsonString.append("\nMap<String, dynamic> _$\(modelName)ToJson(\(modelName) instance) {\n")
            toJsonString.append("    final Map<String, dynamic> json = new Map<String, dynamic>();\n")
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
                    
                    let key = handleMaybeSameKey(key)
                    let modelName = modelClassName(with: key)
                    if config.codeType == .OC {
                        hString.append("/** \(key) */\n@property (nonatomic, strong) \(modelName) *\(key);\n")
                        self.yymodelPropertyGenericClassDicts.setValue(modelName, forKey: key)
                    } else if config.codeType == .Swift {
                        hString.append("    /// \n    var \(key): \(modelName)?\n")
                    } else if config.codeType == .Dart {
                        hString.append("    \(modelName) \(key);\n")
                        self.yymodelPropertyGenericClassDicts.setValue(modelName, forKey: key)
                        
                        let fString =
                        """
                            if (json['\(key)'] != null) {
                                instance.\(key) = new \(modelName)().fromJson(json['\(key)']);
                            }
                        
                        """
                        fromJsonString.append(fString)
                        
                        let tString =
                        """
                            if (instance.\(key) != null) {
                                json['\(key)'] = instance.\(key).toJson();
                            }
                        
                        """
                        toJsonString.append(tString)
                    }
                    self.handleDicts.setValue(value, forKey: key)
                    
                case let arr as [Any]:
                    
                    handleArrayValue(arrayValue: arr, key: key, hString: hString)
                    
                default:
                    // 识别不出类型
                    if config.codeType == .OC {
                        hString.append("/** <#泛型#> */\n@property (nonatomic, strong) id \(key);\n")
                    } else if config.codeType == .Swift {
                        hString.append("    /// <#泛型#>\n    var \(key): Any?\n")
                    } else if config.codeType == .Dart {
                        hString.append("    dynamic \(key);  //<#泛型#>\n")
                        
                        let fString =
                        """
                            if (json['\(key)'] != null) {
                                instance.\(key) = json['\(key)'];
                            }
                        
                        """
                        fromJsonString.append(fString)
                        
                        let tString =
                        """
                            if (instance.\(key) != null) {
                                json['\(key)'] = instance.\(key);
                            }
                        
                        """
                        
                        toJsonString.append(tString)
                    }
                }
            }
            
        default:
            if config.codeType == .OC {
                hString.append("\n@end\n\n")
                mString.append("\n@end\n\n")
            } else if config.codeType == .Swift {
                hString.append("}\n")
            } else if config.codeType == .Dart {
                hString.append("}\n")
            }
            return
        }
        
        if config.codeType == .OC {
            hString.append("\n@end\n\n")
            handleJsonType(hString: hString, mString: mString)
        } else if config.codeType == .Swift {
            handleJsonType(hString: hString, mString: mString)
            hString.append("}\n")
        } else if config.codeType == .Dart {
            var modelName = config.rootModelName;
            if !key.isBlank {
                modelName = modelClassName(with: key)
            }
            let fromJsonString =
            """
            
                \(modelName) fromJson(Map<String, dynamic> json) => _$\(modelName)FromJson(json, this);
                Map<String, dynamic> toJson() => _$\(modelName)ToJson(this);
            
            """
            hString.append(fromJsonString);
            hString.append("}\n")
        }
        if !key.isBlank {
            self.handleDicts.removeObject(forKey: key)
        }
        if config.codeType == .Dart {
            mString.append(fromJsonString as String)
            mString.append("}\n")
            mString.append(toJsonString as String)
            mString.append("}\n")
            fromJsonString = ""
            toJsonString = ""
        } else {
            mString.append("\n@end\n\n")
        }
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
        if config.codeType == .OC {
            if let firstObject = arrayValue.first  {
                if firstObject is String {
                    // String 类型
                    hString.append("/** eg. \(commentName(key, firstObject as! String)) */\n@property (nonatomic, strong) NSArray <NSString *> *\(key);\n")
                }
                else if (firstObject is [String:Any]) {
                    // Dictionary 类型
                    let key = handleMaybeSameKey(key)
                    let modeName = modelClassName(with: key)
                    self.handleDicts.setValue(firstObject, forKey: key)
                    self.yymodelPropertyGenericClassDicts.setValue(modeName, forKey: key)
                    hString.append("/** eg. \(commentName(key, "")) */\n@property (nonatomic, strong) NSArray <\(modeName) *> *\(key);\n")
                }
                else if (firstObject is [Any]) {
                    // Array 类型
                    handleArrayValue(arrayValue: firstObject as! [Any] , key: key, hString: hString)
                }
                else {
                    hString.append("/** eg. \(commentName(key, "")) */\n@property (nonatomic, strong) NSArray *\(key);\n")
                }
            }
        } else if config.codeType == .Swift {
            if let firstObject = arrayValue.first  {
                if firstObject is String {
                    // String 类型
                    hString.append("    /// \(commentName(key, firstObject as! String, false)) \n    var \(key): [String]?\n")
                }
                else if (firstObject is [String:Any]) {
                    // Dictionary 类型
                    let key = handleMaybeSameKey(key)
                    let modeName = modelClassName(with: key)
                    self.handleDicts.setValue(firstObject, forKey: key)
                    hString.append("    ///  \(commentName(key, "", false)) \n    var \(key): [\(modeName)]?\n")
                }
                else if (firstObject is [Any]) {
                    // Array 类型
                    handleArrayValue(arrayValue: firstObject as! [Any] , key: key, hString: hString)
                }
                else {
                    hString.append("    /// \(commentName(key, "", false)) \n    var \(key): [Any]?\n")
                }
            }
        } else if config.codeType == .Dart {
            if let firstObject = arrayValue.first  {
                if firstObject is String {
                    // String 类型
                    hString.append("    List<String> \(key);  \(singlelineCommentName(key, firstObject as! String, false))\n")
                    
                    let fString =
                    """
                        if (json['\(key)'] != null) {
                            instance.\(key) = new List<String>();
                            instance.\(key) = json['\(key)']?.map((v) => v?.toString())?.toList()?.cast<String>();
                        }
                    
                    """
                    fromJsonString.append(fString)
                                        
                    let tString =
                    """
                        if (instance.\(key) != null) {
                            json['\(key)'] = instance.\(key);
                        }
                    
                    """
                    toJsonString.append(tString)
                }
                else if (firstObject is [String:Any]) {
                    // Dictionary 类型
                    let key = handleMaybeSameKey(key)
                    let modeName = modelClassName(with: key)
                    self.handleDicts.setValue(firstObject, forKey: key)
                    self.yymodelPropertyGenericClassDicts.setValue(modeName, forKey: key)
                    hString.append("    List<\(modeName)> \(key);  \(singlelineCommentName(key, "", false))\n")
                    
                    let fString =
                    """
                        if (json['\(key)'] != null) {
                            instance.\(key) = new List<\(modeName)>();
                            (json['\(key)'] as List).forEach((v) {
                                instance.\(key).add(new \(modeName)().fromJson(v));
                            });
                        }
                    
                    """
                    fromJsonString.append(fString)
                                        
                    let tString =
                    """
                        if (instance.\(key) != null) {
                            json['\(key)'] = instance.\(key).map((v) => v.toJson()).toList();
                        }
                    
                    """
                    toJsonString.append(tString)
                    
                }
                else if (firstObject is [Any]) {
                    // Array 类型
                    handleArrayValue(arrayValue: firstObject as! [Any] , key: key, hString: hString)
                }
                else {
                    hString.append("    List<dynamic> \(key);  \(singlelineCommentName(key, "", false))\n")
                    
                    let fString =
                    """
                        if (json['\(key)'] != null) {
                            instance.\(key) = new List<dynamic>();
                            instance.\(key).addAll(json['\(key)']);
                        }
                    
                    """
                    fromJsonString.append(fString)
                                        
                    let tString =
                    """
                        if (instance.\(key) != null) {
                            json['\(key)'] = [];
                        }
                    
                    """
                    toJsonString.append(tString)
                }
            }
        }
    }
    
    private func handleIdNumberValue(numValue:NSNumber, key:String, hString:NSMutableString, ignoreIdValue:Bool) {
                
        let numType = CFNumberGetType(numValue as CFNumber)
        
        switch numType {
            
        case .doubleType, .floatType, .float32Type, .float64Type, .cgFloatType:
            /// 浮点型
            if config.codeType == .OC {
                hString.append("/** eg. \(commentName(key, "\(numValue)")) */\n@property (nonatomic, assign) CGFloat \(key);\n")
            } else if config.codeType == .Swift {
                hString.append("    /// \(commentName(key, "\(numValue)"))\n    var \(key): Double?\n")
            } else if config.codeType == .Dart {
                hString.append("    double \(key);  \(singlelineCommentName(key, "\(numValue)"))\n")
                let fString =
                """
                    if (json['\(key)'] != null) {
                      instance.\(key) = json['\(key)']?.toDouble();
                    }
                
                """
                fromJsonString.append(fString)
                
                let tString = "    json['\(key)'] = instance.\(key);\n"
                toJsonString.append(tString)
            }
            
        case .charType:
            if numValue.int32Value == 0 || numValue.int32Value == 1 {
                /// Bool 类型
                if config.codeType == .OC {
                    hString.append("/** eg. \(commentName(key, "\(numValue)")) */\n@property (nonatomic, assign) BOOL \(key);\n")
                } else if config.codeType == .Swift {
                    hString.append("    /// \(commentName(key, (numValue.boolValue == true ? "true" : "false")))\n    var \(key): Bool = false\n")
                } else if config.codeType == .Dart {
                    hString.append("    bool \(key);  \(singlelineCommentName(key, (numValue.boolValue == true ? "true" : "false")))\n")
                    let fString =
                    """
                        if (json['\(key)'] != null) {
                          instance.\(key) = json['\(key)'];
                        }
                    
                    """
                    fromJsonString.append(fString)
                    
                    let tString = "     json['\(key)'] = instance.\(key);\n"
                    toJsonString.append(tString)
                }
            } else {
                handleIdStringValue(idValue: numValue.stringValue, key: key, hString: hString, ignoreIdValue: ignoreIdValue)
            }
            
        case .shortType, .intType, .sInt32Type, .nsIntegerType, .longType, .longLongType:
            /// Int
            handleIdIntValue(intValue: numValue.intValue, key: key, hString: hString, ignoreIdValue: ignoreIdValue)
            
        default:
            /// Int
            handleIdIntValue(intValue: numValue.intValue, key: key, hString: hString, ignoreIdValue: ignoreIdValue)
        }
    }
    
    private func handleIdIntValue(intValue: Int, key:String, hString:NSMutableString, ignoreIdValue:Bool) {
        /// Int
        let comment = (commentName(key, "\(intValue)"))
        if key == "id" && !ignoreIdValue {
            self.handlePropertyMapper.setValue("id", forKey: "itemId")
            if config.codeType == .OC {
                hString.append("/** eg. \(comment) */\n@property (nonatomic, assign) NSInteger itemId;\n")
            } else if config.codeType == .Swift {
                hString.append("    /// \(comment)\n    var itemId: Int = 0\n")
            }
        } else {
            if config.codeType == .OC {
                hString.append("/** eg. \(comment) */\n@property (nonatomic, assign) NSInteger \(key);\n")
            } else if config.codeType == .Swift {
                hString.append("    /// \(comment)\n    var \(key): Int = 0\n")
            }
        }
        
        if config.codeType == .Dart {
            hString.append("    int \(key);  \(singlelineCommentName(key, "\(intValue)"))\n")
            let fString =
            """
                if (json['\(key)'] != null) {
                  instance.\(key) = json['\(key)']?.toInt();
                }
            
            """
            fromJsonString.append(fString)
            
            let tString = "     json['\(key)'] = instance.\(key);\n"
            toJsonString.append(tString)
        }
    }
    
    /// String
    private func handleIdStringValue(idValue: String, key:String, hString:NSMutableString, ignoreIdValue:Bool) {
         
        if config.codeType == .OC {
            if key == "id" && !ignoreIdValue {
                // 字符串id 替换成 itemId
                self.handlePropertyMapper.setValue("id", forKey: "itemId")
                hString.append("/** eg. \(commentName(key, idValue)) */\n@property (nonatomic, copy) NSString *itemId;\n")
            } else {
                hString.append("/** eg. \(commentName(key, idValue)) */\n@property (nonatomic, copy) NSString *\(key);\n")
            }
        } else if config.codeType == .Swift {
            if key == "id" && !ignoreIdValue {
                self.handlePropertyMapper.setValue("id", forKey: "itemId")
                hString.append("    /// \(commentName(key, idValue))\n    var itemId: String?\n")
            } else {
                if idValue.count > 12 {
                    hString.append("    /// \(commentName(key, idValue, false))\n    var \(key): String?\n")
                } else {
                    hString.append("    /// \(commentName(key, idValue))\n    var \(key): String?\n")
                }
            }
        } else if config.codeType == .Dart {
            if key == "id" && !ignoreIdValue {
                self.handlePropertyMapper.setValue("id", forKey: "itemId")
                hString.append("    String \(key);  \(singlelineCommentName(key, idValue))\n")
            } else {
                if idValue.count > 12 {
                    hString.append("    String \(key);  \(singlelineCommentName(key, idValue, false))\n")
                } else {
                    hString.append("    String \(key);  \(singlelineCommentName(key, idValue))\n")
                }
            }
            let fString =
            """
               if (json['\(key)'] != null) {
                 instance.\(key) = json['\(key)']?.toString();
               }
            
            """
            fromJsonString.append(fString)
            
            let tString = "     json['\(key)'] = instance.\(key);\n"
            toJsonString.append(tString)
        }
    }
    
    /// 处理json解析
    private func handleJsonType(hString:NSMutableString, mString:NSMutableString) {
        
        if config.jsonType == .HandyJSON {
            hString .append("\n    required init() {}\n")
            if self.handlePropertyMapper.count > 0 {
                hString .append("\n    public func mapping(mapper: HelpingMapper) {\n")
                for (key, obj) in self.handlePropertyMapper {
                    hString.append("\n        mapper <<< self.\(key) <-- \"\(obj)\"")
                }
                hString .append("\n\n     }\n")
            }
            return
        }
        
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
                if (needLineBreak) { mString.append("\n") }
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
            
            if (self.handlePropertyMapper.count > 0) {
                if (needLineBreak) { mString.append("\n") }
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
    
    /// 处理可能出现相同的key的问题
    private func handleMaybeSameKey( _ key:String) -> String {
        var tempKey = key
        if allKeys.contains(key) {
            tempKey = "\(key)2"
            self.handlePropertyMapper.setValue(key, forKey: tempKey)
        }
        allKeys.append(tempKey)
        return tempKey
    }
    
    /// 生成类名
    private func modelClassName(with key:String) -> String {
        if key.isBlank { return config.rootModelName }
        let strings = key.components(separatedBy: "_")
        let mutableString = NSMutableString()
        var modelName:String
        if !strings.isEmpty {
            for str in strings {
                let firstCharacterIndex = str.index(str.startIndex, offsetBy: 1)
                var firstCharacter = String(str[..<firstCharacterIndex])
                firstCharacter = firstCharacter.uppercased()
                let start = String.Index.init(utf16Offset: 0, in: str)
                let end = String.Index.init(utf16Offset: 1, in: str)
                let str = str.replacingCharacters(in: start..<end, with: firstCharacter)
                mutableString.append(str)
            }
            modelName = mutableString as String
        } else {
            let firstCharacterIndex = key.index(key.startIndex, offsetBy: 1)
            var firstCharacter = String(key[..<firstCharacterIndex])
            firstCharacter = firstCharacter.uppercased()
            let start = String.Index.init(utf16Offset: 0, in: key)
            let end = String.Index.init(utf16Offset: 1, in: key)
            modelName = key.replacingCharacters(in: start..<end, with: firstCharacter)
        }
        if !modelName.hasPrefix(config.modelNamePrefix) {
            modelName = config.modelNamePrefix + modelName
        }
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
    
    /// 生成注释 带有"// "
    private func singlelineCommentName(_ key:String, _ value:String, _ show:Bool=true) -> String {
        var lineComment = ""
        let comment = commentName(key, value, show);
        if !comment.isBlank {
            lineComment = "// \(comment)"
        }
        return lineComment
    }
    
    /// 生成注释
    private func commentName(_ key:String, _ value:String, _ show:Bool=true) -> String {
        var comment = value
        if value.count > 12 {
            comment = key
            if !show {comment = ""}
        }
        if let commentDict = commentDicts,commentDict.count > 0 {
            if let commentValue = commentDict[key] {
                comment = commentValue
            }
        }
        return comment
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
    
    func nsrangeOf(str:String) -> NSRange {
        let nsString = NSString.init(string: self)
        return nsString.range(of: str)
    }
    
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let start: Int = self.distance(from: startIndex, to: range.lowerBound)
        let end: Int = self.distance(from: startIndex, to: range.upperBound)
        return NSMakeRange(start, end - start)
    }
    
    /// 在字符串中查找另一字符串首次出现的位置（或最后一次出现位置）
    func postionOf(sub:String,backwards:Bool = false) -> Int {
        var pos = -1
        if let range = range(of: sub, options: backwards ? .backwards : .literal, range: nil, locale: nil) {
            if !range.isEmpty {
                pos = self.distance(from: startIndex, to: range.lowerBound)
            }
        }
        return pos
    }
    
    /// url 编码
    func _adler32() -> String {
        if self.isBlank { return self }
        var crc = crc32(0, nil, 0)
        if let data = self.data(using: .utf8) {
            let nData = NSData(data: data)
            crc = crc32(crc, nData.bytes.bindMemory(to: UInt8.self, capacity: data.count), uInt(data.count))
            var adler = adler32(0, nil, 0)
            adler = adler32(adler, nData.bytes.bindMemory(to: UInt8.self, capacity: data.count),  uInt(data.count))
            return "_\(adler ^ crc)"
        }
        return self
    }
}

