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
    func save(extensionn: String) {
        let savePanel = NSSavePanel()
        if savePanel.runModal() == .OK {
            guard let directory = savePanel.directoryURL else { return }
            do {
                try data(using: .utf8)?.write(to: directory.path, name: savePanel.nameFieldStringValue + extensionn)
            } catch {
                NSAlert(error: error).runModal()
            }
        }
    }

    var stripped: String {
        let okayChars = Set("abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLKMNOPQRSTUVWXYZ1234567890_")
        return self.filter {okayChars.contains($0) }
    }
}

extension Data {
    /// Tries to save data into a given directory using a given name and extension
    func write(to directory: String, name: String) throws {
        let filePath: NSString = "file://\(directory)" as NSString
        guard let pathURL: URL = URL(string: filePath.appendingPathComponent(name)) else { return }
        try self.write(to: pathURL)
    }
}
