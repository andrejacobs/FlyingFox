//
//  SocketTests.swift
//  FlyingFox
//
//  Created by Simon Whitty on 22/02/2022.
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

final class SocketTests: XCTestCase {

    func testSocketReads_DataThatIsSent() throws {
        let (s1, s2) = try Socket.makeNonBlockingPair()

        let data = Data([10, 20])
        _ = try s1.write(data, from: data.startIndex)

        XCTAssertEqual(try s2.read(), 10)
        XCTAssertEqual(try s2.read(), 20)
    }

    func testSocketRead_ThrowsBlocked_WhenNoDataIsAvailable() throws {
        let (s1, s2) = try Socket.makeNonBlockingPair()

        XCTAssertThrowsError(try s1.read(), of: SocketError.self) {
            XCTAssertEqual($0, .blocked)
        }

        try s1.close()
        try s2.close()
    }

    func testSocketRead_ThrowsDisconnected_WhenSocketIsClosed() throws {
        let (s1, s2) = try Socket.makeNonBlockingPair()
        try s1.close()
        try s2.close()

        XCTAssertThrowsError(try s1.read(), of: SocketError.self) {
            XCTAssertEqual($0, .disconnected)
        }
    }

    func testSocket_Sets_And_Gets_Int32Option() throws {
        let socket = try Socket(domain: AF_UNIX, type: Socket.stream)

        try socket.setValue(2048, for: .receiveBufferSize)
#if canImport(Darwin)
        XCTAssertEqual(try socket.getValue(for: .receiveBufferSize), Int32(2048))
#else
        // Linux kernel doubles this value (to allow space for bookkeeping overhead)
        XCTAssertEqual(try socket.getValue(for: .receiveBufferSize), Int32(4096))
#endif
    }

    func testSocket_Sets_And_Gets_BoolOption() throws {
        let socket = try Socket(domain: AF_UNIX, type: Socket.stream)

        try socket.setValue(true, for: .localAddressReuse)
        XCTAssertEqual(try socket.getValue(for: .localAddressReuse), true)

        try socket.setValue(false, for: .localAddressReuse)
        XCTAssertEqual(try socket.getValue(for: .localAddressReuse), false)
    }

    func testSocket_Sets_And_Gets_Flags() throws {
        let socket = try Socket(domain: AF_UNIX, type: Socket.stream)
        XCTAssertFalse(socket.flags.contains(.append))

        try socket.setFlags(.append)
        XCTAssertTrue(socket.flags.contains(.append))
    }

    func testSocketAccept_ThrowsError_WhenInvalid() throws {
        let socket = Socket(file: -1)
        XCTAssertThrowsError(
            try socket.accept()
        )
    }

    func testSocketClose_ThrowsError_WhenInvalid() throws {
        let socket = Socket(file: -1)
        XCTAssertThrowsError(
            try socket.close()
        )
    }

    func testSocketListen_ThrowsError_WhenInvalid() throws {
        let socket = Socket(file: -1)
        XCTAssertThrowsError(
            try socket.listen()
        )
    }

    func testSocketBindIP6_ThrowsError_WhenInvalid() throws {
        let socket = Socket(file: -1)
        XCTAssertThrowsError(
            try socket.bindIP6(port: 8080)
        )
    }
}

extension Socket.Flags {
    static let append = Socket.Flags(rawValue: O_APPEND)
}
