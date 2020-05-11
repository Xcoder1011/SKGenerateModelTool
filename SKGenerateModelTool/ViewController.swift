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
    
    /// GET request URL
    /// example url:
    ///
    /// 今日热榜（微博）:https://v1.alapi.cn/api/tophub/get?type=weibo
    
    @IBAction func requestURLBtnClicked(_ sender: NSButton) {
        
        var urlString = urlTF.stringValue
        if urlString.isBlank { return }
        urlString = urlString.urlEncoding()
        print("encode URL = \(urlTF.stringValue)")
        
        UserDefaults.standard.setValue(urlString, forKey: LastInputURLCacheKey)
        
        let session = URLSession.shared
        let task = session.dataTask(with: URL(string: urlString)!) { [weak self] (data, response, error) in
           
            guard let data = data, error == nil else { return }
            
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
                if JSONSerialization.isValidJSONObject(jsonObj) {
                    let formatJsonData = try JSONSerialization.data(withJSONObject: jsonObj, options: .prettyPrinted)
                    if let jsonString = String(data: formatJsonData, encoding: String.Encoding.utf8) {
                        self?.configJsonTextView(text: jsonString, textView: self!.jsonTextView, color: NSColor.blue)
                    }
                }
            } catch let error {
                print(" error = \(error)")
            }
        }
        task.resume()
    }
    
    /// config ui on main queue.
    
    func configJsonTextView(text:String, textView:NSTextView, color:NSColor) {
        let attrString = NSAttributedString(string: text)
        DispatchQueue.main.async {
            textView.textStorage?.setAttributedString(attrString)
            textView.textStorage?.font = NSFont.systemFont(ofSize: 15)
            textView.textStorage?.foregroundColor = color
        }
    }
    
    
    /// start generate code....
    
    @IBAction func startMakeCode(_ sender: NSButton) {
        
        let jsonString = jsonTextView.textStorage?.string
        
        guard let jsonObj = jsonString?._toJsonObj() else {
            showAlertInfoWith("warn: input valid json string!", .warning)
            return
        }
        
        guard JSONSerialization.isValidJSONObject(jsonObj) else {
            showAlertInfoWith("warn: is not a valid JSON !!!", .warning)
            return
        }
        
        saveUserInputContent()
        
        do {
            let formatJsonData = try JSONSerialization.data(withJSONObject: jsonObj, options: .prettyPrinted)
            if let jsonString = String(data: formatJsonData, encoding: String.Encoding.utf8) {
                configJsonTextView(text: jsonString, textView: jsonTextView, color: NSColor.blue)
            }
        } catch let error {
            print(" error = \(error)")
        }
        
        if builder.config.codeType == .OC {
            builder.build_OC_code(with: jsonObj) { [weak self] (hString, mString) in
                print(" hString = \(hString)")
                print(" mString = \(mString)")

                self?.configJsonTextView(text: hString as String, textView: self!.hTextView, color: NSColor.red)
                self?.configJsonTextView(text: mString as String, textView: self!.mTextView, color: NSColor.red)
            }
        }
    }
    
    
    @IBAction func chooseOutputFilePath(_ sender: NSButton) {
        
    }
    
    
    func showAlertInfoWith( _ info: String, _ style:NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = info
        alert.alertStyle = style
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
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
        if let outFilePath = UserDefaults.standard.string(forKey: GenerateFilePathCacheKey)  {
            outputFilePath = outFilePath
        }
        
        builder.config.codeType = SKCodeBuilderCodeType(rawValue: UserDefaults.standard.integer(forKey: BuildCodeTypeCacheKey)) ?? .OC
        codeTypeBtn.selectItem(at: builder.config.codeType.rawValue - 1)
        
        builder.config.jsonType = SKCodeBuilderJSONModelType(rawValue: UserDefaults.standard.integer(forKey: SupportJSONModelTypeCacheKey)) ?? .None
        jsonTypeBtn.selectItem(at: builder.config.jsonType.rawValue)
                    
        generateFileBtn.state = UserDefaults.standard.bool(forKey: SupportJSONModelTypeCacheKey) ? .on : .off
    }
    
    /// MARK: save cache
    func saveUserInputContent() {
        
        let superClassName = superClassNameTF.stringValue.isBlank ? "NSObject" : superClassNameTF.stringValue
        UserDefaults.standard.setValue(superClassName, forKey: SuperClassNameCacheKey)
        builder.config.superClassName = superClassName
        
        let modelNamePrefix = modelNamePrefixTF.stringValue.isBlank ? "NS" : modelNamePrefixTF.stringValue
        UserDefaults.standard.setValue(modelNamePrefix, forKey: ModelNamePrefixCacheKey)
        builder.config.modelNamePrefix = modelNamePrefix

        let rootModelName = rootModelNameTF.stringValue.isBlank ? "NSRootModel" : rootModelNameTF.stringValue
        UserDefaults.standard.setValue(rootModelName, forKey: RootModelNameCacheKey)
        builder.config.rootModelName = rootModelName
        
        let authorName = authorNameTF.stringValue.isBlank ? "SKGenerateModelTool" : authorNameTF.stringValue
        UserDefaults.standard.setValue(authorName, forKey: AuthorNameCacheKey)
        builder.config.authorName = authorName
        
        builder.config.codeType = SKCodeBuilderCodeType(rawValue: codeTypeBtn.indexOfSelectedItem + 1)!
        UserDefaults.standard.set(codeTypeBtn.indexOfSelectedItem + 1, forKey: BuildCodeTypeCacheKey)
        
        builder.config.jsonType = SKCodeBuilderJSONModelType(rawValue: jsonTypeBtn.indexOfSelectedItem)!
        UserDefaults.standard.set(jsonTypeBtn.indexOfSelectedItem, forKey: SupportJSONModelTypeCacheKey)

        if builder.config.superClassName.compare("NSObject") == .orderedSame {
            if builder.config.jsonType == .HandyJSON {
                builder.config.superClassName = "HandyJSON"
            } else if builder.config.jsonType == .YYModel {
                builder.config.superClassName = "YYModel"
            }
        }
        
        UserDefaults.standard.setValue(outputFilePath, forKey: GenerateFilePathCacheKey)
        UserDefaults.standard.set(generateFileBtn.state == .on , forKey: ShouldGenerateFileCacheKey)
    }
    
    

    override var representedObject: Any? {
        didSet {
        }
    }


}

