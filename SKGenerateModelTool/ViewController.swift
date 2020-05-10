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

    var outputFilePath: String?

    let LastInputURLCacheKey = "LastInputURLCacheKey"
    let SuperClassNameCacheKey = "SuperClassNameCacheKey"
    let RootModelNameCacheKey = "RootModelNameCacheKey"
    let ModelNamePrefixCacheKey = "ModelNamePrefixCacheKey"
    let AuthorNameCacheKey = "AuthorNameCacheKey"
    let BuildCodeTypeCacheKey = "BuildCodeTypeCacheKey"
    let SupportJSONModelTypeCacheKey = "SupportJSONModelTypeCacheKey"
    let ShouldGenerateFileCacheKey = "ShouldGenerateFileCacheKey"
    let GenerateFilePathCacheKey = "GenerateFilePathCacheKey"

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
        
    }
    
    

    override var representedObject: Any? {
        didSet {
        }
    }


}

