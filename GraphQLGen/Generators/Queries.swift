//
//  Queries.swift
//  GraphQLGen
//
//  Created by Manuel on 23/05/20.
//  Copyright © 2020 manuelbulos. All rights reserved.
//

import Foundation

/*
 This code turns query types into queries

 Example:

 This:

 type Query {
    user(userId: String): User
 }

 Becomes:

 query user($userId: String) {
    user(userId: $userId) {
        ...UserFragment
    }
 }
 */

/// Helper that returns a collection of queries from a given SDL file (schema.graphql)
struct QueryGenerator {

    let declaredFragments: [String]

    let fragmentSuffix: String

    func generateQueries(for input: String) -> String {

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
        // ignoring enums, object types, and mutations
        var queryPairs = Array<Zip2Sequence<[Int], [Int]>.Element>()

        // iterate through all pairs to populate "typePairs" array
        for pair in pairs {
            let startIndex = pair.0
            let firstLine = lines[startIndex].description
            let isEnum = firstLine.contains("enum")
            let isType = firstLine.contains("type")
            let isMutation = firstLine.contains("Mutation")
            let isQuery = firstLine.contains("Query")

            if isEnum || isMutation {
                // ignore the pair cause its not a query type
            } else if isType && isQuery {
                // store the query type
                queryPairs.append(pair)
            }
        }

        // array that will store all generated queries
        var generatedQueries = [String]()

        // iterate through all typePairs to populate "generatedQueries" array
        for pair in queryPairs {
            let startIndex = pair.0
            let endIndex = pair.1

            // create codeblock string with break lines
            let queryBlock = lines[startIndex...endIndex].joined(separator: "\n")

            let queryDefinitions = queryBlock
                .components(separatedBy: "\n")
                .dropFirst()
                .dropLast()

            queryDefinitions.forEach { (queryDefinition) in
                if let query = generateQuery(for: queryDefinition) {
                    generatedQueries.append("\(query)\n")
                }
            }
        }

        // finally, we return all the queries as a multiline string
        return generatedQueries.joined(separator: "\n")
    }

    /// Create a query from a given query type (string block)
    private func generateQuery(for queryDefinition: String) -> String? {
        // separate query between name, arguments, and result type
        let components = queryDefinition.components(separatedBy: ": ")

        // get query name
        guard let name = components.first?
            .components(separatedBy: "(").first?
            .trimmingCharacters(in: .whitespaces)
            else { return nil }

        // get query result type
        guard let resultType = components.last else { return nil }

        let fixedResultType = resultType
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")

        // get fragment if result type is the same
        let fragment = declaredFragments.first(where: { $0 == fixedResultType + fragmentSuffix })

        var firstLine = "query \(name)"

        var secondLine = name

        if let variables = queryDefinition.slice(from: "(", to: ")")?.components(separatedBy: ",") {
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

        let queryBlockWithFragment =
        """
        \(firstLine) {
          \(secondLine) {
            \(thirdLine)
          }
        }
        """

        let queryBlock =
        """
        \(firstLine) {
          \(secondLine)
        }
        """

        // return the block
        return fragment != nil ? queryBlockWithFragment : queryBlock
    }

}
