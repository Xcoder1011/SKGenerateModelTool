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
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// URL编码
    func urlEncoding() -> String {
        guard !self.isBlank else { return self }
        return self.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? self
    }
    
    /// 字符串转JSON对象
    func toJsonObject() -> Any? {
        guard !self.isBlank,
              let jsonData = self.data(using: .utf8) else { return nil }
        
        do {
            return try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
        } catch {
            print(error)
            return nil
        }
    }
    
    /// 获取子字符串的NSRange
    func nsrangeOf(str: String) -> NSRange {
        (self as NSString).range(of: str)
    }
    
    /// 将Swift的Range转换为NSRange
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let start: Int = self.distance(from: startIndex, to: range.lowerBound)
        let end: Int = self.distance(from: startIndex, to: range.upperBound)
        return NSMakeRange(start, end - start)
    }
    
    /// 在字符串中查找另一字符串首次出现的位置（或最后一次出现位置）
    func positionOf(sub: String, backwards: Bool = false) -> Int {
        guard let range = range(of: sub, options: backwards ? .backwards : .literal) else {
            return -1
        }
        return self.distance(from: startIndex, to: range.lowerBound)
    }
    
    /// 计算字符串的Adler32和CRC32值
    func checksum() -> String {
        guard !self.isBlank, let data = self.data(using: .utf8) else { return self }
        
        let nData = NSData(data: data)
        var crc = crc32(0, nil, 0)
        crc = crc32(crc, nData.bytes.bindMemory(to: UInt8.self, capacity: data.count), uInt(data.count))
        
        var adler = adler32(0, nil, 0)
        adler = adler32(adler, nData.bytes.bindMemory(to: UInt8.self, capacity: data.count), uInt(data.count))
        
        return "_\(adler ^ crc)"
    }
    
    /// 驼峰转下划线
    var underscore_name: String {
        guard !self.isBlank else { return "" }
        
        var name = ""
        var upperword = ""
        var canAdd = false
        
        for character in self {
            if character.isUppercase {
                if canAdd {
                    name.append("_\(character.lowercased())")
                } else {
                    name.append("\(character.lowercased())")
                    upperword.append(character)
                }
            } else {
                if !name.contains("_") && upperword.count > 1 {
                    let nsString = name as NSString
                    let frontString = nsString.substring(to: upperword.count - 1)
                    let lastString = nsString.substring(from: upperword.count - 1)
                    name = "\(frontString)_\(lastString)"
                }
                name.append(character)
                canAdd = true
            }
        }
        
        return name
    }
}
