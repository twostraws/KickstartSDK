//
// JSONRequestBody.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
import Testing

/// Decodes captured HTTP request bodies into JSON objects for assertions.
enum JSONRequestBody {
    static func object(from request: URLRequest) throws -> [String: Any] {
        let body = try #require(request.httpBody)
        return try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
    }
}
