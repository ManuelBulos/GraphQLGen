//
//  ContentView.swift
//  GraphQLGen
//
//  Created by Manuel on 21/05/20.
//  Copyright © 2020 manuelbulos. All rights reserved.
//

import SwiftUI

struct ContentView: View {

    @State var suffix: String = "Fragment"

    @State var endpoint: String = ""

    @State var directory: String = ""

    let updateSchemasScriptName: String = "update_schemas.sh"

    let actions = ["Drop SDL file", "Download from endpoint"]

    @State var selectedActionIndex: Int = 0

    private func getOpenPanel() -> NSOpenPanel {
        let openPanel = NSOpenPanel()
        openPanel.canCreateDirectories = true
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        return openPanel
    }

    var body: some View {
        VStack {

            /*
            Section {
                Picker("", selection: $selectedActionIndex) {
                    ForEach(0 ..< actions.count) {
                        Text(self.actions[$0])
                    }
                }.pickerStyle(SegmentedPickerStyle())
            }.padding(.top)
             */

            dropSDLFileView
            //selectedActionIndex == 0 ? AnyView(dropSDLFileView) : AnyView(downloadAndGenerateEverything)

            Text(
                """
                Write a suffix for your fragments.
                """)
                .multilineTextAlignment(.center)
                .padding(.top)

            TextField("Suffix", text: $suffix)
                .frame(maxWidth: 100, maxHeight: 40, alignment: .center)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .onDrop(of: [(kUTTypeFileURL as String)], delegate: self)
    }

    var dropSDLFileView: some View {
        Text("Drop your GraphQL SDL file here!")
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .background(Color(red: 222/255, green: 53/255, blue: 166/255))
    }

    var downloadAndGenerateEverything: some View {
        VStack {
            TextField("endpoint", text: $endpoint)
                .frame(maxWidth: 250, maxHeight: 40, alignment: .center)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Text(directory.isEmpty ? "" : "Files will be saved in " + directory)
                .frame(maxWidth: .infinity, maxHeight: 40, alignment: .center)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                let openPanel = self.getOpenPanel()
                if openPanel.runModal() == .OK {
                    self.directory = openPanel.directoryURL?.absoluteString ?? ""
                }
            }) {
                Text("Select directory")
            }

            self.endpoint.isEmpty || self.directory.isEmpty ? AnyView(Text("")) : AnyView(downloadButton)
        }
    }

    var downloadButton: some View {
        Button(action: {
            self.download(from: self.endpoint, to: self.directory)
        }) {
            Text("Download and generate files")
        }
    }

    private func generate(input: String) {
        let fragmentSuffix = suffix.stripped

        let fragmentGenerator = FragmentGenerator(fragmentSuffix:  fragmentSuffix)
        let fragmentsOutput = fragmentGenerator.generateFragments(for: input)

        let queryGenerator = QueryGenerator(declaredFragments: fragmentGenerator.declaredFragments, fragmentSuffix: fragmentSuffix)
        let queriesOutput = queryGenerator.generateQueries(for: input)

        let mutationGenerator = MutationGenerator(declaredFragments: fragmentGenerator.declaredFragments, fragmentSuffix: fragmentSuffix)
        let mutationsOutput = mutationGenerator.generateMutations(for: input)

        fragmentsOutput.save(fileName: "Fragments", extensionn: ".graphql")
        queriesOutput.save(fileName: "Queries", extensionn: ".graphql")
        mutationsOutput.save(fileName: "Mutations", extensionn: ".graphql")
    }

    private func download(from endpoint: String, to directory: String) {
        if endpoint.isEmpty || directory.isEmpty { return }

        let script =
        """
        #!/bin/bash
        # Downloads the latest schema.json and schema.graphql files from the GraphQL endpoint

        declare -r endpoint="\(endpoint)"
        declare -r directory="\(directory.dropFirst(7))"

        cd $directory
        echo "🗂 Switched to directory: "$directory

        echo "⬇️ Downloading schema.json file from: "$endpoint
        apollo schema:download --endpoint=$endpoint schema.json

        echo "⬇️ Downloading schema.graphql file from: "$endpoint
        apollo schema:download --endpoint=$endpoint schema.graphql
        """

        guard let url = URL(string: directory) else { return }
        do {
            try script.data(using: .utf8)?.write(to: url, name: updateSchemasScriptName)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let path = "\(directory.dropFirst(8))\(self.updateSchemasScriptName)"
//                let status = self.shell("-s chmod 777 \(path)", "./\(self.updateSchemasScriptName)")
                let see = self.shell(script)
                print(see)
            }
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    func shell(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c"]
        task.arguments = task.arguments! + args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
}

extension ContentView: DropDelegate {
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [(kUTTypeFileURL as String)]).first else { return false }

        itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) {item, error in
            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                let input = url.contentsOfFile()
                self.generate(input: input)
            }
        }

        return true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
