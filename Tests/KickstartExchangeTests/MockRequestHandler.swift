//
// MockRequestHandler.swift
// KickstartSDK
// https://github.com/twostraws/KickstartSDK
// See LICENSE for license information.
//

import Foundation
@testable import KickstartExchange

/// Queues network results and records requests for asynchronous tests.
actor MockRequestHandler {
    /// The response tuple returned by the mock transport.
    typealias Response = (data: Data, statusCode: Int?, headers: [String: String])

    private var queuedResults: [Result<Response, URLError>]
    private var capturedRequests: [URLRequest] = []
    private var requestMilestones: [RequestMilestone] = []
    private var requestStartWaiters: [Int: [CheckedContinuation<Void, Never>]] = [:]
    private let suspendedRequestNumber: Int?
    private var suspendedRequest: CheckedContinuation<Void, Never>?

    init(
        _ results: [Result<Response, URLError>] = [],
        suspendedRequestNumber: Int? = nil
    ) {
        queuedResults = results
        self.suspendedRequestNumber = suspendedRequestNumber
    }

    func response(for request: URLRequest) async throws -> Response {
        capturedRequests.append(request)
        let requestNumber = capturedRequests.count
        requestMilestones.append(.started(requestNumber))
        let waiters = requestStartWaiters.removeValue(forKey: requestNumber) ?? []
        for waiter in waiters {
            waiter.resume()
        }
        defer {
            requestMilestones.append(.finished(requestNumber))
        }

        guard queuedResults.isEmpty == false else {
            throw URLError(.badServerResponse)
        }

        let result = queuedResults.removeFirst()
        if let suspendedRequestNumber,
           capturedRequests.count == suspendedRequestNumber {
            await withCheckedContinuation { continuation in
                suspendedRequest = continuation
            }
        }

        return try result.get()
    }

    func requests() -> [URLRequest] {
        capturedRequests
    }

    func waitUntilRequestStarts(_ requestNumber: Int) async {
        guard requestMilestones.contains(.started(requestNumber)) == false else {
            return
        }

        await withCheckedContinuation { continuation in
            requestStartWaiters[requestNumber, default: []].append(continuation)
        }
    }

    func milestones() -> [RequestMilestone] {
        requestMilestones
    }

    func resumeSuspendedRequest() {
        suspendedRequest?.resume()
        suspendedRequest = nil
    }
}
