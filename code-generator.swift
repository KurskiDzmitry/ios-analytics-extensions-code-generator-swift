import Foundation

func main() {
    let fileManager = FileManager.default
    let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let schemasDir = currentDir.appendingPathComponent("Schemas")
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
    
    // Process schemas to generate Swift code
    processSchemas(schemas, objectModelDir: objectModelDir)
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

func formatConstValue(_ constValue: Any, type: String) -> String {
    switch type {
    case "string":
        return "\"\(constValue)"
    case "number":
        return "\(constValue)"
    default:
        return "\(constValue)"
    }
}

func processSchemas(_ schemas: [URL], objectModelDir: URL) {
    for schema in schemas {
        if let data = try? Data(contentsOf: schema),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            let swiftCode = generateSwiftCode(from: json)
            if let title = json["title"] as? String {
                let filename = "\(title).swift"
                writeToFile(directory: objectModelDir, filename: filename, content: swiftCode)
            }
        }
    }
}

func generateSwiftCode(from schema: [String: Any]) -> String {
    guard let title = schema["title"] as? String,
          let properties = schema["properties"] as? [String: Any] else {
        return ""
    }
    
    var swiftCode = "public struct \(title): Codable {\n"
    
    for (propertyName, propertyAttributes) in properties {
        if let propertyAttributes = propertyAttributes as? [String: Any] {
            if let description = propertyAttributes["description"] as? String {
                swiftCode += "    /// \(description)\n"
            }
            if let type = propertyAttributes["type"] as? String {
                let optional = (propertyAttributes["optional"] as? String) == "true"
                let swiftType = swiftTypeFromSchemaType(type, propertyAttributes: propertyAttributes, optional: optional)
                if let constValue = propertyAttributes["const"] {
                    let constValueString = formatConstValue(constValue, type: type)
                    swiftCode += "    let \(propertyName): \(swiftType) = \(constValueString)\n"
                } else {
                    swiftCode += "    let \(propertyName): \(swiftType)\n"
                }
            }
        }
    }
    
    swiftCode += "}\n\n"
    
    // Generate inner structs if any
    for (_, propertyAttributes) in properties {
        if let propertyAttributes = propertyAttributes as? [String: Any],
           let type = propertyAttributes["type"] as? String,
           type == "objectArray",
           let items = propertyAttributes["items"] as? [String: Any],
           let itemTitle = items["title"] as? String {
            swiftCode += generateSwiftCode(from: ["title": itemTitle, "properties": items["properties"] ?? [:]])
        }
    }
    
    return swiftCode
}

func swiftTypeFromSchemaType(_ type: String, propertyAttributes: [String: Any], optional: Bool) -> String {
    switch type {
    case "string":
        return optional ? "String?" : "String"
        
    case "number":
        return optional ? "Double?" : "Double"
        
    case "object":
        if let title = propertyAttributes["title"] as? String {
            return optional ? "\(title)?" : title
        }
        return optional ? "[String: Any]?" : "[String: Any]"
        
    case "objectArray":
        if let items = propertyAttributes["items"] as? [String: Any],
           let itemTitle = items["title"] as? String {
            return optional ? "[\(itemTitle)]?" : "[\(itemTitle)]"
        }
        return optional ? "[Any]?" : "[Any]"
        
    case "dictionary":
        return optional ? "[String: Any]?" : "[String: Any]"
        
    default:
        return "Any"
    }
}

main()
