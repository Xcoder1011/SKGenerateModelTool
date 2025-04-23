//
//  SKEncryptTool.swift
//  SKGenerateModelTool
//
//  Created by shangkun on 2020/7/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

typealias EncryptComplete = (NSMutableString, NSMutableString) -> ()

class SKEncryptTool: NSObject {
    /// 加密字符串
    /// - Parameters:
    ///   - str: 待加密的字符串
    ///   - key: 密钥（可选设置）
    ///   - complete: 完成回调
    static func encryptString(str: String, key: String?, complete: EncryptComplete?) {
        let tempStr = str.replacingOccurrences(of: " ", with: "")
        if tempStr.isBlank { return }
        let value = NSMutableString()
        let secretValues = NSMutableString()
        var length = 0
        var cstring: [CChar] = []
        if let cstr = str.cString(using: .utf8) {
            cstring = cstr
            length = cstring.count - 1
        }
        var keyLength = 0
        var ckeystring: [CChar] = []
        if let secretKey = key {
            if secretKey.count > 0 {
                if let ckeystr = secretKey.cString(using: .utf8) {
                    ckeystring = ckeystr
                    keyLength = ckeystring.count - 1
                }
            }
        }
        let a: CChar = 99
        let t = MemoryLayout<CChar>.stride
        let range = pow(2.0, Float(t * 7)) - 1
        let factor = Int8(arc4random_uniform(UInt32(range)) - 1)
        if keyLength > 0 {
            let b: CChar = 100
            for index in 0..<keyLength {
                let k = b ^ factor ^ ckeystring[index]
                secretValues.appendFormat("%d,", k)
            }
            secretValues.append("0")
            
            var cipherIndex = 0
            for index in 0..<length {
                cipherIndex %= keyLength
                let v = a ^ factor ^ ckeystring[cipherIndex]
                value.appendFormat("%d,", v ^ cstring[index])
                cipherIndex += 1
            }
        } else {
            for index in 0..<length {
                value.appendFormat("%d,", a ^ factor ^ cstring[index])
            }
        }
        value.append("0")
        
        let hString = NSMutableString()
        let varName = str.checksum()
        hString.append("/** \(str) */\n")
        hString.append("extern const SKEncryptString * const \(varName);\n")
        
        let mString = NSMutableString()
        mString.append("/** \(str) */\n")
        mString.append("const SKEncryptString * const \(varName) = &(SKEncryptString){\n")
        
        mString.append("       .factor = (char)\(factor),\n")
        mString.append("       .value = (char[]){\(value)},\n")
        mString.append("       .length = \(length),\n")
        
        if keyLength > 0 {
            mString.append("       .key = (char[]){\(secretValues)},\n")
            mString.append("       .kl = \(keyLength)\n")
        }
        mString.append("};\n")
        
        if let block = complete {
            block(hString, mString)
        }
    }
}
