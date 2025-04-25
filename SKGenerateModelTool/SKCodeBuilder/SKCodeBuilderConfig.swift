// SKCodeBuilderConfig.swift
// SKGenerateModelTool
//
// Created by shangkun on 2023/11/09.
// Copyright © 2023 wushangkun. All rights reserved.
//

import Foundation

@propertyWrapper
struct UserDefaultsStored<T> {
    private let key: String
    private let defaultValue: T
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

/// 代码生成器配置项
public class SKCodeBuilderConfig {
    private enum DefaultValues {
        static let objectiveCClass = "NSObject"
        static let swiftProtocol = "Codable"
        static let defaultRootModelName = "RootModel"
        static let defaultAuthorName = "SKGenerateModelTool"
    }
    
    /// 父类名称
    var superClassName: String {
        get {
            // 基于代码类型返回适当的默认父类
            if _superClassName.isEmpty {
                switch codeType {
                case .swift:
                    return DefaultValues.swiftProtocol
                case .objectiveC:
                    // 处理HandyJSON特殊情况
                    if jsonType == .handyJSON {
                        return "HandyJSON"
                    }
                    return DefaultValues.objectiveCClass
                default:
                    return _superClassName
                }
            }
            return _superClassName
        }
        set {
            _superClassName = newValue
        }
    }
    
    private var _superClassName: String = ""
    
    /// 根模型名称
    var rootModelName: String {
        get {
            return _rootModelName.isEmpty ? DefaultValues.defaultRootModelName : _rootModelName
        }
        set {
            _rootModelName = newValue
        }
    }
    
    private var _rootModelName: String = ""
    
    /// 模型名称前缀
    var modelNamePrefix: String = ""
    
    /// 作者名称
    var authorName: String {
        get {
            return _authorName.isEmpty ? DefaultValues.defaultAuthorName : _authorName
        }
        set {
            _authorName = newValue
        }
    }
    
    private var _authorName: String = ""
    
    /// 代码类型
    var codeType: SKCodeType = .swift
    
    /// JSON模型类型
    var jsonType: SKJSONModelType = .none
    
    /// 是否生成注释
    var shouldGenerateComment = false
    
    public init() {}
}
