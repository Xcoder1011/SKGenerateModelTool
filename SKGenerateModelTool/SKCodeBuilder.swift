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
    
    func build_OC_code(with jsonObj:Any, complete:BuildComplete?){
        let hString = NSMutableString()
        let mString = NSMutableString()
        handleDictValue(dictValue: jsonObj, key: "", hString: hString, mString: mString)
        if let handler = complete  {
            handler(hString, mString)
        }
    }
    
    func generate_OC_File(with filePath:String, hString:NSMutableString, mString:NSMutableString, complete:GenerateFileComplete) {
        
    }
    
    private func handleDictValue(dictValue:Any, key:String, hString:NSMutableString, mString:NSMutableString) {
        
        if key.isBlank { // Root model
            let modeName = modelName(with: key)
            hString.appending("\n\n@interface \(modeName) : \(self.config.superClassName)\n\n")
            mString.appending("\n\n@implementation \(modeName)\n\n")

        } else { // sub model
            hString.appending("\n\n@interface \(self.config.rootModelName) : \(self.config.superClassName)\n\n")
            mString.appending("\n\n@implementation \(self.config.rootModelName)\n\n")
        }
    }
    
    private func modelName(with key:String) -> String {
        if key.isBlank { return config.rootModelName }
        let firstCharacterIndex = key.index(key.startIndex, offsetBy: 1)
        var firstCharacter = String(key[...firstCharacterIndex])
        firstCharacter = firstCharacter.uppercased()
        let start = String.Index.init(utf16Offset: 0, in: key)
        let end = String.Index.init(utf16Offset: 1, in: key)
        var modelName = key.replacingCharacters(in: start..<end, with: firstCharacter)
        if !modelName.hasPrefix(config.modelNamePrefix) {
            modelName = config.modelNamePrefix + key
        }
        return modelName
    }
}

class SKCodeBuilderConfig: NSObject {
    var superClassName = "NSObject"
    var rootModelName = "NSRootModel"
    var modelNamePrefix = "NS"
    var codeType: SKCodeBuilderCodeType = .OC
    var jsonType: SKCodeBuilderJSONModelType = .None
}

extension String {
    var isBlank: Bool {
        let trimmedStr = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedStr.isEmpty
    }
}
