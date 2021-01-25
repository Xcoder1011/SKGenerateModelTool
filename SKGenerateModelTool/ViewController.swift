//
//  ViewController.swift
//  SKGenerateModelTool
//
//  Created by KUN on 2020/5/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSControlTextEditingDelegate {
    
    @IBOutlet weak var urlTF: NSTextField!
    @IBOutlet var jsonTextView: NSTextView!
    @IBOutlet var hTextView: NSTextView!
    @IBOutlet var mTextView: NSTextView!
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
    
    var builder = SKCodeBuilder()

    var outputFilePath: String?
    var currentInputTF: NSTextField?
    
    lazy var jsonTextColor = NSColor.blue
    lazy var codeTextColor = NSColor(red: 215/255.0, green: 0/255.0 , blue: 143/255.0, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        reqTypeBtn.removeAllItems()
        reqTypeBtn.addItems(withTitles: ["GET","POST"])
        reqTypeBtn.selectItem(at: 0)
        
        codeTypeBtn.removeAllItems()
        codeTypeBtn.addItems(withTitles: ["Objective-C","Swift","Dart"])
        codeTypeBtn.selectItem(at: 0)

        jsonTypeBtn.removeAllItems()
        jsonTypeBtn.addItems(withTitles: ["None","YYModel","MJExtension","HandyJSON"])
        jsonTypeBtn.selectItem(at: 0)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        loadUserLastInputContent()
    }
        
    /// GET / POST request URL

    @IBAction func requestURLBtnClicked(_ sender: NSButton) {
       
        var urlString = urlTF.stringValue
        if urlString.isBlank { return }
        urlString = urlString.urlEncoding()
        print("encode URL = \(urlTF.stringValue)")
        UserDefaults.standard.setValue(urlString, forKey: LastInputURLCacheKey)
        let session = URLSession.shared
        let url = URL(string: urlString)
        var request = URLRequest(url: url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        
        if reqTypeBtn.indexOfSelectedItem == 1 {
            if let query = url?.query {
                urlString = urlString.replacingOccurrences(of: query, with: "")
                if urlString.hasSuffix("?") {
                    urlString.removeLast()
                }
                request = URLRequest(url: URL(string: urlString)!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
                if let httpBody = query.data(using: .utf8) {
                    print("httpBody query = \(query)")
                    request.httpBody = httpBody
                }
            }
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
        }

        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
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
    
    /// start generate code....
    
    @IBAction func startMakeCode(_ sender: NSButton) {
       
        if let jsonString = jsonTextView.textStorage?.string {
            if jsonString.isBlank { return }
            var trimmedStr = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            trimmedStr = trimmedStr .replacingOccurrences(of: "”", with: "\"")
            trimmedStr = trimmedStr .replacingOccurrences(of: "，", with: ",")
            let attriStr = NSMutableString(string: trimmedStr)
            var commentDicts:[String:String] = [:]
            attriStr.enumerateLines { (line, _) in
                if line.contains("//") {
                    let substrings = line.components(separatedBy: "//")
                    let hasHttpLink = line.contains("http://") || line.contains("https://") || line.contains("tel://")
                    // 只有图片链接 且没注释的情况下 不做截断操作
                    let cannComment = !(substrings.count == 2 && hasHttpLink)
                    guard cannComment else { return }
                    let trimmedLineStr = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    let position = trimmedLineStr.postionOf(sub: "//",backwards: true)
                    if position >= 0 {
                        let linestr = trimmedLineStr.prefix(position)
                        var keystr = String(linestr).trimmingCharacters(in: .whitespacesAndNewlines)
                        let commentstr = trimmedLineStr.suffix(trimmedLineStr.count - position)
                        if keystr.contains(":") {
                          let lines = keystr.components(separatedBy: ":")
                            keystr = lines.first ?? ""
                            keystr = keystr.replacingOccurrences(of: "\"", with: "")
                            keystr = keystr.trimmingCharacters(in: .whitespacesAndNewlines)
                            let comment = String(commentstr).replacingOccurrences(of: "//", with: "")
                            commentDicts.updateValue(comment, forKey: keystr)
                        }
                        let range = attriStr.range(of: String(commentstr))
                        attriStr.replaceCharacters(in: range, with: "")
                    }
                }
            }
            
            let jsonStr = attriStr
            guard let jsonData = jsonStr.data(using: String.Encoding.utf8.rawValue) else {
                showAlertInfoWith("warn: input valid json string!", .warning)
                return
            }
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
                guard JSONSerialization.isValidJSONObject(jsonObj) else {
                    showAlertInfoWith("warn: is not a valid JSON !!!", .warning)
                    return
                }
                if commentDicts.count > 0 {
                    configJsonTextView(text: jsonString, textView: jsonTextView, color: NSColor.blue)
                    builder.commentDicts = commentDicts
                } else {
                    builder.commentDicts = nil
                    let formatJsonData = try JSONSerialization.data(withJSONObject: jsonObj, options: .prettyPrinted)
                    if let jsonString = String(data: formatJsonData, encoding: String.Encoding.utf8) {
                        configJsonTextView(text: jsonString, textView: jsonTextView, color: NSColor.blue)
                    }
                }
                saveUserInputContent()
                builder.generateCode(with: jsonObj) { [weak self] (hString, mString) in
                    self?.handleGeneratedCode(hString, mString)
                }
            } catch let error as NSError {
                print(" error = \(error)")
                if let errorInfo = error.userInfo["NSDebugDescription"] {
                    showAlertInfoWith("Invalid json: \(errorInfo)", .warning)
                }
            }
        }
    }
    
    private func handleGeneratedCode(_ hString:NSMutableString, _ mString:NSMutableString) {
        
        var multiplier:CGFloat = 3/5.0
        if builder.config.codeType == .OC {
            configJsonTextView(text: mString as String , textView: mTextView, color: codeTextColor)
        } else if builder.config.codeType == .Swift {
            multiplier = 1.0
        } else if builder.config.codeType == .Dart {
            configJsonTextView(text: mString as String , textView: mTextView, color: codeTextColor)
        }
        hTextViewHeightPriority = modifyConstraint(hTextViewHeightPriority, multiplier)
        configJsonTextView(text: hString as String, textView: hTextView, color: codeTextColor)
        let state = generateFileBtn.state
        guard state == .on else { return }
        if let path = outputFilePath {
            builder.generateFile(with: path, hString: hString, mString: mString) { [weak self] (success, filePath) in
                if success {
                    self?.showAlertInfoWith("生成文件路径在：\(filePath)", .informational)
                    self?.outputFilePath = filePath
                    self?.saveUserInputContent()
                }
            }
        } else {
            showAlertInfoWith("请先选择文件输出路径", .warning)
        }
    }
    
    @IBAction func chooseOutputFilePath(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        let modal = openPanel.runModal()
        if modal == .OK {
            if let fileUrl = openPanel.urls.first{
                outputFilePath = fileUrl.path
            }
        }
    }
    
    // MARK: - Private Method
    
    private func modifyConstraint( _ constraint: NSLayoutConstraint?, _ multiplier: CGFloat) -> NSLayoutConstraint? {
        
        guard let constraint = constraint else {
            return nil
        }
        NSLayoutConstraint.deactivate([constraint])
        let newConstraint = NSLayoutConstraint.init(item: constraint.firstItem as Any, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: constraint.secondItem, attribute: constraint.secondAttribute, multiplier: multiplier, constant: 0)
        newConstraint.identifier = constraint.identifier;
        newConstraint.priority = constraint.priority;
        newConstraint.shouldBeArchived = constraint.shouldBeArchived;
        NSLayoutConstraint .activate([newConstraint])
        return newConstraint
    }
    
    private func showAlertInfoWith( _ info: String, _ style:NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = info
        alert.alertStyle = style
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    /// config ui on main queue.
    
    private func configJsonTextView(text:String, textView:NSTextView, color:NSColor) {
        let attrString = NSAttributedString(string: text)
        DispatchQueue.main.async {
            textView.textStorage?.setAttributedString(attrString)
            textView.textStorage?.font = NSFont.systemFont(ofSize: 15)
            textView.textStorage?.foregroundColor = color
        }
    }
    
    // MARK: - NSControlTextEditingDelegate

    func controlTextDidChange(_ obj: Notification) {
        if let tf =  obj.object {
            currentInputTF = tf as? NSTextField
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(caculateInputContentWidth), object: nil)
            self.perform(#selector(caculateInputContentWidth))
        }
    }
    
    @objc private func caculateInputContentWidth() {
        if let tf =  currentInputTF {
            let constraints = tf.constraints
            let attributes = [NSAttributedString.Key.font : tf.font]
            let string = NSString(string: tf.stringValue)
            var strWidth = string.boundingRect(with: NSSizeFromCGSize(CGSize(width: Double(Float.greatestFiniteMagnitude), height: 22.0)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes as [NSAttributedString.Key : Any]).width + 10
            strWidth = max(strWidth, 114)
            constraints.forEach { (constraint) in
                if constraint.firstAttribute == .width {
                    constraint.constant = strWidth
                }
            }
        }
    }
    
    /// load cache
    
    private func loadUserLastInputContent() {
        
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
        generateFileBtn.state = UserDefaults.standard.bool(forKey: ShouldGenerateFileCacheKey) ? .on : .off
    }
    
    /// save cache
    
    private func saveUserInputContent() {
      
        builder.config.codeType = SKCodeBuilderCodeType(rawValue: codeTypeBtn.indexOfSelectedItem + 1) ?? .OC
        
        var superClassName = ""
        if builder.config.codeType == .Dart {
            superClassName = superClassNameTF.stringValue
        } else {
            superClassName = superClassNameTF.stringValue.isBlank ? "NSObject" : superClassNameTF.stringValue
        }
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
        didSet { }
    }
}

