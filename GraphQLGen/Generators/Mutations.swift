//
//  Mutations.swift
//  GraphQLGen
//
//  Created by Manuel on 23/05/20.
//  Copyright © 2020 manuelbulos. All rights reserved.
//

import Foundation

/*
 This code turns mutation types into mutations

 Example:

 This:

 type Mutation {
    user(userId: String): User
 }

 Becomes:

 mutation user($userId: String) {
    user(userId: $userId) {
      ...UserFragment
    }
 }
 */

/// Helper that returns a collection of mutations from a given SDL file (schema.graphql)
struct MutationGenerator {

    let declaredFragments: [String]

    let fragmentSuffix: String

    func generateMutations(for input: String) -> String {

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
        // ignoring enums, object types, and queries
        var mutationPairs = Array<Zip2Sequence<[Int], [Int]>.Element>()

        // helps us store all fragment names (fragmentName + suffix)

        // iterate through all pairs to populate "typePairs" array
        for pair in pairs {
            let startIndex = pair.0
            let firstLine = lines[startIndex].description
            let isEnum = firstLine.contains("enum")
            let isType = firstLine.contains("type")
            let isMutation = firstLine.contains("Mutation")
            let isQuery = firstLine.contains("Query")

            if isEnum || isQuery {
                // ignore the pair cause its not a mutation type
            } else if isType && isMutation {
                // store the mutation type
                mutationPairs.append(pair)
            }
        }

        // array that will store all generated mutations
        var generatedMutations = [String]()

        // iterate through all typePairs to populate "generatedMutations" array
        for pair in mutationPairs {
            let startIndex = pair.0
            let endIndex = pair.1

            // create codeblock string with break lines
            let mutationBlock = lines[startIndex...endIndex].joined(separator: "\n")

            let mutationDefinitions = mutationBlock
                .components(separatedBy: "\n")
                .dropFirst()
                .dropLast()

            mutationDefinitions.forEach { (mutationDefinition) in
                if let mutation = generateMutation(for: mutationDefinition) {
                    generatedMutations.append("\(mutation)\n")
                }
            }
        }

        // finally, we return all the mutations as a multiline string
        return generatedMutations.joined(separator: "\n")
    }

    /// Create a mutation from a given mutation type (string block)
    private func generateMutation(for mutationDefinition: String) -> String? {
        // separate mutation between name, arguments, and result type
        let components = mutationDefinition.components(separatedBy: ": ")

        // get mutation name
        guard let name = components.first?
            .components(separatedBy: "(").first?
            .trimmingCharacters(in: .whitespaces)
            else { return nil }

        // get mutation result type
        guard let resultType = components.last else { return nil }

        let fixedResultType = resultType
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")

        // get fragment if result type is the same
        let fragment = declaredFragments.first(where: { $0 == fixedResultType + fragmentSuffix })

        var firstLine = "mutation \(name)"

        var secondLine = name

        if let variables = mutationDefinition.slice(from: "(", to: ")")?.components(separatedBy: ",") {
            let topVariables = variables.compactMap({ "$\($0.trimmingCharacters(in: .whitespaces))" })
            let topVariablesString = topVariables.joined(separator: ", ")
            firstLine.append("(\(topVariablesString))")

            let bottomVariables = variables.compactMap { $0.components(separatedBy: ":") }
            let bottomVariblesString = bottomVariables.compactMap { (pair) -> String? in
                let variableName = pair.first!.trimmingCharacters(in: .whitespaces)
                return "\(variableName): $\(variableName)"
            }.joined(separator: ", ")
            secondLine.append("(\(bottomVariblesString))")
        }

        var thirdLine = name

        if let fragment = fragment {
            thirdLine = "...\(fragment)"
        }

        let mutationBlockWithFragment =
        """
        \(firstLine) {
          \(secondLine) {
            \(thirdLine)
          }
        }
        """

        let mutationBlock =
        """
        \(firstLine) {
          \(secondLine)
        }
        """

        // return the block
        return fragment != nil ? mutationBlockWithFragment : mutationBlock
    }

}
