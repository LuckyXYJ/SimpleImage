//
//  RenameView.swift
//  image
//
//  Created by lucky on 2024/9/5.
//

import Cocoa

class RenameView: NSView {

    var fileList: [SameImageModel] = [] {
        didSet {
            scrolllView.isHidden = fileList.count <= 0
            clearButton.isHidden = fileList.count <= 0
            tableView.reloadData()
            fileButton.isHidden = fileList.count > 0
            fileTips.isHidden = fileList.count > 0
        }
    }
    
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
        let modelList = urls.map({RenameImageModel(url: $0)})
        fileList = RenameTools.mergeSameImageModel(imgModels: modelList)
        return true
    }
    
    lazy var fileButton: NSButton = {
        let button = NSButton()
        var fileImage: NSImage?
        if #available(macOS 11.0, *) {
            fileImage = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil) ?? NSImage(named: "file_dir")
        } else {
            fileImage = NSImage(named: "file_dir")
        }
        fileImage?.size = NSSize(width: 100, height: 100)
        button.image = fileImage
        button.imageScaling = .scaleProportionallyUpOrDown
        button.isBordered = false
        button.target = self
        button.action = #selector(selectClicked)
        return button
    }()
    
    lazy var fileTips: NSTextField = {
        let textField = NSTextField(labelWithString: "拖入文件开始改名")
        textField.font = NSFont.systemFont(ofSize: 20)
        textField.alignment = .center
        return textField
    }()
    
    lazy var scrolllView: NSScrollView = {
        let scrolllView = NSScrollView()
        scrolllView.hasVerticalScroller = true
        scrolllView.autohidesScrollers = true
        scrolllView.isHidden = true
        scrolllView.translatesAutoresizingMaskIntoConstraints = false
        scrolllView.documentView = tableView
        return scrolllView
    }()
    
    lazy var tableView: NSTableView = {
        let tableView = NSTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Open Finder", action: #selector(openFinder), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Preview Image", action: #selector(previewImage), keyEquivalent: ""))
        tableView.menu = menu
        addTableColumn(tableView: tableView)
        return tableView
    }()
    
    lazy var clearButton: NSButton = {
        let clearButton = NSButton()
        var fileImage: NSImage?
        if #available(macOS 11.0, *) {
            fileImage = NSImage(systemSymbolName: "clear", accessibilityDescription: nil) ?? NSImage(named: "file_dir")
        } else {
            fileImage = NSImage(named: "file_dir")
        }
        fileImage?.size = NSSize(width: 44, height: 44)
        clearButton.image = fileImage
        clearButton.imageScaling = .scaleProportionallyUpOrDown
        clearButton.isHidden = true
        clearButton.isBordered = false
        clearButton.target = self
        clearButton.action = #selector(clearAllData)
        return clearButton
    }()
    
    var selectedRow: Int?
}

extension RenameView {
    @objc func selectClicked() {
        CommonTools.selectLocalImageFile { [weak self] urls in
            let modelList = urls.map({RenameImageModel(url: $0)})
            self?.fileList = RenameTools.mergeSameImageModel(imgModels: modelList)
        }
    }
    
    // 菜单项的动作方法
    @objc func openFinder(_ sender: NSMenuItem) {
        guard let row = selectedRow else { return }
        let imageFile = fileList[row]
        let fileURL = imageFile.parentFolderUrl
        NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
    }
    // 预览
    @objc func previewImage(_ sender: NSMenuItem) {
        guard let row = selectedRow else { return }
        let imageFile = fileList[row]
        let fileURL = imageFile.exampleUrl
        NSWorkspace.shared.open(fileURL)
    }
    
    @objc func clearAllData() {
        fileList = []
    }
    
    @objc func renameImage(_ sender: NSButton) {
        let row = tableView.row(for: sender)
        let renameModel = fileList[row]
        
        let inputView = tableView.view(atColumn: 2, row: row, makeIfNecessary: false)?.subviews.first(where: { $0 is NSTextField }) as? NSTextField
        if let reString = inputView?.stringValue, reString.count > 0 {
            renameModel.rename(reString)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView.reloadData()
        }
    }
    
    func getCurrentRow() -> Int? {
        guard let mouseLocation = self.tableView.window?.mouseLocationOutsideOfEventStream else { return nil }
        let tableViewLocation = self.tableView.convert(mouseLocation, from: nil)
        let row = self.tableView.row(at: tableViewLocation)
        return row
    }
}

extension RenameView {
    
