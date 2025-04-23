//
//  SKCodeBuilder.swift
//  SKGenerateModelTool
//
//  Created by KUN on 2020/5/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

public class SKCodeBuilder {
    var config = SKCodeBuilderConfig()

    // 适配json文件的注释
    var commentDicts: [String: String]?

    /// 生成代码
    func generateCode(with jsonObj: Any, complete: BuildComplete?) {
        let generator = SKModelGenerator(config: config, commentDicts: commentDicts)
        generator.generateCode(with: jsonObj, complete: complete)
    }

    /// 生成文件
    func generateFile(with filePath: String?, hString: NSMutableString, mString: NSMutableString, complete: GenerateFileComplete?) {
        let fileManager = SKFileManager(config: config)
        fileManager.generateFile(with: filePath, hString: hString, mString: mString, complete: complete)
    }
}
