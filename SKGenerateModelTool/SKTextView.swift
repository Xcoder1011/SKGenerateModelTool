//
//  SKTextView.swift
//  SKGenerateModelTool
//
//  Created by shangkun on 2020/9/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

class SKTextView: NSTextView {
    
    var placeHolderAttriStr: NSAttributedString?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let attributes = [NSAttributedString.Key.foregroundColor : NSColor.placeholderTextColor, NSAttributedString.Key.font : NSFont.systemFont(ofSize: 15)]
        placeHolderAttriStr = NSAttributedString(string: "Input json here...", attributes: attributes)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        if self.string.isEmpty {
            placeHolderAttriStr?.draw(at: NSPoint(x: 4, y: 0))
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        self.setNeedsDisplay(self.bounds)
        self.font = NSFont.systemFont(ofSize: 15)
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        self.setNeedsDisplay(self.bounds)
        self.font = NSFont.systemFont(ofSize: 15)
        return super.resignFirstResponder()
    }
   
}
