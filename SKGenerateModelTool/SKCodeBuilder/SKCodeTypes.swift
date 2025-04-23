// SKCodeTypes.swift
// SKGenerateModelTool
//
// Created by shangkun on 2023/11/09.
// Copyright © 2023 wushangkun. All rights reserved.
//

import Foundation

public enum SKCodeType: String, CaseIterable {
    case objectiveC = "Objective-C"
    case swift = "Swift"
    case dart = "Dart"
    case typeScript = "TypeScript"

    var language: String {
        switch self {
        case .objectiveC:
            return "objectivec"
        case .swift:
            return "swift"
        case .dart:
            return "dart"
        case .typeScript:
            return "javascript"
        }
    }

    var theme: String {
        switch self {
        case .objectiveC, .swift:
            return "xcode"
        case .dart:
            return "androidstudio"
        case .typeScript:
            return "docco"
        }
    }

    var fileExtension: String {
        switch self {
        case .swift:
            return "swift"
        case .dart:
            return "dart"
        case .typeScript:
            return "ts"
        case .objectiveC:
            return "h"
        }
    }
}

public enum SKJSONModelType: String, CaseIterable {
    case none = "None"
    case yyModel = "YYModel"
    case mjExtension = "MJExtension"
    case handyJSON = "HandyJSON"
}

public typealias BuildComplete = (NSMutableString, NSMutableString) -> Void
public typealias GenerateFileComplete = (Bool, String) -> Void
