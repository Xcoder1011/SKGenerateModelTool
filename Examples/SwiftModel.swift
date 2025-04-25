//
//  RootModel.swift
//  SKGenerateModelTool
//
//  Created by SKGenerateModelTool on 2021/12/31.
//  Copyright © 2021 SKGenerateModelTool. All rights reserved.
//

struct RootModel: Codable {
    var complexStructure: ComplexStructureModel?
    var basicTypes: BasicTypesModel?
    var internationalization: InternationalizationModel?
    var arrayTypes: ArrayTypesModel?
    var specialCharacters: SpecialCharactersModel?
    var specialFormats: SpecialFormatsModel?
    var edgeCases: EdgeCasesModel?
    var nestedObject: NestedObjectModel?
}

struct ComplexStructureModel: Codable {
    var data: [DataModel]? 
    var metadata: MetadataModel?
}

struct EdgeCasesModel: Codable {
    var maxSafeInteger: Int = 0 
    var minSafeInteger: Int = 0 
    var largeNumber: Double? // 1e+308
    var smallNumber: Double? // -1e+308
    var longString: String? 
}

struct InternationalizationModel: Codable {
    var chinese: String? // 简体中文
    var arabic: String? // نص عربي
    var russian: String? 
    var japanese: String? // 日本語テキスト
    var emojiCombination: String? 
}

struct BasicTypesModel: Codable {
    var string: String? // Hello World!
    var emptyString: String? 
    var booleanFalse: Bool = false // false
    var negativeNumber: Int = 0 // -100
    var nullValue: Any? // <#泛型#>
    var scientificNotation: Double? // 6.022e+23
    var zero: Int = 0 // 0
    var integer: Int = 0 // 42
    var booleanTrue: Bool = false // true
    var float: Double? // 3.14159
}

struct SpecialFormatsModel: Codable {
    var hexValue: String? // 0x1A3F
    var isoDate: String? 
    var url: String? 
    var base64Data: String? //  "Hello World!" in Base64
    var uuid: String? 
}

struct DataModel: Codable {
    var id: Int = 0 // 1
    var tags: [String]? 
    var coordinates: CoordinatesModel?
}

struct CoordinatesModel: Codable {
    var x: Double? // 12.34
    var y: Double? // -56.78
}

struct ArrayTypesModel: Codable {
    var nestedArray: [String]? 
    var mixedArray: [Any]? 
    var simpleArray: [Any]? 
}

struct SpecialCharactersModel: Codable {
    var emoji: String? // 😀🚀🌟
    var newlines: String? 
    var specialSymbols: String? 
    var whitespace: String? 
    var escapedCharacters: String? 
    var unicode: String? 
}

struct NestedObjectModel: Codable {
    var user: UserModel?
}

struct UserModel: Codable {
    var username: String? // john_doe
    var preferences: PreferencesModel?
    var contact: ContactModel?
    var id: Int = 0 // 12345
}

struct PreferencesModel: Codable {
    var theme: String? // dark
    var notifications: Bool = false // true
}

struct ContactModel: Codable {
    var phones: [String]? 
    var email: String? 
}

struct MetadataModel: Codable {
    var version: String? // 1.0.0
    var createdAt: String? // 2023-01-01
    var active: Bool = false // true
}
