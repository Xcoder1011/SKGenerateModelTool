// SKCodeBuilderConfig.swift
// SKGenerateModelTool
//
// Created by shangkun on 2023/11/09.
// Copyright © 2023 wushangkun. All rights reserved.
//

import Foundation

/// 代码生成器配置项
public class SKCodeBuilderConfig {
    /// 父类名称
    var superClassName = "NSObject"
    
    /// 根模型名称
    var rootModelName = "NSRootModel"
    
    /// 模型名称前缀
    var modelNamePrefix = ""
    
    /// 作者名称
    var authorName = "SKGenerateModelTool"
    
    /// 代码类型
    var codeType: SKCodeType = .objectiveC
    
    /// JSON模型类型
    var jsonType: SKJSONModelType = .none
    
    /// 是否生成注释
    var shouldGenerateComment = false
    
    /// 初始化方法
    public init() {}
} 
