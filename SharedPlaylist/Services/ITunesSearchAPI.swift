//
//  ITunesSearchAPI.swift
//  SharedPlaylist
//
//  Created by Dmitry Borodin on 23.02.2021.
//

import Foundation
import Moya

enum ITunesSearchAPI {
    case songs(query: String)
}

extension ITunesSearchAPI: TargetType {
    var baseURL: URL {
        URL(string: "https://itunes.apple.com")!
    }
    
    var path: String {
        switch self {
        case .songs:
            return "/search"
        }
    }
    
    var method: Moya.Method {
        .get
    }
    
    var sampleData: Data {
        Data()
    }
    
    var task: Task {
        switch self {
        case .songs(let query):
            let parameters: [String: Any] = [
                "term": searchTerm(from: query),
                "entity": "song"
            ]
            return .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        }
        
    }
    
    var headers: [String : String]? {
        ["Content-type": "application/json"]
    }
    
    private func searchTerm(from query: String) -> String {
        query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "+")
    }
}
