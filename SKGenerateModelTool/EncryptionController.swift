//
//  EncryptionController.swift
//  SKGenerateModelTool
//
//  Created by shangkun on 2020/6/24.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

class EncryptionController: NSViewController {
    private enum UserDefaultsKeys {
        static let useKeyBtnState = "UseKeyBtnSelectStateCacheKey"
        static let cipherContent = "CipherContentCacheKey"
    }
    
    private enum CopyButtonTag {
        static let header = 100
        static let implementation = 101
    }
    
    // MARK: - IBOutlet
    
    @IBOutlet private var inputTextView: NSTextView!
    @IBOutlet private var hTextView: NSTextView!
    @IBOutlet private var mTextView: NSTextView!
    @IBOutlet private var useKeyBtn: NSButton!
    @IBOutlet private var keyTF: NSTextField!
    
    // MARK: - Properties
    
    private lazy var inputTextColor = NSColor.blue
    private lazy var codeTextColor = NSColor(red: 215/255.0, green: 0/255.0, blue: 143/255.0, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureInitialState()
    }
    
    // MARK: - IBAction
    
    @IBAction func encryptString(_ sender: NSButton) {
        guard let inputString = inputTextView.textStorage?.string, !inputString.replacingOccurrences(of: " ", with: "").isBlank else {
            return
        }
        saveUserPreferences()
        configJsonTextView(text: inputString, textView: inputTextView, color: inputTextColor)
        
        // 执行加密
        let key = useKeyBtn.state == .on ? keyTF.stringValue : nil
        encryptAndDisplay(inputString: inputString, key: key)
    }
    
    @IBAction func copyCodeString(_ sender: NSButton) {
        let stringToCopy: String
        
        switch sender.tag {
        case CopyButtonTag.header:
            stringToCopy = hTextView.textStorage?.string ?? ""
        case CopyButtonTag.implementation:
            stringToCopy = mTextView.textStorage?.string ?? ""
        default:
            return
        }
        
        copyToClipboard(string: stringToCopy)
    }
}

// MARK: - Private Method

private extension EncryptionController {
    func configureInitialState() {
        useKeyBtn.state = UserDefaults.standard.bool(forKey: UserDefaultsKeys.useKeyBtnState) ? .on : .off
        
        if let key = UserDefaults.standard.string(forKey: UserDefaultsKeys.cipherContent) {
            keyTF.stringValue = key
        }
        
        ///////////////  使用范例 （Usage Example） /////////////////
        
//        if let string = sk_OCString(_3596508958) {
//            print("示例：解密后的数据为：\(string)")
//        }
//        if let string = sk_OCString(_4038772756) {
//            print("The decrypted data is：\(string)")
//        }
    }
    
    func saveUserPreferences() {
        let useKey = useKeyBtn.state == .on
        UserDefaults.standard.set(useKey, forKey: UserDefaultsKeys.useKeyBtnState)
        
        if useKey {
            UserDefaults.standard.setValue(keyTF.stringValue, forKey: UserDefaultsKeys.cipherContent)
        }
    }
    
    func encryptAndDisplay(inputString: String, key: String?) {
        SKEncryptTool.encryptString(str: inputString, key: key) { [weak self] hStr, mStr in
            guard let self = self else { return }
            
            let headerString = hStr.substring(to: hStr.length)
            self.configJsonTextView(text: headerString, textView: self.hTextView, color: self.codeTextColor)
            
            let implementationString = mStr.substring(to: mStr.length)
            self.configJsonTextView(text: implementationString, textView: self.mTextView, color: self.codeTextColor)
        }
    }
    
    func copyToClipboard(string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
    
    func configJsonTextView(text: String, textView: NSTextView, color: NSColor) {
        let attrString = NSAttributedString(string: text)
        DispatchQueue.main.async {
            textView.textStorage?.setAttributedString(attrString)
            textView.textStorage?.font = NSFont.systemFont(ofSize: 15)
            textView.textStorage?.foregroundColor = color
        }
    }
}
