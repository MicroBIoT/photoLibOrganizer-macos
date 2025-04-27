import SwiftUI

struct ContentView: View {
    @State private var selectedDirectory: URL?
    @State private var logMessages: [String] = []
    private let databaseManager = DatabaseManager()

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Select Directory") {
                    selectDirectory()
                }
                Button("Scan and Insert") {
                    scanAndInsert()
                }
            }

            Text("Logs:")
                .font(.headline)

            ScrollView {
                ForEach(logMessages, id: \.self) { message in
                    Text(message)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxHeight: 200)
            .border(Color.gray, width: 1)
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            selectedDirectory = panel.url
            logMessages.append("Selected directory: \(selectedDirectory?.path ?? "None")")
        }
    }

    private func scanAndInsert() {
        guard let directory = selectedDirectory else {
            logMessages.append("No directory selected!")
            return
        }

        let filePaths = listAllFiles(in: directory, withExtension: "jpg")
        logMessages.append("Found files: \(filePaths)")

        for filePath in filePaths {
            databaseManager.insertFilePath(filePath: filePath)
            logMessages.append("Inserted into database: \(filePath)")
        }
    }

    private func listAllFiles(in directory: URL, withExtension fileExtension: String) -> [String] {
        let fileManager = FileManager.default
        var filePaths: [String] = []

        if let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension.lowercased() == fileExtension.lowercased() {
                    filePaths.append(fileURL.path)
                }
            }
        } else {
            logMessages.append("Failed to enumerate files in the directory: \(directory.path)")
        }

        return filePaths
    }
}
