//
//  HomeViewController.swift
//  image
//
//  Created by dingtone on 2024/8/24.
//

import Cocoa
import SnapKit
class HomeViewController: NSViewController {

    var dropView: DraggableView = DraggableView()
    
    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(dropView)
        dropView.snp.makeConstraints({ $0.edges.equalToSuperview() })
    }
}
