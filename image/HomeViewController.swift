//
//  HomeViewController.swift
//  image
//
//  Created by lucky on 2024/8/24.
//

import Cocoa
import SnapKit
class HomeViewController: NSViewController {

    var dropView: DraggableView = DraggableView()
    var renameView = RenameView()
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(leftView)
        leftView.snp.makeConstraints({
            $0.width.equalTo(100)
            $0.centerY.left.equalToSuperview()
        })
        
        view.addSubview(renameView)
        renameView.isHidden = true
        renameView.snp.makeConstraints({
            $0.left.equalTo(100)
            $0.top.right.bottom.equalToSuperview()
        })
        
        view.addSubview(dropView)
        dropView.snp.makeConstraints({
            $0.left.equalTo(100)
            $0.top.right.bottom.equalToSuperview()
        })
        
        [compressButton, reNameButton].forEach {
            leftView.addSubview($0)
        }
        compressButton.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(50)
        }
        reNameButton.snp.makeConstraints { make in
            make.top.equalTo(compressButton.snp.bottom)
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(50)
        }
    }
    
    lazy var leftView: NSView = {
        let view = NSView()
        return view
    }()
    
    lazy var compressButton: NSButton = {
        let add = NSButton(title: "压缩", target: self, action: #selector(compressAction))
        add.bezelStyle = .rounded
        return add
    }()
    
    lazy var reNameButton: NSButton = {
        let add = NSButton(title: "改名", target: self, action: #selector(renameAction))
        add.bezelStyle = .rounded
        return add
    }()
    
    @objc func compressAction() {
        dropView.isHidden = false
        renameView.isHidden = true
    }
    
    @objc func renameAction() {
        renameView.isHidden = false
        dropView.isHidden = true
    }
}

