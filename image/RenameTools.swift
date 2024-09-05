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

class SameImageModel {
    
    var name: String = ""
    var baseUrl: String = ""
    var suffixString: String = ""
    
    var files: [FileModel] = []
}

extension SameImageModel {
    
    
}

struct RenameTools {
    
    
    
}
