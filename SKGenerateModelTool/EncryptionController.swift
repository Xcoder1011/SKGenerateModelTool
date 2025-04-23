//
//  EncryptionController.swift
//  SKGenerateModelTool
//
//  Created by shangkun on 2020/6/24.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

class EncryptionController: NSViewController {
    let UseKeyBtnSelectStateCacheKey = "UseKeyBtnSelectStateCacheKey"
    let CipherContentCacheKey = "CipherContentCacheKey"
    
    @IBOutlet var inputTextView: NSTextView!
    @IBOutlet var hTextView: NSTextView!
    @IBOutlet var mTextView: NSTextView!
    @IBOutlet var useKeyBtn: NSButton!
    @IBOutlet var keyTF: NSTextField!
    
    lazy var inputTextColor = NSColor.blue
    lazy var codeTextColor = NSColor(red: 215/255.0, green: 0/255.0, blue: 143/255.0, alpha: 1.0)

    @IBAction func encryptString(_ sender: NSButton) {
        if let inputString = inputTextView.textStorage?.string {
            let state = useKeyBtn.state
            UserDefaults.standard.set(state == .on, forKey: UseKeyBtnSelectStateCacheKey)
            let key = state == .on ? keyTF.stringValue : nil
            UserDefaults.standard.setValue(key, forKey: CipherContentCacheKey)
            let tempStr = inputString.replacingOccurrences(of: " ", with: "")
            if tempStr.isBlank { return }
            configJsonTextView(text: inputString, textView: inputTextView, color: inputTextColor)
            SKEncryptTool.encryptString(str: inputString, key: key) { [weak self] hStr, mStr in
                let hstring = hStr.substring(to: hStr.length)
                self?.configJsonTextView(text: hstring, textView: self!.hTextView, color: (self?.codeTextColor)!)
                let mstring = mStr.substring(to: mStr.length)
                self?.configJsonTextView(text: mstring, textView: self!.mTextView, color: (self?.codeTextColor)!)
            }
        }
    }
    
    @IBAction func copyCodeString(_ sender: NSButton) {
        let tag = sender.tag
        var string = ""
        switch tag {
        case 100:
            if let tempstr = hTextView.textStorage?.string {
                string = tempstr
            }
        case 101:
            if let tempstr = mTextView.textStorage?.string {
                string = tempstr
            }
        default: break
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
    
    /// config ui on main queue.
    
    private func configJsonTextView(text: String, textView: NSTextView, color: NSColor) {
        let attrString = NSAttributedString(string: text)
        DispatchQueue.main.async {
            textView.textStorage?.setAttributedString(attrString)
            textView.textStorage?.font = NSFont.systemFont(ofSize: 15)
            textView.textStorage?.foregroundColor = color
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        useKeyBtn.state = UserDefaults.standard.bool(forKey: UseKeyBtnSelectStateCacheKey) ? .on : .off
        if let key = UserDefaults.standard.string(forKey: CipherContentCacheKey) {
            keyTF.stringValue = key
        }
        
        ///////////////  使用范例 （Usage Example） /////////////////
        
//        if let string =  sk_OCString(_3596508958) {
//            print("示例：解密后的数据为：\(string)")
//        }
//        if let string =  sk_OCString(_4038772756) {
//            print("The decrypted data is：\(string)")
//        }
    }
}
