//
//  CommonTools.swift
//  image
//
//  Created by lucky on 2024/9/6.
//

import Foundation
import Cocoa

struct CommonTools {
    // 选择图片
    static func selectLocalImageFile(completion: @escaping (([URL]) -> Void)) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        if #available(macOS 11.0, *) {
            openPanel.allowedContentTypes = [.png, .jpeg, .webP]
        } else {
            // Fallback on earlier versions
            openPanel.allowedFileTypes = ["png", "jpeg", "jpg", "webp"]
        }
        
        openPanel.message = "请选择最多20个图片文件"
        
        openPanel.begin { response in
            if response == .OK {
                let selectedFiles = openPanel.urls
                var urls: [URL] = []
                for file in selectedFiles {
                    urls.append(contentsOf: self.getSubFiles(url: file))
                }
                completion(urls)
            }
        }
    }
    
    static func getSubFiles(url: URL) -> [URL] {
        var files: [URL] = []
        if url.hasDirectoryPath {
            if let resources = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) {
                for path in resources {
                    let subUrls = getSubFiles(url: path)
                    files.append(contentsOf: subUrls)
                }
            }
        } else {
            if isImage(url: url) {
                files.append(url)
            }
        }
        return files
    }
    
    static func isImage(url: URL) -> Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "webp"]
        return imageExtensions.contains(url.pathExtension.lowercased())
    }
}

class Throttler {
    private var lastExecuted: Date?
    private let queue: DispatchQueue
    private let interval: TimeInterval
    private var lastRequest: Date?
    private var scheduledWorkItem: DispatchWorkItem?

    init(interval: TimeInterval, queue: DispatchQueue = DispatchQueue.main) {
        self.interval = interval
        self.queue = queue
        lastExecuted = Date(timeIntervalSince1970: 0)
    }

    func call(_ action: @escaping () -> Void) {
        let now = Date()
        lastRequest = now
        
        guard lastExecuted == nil || now.timeIntervalSince(lastExecuted!) >= interval else {
            // If already have a scheduled work item, cancel it
            scheduledWorkItem?.cancel()
            
            // Schedule a new work item
            let workItem = DispatchWorkItem { [weak self] in
                self?.lastExecuted = Date()
                self?.performTask(action)
            }
            scheduledWorkItem = workItem
            queue.asyncAfter(deadline: .now() + interval - now.timeIntervalSince(lastExecuted!)) {
                // Ensure that lastRequest time hasn't changed
                if self.lastRequest == now {
                    workItem.perform()
                }
            }
            return
        }
        
        lastExecuted = now
        performTask(action)
    }
    
    func performTask(_ action: @escaping () -> Void) {
        queue.async {
            action()
        }
    }
}
