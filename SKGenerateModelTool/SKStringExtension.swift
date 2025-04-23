// SKStringExtension.swift
// SKGenerateModelTool
//
// Created by shangkun on 2023/11/09.
// Copyright © 2023 wushangkun. All rights reserved.
//

import Foundation
import zlib

extension String {
    /// 判断字符串是否为空
    var isBlank: Bool {
        let trimmedStr = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedStr.isEmpty
    }
    
    /// URL编码
    func urlEncoding() -> String {
        if self.isBlank { return self }
        if let encodeUrl = self.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) {
            return encodeUrl
        }
        return self
    }
    
    /// 字符串转JSON对象
    func toJsonObject() -> Any? {
        if self.isBlank { return nil }
        if let jsonData = self.data(using: String.Encoding.utf8) {
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
                return jsonObj
            } catch {
                print(error)
            }
        }
        return nil
    }
    
    /// 获取子字符串的NSRange
    func nsrangeOf(str: String) -> NSRange {
        let nsString = NSString(string: self)
        return nsString.range(of: str)
    }
    
    /// 将Swift的Range转换为NSRange
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let start: Int = self.distance(from: startIndex, to: range.lowerBound)
        let end: Int = self.distance(from: startIndex, to: range.upperBound)
        return NSMakeRange(start, end - start)
    }
    
    /// 在字符串中查找另一字符串首次出现的位置（或最后一次出现位置）
    func positionOf(sub: String, backwards: Bool = false) -> Int {
        var pos = -1
        if let range = range(of: sub, options: backwards ? .backwards : .literal, range: nil, locale: nil) {
            if !range.isEmpty {
                pos = self.distance(from: startIndex, to: range.lowerBound)
            }
        }
        return pos
    }
    
    /// 计算字符串的Adler32和CRC32值
    func checksum() -> String {
        if self.isBlank { return self }
        var crc = crc32(0, nil, 0)
        if let data = self.data(using: .utf8) {
            let nData = NSData(data: data)
            crc = crc32(crc, nData.bytes.bindMemory(to: UInt8.self, capacity: data.count), uInt(data.count))
            var adler = adler32(0, nil, 0)
            adler = adler32(adler, nData.bytes.bindMemory(to: UInt8.self, capacity: data.count), uInt(data.count))
            return "_\(adler ^ crc)"
        }
        return self
    }
    
    /// 驼峰转下划线
    var underscore_name: String {
        var name = ""
        if self.isBlank { return "" }
        var upperword = ""
        var canAdd = false
        
        for character in self {
            if character.isUppercase { // 大写
                if canAdd {
                    name.append("_\(character.lowercased())")
                } else {
                    name.append("\(character.lowercased())")
                    upperword.append(character)
                }
            } else { // 小写
                if !name.contains("_") {
                    if upperword.count > 1 {
                        let frontString = (name as NSString).substring(to: upperword.count - 1)
                        let lastString = (name as NSString).substring(from: upperword.count - 1)
                        name.removeAll()
                        name.append("\(frontString)_\(lastString)")
                    }
                }
                name.append(character)
                canAdd = true
            }
        }
        return name
    }
}
