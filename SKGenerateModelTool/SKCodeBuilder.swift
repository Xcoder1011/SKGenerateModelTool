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
    case TypeScript
    case Java
    
    var language: String {
        switch self {
        case .OC:
            return "objectivec"
        case .Swift:
            return "swift"
        case .Dart:
            return "dart"
        case .TypeScript:
            return "javascript"
        case .Java:
            return "java"
        }
    }
    
    var theme: String {
        switch self {
        case .OC, .Swift:
            return "xcode"
        case .Dart, .Java:
            return "androidstudio"
        case .TypeScript:
            return "docco"
        }
    }
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
    lazy var blankSpace = "   ";
    lazy var blankSpace2 = "  ";

    // 适配json文件的注释
    var commentDicts:[String:String]?
    
    // Dart => FromJson & ToJson
    lazy var fromJsonString = NSMutableString()
    lazy var toJsonString = NSMutableString()
    
    var fileType:String {
        get {
            if config.codeType == .Swift { return "swift" }
            else if config.codeType == .Dart { return "dart" }
            else if config.codeType == .TypeScript { return "ts" }
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
        let fileName = (config.codeType == .Dart) ? config.rootModelName.underscore_name : config.rootModelName
        handleDictValue(dictValue: jsonObj, key: "", hString: hString, mString: mString)
        if config.codeType == .OC {
            if config.superClassName == "NSObject" {
                if ((config.jsonType == .YYModel) && (config.superClassName.compare("NSObject") == .orderedSame)) {
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
        } else if config.codeType == .Swift {
            if (config.jsonType == .HandyJSON) {
                hString.insert("\nimport HandyJSON\n", at: 0)
            }
        } else if config.codeType == .Dart {
            hString.insert("\npart '\(fileName).m.dart';\n\n", at: 0)
            mString.insert("\npart of '\(fileName).dart';\n", at: 0)
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let time = dateFormatter.string(from: Date())
        let year = time.components(separatedBy: "/").first ?? "2020"
        
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
        if config.codeType == .Dart {
            fileSuffixName = "m.dart"
        } else if config.codeType == .TypeScript {
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
            let fileName = (config.codeType == .Dart) ? config.rootModelName.underscore_name : config.rootModelName
            var fileNameH = "", fileNameM = ""
            if let filePath = filePath {
                if config.codeType == .OC {
                    fileNameH = filePath.appending("/\(fileName).h")
                    fileNameM = filePath.appending("/\(fileName).m")
                } else if config.codeType == .Swift {
                    fileNameH = filePath.appending("/\(fileName).swift")
                } else if config.codeType == .Dart {
                    fileNameH = filePath.appending("/\(fileName).dart")
                    fileNameM = filePath.appending("/\(fileName).m.dart")
                } else if config.codeType == .TypeScript {
                    fileNameH = filePath.appending("/\(fileName).ts")
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
                if ((config.jsonType == .YYModel) && (config.superClassName.compare("NSObject") == .orderedSame)) {
                    hString.append("\n@interface \(config.rootModelName) : \(config.superClassName) <YYModel>\n\n")
                } else {
                    hString.append("\n@interface \(config.rootModelName) : \(config.superClassName)\n\n")
                }
                mString.append("\n@implementation \(config.rootModelName)\n\n")
            } else { // sub model
                let modelName = modelClassName(with: key)
                hString.insert("@class \(modelName);\n", at: 0)
                if ((config.jsonType == .YYModel) && (config.superClassName.compare("NSObject") == .orderedSame)) {
                    hString.append("\n@interface \(modelName) : \(config.superClassName) <YYModel>\n\n")
                } else {
                    hString.append("\n@interface \(modelName) : \(config.superClassName)\n\n")
                }
                mString.append("\n@implementation \(modelName)\n\n")
            }
        } else if config.codeType == .Swift {
            if key.isBlank { // Root model
                hString.append("\nclass \(config.rootModelName) : \(config.superClassName) {\n")
            } else { // sub model
                let modelName = modelClassName(with: key)
                hString.append("\nclass \(modelName) : \(config.superClassName) {\n")
            }
        } else if config.codeType == .Dart {
            var modelName = config.rootModelName
            if key.isBlank { // Root model
                if config.superClassName.isBlank {
                    hString.append("class \(config.rootModelName) {\n")
                } else {
                    hString.append("class \(config.rootModelName) extends \(config.superClassName) {\n")
                }
            } else { // sub model
                modelName = modelClassName(with: key)
                if config.superClassName.isBlank {
                    hString.append("\nclass \(modelName) {\n")
                } else {
                    hString.append("\nclass \(modelName) extends \(config.superClassName) {\n")
                }
            }
            fromJsonString.append("\n\(modelName) _$\(modelName)FromJson(Map<String, dynamic> json, \(modelName) instance) {\n")
            toJsonString.append("\nMap<String, dynamic> _$\(modelName)ToJson(\(modelName) instance) {\n")
            toJsonString.append("   final Map<String, dynamic> json = <String, dynamic>{};\n")
        } else if config.codeType == .TypeScript {
            if key.isBlank { // Root model
                hString.append("\nexport interface \(config.rootModelName) {\n")
            } else { // sub model
                let modelName = modelClassName(with: key)
                hString.append("\n\nexport interface \(modelName) {\n")
            }
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
                        hString.append("\(ocCommentName(key, "", false))@property (nonatomic, strong) \(modelName) *\(key);\n")
                        self.yymodelPropertyGenericClassDicts.setValue(modelName, forKey: key)
                    } else if config.codeType == .Swift {
                        hString.append("    var \(key): \(modelName)?\n")
                    } else if config.codeType == .Dart {
                        hString.append("   \(modelName)? \(key);\n")
                        self.yymodelPropertyGenericClassDicts.setValue(modelName, forKey: key)
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
                    } else if config.codeType == .TypeScript {
                        hString.append("   \(key): \(modelName);\n")
                    }
                    self.handleDicts.setValue(value, forKey: key)
                    
                case let arr as [Any]:
                    
                    handleArrayValue(arrayValue: arr, key: key, hString: hString)
                    
                default:
                    // 识别不出类型
                    if config.codeType == .OC {
                        hString.append("\(ocCommentName(key, "<#泛型#>"))@property (nonatomic, strong) id \(key);\n")
                    } else if config.codeType == .Swift {
                        hString.append("    var \(key): Any?  \(singlelineCommentName(key, "<#泛型#>"))\n")
                    } else if config.codeType == .Dart {
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
                    } else if config.codeType == .TypeScript {
                        hString.append("   \(key)?: null;\n")
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
            } else if config.codeType == .TypeScript {
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
            let headerString =
            """
            
            \(blankSpace)\(modelName) fromJson(Map<String, dynamic> json) => _$\(modelName)FromJson(json, this);
            \(blankSpace)Map<String, dynamic> toJson() => _$\(modelName)ToJson(this);
            
            """
            hString.append(headerString);
            hString.append("}\n")
            
            fromJsonString.append("   return instance;\n");
            toJsonString.append("   return json;\n");
        } else if config.codeType == .TypeScript {
            handleJsonType(hString: hString, mString: mString)
            hString.append("}")
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
                    hString.append("\(ocCommentName(key, "", false))@property (nonatomic, strong) NSArray <NSString *> *\(key);\n")
                }
                else if (firstObject is [String:Any]) {
                    // Dictionary 类型
                    let key = handleMaybeSameKey(key)
                    let modeName = modelClassName(with: key)
                    self.handleDicts.setValue(firstObject, forKey: key)
                    self.yymodelPropertyGenericClassDicts.setValue(modeName, forKey: key)
                    hString.append("\(ocCommentName(key, "", false))@property (nonatomic, strong) NSArray <\(modeName) *> *\(key);\n")
                }
                else if (firstObject is [Any]) {
                    // Array 类型
                    handleArrayValue(arrayValue: firstObject as! [Any] , key: key, hString: hString)
                }
                else {
                    hString.append("\(ocCommentName(key, "", false))@property (nonatomic, strong) NSArray *\(key);\n")
                }
            }
        } else if config.codeType == .Swift {
            if let firstObject = arrayValue.first  {
                if firstObject is String {
                    // String 类型
                    hString.append("    var \(key): [String]?  \(singlelineCommentName(key, "", false))\n")
                }
                else if (firstObject is [String:Any]) {
                    // Dictionary 类型
                    let key = handleMaybeSameKey(key)
                    let modeName = modelClassName(with: key)
                    self.handleDicts.setValue(firstObject, forKey: key)
                    hString.append("    var \(key): [\(modeName)]?  \(singlelineCommentName(key, "", false))\n")
                }
                else if (firstObject is [Any]) {
                    // Array 类型
                    handleArrayValue(arrayValue: firstObject as! [Any] , key: key, hString: hString)
                }
                else {
                    hString.append("    var \(key): [Any]?  \(singlelineCommentName(key, "", false))\n")
                }
            }
        } else if config.codeType == .Dart {
            if let firstObject = arrayValue.first  {
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
                }
                else if (firstObject is [String:Any]) {
                    // Dictionary 类型
                    let key = handleMaybeSameKey(key)
                    let modeName = modelClassName(with: key)
                    self.handleDicts.setValue(firstObject, forKey: key)
                    self.yymodelPropertyGenericClassDicts.setValue(modeName, forKey: key)
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
                    
                }
                else if (firstObject is [Any]) {
                    // Array 类型
                    handleArrayValue(arrayValue: firstObject as! [Any] , key: key, hString: hString)
                }
                else {
                    hString.append("    List<dynamic>? \(key);  \(singlelineCommentName(key, "", false))\n")
                    
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
        } else if config.codeType == .TypeScript {
            if let firstObject = arrayValue.first  {
                if firstObject is String {
                    // String 类型
                    hString.append("   \(key)?: string[] | null;  \(singlelineCommentName(key, "", false))\n")
                }
                else if (firstObject is [String:Any]) {
                    // Dictionary 类型
                    let key = handleMaybeSameKey(key)
                    let modeName = modelClassName(with: key)
                    self.handleDicts.setValue(firstObject, forKey: key)
                    hString.append("   \(key)?: (\(modeName))[] | null;  \(singlelineCommentName(key, "", false))\n")
                }
                else if (firstObject is [Any]) {
                    // Array 类型
                    handleArrayValue(arrayValue: firstObject as! [Any] , key: key, hString: hString)
                }
                else {
                    hString.append("   \(key)?: (null))[] | null;  \(singlelineCommentName(key, "", false))\n")
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
                hString.append("\(ocCommentName(key, "\(numValue)"))@property (nonatomic, assign) CGFloat \(key);\n")
            } else if config.codeType == .Swift {
                hString.append("    var \(key): Double?  \(singlelineCommentName(key, "\(numValue)"))\n")
            } else if config.codeType == .Dart {
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
            } else if config.codeType == .TypeScript {
                hString.append("   \(key): number;  \(singlelineCommentName(key, "\(numValue)"))\n")
            }
            
        case .charType:
            if numValue.int32Value == 0 || numValue.int32Value == 1 {
                /// Bool 类型
                if config.codeType == .OC {
                    hString.append("\(ocCommentName(key, "\(numValue)"))@property (nonatomic, assign) BOOL \(key);\n")
                } else if config.codeType == .Swift {
                    hString.append("    var \(key): Bool = false  \(singlelineCommentName(key, (numValue.boolValue == true ? "true" : "false")))\n")
                } else if config.codeType == .Dart {
                    hString.append("   bool? \(key);  \(singlelineCommentName(key, (numValue.boolValue == true ? "true" : "false")))\n")
                    let fString =
                    """
                    \(blankSpace)if(json['\(key)'] != null) {
                    \(blankSpace)\(blankSpace2)instance.\(key) = json['\(key)'];
                    \(blankSpace)}
                    
                    """
                    fromJsonString.append(fString)
                    
                    let tString = "\(blankSpace)json['\(key)'] = instance.\(key);\n"
                    toJsonString.append(tString)
                } else if config.codeType == .TypeScript {
                    hString.append("   \(key): boolean;  \(singlelineCommentName(key, (numValue.boolValue == true ? "true" : "false")))\n")
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
        if key == "id" && !ignoreIdValue {
            self.handlePropertyMapper.setValue("id", forKey: "itemId")
            if config.codeType == .OC {
                hString.append("\(ocCommentName(key, "\(intValue)"))@property (nonatomic, assign) NSInteger itemId;\n")
            } else if config.codeType == .Swift {
                hString.append("    var itemId: Int = 0  \(singlelineCommentName(key, "\(intValue)"))\n")
            }
        } else {
            if config.codeType == .OC {
                hString.append("\(ocCommentName(key, "\(intValue)"))@property (nonatomic, assign) NSInteger \(key);\n")
            } else if config.codeType == .Swift {
                hString.append("    var \(key): Int = 0  \(singlelineCommentName(key, "\(intValue)"))\n")
            }
        }
        
        if config.codeType == .Dart {
            hString.append("   int? \(key);  \(singlelineCommentName(key, "\(intValue)"))\n")
            
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
        } else if config.codeType == .TypeScript {
            hString.append("   \(key): number;  \(singlelineCommentName(key, "\(intValue)"))\n")
        }
    }
    
    /// String
    private func handleIdStringValue(idValue: String, key:String, hString:NSMutableString, ignoreIdValue:Bool) {
        
        if config.codeType == .OC {
            if key == "id" && !ignoreIdValue {
                // 字符串id 替换成 itemId
                self.handlePropertyMapper.setValue("id", forKey: "itemId")
                hString.append("\(ocCommentName(key, idValue))@property (nonatomic, copy) NSString *itemId;\n")
            } else {
                hString.append("\(ocCommentName(key, idValue))@property (nonatomic, copy) NSString *\(key);\n")
            }
        } else if config.codeType == .Swift {
            if key == "id" && !ignoreIdValue {
                self.handlePropertyMapper.setValue("id", forKey: "itemId")
                hString.append("    var itemId: String?  \(commentName(key, idValue))\n")
            } else {
                if idValue.count > 12 {
                    hString.append("    var \(key): String?  \(commentName(key, idValue, false))\n")
                } else {
                    hString.append("    var \(key): String?  \(commentName(key, idValue))\n")
                }
            }
        } else if config.codeType == .Dart {
            if key == "id" && !ignoreIdValue {
                self.handlePropertyMapper.setValue("id", forKey: "itemId")
                hString.append("   String? \(key);  \(singlelineCommentName(key, idValue))\n")
            } else {
                hString.append("   String? \(key);  \(singlelineCommentName(key, idValue))\n")
            }
            let fString =
            """
            \(blankSpace)if(json['\(key)'] != null) {
            \(blankSpace)\(blankSpace2)instance.\(key) = json['\(key)']?.toString();
            \(blankSpace)}
            
            """
            fromJsonString.append(fString)
            
            let tString = "\(blankSpace)json['\(key)'] = instance.\(key);\n"
            toJsonString.append(tString)
        } else if config.codeType == .TypeScript {
            hString.append("   \(key): string;  \(singlelineCommentName(key, idValue))\n")
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
    
    /// oc类注释 带有"/** eg.  */"
    private func ocCommentName(_ key:String, _ value:String, _ show:Bool=true) -> String {
        var realComment = ""
        let comment = commentName(key, value, show)
        if !comment.isBlank {
            realComment = "/** eg. \(comment) */\n"
        }
        return realComment
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
        if (!config.shouldGenerateComment) {return ""}
        var comment = value
        if value.count > 12 {
            comment = ""
        }
        if !show {comment = ""}
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
    var modelNamePrefix = ""
    var authorName = "SKGenerateModelTool"
    var codeType: SKCodeBuilderCodeType = .OC
    var jsonType: SKCodeBuilderJSONModelType = .None
    var shouldGenerateComment = false
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
    
    /// 驼峰转下划线
    var underscore_name: String {
        var name = ""
        if self.isBlank { return "" }
        var upperword = ""
        var _canAdd = false
        self.forEach { (character) in
            if character.isUppercase { // 大写
                if _canAdd {
                    name.append("_\(character.lowercased())")
                } else {
                    name.append("\(character.lowercased())")
                    upperword.append(character)
                }
            } else { // 小写
                if !name.contains("_"){
                    if upperword.count > 1 {
                        let frontString = (name as NSString).substring(to: upperword.count-1)
                        let lastString = (name as NSString).substring(from: upperword.count-1)
                        name.removeAll()
                        name.append("\(frontString)_\(lastString)")
                    }
                }
                name.append(character)
                _canAdd = true
            }
        }
        return name
    }
}

