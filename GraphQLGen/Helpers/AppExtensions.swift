//
//  Extensions.swift
//  GraphQGen
//
//  Created by Manuel on 21/05/20.
//  Copyright © 2020 manuelbulos. All rights reserved.
//

import Foundation
import Cocoa

extension URL {
    /// Returns the file contents as a string
    func contentsOfFile() -> String {
        do {
            let input = try String(contentsOfFile: path)
            return input
        } catch {
            NSAlert(error: error).runModal()
        }
        return ""
    }
}

extension String {
    /// Returns the file contents as a string
    func contentsOfFile() -> String {
        guard let url = URL(string: self) else { return "" }
        do {
            let input = try String(contentsOfFile: url.path)
            return input
        } catch {
            NSAlert(error: error).runModal()
        }
        return ""
    }

    /// Tries to save string as a file with an extension
    func save(fileName: String, extensionn: String) {
        let savePanel = NSSavePanel()

        savePanel.nameFieldLabel = "Name your \(fileName) file"
        savePanel.nameFieldStringValue = fileName

        if savePanel.runModal() == .OK {
            guard let directory = savePanel.directoryURL else { return }
            do {
                try data(using: .utf8)?.write(to: directory, name: savePanel.nameFieldStringValue + extensionn)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    /// Returns the same string with the allowed characters only
    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890_")
        return self.filter {okayChars.contains($0) }
    }
}

extension Data {
    /// Tries to save data into a given directory using a given name and extension
    func write(to directory: URL, name: String) throws {
        let filePath = directory.appendingPathComponent(name)

        "rm \(filePath.absoluteString)".runAsCommand()

        do {
            try self.write(to: filePath, options: .atomic)
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}

extension String {
    @discardableResult
    func runAsCommand() -> String {
        let pipe = Pipe()
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", String(format:"%@", self)]
        task.standardOutput = pipe
        let file = pipe.fileHandleForReading
        task.launch()
        if let result = NSString(data: file.readDataToEndOfFile(), encoding: String.Encoding.utf8.rawValue) {
            return result as String
        }
        else {
            return "--- Error running command - Unable to initialize string from file data ---"
        }
    }
}
