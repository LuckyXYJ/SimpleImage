//
//  DraggableView.swift
//  image
//
//  Created by lucky on 2024/8/26.
//

import Cocoa

//enum ImageHandleStatus: String {
//    case waiting = "等待"
//    case inProcess = "进行中"
//    case success(String, String) =
//    case fail =
//}

let tinyUserDefaultsKey = "com.lucky.tinyUserDefaultsKey"

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
            scrolllView.isHidden = fileList.count <= 0
            clearButton.isHidden = fileList.count <= 0
            tableView.reloadData()
            fileButton.isHidden = fileList.count > 0
            fileTips.isHidden = fileList.count > 0
            addKeyView.isHidden = fileList.count > 0
            
            CompressTools.tinifyCompress(fileList) { [weak self] in
                guard let self else { return }
                self.throttler.call { [weak self] in
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    var fileButton: NSButton!
    var fileTips: NSTextField!
    var addKeyView = AddKeyView()
    
    var scrolllView: NSScrollView!
    var tableView: NSTableView!
    var clearButton: NSButton!
    
    var selectedRow: Int?
    
    lazy var throttler: Throttler = {
        let throttler = Throttler(interval: 1.5) // 例如，间隔1秒
        return throttler
    }()
    
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
        
//        self.wantsLayer = true
//        self.layer?.backgroundColor = .white
        
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
        
        self.addSubview(addKeyView)
        addKeyView.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(30)
            make.left.right.equalToSuperview()
        }
        
        scrolllView = NSScrollView()
        scrolllView.hasHorizontalScroller = true
        scrolllView.hasVerticalScroller = true
        scrolllView.autohidesScrollers = true
        scrolllView.isHidden = true
        scrolllView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(scrolllView)
        scrolllView.snp.makeConstraints { make in
//            make.left.right.top.equalToSuperview()
//            
//            make.bottom.lessThanOrEqualToSuperview()
            
            make.top.equalTo(snp.top)
                        make.bottom.equalTo(snp.bottom)
                        make.left.equalTo(snp.left)
                        make.right.equalTo(snp.right)
        }
        
        tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        scrolllView.documentView = tableView
//        scrolllView.addSubview(tableView)
//        tableView.snp.makeConstraints { make in
//            make.left.right.top.equalToSuperview()
//            make.bottom.lessThanOrEqualToSuperview()
//        }
        tableView.translatesAutoresizingMaskIntoConstraints = false

        // 设置 tableView 视图到 scrollView 的 documentView 的约束
//        tableView.snp.makeConstraints { make in
//            make.edges.equalTo(scrolllView.contentView)
//            make.width.equalTo(scrolllView.contentView)
//        }
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Open Finder", action: #selector(openFinder), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preview Image", action: #selector(previewImage), keyEquivalent: ""))
                
        // Set tableView's menu to your custom created menu
        tableView.menu = menu
        
        let thumbnailColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ThumbnailColumn"))
        thumbnailColumn.title = "Thumbnail"
        thumbnailColumn.width = 60
        thumbnailColumn.headerCell = NSTableHeaderCell(textCell: "Thumbnail")
        tableView.addTableColumn(thumbnailColumn)
        
        let statusColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("StatusColumn"))
        statusColumn.title = "Status"
        statusColumn.width = 180
        statusColumn.headerCell = NSTableHeaderCell(textCell: "Status")
        tableView.addTableColumn(statusColumn)
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        nameColumn.title = "Name1"
//        thumbnailColumn.width = 200
        nameColumn.headerCell = NSTableHeaderCell(textCell: "Name")
        nameColumn.resizingMask = .autoresizingMask
        tableView.addTableColumn(nameColumn)
        
        
        clearButton = NSButton()
        
        if #available(macOS 11.0, *) {
            if let plusImage = NSImage(systemSymbolName: "clear", accessibilityDescription: nil) {
                plusImage.size = NSSize(width: 44, height: 44)
                clearButton.image = plusImage
                clearButton.imageScaling = .scaleProportionallyUpOrDown
            }
        } else {
            // Fallback on earlier versions
            let plusImage = NSImage(named: "file_dir")
            plusImage?.size = NSSize(width: 44, height: 44)
            clearButton.image = plusImage
            clearButton.imageScaling = .scaleProportionallyUpOrDown
        }
        clearButton.isHidden = true
        clearButton.isBordered = false
        clearButton.target = self
        clearButton.action = #selector(clearAllData)
        self.addSubview(clearButton)
        clearButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.bottom.right.equalToSuperview().inset(44)
        }
    }
    
    @objc func clearAllData() {
        self.fileList = []
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
    override func rightMouseDown(with event: NSEvent) {
        let point = tableView.convert(event.locationInWindow, from: nil)
        selectedRow = tableView.row(at: point)
        super.rightMouseDown(with: event)
    }
    
    
    @objc func imageViewClicked(_ sender: NSClickGestureRecognizer) {
        guard let imageView = sender.view as? NSImageView else { return }
        guard let image = imageView.image else { return }
        showPreviewWindow(with: image)
    }
    
    func showPreviewWindow(with image: NSImage) {
        // 创建新的窗口或视图控制器来显示预览图片
        let previewViewController = NSViewController()
        // 设置窗口内容
        let previewImageView = NSImageView()
        previewImageView.image = image
        previewImageView.frame = previewViewController.view.bounds
        previewImageView.autoresizingMask = [.width, .height]
        previewViewController.view.addSubview(previewImageView)
        
        // 创建新窗口
        let previewWindow = NSWindow(contentViewController: previewViewController)
        previewWindow.setContentSize(NSSize(width: 400, height: 400))
        previewWindow.styleMask = [.titled, .closable, .resizable]
        previewWindow.title = "Image Preview"
        
        let windowController = NSWindowController(window: previewWindow)
        windowController.showWindow(self)
    }
    
    func getCurrentRow() -> Int? {
        guard let mouseLocation = self.tableView.window?.mouseLocationOutsideOfEventStream else { return nil }
        let tableViewLocation = self.tableView.convert(mouseLocation, from: nil)
        let row = self.tableView.row(at: tableViewLocation)
        return row
    }
    // 菜单项的动作方法
    @objc func openFinder(_ sender: NSMenuItem) {
        guard let row = selectedRow else { return }
        let imageFile = fileList[row]
        let fileURL = imageFile.url
        NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
    }
    // 预览
    @objc func previewImage(_ sender: NSMenuItem) {
        guard let row = selectedRow else { return }
        let imageFile = fileList[row]
        let fileURL = imageFile.url
        NSWorkspace.shared.open(fileURL)
    }
}

