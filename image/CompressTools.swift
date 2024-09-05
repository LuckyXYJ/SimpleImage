//
//  CompressTools.swift
//  image
//
//  Created by lucky on 2024/8/26.
//

import Foundation

protocol CompressImage {
    var fileUrl: URL { get }
    func changeStatus(_ status: ImageHandleStatus)
}

struct CompressTools {
    static func tinifyCompress(_ images: [CompressImage], closure: (()-> Void)? = nil) {
        
        let savedStringArray = UserDefaults.standard.array(forKey: tinyUserDefaultsKey) as? [String]
        guard let apiKey = savedStringArray?.first else { return }
        
        for imageURL in images {
            imageURL.changeStatus(.inProcess)
            
            var oldSize = ""
            if #available(macOS 13.0, *) {
                oldSize = Self.formatFileSize(Self.fileSize(at: imageURL.fileUrl) ?? 0)
            } else {
                oldSize = Self.formatFileSize(Self.fileSize(at: imageURL.fileUrl) ?? 0)
            }
            closure?()
            let fileData = try? Data(contentsOf: imageURL.fileUrl)
            let request = NSMutableURLRequest(url: URL(string: "https://api.tinify.com/shrink")!)
            request.httpMethod = "POST"
            request.httpBody = fileData
            let authString = "api:\(apiKey)"
            let authData = authString.data(using: .utf8)!
            let base64AuthString = authData.base64EncodedString()
            request.setValue("Basic \(base64AuthString)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                guard let response = response as? HTTPURLResponse, response.statusCode == 201 else {
                    print("Failed to compress image: \(error?.localizedDescription ?? "Unknown error")")
                    imageURL.changeStatus(.fail)
                    closure?()
                    return
                }
                
                if let result = try? JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any],
                   let output = result["output"] as? [String: Any],
                   let outputURLString = output["url"] as? String,
                   let outputURL = URL(string: outputURLString) {
                    
                    URLSession.shared.dataTask(with: outputURL) { data, _, _ in
                        
                        closure?()
                        if let data = data {
                            let outputFileURL = imageURL.fileUrl // downloadFolder.appendingPathComponent(imageURL.fileUrl.lastPathComponent)
                            try? data.write(to: outputFileURL)
                            print("Compressed image saved to: \(outputFileURL)")
                            
                            
                            let newSize = Self.formatFileSize(UInt64(data.count))
                            
                            imageURL.changeStatus(.success(oldSize: oldSize, newSize: newSize))
                        }
                    }.resume()
                }else {
                    imageURL.changeStatus(.fail)
                    closure?()
                }
            }
            task.resume()
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
    
    static func fileSize(at url: URL) -> UInt64? {
        do {
            let resourceValues = try url.resourceValues(forKeys:[.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                return UInt64(fileSize)
            } else {
                return nil
            }
        } catch {
            print("Error retrieving file size: \(error)")
            return nil
        }
    }
    
    static func fileSize(atPath path: String) -> UInt64? {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: path)
            if let fileSize = fileAttributes[FileAttributeKey.size] as? UInt64 {
                return fileSize
            } else {
                return nil
            }
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
    
    static func formatFileSize(_ size: UInt64) -> String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useKB, .useMB, .useGB, .useBytes] // 你可以根据需要更改单位
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(size))
    }
}
