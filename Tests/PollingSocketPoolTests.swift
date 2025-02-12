//
//  PollingSocketPoolTests.swift
//  FlyingFox
//
//  Created by Simon Whitty on 23/02/2022.
//  Copyright © 2022 Simon Whitty. All rights reserved.
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/swhitty/FlyingFox
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

@testable import FlyingFox
import XCTest

final class PollingSocketPoolTests: XCTestCase {

    func testPoolThowsError_WhenAlreadyRunning() async throws {
        let pool = PollingSocketPool()

        let task = Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await pool.run()
                }
                group.addTask {
                    try await pool.run()
                }
                try await group.waitForAll()
            }
        }

        await XCTAssertThrowsError(try await task.value, of: PollingSocketPool.Error.self)
        task.cancel()
    }

    func testPollingInterval() async throws {
        XCTAssertEqual(
            PollingSocketPool.Interval.immediate.milliseconds,
            0
        )

        XCTAssertEqual(
            PollingSocketPool.Interval.seconds(1).milliseconds,
            1000
        )
    }

    func testSuspendedSockets_ThrowError_WhenCancelled() async throws {
        let pool = PollingSocketPool()

        let task = Task {
            let socket = try Socket(domain: AF_UNIX, type: Socket.stream)
            try await pool.suspend(untilReady: socket, for: .read)
        }

        task.cancel()

        await XCTAssertThrowsError(try await task.value, of: CancellationError.self)
    }

    func testCancellingPollingPool_CancelsSockets() async throws {
        let pool = PollingSocketPool()

        let task = Task {
            let socket = try Socket(domain: AF_UNIX, type: Socket.stream)
            try await pool.suspend(untilReady: socket, for: .read)
        }

        _ = Task(timeout: 0.5) {
            try await pool.run()
        }

        await XCTAssertThrowsError(try await task.value, of: CancellationError.self)
    }
}
