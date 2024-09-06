//
//  RenameTools.swift
//  image
//
//  Created by lucky on 2024/9/5.
//

import Foundation

enum RenameStatus {
    case waiting
    case inProcess
    case success(oldSize: String, newSize: String)
    case fail
}

let suffixStrings = ["@2x", "@3x"]

class RenameImageModel: FileModel {
    
    var name: String
    var parentFolderUrl: URL
    var suffixString: String = ""
    
    override init(url: URL) {
        let allName = url.deletingPathExtension().lastPathComponent
        self.name = allName
        for suffix in suffixStrings where allName.hasSuffix(suffix) {
            self.suffixString = suffix
            self.name = self.name.replacingOccurrences(of: suffix, with: "")
        }
        
        var parentUrl = url.deletingLastPathComponent()
        if parentUrl.lastPathComponent.hasPrefix("mipmap") {
            parentUrl = parentUrl.deletingLastPathComponent()
        }
        self.parentFolderUrl = parentUrl
        super.init(url: url)
    }
    
    func analyzeUrl(_ url: URL) {
        self.url = url
        let allName = url.deletingPathExtension().lastPathComponent
        self.name = allName
        for suffix in suffixStrings where allName.hasSuffix(suffix) {
            self.suffixString = suffix
            self.name = self.name.replacingOccurrences(of: suffix, with: "")
        }
        
        var parentUrl = url.deletingLastPathComponent()
        if parentUrl.lastPathComponent.hasPrefix("mipmap") {
            parentUrl = parentUrl.deletingLastPathComponent()
        }
        self.parentFolderUrl = parentUrl
    }
}

class SameImageModel: Hashable {
    var name: String
    var parentFolderUrl: URL
    var exampleUrl: URL
    var files: [RenameImageModel] = []
    var renameString: String?
    
    init(imgModel: RenameImageModel) {
        name = imgModel.name
        parentFolderUrl = imgModel.parentFolderUrl
        exampleUrl = imgModel.fileUrl
        files = [imgModel]
    }
    
    func rename(_ name: String) {
        for file in files {
            let newURL = file.url.deletingLastPathComponent().appendingPathComponent("\(name)\(file.suffixString)").appendingPathExtension(file.url.pathExtension)
            do {
                try FileManager.default.moveItem(at: file.url, to: newURL)
                file.analyzeUrl(newURL)
                print(file.name)
            } catch {
                print("Error renaming file: \(error)")
            }
        }
        self.analyzeFile(imgModel: files.first)
    }
    
    func analyzeFile(imgModel: RenameImageModel?) {
        guard let imgModel else { return }
        name = imgModel.name
        parentFolderUrl = imgModel.parentFolderUrl
        exampleUrl = imgModel.fileUrl
        renameString = nil
    }
}

extension SameImageModel: Equatable {
    static func == (lhs: SameImageModel, rhs: SameImageModel) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(parentFolderUrl)
        hasher.combine(name)
    }
}

struct RenameTools {
    
    static func mergeSameImageModel(imgModels: [RenameImageModel]) -> [SameImageModel] {
        
        var res: [SameImageModel] = []
        for imgModel in imgModels {
            if let sameModel = res.first(where: { $0.parentFolderUrl == imgModel.parentFolderUrl && $0.name == imgModel.name }) {
                sameModel.files.append(imgModel)
            } else {
                res.append(SameImageModel(imgModel: imgModel))
            }
        }
        return res
    }
    
}
