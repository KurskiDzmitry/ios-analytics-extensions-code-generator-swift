import Foundation

func main() {
    let fileManager = FileManager.default
    let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let schemasDir = currentDir.appendingPathComponent("Schema")
    let sourceDir = currentDir.appendingPathComponent("Sources")
    let objectModelDir = sourceDir.appendingPathComponent("ObjectModel")
    let extensionDir = sourceDir.appendingPathComponent("Extension")
    
    // Constants
    let analyticsExtensionConst = "RoRAnalyticsExtension.swift"
    
    // Ensure directories exist
    createDirectoryIfNeeded(at: objectModelDir)
    createDirectoryIfNeeded(at: extensionDir)
    
    // List JSON files in the schemas directory
    let schemas = listJSONFiles(in: schemasDir)
    print("Found \(schemas.count) JSON files in \(schemasDir.path)")
    
    // Handle the analytics extension file
    let analyticsExtensionFile = extensionDir.appendingPathComponent(analyticsExtensionConst)
    handleAnalyticsExtensionFile(at: analyticsExtensionFile)
}

func createDirectoryIfNeeded(at url: URL) {
    let fileManager = FileManager.default
    do {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        print("Directory created or already exists at: \(url.path)")
    } catch {
        print("Error creating directory at \(url.path): \(error)")
    }
}

func listJSONFiles(in directory: URL) -> [URL] {
    let fileManager = FileManager.default
    do {
        let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        return files.filter { $0.pathExtension == "json" }
    } catch {
        print("Error listing JSON files in \(directory.path): \(error)")
        return []
    }
}

func handleAnalyticsExtensionFile(at url: URL) {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: url.path) {
        let content = """
        import Foundation
        import RakutenAnalytics

        public extension RAnalyticsRATTracker {
        """
        writeToFile(directory: url.deletingLastPathComponent(), filename: url.lastPathComponent, content: content)
    }
    
    do {
        let existingContent = try String(contentsOf: url)
        print("Existing content of \(url.path):\n\(existingContent)")
    } catch {
        print("Error reading content of \(url.path): \(error)")
    }
}

func writeToFile(directory: URL, filename: String, content: String) {
    let fileURL = directory.appendingPathComponent(filename)
    do {
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        print("File written to \(fileURL.path)")
    } catch {
        print("Error writing to file \(fileURL.path): \(error)")
    }
}

main()
