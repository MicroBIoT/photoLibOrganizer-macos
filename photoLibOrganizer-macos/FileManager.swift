//
//  FileManager.swift
//  photoLibOrganizer-macos
//
//  Created by Steeve Taillon on 2025-04-27.
//

import Foundation
import UniformTypeIdentifiers
import CryptoKit


func isJPEGImage(filePath: String) -> Bool {
    let url = URL(fileURLWithPath: filePath)
    
    // Check if the file exists
    guard FileManager.default.fileExists(atPath: filePath) else {
        print("File does not exist at path: \(filePath)")
        return false
    }
    
    do {
        // Read the file's data
        let fileData = try Data(contentsOf: url)
        
        // Check for JPEG magic numbers (SOI marker: 0xFF, 0xD8)
        if fileData.starts(with: [0xFF, 0xD8]) {
            return true
        }
    } catch {
        print("Failed to read file: \(error)")
    }
    
    return false
}



func fileChecksum(filePath: String) -> String {
   // let filePath = CommandLine.arguments[1]
    
    // Ensure the script is invoked with a file path argument
    guard CommandLine.arguments.count == 3 else {
        print("Usage: swift md5_checksum.swift <file_path>")
        print(CommandLine.arguments.count)
       exit(1)
    }
    
    // Check if the file exists
    //  guard FileManager.default.fileExists(atPath: filePath) else {
    //      print("Error: File not found at path \(filePath)")
    //      exit(1)
    //  }
    
    do {
        // Read the file contents
        let fileData = try Data(contentsOf: URL(fileURLWithPath: filePath))
        
        // Compute the MD5 checksum
        let md5Checksum = Insecure.MD5.hash(data: fileData)
            .map { String(format: "%02hhx", $0) }
            .joined()
        
        print("MD5 checksum: \(md5Checksum)")
        return md5Checksum
    } catch {
        print("Error: \(error.localizedDescription)")
        exit(1)
    }
    
}




struct FileRecord {
    let id: Int
    let filePath: String
}

let databaseManager = DatabaseManager()

func computeMD5Checksum(for filePath: String) -> String? {
    guard let data = FileManager.default.contents(atPath: filePath) else { return nil }
    let digest = Insecure.MD5.hash(data: data)
    return digest.map { String(format: "%02hhx", $0) }.joined()
}



func processFilesConcurrently(fileRecords: [FileRecord], maxConcurrentThreads: Int = 20) {
    let queue = DispatchQueue(label: "checksumQueue", attributes: .concurrent)
    let semaphore = DispatchSemaphore(value: maxConcurrentThreads)
    let group = DispatchGroup()
    let fileManager = FileManager.default
    

    for record in fileRecords {
        semaphore.wait()
        group.enter()
        queue.async {
            defer {
                semaphore.signal()
                group.leave()
            }
            // Check if file exists
            //if fileManager.fileExists(atPath: record.filePath)  {
            //        print("Error: File does not exist at path \(record.filePath)")
            //    }

                // Attempt to read file data
          //      if let fileData = fileManager.contents(atPath: record.filePath)  {
          //          print("Error: Unable to read file data at path \(record.filePath)")
          //      }
            
            if let checksum = computeMD5Checksum(for: record.filePath) {
                do {
                    try databaseManager.updateChecksum(id: record.id, checksum: checksum)
                    //logMessages.append("file:: \(filePath) verified")
                } catch {
                    print("Failed to update checksum for file ID \(record.id): \(error)")
                }
            } else {
                print("Failed to compute checksum for file at path \(record.filePath)")
                print(computeMD5Checksum(for: record.filePath))
            }
        }
    }
    group.wait()
}

func fullpowerscotty() {
        do {
            let fileRecords = try databaseManager.fetchFilePaths()
            processFilesConcurrently(fileRecords: fileRecords)
        } catch {
            print("Error: \(error)")
        }
    }
