//
//  main.swift
//  JSON2CSV
//
//  Created by Alex on 07.06.18.
//  Copyright © 2018 Alexander Dobrynin. All rights reserved.
//

import Foundation

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

typealias JSON = [String: Any]
typealias JSONArray = [JSON]

enum OutputType {
    case error
    case standard
}

func writeMessage(_ message: String, to: OutputType = .standard) {
    switch to {
    case .standard:
        print(message)
    case .error:
        fputs("Error: \(message)\n", stderr)
    }
}

if let executableName = CommandLine.arguments.first, CommandLine.arguments.count == 1 {
    writeMessage("Usage: \(executableName) /path/to/source.json /path/to/dest.csv")
} else {
    let fm = FileManager.default
    
    let firstParam = CommandLine.arguments[safe: 1]
    let secondParam = CommandLine.arguments[safe: 2]
    
    if let source = firstParam, let data = fm.contents(atPath: source), let jsonArray = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? JSONArray, jsonArray.count >= 1 {
        if let dest = secondParam {
            let base = jsonArray.first!.reduce(into: "", { (res: inout String, json) in
                let (key, value) = json
                
                let header: String
                
                if let sj = value as? JSON {
                    let subString = sj.reduce(into: "") { (sRes: inout String, sjj) in
                        let (sK, _) = sjj
                        sRes.append("\(key)/\(sK),")
                        }.dropLast()
                    
                    header = String(subString)
                } else {
                    header = key
                }
                
                res.append("\(header),")
            }).dropLast().appending("\n")
            
            let csvString = jsonArray.reduce(into: base) { (res: inout String, j) in
                let entry = j.reduce(into: "") { (res: inout String, jj) in
                    let (_, value) = jj
                    
                    let footer: Any
                    
                    if let sj = value as? JSON {
                        let subString = sj.reduce(into: "") { (sRes: inout String, sjj) in
                            let (_, sV) = sjj
                            sRes.append("\(sV),")
                            }.dropLast()
                        
                        footer = String(subString)
                    } else {
                        footer = value
                    }
                    
                    res.append("\(footer),")
                }
                
                res.append("\(entry)\n")
                }.dropLast()
            
            if fm.createFile(atPath: dest, contents: csvString.data(using: .utf8), attributes: nil) {
                writeMessage("successfully created file at \(dest)", to: .standard)
            } else {
                writeMessage("failed to create file at \(dest)", to: .error)
            }
            
        } else {
            writeMessage("second parameter needs to be a destination", to: .error)
        }
    } else {
        writeMessage("first parameter needs to be a valid path to JSON file", to: .error)
    }
}


