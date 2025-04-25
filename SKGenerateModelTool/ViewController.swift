//
//  ViewController.swift
//  SKGenerateModelTool
//
//  Created by KUN on 2020/5/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSControlTextEditingDelegate {
    // MARK: - IBOutlets
    
    @IBOutlet var urlTF: NSTextField!
    @IBOutlet var jsonTextView: SKTextView!
    @IBOutlet var hTextView: NSTextView!
    @IBOutlet var mTextView: NSTextView!
    @IBOutlet var hTextViewHeightPriority: NSLayoutConstraint!
    @IBOutlet var superClassNameTF: NSTextField!
    @IBOutlet var modelNamePrefixTF: NSTextField!
    @IBOutlet var rootModelNameTF: NSTextField!
    @IBOutlet var authorNameTF: NSTextField!
    @IBOutlet var reqTypeBtn: NSPopUpButton!
    @IBOutlet var codeTypeBtn: NSPopUpButton!
    @IBOutlet var jsonTypeBtn: NSPopUpButton!
    @IBOutlet var generateFileBtn: NSButton!
    @IBOutlet var generateComment: NSButton!
        
    /// 缓存键
    private enum CacheKeys {
        static let lastInputURL = "LastInputURLCacheKey"
        static let superClassName = "SuperClassNameCacheKey"
        static let rootModelName = "RootModelNameCacheKey"
        static let modelNamePrefix = "ModelNamePrefixCacheKey"
        static let authorName = "AuthorNameCacheKey"
        static let buildCodeType = "BuildCodeTypeCacheKey"
        static let supportJSONModelType = "SupportJSONModelTypeCacheKey"
        static let shouldGenerateFile = "ShouldGenerateFileCacheKey"
        static let generateFilePath = "GenerateFilePathCacheKey"
        static let shouldGenerateComment = "ShouldGenerateCommentCacheKey"
    }
    
    // MARK: - Properties
    
    private var builder = SKCodeBuilder()
    private var outputFilePath: String?
    private var currentInputTF: NSTextField?
    
    private lazy var jsonTextColor = NSColor.blue
    private lazy var codeTextColor = NSColor(red: 215/255.0, green: 0/255.0, blue: 143/255.0, alpha: 1.0)
    
    private lazy var jsonTextStorage: CodeAttributedString = {
        let storage = CodeAttributedString()
        storage.highlightr.setTheme(to: SKCodeType.objectiveC.theme)
        storage.highlightr.theme.codeFont = NSFont(name: "Menlo", size: 14)
        storage.language = "json"
        return storage
    }()
    
    private lazy var hTextStorage: CodeAttributedString = {
        let storage = CodeAttributedString()
        storage.highlightr.setTheme(to: SKCodeType.objectiveC.theme)
        storage.highlightr.theme.codeFont = NSFont(name: "Menlo", size: 14)
        storage.language = SKCodeType.objectiveC.language
        return storage
    }()
    
    private lazy var mTextStorage: CodeAttributedString = {
        let storage = CodeAttributedString()
        storage.highlightr.setTheme(to: SKCodeType.objectiveC.theme)
        storage.highlightr.theme.codeFont = NSFont(name: "Menlo", size: 14)
        storage.language = SKCodeType.objectiveC.language
        return storage
    }()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        jsonTextStorage.addLayoutManager(jsonTextView.layoutManager!)
        hTextStorage.addLayoutManager(hTextView.layoutManager!)
        mTextStorage.addLayoutManager(mTextView.layoutManager!)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        loadUserLastInputContent()
        updateCodeTheme()
    }
    
    private func setupUI() {
        // 网络请求类型
        reqTypeBtn.removeAllItems()
        reqTypeBtn.addItems(withTitles: ["GET", "POST"])
        reqTypeBtn.selectItem(at: 0)
        
        // 代码类型
        codeTypeBtn.removeAllItems()
        codeTypeBtn.addItems(withTitles: SKCodeType.allCases.map { $0.rawValue })
        codeTypeBtn.selectItem(at: 0)
        
        // JSON解析框架类型
        jsonTypeBtn.removeAllItems()
        jsonTypeBtn.addItems(withTitles: SKJSONModelType.allCases.map { $0.rawValue })
        jsonTypeBtn.selectItem(at: 0)
    }
    
    // MARK: - IBActions
    
    /// 通过URL获取JSON数据
    @IBAction func requestURLBtnClicked(_ sender: NSButton) {
        updateCodeTheme()
        var urlString = urlTF.stringValue
        guard !urlString.isBlank else { return }
        
        urlString = urlString.urlEncoding()
        UserDefaults.standard.setValue(urlString, forKey: CacheKeys.lastInputURL)
        
        guard let url = URL(string: urlString) else {
            showAlertInfoWith("无效的URL格式", .warning)
            return
        }
        
        Task {
            do {
                let jsonString = try await fetchJsonData(from: url)
                configJsonTextView(text: jsonString, textView: jsonTextView, color: NSColor.blue)
            } catch {
                showAlertInfoWith("请求失败: \(error.localizedDescription)", .warning)
            }
        }
    }
    
    /// 使用async/await获取JSON数据
    private func fetchJsonData(from url: URL) async throws -> String {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        
        // 处理POST请求
        if reqTypeBtn.indexOfSelectedItem == 1 {
            request = try configurePostRequest(originalUrl: url)
        }
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let jsonObj = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        
        guard JSONSerialization.isValidJSONObject(jsonObj) else {
            throw NSError(domain: "JSONError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效的JSON响应"])
        }
        
        let formatJsonData = try JSONSerialization.data(withJSONObject: jsonObj, options: .prettyPrinted)
        guard let jsonString = String(data: formatJsonData, encoding: .utf8) else {
            throw NSError(domain: "JSONError", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法将JSON数据转换为字符串"])
        }
        
        return jsonString
    }
    
    /// 配置POST请求
    private func configurePostRequest(originalUrl: URL) throws -> URLRequest {
        guard let query = originalUrl.query else {
            return URLRequest(url: originalUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        }
        
        let urlString = originalUrl.absoluteString
        var urlWithoutQuery = urlString.replacingOccurrences(of: query, with: "")
        if urlWithoutQuery.hasSuffix("?") {
            urlWithoutQuery.removeLast()
        }
        
        guard let newUrl = URL(string: urlWithoutQuery) else {
            throw NSError(domain: "URLError", code: 3, userInfo: [NSLocalizedDescriptionKey: "无法创建不带查询参数的URL"])
        }
        
        var request = URLRequest(url: newUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = query.data(using: .utf8)
        
        return request
    }
    
    /// 开始生成代码
    @IBAction func startMakeCode(_ sender: NSButton) {
        guard let jsonString = jsonTextView.textStorage?.string, !jsonString.isBlank else { return }
        
        // 处理JSON字符串
        let trimmedStr = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        let attriStr = NSMutableString(string: trimmedStr)
        
        // 处理注释
        var commentDicts: [String: String] = [:]
        parseComments(from: trimmedStr, commentDicts: &commentDicts, attriStr: attriStr)
        
        do {
            guard let jsonData = attriStr.data(using: String.Encoding.utf8.rawValue) else {
                showAlertInfoWith("警告: 请输入有效的JSON字符串!", .warning)
                return
            }
            
            let jsonObj = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers)
            guard JSONSerialization.isValidJSONObject(jsonObj) else {
                showAlertInfoWith("警告: 不是有效的JSON格式!!!", .warning)
                return
            }
            
            // 保存用户输入内容并更新主题
            saveUserInputContent()
            updateCodeTheme()
            
            if !commentDicts.isEmpty {
                configJsonTextView(text: jsonString, textView: jsonTextView, color: NSColor.blue)
                builder.commentDicts = commentDicts
            } else {
                builder.commentDicts = nil
                let formatJsonData = try JSONSerialization.data(withJSONObject: jsonObj, options: .prettyPrinted)
                if let formattedJsonString = String(data: formatJsonData, encoding: .utf8) {
                    configJsonTextView(text: formattedJsonString, textView: jsonTextView, color: NSColor.blue)
                }
            }
            
            Task {
                await generateModelCode(from: jsonObj)
            }
        } catch {
            print("解析错误 = \(error)")
            let errorInfo = (error as NSError).userInfo["NSDebugDescription"] as? String ?? error.localizedDescription
            showAlertInfoWith("无效的JSON: \(errorInfo)", .warning)
        }
    }
    
    /// 异步生成代码
    private func generateModelCode(from jsonObj: Any) async {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async { [weak self] in
                self?.builder.generateCode(with: jsonObj) { hString, mString in
                    DispatchQueue.main.async {
                        self?.handleGeneratedCode(hString, mString)
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// 选择输出文件路径
    @IBAction func chooseOutputFilePath(_ sender: NSButton) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        let modal = openPanel.runModal()
        if modal == .OK {
            if let fileUrl = openPanel.urls.first {
                outputFilePath = fileUrl.path
            }
        }
    }
    
    @objc private func caculateInputContentWidth() {
        guard let tf = currentInputTF else { return }
        
        let constraints = tf.constraints
        let attributes = [NSAttributedString.Key.font: tf.font as Any]
        let string = NSString(string: tf.stringValue)
        var strWidth = string.boundingRect(
            with: NSSizeFromCGSize(CGSize(width: Double(Float.greatestFiniteMagnitude), height: 22.0)),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        ).width + 10
        
        strWidth = max(strWidth, 114)
        
        for constraint in constraints {
            if constraint.firstAttribute == .width {
                constraint.constant = strWidth
            }
        }
    }
    
    // MARK: - NSControlTextEditingDelegate
    
    func controlTextDidChange(_ obj: Notification) {
        if let tf = obj.object as? NSTextField {
            currentInputTF = tf
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(caculateInputContentWidth), object: nil)
            self.perform(#selector(caculateInputContentWidth))
        }
    }
    
    override var representedObject: Any? {
        didSet {}
    }
}

// MARK: - Private Method

private extension ViewController {
    /// 解析JSON中的注释
    func parseComments(from jsonString: String, commentDicts: inout [String: String], attriStr: NSMutableString) {
        var localCommentDicts = [String: String]()
        attriStr.enumerateLines { line, _ in
            guard line.contains("//") else { return }
            
            let substrings = line.components(separatedBy: "//")
            let hasHttpLink = line.contains("http://") || line.contains("https://") || line.contains("://")
            // 只有图片链接且没注释的情况下不做截断操作
            let canComment = !(substrings.count == 2 && hasHttpLink)
            guard canComment else { return }
            
            let trimmedLineStr = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let position = trimmedLineStr.positionOf(sub: "//", backwards: true)
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
                    localCommentDicts.updateValue(comment, forKey: keystr)
                }
                let range = attriStr.range(of: String(commentstr))
                attriStr.replaceCharacters(in: range, with: "")
            }
        }
        for (key, value) in localCommentDicts {
            commentDicts[key] = value
        }
    }
    
    /// 更新代码显示主题
    func updateCodeTheme() {
        let theme = builder.config.codeType.theme
        let language = builder.config.codeType.language
        jsonTextStorage.highlightr.setTheme(to: theme)
        hTextStorage.highlightr.setTheme(to: theme)
        mTextStorage.highlightr.setTheme(to: theme)
        hTextStorage.language = language
        mTextStorage.language = language
    }
    
    /// 处理生成的代码
    func handleGeneratedCode(_ hString: NSMutableString, _ mString: NSMutableString) {
        var multiplier: CGFloat = 3/5.0
        
        switch builder.config.codeType {
        case .objectiveC:
            configJsonTextView(text: mString as String, textView: mTextView, color: codeTextColor)
        case .swift, .typeScript:
            multiplier = 1.0
        case .dart:
            configJsonTextView(text: mString as String, textView: mTextView, color: codeTextColor)
        }
        
        hTextViewHeightPriority = modifyConstraint(hTextViewHeightPriority, multiplier)
        configJsonTextView(text: hString as String, textView: hTextView, color: codeTextColor)
        
        // 如果开启了生成文件选项，则生成文件
        guard generateFileBtn.state == .on else { return }
        if let path = outputFilePath {
            builder.generateFile(with: path, hString: hString, mString: mString) { [weak self] success, filePath in
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
    
    /// 修改约束
    func modifyConstraint(_ constraint: NSLayoutConstraint?, _ multiplier: CGFloat) -> NSLayoutConstraint? {
        guard let oldConstraint = constraint else { return nil }
        let newConstraint = NSLayoutConstraint(
            item: oldConstraint.firstItem as Any,
            attribute: oldConstraint.firstAttribute,
            relatedBy: oldConstraint.relation,
            toItem: oldConstraint.secondItem,
            attribute: oldConstraint.secondAttribute,
            multiplier: multiplier,
            constant: oldConstraint.constant
        )
        // 复制约束属性
        newConstraint.identifier = oldConstraint.identifier
        newConstraint.priority = oldConstraint.priority
        newConstraint.shouldBeArchived = oldConstraint.shouldBeArchived
        NSLayoutConstraint.deactivate([oldConstraint])
        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
    
    /// 显示警告或信息
    func showAlertInfoWith(_ info: String, _ style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = info
        alert.alertStyle = style
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    /// 配置文本视图
    func configJsonTextView(text: String, textView: NSTextView, color: NSColor) {
        let attrString = NSAttributedString(string: text)
        DispatchQueue.main.async {
            textView.textStorage?.setAttributedString(attrString)
            textView.textStorage?.foregroundColor = .clear
        }
    }
        
    /// 加载用户上次的输入内容
    func loadUserLastInputContent() {
        // URL
        if let lastUrl = UserDefaults.standard.string(forKey: CacheKeys.lastInputURL) {
            urlTF.stringValue = lastUrl
        }
        
        // 父类名或协议名
        if let superClassName = UserDefaults.standard.string(forKey: CacheKeys.superClassName) {
            superClassNameTF.stringValue = superClassName
        }
        
        // 模型名前缀
        if let modelNamePrefix = UserDefaults.standard.string(forKey: CacheKeys.modelNamePrefix) {
            modelNamePrefixTF.stringValue = modelNamePrefix
        }
        
        // 根模型名
        if let rootModelName = UserDefaults.standard.string(forKey: CacheKeys.rootModelName) {
            rootModelNameTF.stringValue = rootModelName
        }
        
        // 作者名
        if let authorName = UserDefaults.standard.string(forKey: CacheKeys.authorName) {
            authorNameTF.stringValue = authorName
        }
        
        // 输出文件路径
        if let outFilePath = UserDefaults.standard.string(forKey: CacheKeys.generateFilePath) {
            outputFilePath = outFilePath
        }
        
        // 代码类型
        let codeTypeIndex = UserDefaults.standard.integer(forKey: CacheKeys.buildCodeType)
        if codeTypeIndex > 0, codeTypeIndex <= SKCodeType.allCases.count {
            builder.config.codeType = SKCodeType.allCases[codeTypeIndex - 1]
            codeTypeBtn.selectItem(at: codeTypeIndex - 1)
        }
        
        // JSON模型类型
        let jsonTypeIndex = UserDefaults.standard.integer(forKey: CacheKeys.supportJSONModelType)
        if jsonTypeIndex >= 0, jsonTypeIndex < SKJSONModelType.allCases.count {
            builder.config.jsonType = SKJSONModelType.allCases[jsonTypeIndex]
            jsonTypeBtn.selectItem(at: jsonTypeIndex)
        }
        
        // 是否生成文件
        generateFileBtn.state = UserDefaults.standard.bool(forKey: CacheKeys.shouldGenerateFile) ? .on : .off
        
        // 是否生成注释
        generateComment.state = UserDefaults.standard.bool(forKey: CacheKeys.shouldGenerateComment) ? .on : .off
    }
    
    /// 保存用户输入内容
    func saveUserInputContent() {
        // 代码类型
        let codeTypeIndex = codeTypeBtn.indexOfSelectedItem
        if codeTypeIndex >= 0 && codeTypeIndex < SKCodeType.allCases.count {
            builder.config.codeType = SKCodeType.allCases[codeTypeIndex]
            UserDefaults.standard.set(codeTypeIndex + 1, forKey: CacheKeys.buildCodeType)
        }
        
        // 父类名或协议名
        var superClassName = ""
        if builder.config.codeType == .dart || builder.config.codeType == .typeScript {
            superClassName = superClassNameTF.stringValue
        } else if builder.config.codeType == .swift {
            superClassName = superClassNameTF.stringValue.isBlank ? "Codable" : superClassNameTF.stringValue
        } else {
            superClassName = superClassNameTF.stringValue.isBlank ? "NSObject" : superClassNameTF.stringValue
        }
        UserDefaults.standard.setValue(superClassName, forKey: CacheKeys.superClassName)
        builder.config.superClassName = superClassName
        
        // 类名前缀
        let modelNamePrefix = modelNamePrefixTF.stringValue.isBlank ? "" : modelNamePrefixTF.stringValue
        UserDefaults.standard.setValue(modelNamePrefix, forKey: CacheKeys.modelNamePrefix)
        builder.config.modelNamePrefix = modelNamePrefix
        
        // RootModel
        let rootModelName = rootModelNameTF.stringValue.isBlank ? "RootModel" : rootModelNameTF.stringValue
        UserDefaults.standard.setValue(rootModelName, forKey: CacheKeys.rootModelName)
        builder.config.rootModelName = rootModelName
        
        // 作者名
        let authorName = authorNameTF.stringValue.isBlank ? "SKGenerateModelTool" : authorNameTF.stringValue
        UserDefaults.standard.setValue(authorName, forKey: CacheKeys.authorName)
        builder.config.authorName = authorName
        
        // JSON解析框架类型
        let jsonTypeIndex = jsonTypeBtn.indexOfSelectedItem
        if jsonTypeIndex >= 0, jsonTypeIndex < SKJSONModelType.allCases.count {
            builder.config.jsonType = SKJSONModelType.allCases[jsonTypeIndex]
            UserDefaults.standard.set(jsonTypeIndex, forKey: CacheKeys.supportJSONModelType)
        }
        
        // 处理HandyJSON特殊情况
        if builder.config.superClassName.compare("NSObject") == .orderedSame, builder.config.jsonType == .handyJSON {
            builder.config.superClassName = "HandyJSON"
        }
        
        UserDefaults.standard.setValue(outputFilePath, forKey: CacheKeys.generateFilePath)
        UserDefaults.standard.set(generateFileBtn.state == .on, forKey: CacheKeys.shouldGenerateFile)
        UserDefaults.standard.set(generateComment.state == .on, forKey: CacheKeys.shouldGenerateComment)
        builder.config.shouldGenerateComment = (generateComment.state == .on)
    }
}
