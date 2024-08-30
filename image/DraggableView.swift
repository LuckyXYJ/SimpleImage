//
//  DraggableView.swift
//  image
//
//  Created by dingtone on 2024/8/26.
//

import Cocoa

//enum ImageHandleStatus: String {
//    case waiting = "等待"
//    case inProcess = "进行中"
//    case success(String, String) =
//    case fail =
//}

enum ImageHandleStatus {
    case waiting
    case inProcess
    case success(oldSize: String, newSize: String)
    case fail
    
    var rawValue: String {
        switch self {
        case .waiting:
            "等待"
        case .inProcess:
            "进行中"
        case .success(let oldSize, let newSize):
            "成功\(oldSize) / \(newSize)"
        case .fail:
            "失败"
        }
    }
}

class FileModel {
    var url: URL
    var hasHandle = false
    var status: ImageHandleStatus = .waiting
    var size: UInt64?
    
    init(url: URL) {
        self.url = url
    }
}

extension FileModel: CompressImage {
    
    var fileUrl: URL {
        return url
    }
    
    func changeStatus(_ status: ImageHandleStatus) {
        self.status = status
    }
}


class DraggableView: NSView {
    
    var fileList: [FileModel] = [] {
        didSet {
            tableView.reloadData()
            fileButton.isHidden = fileList.count > 0
            fileTips.isHidden = fileList.count > 0
            
            CompressTools.tinifyCompress(fileList) { [weak self] in
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    var fileButton: NSButton!
    var fileTips: NSTextField!
    var tableView: NSTableView!
    
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
        fileList = urls.map({FileModel(url: $0)})
        for url in urls {
            print(url.lastPathComponent)
        }
        return true
    }
    
    func creatUI() {
        
        // 创建一个NSButton，并设置其大小和位置
        let button = NSButton()
        
        if #available(macOS 11.0, *) {
            if let plusImage = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil) {
                plusImage.size = NSSize(width: 100, height: 100)
                button.image = plusImage
                button.imageScaling = .scaleProportionallyUpOrDown
            }
        } else {
            // Fallback on earlier versions
            let plusImage = NSImage(named: "file_dir")
            plusImage?.size = NSSize(width: 100, height: 100)
            button.image = plusImage
            button.imageScaling = .scaleProportionallyUpOrDown
        }
        button.isBordered = false
        button.target = self
        button.action = #selector(buttonClicked)
        self.addSubview(button)
        button.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.center.equalToSuperview()
        }
        fileButton = button
        
        let textField = NSTextField(labelWithString: "拖入文件开始压缩")
        textField.font = NSFont.systemFont(ofSize: 20)
        textField.alignment = .center
        self.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.centerX.equalTo(button)
            make.top.equalTo(button.snp.bottom)
        }
        fileTips = textField
        
        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        self.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        let thumbnailColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ThumbnailColumn"))
        thumbnailColumn.title = "Thumbnail"
        thumbnailColumn.width = 60
        tableView.addTableColumn(thumbnailColumn)
        
        let statusColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("StatusColumn"))
        statusColumn.title = "Status"
        statusColumn.width = 180
        tableView.addTableColumn(statusColumn)
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        nameColumn.title = "Name"
//        thumbnailColumn.width = 200
        nameColumn.resizingMask = .autoresizingMask
        tableView.addTableColumn(nameColumn)
        
    }
    
    @objc func buttonClicked() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
//        openPanel.allowedContentTypes = [.png, .jpeg, .webP]
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        if #available(macOS 11.0, *) {
//            openPanel.allowedContentTypes = [.image]
            openPanel.allowedContentTypes = [.png, .jpeg, .webP]
        } else {
            
        } // 确保选择图片文件类型
        openPanel.message = "请选择最多20个图片文件"
        
        openPanel.begin { [weak self] response in
            if response == .OK {
                let selectedFiles = openPanel.urls
                var urls: [URL] = []
                for file in selectedFiles {
                    urls.append(contentsOf: CompressTools.getSubFiles(url: file))
                }
                self?.fileList = urls.map({FileModel(url: $0)})
                for url in urls {
                    print(url.lastPathComponent)
                }
            }
        }
    }
}


extension DraggableView: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileList.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        60
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let imageFile = fileList[row]
        let columnIdentifier = tableColumn!.identifier.rawValue
        
        if columnIdentifier == "ThumbnailColumn" {
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(columnIdentifier), owner: self) as? NSTableCellView {
                if let imageView = cellView.subviews.first as? NSImageView {
                    imageView.image = NSImage(contentsOf: imageFile.url)
                }
                return cellView
            }
            
            let cellView = NSTableCellView()
            cellView.identifier = NSUserInterfaceItemIdentifier(columnIdentifier)
            let imageView = NSImageView(image: NSImage(contentsOf: imageFile.url) ?? NSImage())
            imageView.frame = CGRect(x: 5, y: 5, width: 50, height: 50)
            cellView.addSubview(imageView)
            return cellView
            
        } else if columnIdentifier == "NameColumn" {
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(columnIdentifier), owner: self) as? NSTableCellView {
                if let textField = cellView.subviews.first as? NSTextField {
                    textField.stringValue = imageFile.url.lastPathComponent
                }
                return cellView
            }
            
            let cellView = NSTableCellView()
            cellView.identifier = NSUserInterfaceItemIdentifier(columnIdentifier)
            let textField = NSTextField(labelWithString: imageFile.url.lastPathComponent)
            textField.autoresizingMask = [.width]
            cellView.addSubview(textField)
            textField.snp.makeConstraints({
                $0.left.right.equalToSuperview()
                $0.centerY.equalToSuperview()
            })
            return cellView
            
        } else if columnIdentifier == "StatusColumn" {
            
            if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(columnIdentifier), owner: self) as? NSTableCellView {
                if let textField = cellView.subviews.first as? NSTextField {
                    textField.stringValue = imageFile.status.rawValue
                }
                return cellView
            }
            
            let cellView = NSTableCellView()
            cellView.identifier = NSUserInterfaceItemIdentifier(columnIdentifier)
            let textField = NSTextField(labelWithString: imageFile.status.rawValue)
            textField.autoresizingMask = [.width]
            cellView.addSubview(textField)
            textField.snp.makeConstraints({
                $0.left.right.equalToSuperview()
                $0.centerY.equalToSuperview()
            })
            return cellView
        }
        return nil
    }
}
