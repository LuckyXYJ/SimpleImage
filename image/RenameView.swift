//
//  RenameView.swift
//  image
//
//  Created by lucky on 2024/9/5.
//

import Cocoa

class RenameView: NSView {

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.registerForDraggedTypes([.fileURL])
        creatUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let pasteboardItems = sender.draggingPasteboard.pasteboardItems else {
            return false
        }
        var urls: [URL] = []
        for item in pasteboardItems {
            if let filePath = item.string(forType: .fileURL), let fileUrl = URL(string: filePath) {
                urls.append(contentsOf: CompressTools.getSubFiles(url: fileUrl))
            }
        }
//        fileList = urls.map({FileModel(url: $0)})
        for url in urls {
            print(url.lastPathComponent)
        }
        return true
    }
}

extension RenameView {
    func creatUI() {
        
    }
}