    func creatUI() {
//        self.wantsLayer = true
//        self.layer?.backgroundColor = .white
        
        self.addSubview(fileButton)
        fileButton.snp.makeConstraints { make in
            make.size.equalTo(100)
            make.center.equalToSuperview()
        }
        
        self.addSubview(fileTips)
        fileTips.snp.makeConstraints { make in
            make.centerX.equalTo(fileButton)
            make.top.equalTo(fileButton.snp.bottom)
        }
    
        self.addSubview(scrolllView)
        scrolllView.snp.makeConstraints { make in
            make.top.equalTo(snp.top)
            make.bottom.equalTo(snp.bottom)
            make.left.equalTo(snp.left)
            make.right.equalTo(snp.right)
        }
    
        self.addSubview(clearButton)
        clearButton.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.bottom.right.equalToSuperview().inset(44)
        }
    }
    
    func addTableColumn(tableView: NSTableView) {
        let thumbnailColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ThumbnailColumn"))
        thumbnailColumn.title = "Thumbnail"
        thumbnailColumn.width = 80
        thumbnailColumn.headerCell = NSTableHeaderCell(textCell: "Thumbnail")
        tableView.addTableColumn(thumbnailColumn)
        
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("NameColumn"))
        nameColumn.title = "Name"
        thumbnailColumn.width = 200
        tableView.addTableColumn(nameColumn)
        
        let inputColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("InputColumn"))
        inputColumn.title = "Rename"
        inputColumn.width = 200
        tableView.addTableColumn(inputColumn)
        
        let actionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ActionColumn"))
        actionColumn.title = "Action"
        actionColumn.width = 100
        tableView.addTableColumn(actionColumn)
    }
}

extension RenameView: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        selectedRow = getCurrentRow()
    }
}

extension RenameView: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return fileList.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        80
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let imageFile = fileList[row]
        guard let columnIdentifier = tableColumn?.identifier.rawValue else {
            return nil
        }
        
        if columnIdentifier == "ThumbnailColumn" {
            var cellView: NSTableCellView
            if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(columnIdentifier), owner: self) as? NSTableCellView {
                cellView = view
            } else {
                cellView = NSTableCellView()
                cellView.identifier = NSUserInterfaceItemIdentifier(columnIdentifier)
                let imageView = NSImageView()
                imageView.frame = CGRect(x: 5, y: 5, width: 70, height: 70)
                cellView.addSubview(imageView)
            }
            if let imageView = cellView.subviews.first as? NSImageView {
                imageView.image = NSImage(contentsOf: imageFile.exampleUrl)
            }
            return cellView
            
        } else if columnIdentifier == "NameColumn" {
            
            var cellView: NSTableCellView
            if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(columnIdentifier), owner: self) as? NSTableCellView {
                cellView = view
            } else {
                cellView = NSTableCellView()
                cellView.identifier = NSUserInterfaceItemIdentifier(columnIdentifier)
                let textField = NSTextField()
                textField.autoresizingMask = [.width]
                textField.isEnabled = false
                textField.isBezeled = false // Remove bevel border
                textField.backgroundColor = .clear
                textField.focusRingType = .none
                cellView.addSubview(textField)
                textField.snp.makeConstraints({
                    $0.left.right.equalToSuperview()
                    $0.centerY.equalToSuperview()
                })
            }
            if let textField = cellView.subviews.first as? NSTextField {
                textField.stringValue = imageFile.name
            }
            return cellView
        } else if columnIdentifier == "InputColumn" {
            var cellView: NSTableCellView
            if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(columnIdentifier), owner: self) as? NSTableCellView {
                cellView = view
            } else {
                cellView = NSTableCellView()
                let textField = NSTextField()
//                textField.frame = CGRect(x: 0, y: 0, width: 200, height: 60)
                cellView.addSubview(textField)
                textField.snp.makeConstraints({
                    $0.left.right.equalToSuperview()
                    $0.centerY.equalToSuperview()
                })
                cellView.wantsLayer = true
            }
            if let textField = cellView.subviews.first as? NSTextField {
                textField.stringValue = imageFile.renameString ?? ""
            }
            return cellView
        } else if columnIdentifier == "ActionColumn" {
            var cellView: NSTableCellView
            if let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(columnIdentifier), owner: self) as? NSTableCellView {
                cellView = view
            } else {
                cellView = NSTableCellView()
                let button = NSButton(title: "rename", target: self, action: #selector(renameImage(_:)))
                button.bezelStyle = .rounded
                cellView.addSubview(button)
                button.snp.makeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.left.equalToSuperview().offset(40)
                    make.size.equalTo(CGSize(width: 90, height: 30))
                }
                cellView.wantsLayer = true
            }
            return cellView
        }
        return nil
    }
}
