//
//  DatabaseManager.swift
//  photoLibOrganizer-macos
//
//  Created by Steeve Taillon on 2025-04-27.
//


import PostgresClientKit

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

            // Insert file path into the file_ingestion table
            let statement = try connection.prepareStatement(text: "INSERT INTO \"all\".file_ingestion (\"ID\", file_path) VALUES (nextval('\"all\".file_ingestion_idseq'),$1)")
            defer { statement.close() }

            try statement.execute(parameterValues: [filePath])
            print("Inserted file path: \(filePath)")
        } catch {
            print("Error: \(error)")
        }
    }
}
