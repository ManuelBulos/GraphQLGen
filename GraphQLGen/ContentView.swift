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

    var body: some View {
        VStack {
            Button(action: {
                let openPanel = NSOpenPanel()
                if openPanel.runModal() == .OK {
                    guard let input = openPanel.directoryURL?.contentsOfFile() else { return }
                    self.generate(input: input)
                }
            }) {
                VStack {
                    Text("Drop your GraphQL SDL file here!")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .background(Color(red: 222/255, green: 53/255, blue: 166/255))
            }.buttonStyle(PlainButtonStyle())

            Spacer()

            Text(
                """
                Write a suffix for your fragments.

                e.g. fragment User\(suffix.stripped) on User
                """)
                .multilineTextAlignment(.center)

            TextField("Suffix", text: $suffix)
                .frame(maxWidth: 100, maxHeight: 40, alignment: .center)
                .multilineTextAlignment(.center)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .onDrop(of: [(kUTTypeFileURL as String)], delegate: self)
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
