//
//  ViewController.swift
//  SKGenerateModelTool
//
//  Created by KUN on 2020/5/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var urlTF: NSTextField!
    @IBOutlet weak var jsonTextView: NSTextView!
    @IBOutlet weak var hTextView: NSTextView!
    @IBOutlet weak var mTextView: NSTextView!
    @IBOutlet weak var hTextViewHeightPriority: NSLayoutConstraint!
    @IBOutlet weak var superClassNameTF: NSTextField!  /// default 3:5
    @IBOutlet weak var modelNamePrefixTF: NSTextField!
    @IBOutlet weak var rootModelNameTF: NSTextField!
    @IBOutlet weak var authorNameTF: NSTextField!
    @IBOutlet weak var reqTypeBtn: NSPopUpButton!
    @IBOutlet weak var codeTypeBtn: NSPopUpButton!
    @IBOutlet weak var jsonTypeBtn: NSPopUpButton!
    @IBOutlet weak var generateFileBtn: NSButton!

    /// cache key

    let LastInputURLCacheKey = "LastInputURLCacheKey"
    let SuperClassNameCacheKey = "SuperClassNameCacheKey"
    let RootModelNameCacheKey = "RootModelNameCacheKey"
    let ModelNamePrefixCacheKey = "ModelNamePrefixCacheKey"
    let AuthorNameCacheKey = "AuthorNameCacheKey"
    let BuildCodeTypeCacheKey = "BuildCodeTypeCacheKey"
    let SupportJSONModelTypeCacheKey = "SupportJSONModelTypeCacheKey"
    let ShouldGenerateFileCacheKey = "ShouldGenerateFileCacheKey"
    let GenerateFilePathCacheKey = "GenerateFilePathCacheKey"
    
    /// cache key
    var outputFilePath: String?

    var builder = SKCodeBuilder()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        reqTypeBtn.removeAllItems()
        reqTypeBtn.addItems(withTitles: ["GET","POST"])
        reqTypeBtn.selectItem(at: 0)
        
        codeTypeBtn.removeAllItems()
        codeTypeBtn.addItems(withTitles: ["Objective-C","Swift"])
        codeTypeBtn.selectItem(at: 0)

        jsonTypeBtn.removeAllItems()
        jsonTypeBtn.addItems(withTitles: ["None","YYMode","MJExtension","HandyJSON"])
        jsonTypeBtn.selectItem(at: 0)
        
    }
    
    override func viewDidAppear() {
        loadUserLastInputContent()
    }
    
    /// load cache
    func loadUserLastInputContent() {
        
        if let lastUrl = UserDefaults.standard.string(forKey: LastInputURLCacheKey)  {
            urlTF.stringValue = lastUrl
        }
        if let superClassName = UserDefaults.standard.string(forKey: SuperClassNameCacheKey)  {
            superClassNameTF.stringValue = superClassName
        }
        if let modelNamePrefix = UserDefaults.standard.string(forKey: ModelNamePrefixCacheKey)  {
            modelNamePrefixTF.stringValue = modelNamePrefix
        }
        if let rootModelName = UserDefaults.standard.string(forKey: RootModelNameCacheKey)  {
            rootModelNameTF.stringValue = rootModelName
        }
        if let authorName = UserDefaults.standard.string(forKey: AuthorNameCacheKey)  {
            authorNameTF.stringValue = authorName
        }
        if let outFilePath = UserDefaults.standard.string(forKey: LastInputURLCacheKey)  {
            outputFilePath = outFilePath
        }
        
        builder.config.codeType = SKCodeBuilderCodeType(rawValue: UserDefaults.standard.integer(forKey: BuildCodeTypeCacheKey)) ?? .OC
        codeTypeBtn.selectItem(at: builder.config.codeType.rawValue - 1)
        
        builder.config.jsonType = SKCodeBuilderJSONModelType(rawValue: UserDefaults.standard.integer(forKey: SupportJSONModelTypeCacheKey)) ?? .None
        jsonTypeBtn.selectItem(at: builder.config.jsonType.rawValue)
                    
        generateFileBtn.state = UserDefaults.standard.bool(forKey: SupportJSONModelTypeCacheKey) ? .on : .off
    }
    
    /// save cache
    func saveUserInputContent() {
        let superClassName = superClassNameTF.stringValue.isBlank ? "NSObject" : superClassNameTF.stringValue
        UserDefaults.standard.setValue(superClassName, forKey: SuperClassNameCacheKey)
    }
    
    

    override var representedObject: Any? {
        didSet {
        }
    }


}

