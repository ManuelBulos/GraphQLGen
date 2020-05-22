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
                    let fragments = FragmentGenerator().generateFragments(for: input, suffix: self.suffix.stripped)
                    fragments.save(extensionn: ".graphql")
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
}

extension ContentView: DropDelegate {
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [(kUTTypeFileURL as String)]).first else { return false }

        itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) {item, error in
            guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                let input = url.contentsOfFile()
                let fragments = FragmentGenerator().generateFragments(for: input, suffix: self.suffix.stripped)
                fragments.save(extensionn: ".graphql")
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