extension DraggableView: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        selectedRow = getCurrentRow()
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
                    textField.stringValue = imageFile.url.lastPathComponent + "(\(row))"
                }
                return cellView
            }
            
            let cellView = NSTableCellView()
            cellView.identifier = NSUserInterfaceItemIdentifier(columnIdentifier)
            let textField = NSTextField(labelWithString: imageFile.url.lastPathComponent + "(\(row))")
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

class AddKeyView: NSView {
    
    // 获取UserDefaults的实例
    let defaults = UserDefaults.standard
    
    lazy var keyField: NSTextField = {
        let textField = NSTextField()
        textField.placeholderString = "input tinypng api key"
        textField.font = NSFont.systemFont(ofSize: 20)
        textField.alignment = .center
        textField.wantsLayer = true
        
        textField.isBezeled = false // Remove bevel border
        textField.backgroundColor = .white
        textField.focusRingType = .none
        
        return textField
    }()
    
    lazy var addButton: NSButton = {
        let add = NSButton(title: "添加Tiny Key", target: self, action: #selector(addOrChangeKey))
        add.bezelStyle = .rounded
        return add
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.registerForDraggedTypes([.fileURL])
        creatUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func creatUI() {
        
        self.addSubview(keyField)
        keyField.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.equalTo(400)
        }
        
        self.addSubview(addButton)
        addButton.snp.makeConstraints { make in
            make.top.equalTo(keyField.snp.bottom)
            make.width.equalTo(200)
            make.height.equalTo(44)
            make.bottom.centerX.equalToSuperview()
        }
        
        // 读取存储的字符串数组
        let savedStringArray = defaults.array(forKey: tinyUserDefaultsKey) as? [String]
        showContent(text: savedStringArray?.first)
    }
    
    func showContent(text: String?) {
        keyField.stringValue = text ?? ""
        if text != nil {
            keyField.backgroundColor = .clear
            keyField.isEnabled = false
            addButton.title = "修改Tiny Key"
        }else {
            keyField.backgroundColor = .white
            keyField.isEnabled = true
            addButton.title = "保存Tiny Key"
        }
    }
    
    @objc func addOrChangeKey() {
        
        if keyField.isEnabled, keyField.stringValue.count > 0 {
            let stringArray = [keyField.stringValue]
            defaults.set(stringArray, forKey: tinyUserDefaultsKey)
            showContent(text: keyField.stringValue)
        } else {
            defaults.set(nil, forKey: tinyUserDefaultsKey)
            showContent(text: nil)
        }
    }
}
