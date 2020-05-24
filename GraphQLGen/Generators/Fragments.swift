//
//  Fragments.swift
//  GraphQGen
//
//  Created by Manuel on 21/05/20.
//  Copyright © 2020 manuelbulos. All rights reserved.
//

import Foundation

/*
 This code turns object types into fragments with a given suffix

 Example:

 This:

 type User {
 name: String
 email: String
 }

 Becomes:

 fragment UserFragment on User {
 name
 email
 }

 -----------------------------------------------------------------

 It also replaces the property type for the fragment name if its the same type.
 Regardless if the type is/isn't an array, an optional or a required property

 Example:

 This:

 type Foo {
 id: Int!
 user: [User]!
 }

 Becomes:

 fragment FooFragment on User {
 id
 user {
 ...UserFragment
 }
 }
 */

/// Helper that returns a collection of fragments from a given SDL file (schema.graphql)
class FragmentGenerator {

    let fragmentSuffix: String

    // helps us store all fragment names (fragmentName + suffix)
    private(set) var declaredFragments: [String]

    init(fragmentSuffix: String) {
        self.fragmentSuffix = fragmentSuffix
        self.declaredFragments = [String]()
    }

    /// Needs a non-empty suffix or it will malfunction with the Apollo client for iOS
    func generateFragments(for input: String) -> String {

        // get each line in an array
        let lines = input.components(separatedBy: "\n")

        // starting index of each block
        let startingIndexes = lines.indexes(of: "{")

        // ending index of each block
        let endingIndexes = lines.indexes(of: "}")

        // sequence of pairs built out of two underlying sequences.
        // (startingIndex1,endingIndex1) (startingIndex2,endingIndex2) etc...
        let pairs = zip(startingIndexes, endingIndexes)

        // stores only the pairs where the code block is an object type
        // ignoring enums, mutations, and queries
        var typePairs = Array<Zip2Sequence<[Int], [Int]>.Element>()

        // iterate through all pairs to populate "typePairs" array
        for pair in pairs {
            let startIndex = pair.0
            let firstLine = lines[startIndex].description
            let isEnum = firstLine.contains("enum")
            let isType = firstLine.contains("type")
            let isMutation = firstLine.contains("Mutation")
            let isQuery = firstLine.contains("Query")

            let fragmentName = lines[startIndex].components(separatedBy: " ")[1]

            if isEnum || isMutation || isQuery {
                // ignore the pair cause its not an object type
            } else if isType {
                // store the object type
                typePairs.append(pair)
                declaredFragments.append(fragmentName + fragmentSuffix)
            }
        }

        // array that will store all generated fragments
        var generatedFragments = [String]()

        // iterate through all typePairs to populate "generatedFragments" array
        for pair in typePairs {
            let startIndex = pair.0
            let endIndex = pair.1

            // create codeblock string with break lines
            let type = lines[startIndex...endIndex].joined(separator: "\n")

            // if fragment is created successfully, we add it to the generatedFragments array
            if let fragment = generateFragment(for: type, fragmentSuffix: fragmentSuffix, declaredFragments: declaredFragments) {
                generatedFragments.append("\(fragment)\n")
            }
        }

        // finally, we return all the fragments as a multiline string
        return generatedFragments.joined(separator: "\n")
    }

    /// Create a fragment from a given object type (string block)
    private func generateFragment(for type: String, fragmentSuffix: String, declaredFragments: [String]) -> String? {
        // check string contains type
        guard type.hasPrefix("type") else { return nil }

        // separate string by linebreaks
        let lines = type
            .components(separatedBy: "\n")
            .compactMap{ return $0.contains("\"\"\"") ?  "  \($0.fromSchemaCommentToFragmentComment)" : $0 }

        // get type name
        guard let typeName = lines.first?.components(separatedBy: " ")[1] else { return nil }

        // create new fragment
        let fragmentName = typeName + fragmentSuffix

        // get properties by removing type / fragment definition and last '}'
        let properties = lines.dropFirst().dropLast()

        // is gonna store all the properties of each fragment
        var fragmentProperties = String()

        /// Iterate through properties
        for (index, property) in properties.enumerated() {

            guard let propertyName = property.components(separatedBy: ":").first else { break }

            guard let propertyType = property.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) else { break }

            var newPropertyLine = "\(propertyName)"

            // returns the fragment name if the property TYPE is the same
            let frag = declaredFragments.first { (declaredFragment) -> Bool in
                let fragmentToType = declaredFragment.replacingOccurrences(of: fragmentSuffix, with: "")

                return fragmentToType ==
                    propertyType
                        .replacingOccurrences(of: "!", with: "")
                        .replacingOccurrences(of: "[", with: "")
                        .replacingOccurrences(of: "]", with: "")
            }

            // if a fragment name was returned, we add {...<fragment-name>} as the "selection of subfields" of the property
            if let frag = frag {
                let fragString =
                """
                 {
                    ...\(frag)
                  }
                """
                newPropertyLine.append(fragString)
            }

            // adds a breakline if it's not the last property
            let breakLine = index == properties.count - 1 ? "" : "\n"

            let fragmentProperty = "\(newPropertyLine)\(breakLine)"

            // finally we populate the fragment properties
            fragmentProperties.append(fragmentProperty)
        }

        // creates the complete fragment block
        let newFragmentString =
        """
        fragment \(fragmentName) on \(typeName) {
        \(fragmentProperties)
        }
        """

        // return the block
        return newFragmentString
    }

}
