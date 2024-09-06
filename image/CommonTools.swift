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
