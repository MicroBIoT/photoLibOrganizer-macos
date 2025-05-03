//
//  DatabaseManager.swift
//  photoLibOrganizer-macos
//
//  Created by Steeve Taillon on 2025-04-27.
//


import PostgresClientKit
import Foundation

struct DatabaseManager {
    var configuration: PostgresClientKit.ConnectionConfiguration

    init() {
        configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = "localhost"
        configuration.port = 5432
        configuration.ssl = false
        configuration.database = "photolib"
        configuration.user = "photoingester"
        configuration.credential = .scramSHA256(password: "photoingester")
    }

    func insertFilePath(filePath: String) {
        do {
            let connection = try PostgresClientKit.Connection(configuration: configuration)
            defer { connection.close() }
            
            //let filechecksum = fileChecksum(filePath: filePath)

            // Insert file path into the file_ingestion table
            let statement = try connection.prepareStatement(text: "INSERT INTO \"all\".file_ingestion (\"ID\", file_path) VALUES (nextval('\"all\".file_ingestion_idseq'),$1)")
            defer { statement.close() }

        try statement.execute(parameterValues: [filePath])
            print("Inserted file path: \(filePath)")
        } catch {
            print("Error: \(error)")
        }
    }
    
    
    func updateChecksum(id: Int, checksum: String) throws {
        let connection = try PostgresClientKit.Connection(configuration: configuration)
        defer { connection.close() }
        
        let text = "UPDATE \"all\".file_ingestion SET checksum = $1 WHERE \"ID\" = $2"
        let statement = try connection.prepareStatement(text: text)
        defer { statement.close() }
        
        try statement.execute(parameterValues: [checksum, String(id)])
    }
    
    
    func fetchFilePaths() throws -> [FileRecord] {
        var fileRecords: [FileRecord] = []
        
        let connection = try PostgresClientKit.Connection(configuration: configuration)
        defer { connection.close() }
        
        let text = "SELECT \"ID\", file_path FROM \"all\".file_ingestion WHERE checksum IS NULL"
        let statement = try connection.prepareStatement(text: text)
        defer { statement.close() }
        
        let cursor = try statement.execute()
        defer { cursor.close() }
        
        for row in cursor {
            let columns = try row.get().columns
            let id = try columns[0].int()
            let filePath = try columns[1].string()
            fileRecords.append(FileRecord(id: id, filePath: filePath))
        }
        
        return fileRecords
    }
    
    
}


