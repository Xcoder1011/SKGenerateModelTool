//
//  SKTextView.swift
//  SKGenerateModelTool
//
//  Created by shangkun on 2020/9/10.
//  Copyright © 2020 wushangkun. All rights reserved.
//

import Cocoa

class SKTextView: NSTextView {
    private lazy var placeHolderAttriStr: NSAttributedString = {
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.placeholderTextColor,
            .font: NSFont.systemFont(ofSize: 15)
        ]
        return NSAttributedString(string: "Input json here...", attributes: attributes)
    }()
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.font = NSFont.systemFont(ofSize: 15)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if self.string.isEmpty {
            placeHolderAttriStr.draw(at: NSPoint(x: 4, y: 0))
        }
    }
        
    override func becomeFirstResponder() -> Bool {
        defer {
            setNeedsDisplay(bounds)
        }
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        defer {
            setNeedsDisplay(bounds)
        }
        return super.resignFirstResponder()
    }
}
