//
//  HTTPRequestDecoderTests.swift
//  FlyingFox
//
//  Created by Simon Whitty on 17/02/2022.
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
import Foundation
import XCTest

final class HTTPRequestDecoderTests: XCTestCase {

    func testGETMethod_IsParsed() async throws {
        let request = try await HTTPRequestDecoder.decodeRequestFromString(
            """
            GET /hello HTTP/1.1\r
            \r
            """
        )

        XCTAssertEqual(
            request.method,
            .GET
        )
    }

    func testPOSTMethod_IsParsed() async throws {
        let request = try await HTTPRequestDecoder.decodeRequestFromString(
            """
            POST /hello HTTP/1.1\r
            \r
            """
        )

        XCTAssertEqual(
            request.method,
            .POST
        )
    }

    func testCUSTOMMethod_IsParsed() async throws {
        let request = try await HTTPRequestDecoder.decodeRequestFromString(
            """
            FISH /hello HTTP/1.1\r
            \r
            """
        )

        XCTAssertEqual(
            request.method,
            HTTPMethod("FISH")
        )
    }

    func testPath_IsParsed() async throws {
        let request = try await HTTPRequestDecoder.decodeRequestFromString(
            """
            GET /hello/world?fish=Chips&with=Mushy%20Peas HTTP/1.1\r
            \r
            """
        )

        XCTAssertEqual(
            request.path,
            "/hello/world"
        )

        XCTAssertEqual(
            request.query,
            [.init(name: "fish", value: "Chips"),
             .init(name: "with", value: "Mushy Peas")]
        )
    }

    func testHeaders_AreParsed() async throws {
        let request = try await HTTPRequestDecoder.decodeRequestFromString(
            """
            GET /hello HTTP/1.1\r
            Fish: Chips\r
            Connection: Keep-Alive\r
            content-type: none\r
            \r
            """
        )

        XCTAssertEqual(
            request.headers,
            [HTTPHeader("Fish"): "Chips",
             HTTPHeader("Connection"): "Keep-Alive",
             HTTPHeader("Content-Type"): "none"]
        )
    }

    func testBody_IsNotParsed_WhenContentLength_IsNotProvided() async throws {
        let request = try await HTTPRequestDecoder.decodeRequestFromString(
            """
            GET /hello HTTP/1.1\r
            \r
            Hello
            """
        )

        XCTAssertEqual(
            request.body,
            Data()
        )
    }

    func testBody_IsParsed_WhenContentLength_IsProvided() async throws {
        let request = try await HTTPRequestDecoder.decodeRequestFromString(
            """
            GET /hello HTTP/1.1\r
            Content-Length: 5\r
            \r
            Hello
            """
        )

        XCTAssertEqual(
            request.body,
            "Hello".data(using: .utf8)
        )
    }

    func testInvalidStatusLine_ThrowsErrorM() async throws {
        do {
            _ = try await HTTPRequestDecoder.decodeRequestFromString(
                """
                GET/hello HTTP/1.1\r
                \r
                """
            )
            XCTFail("Expected Error")
        } catch {
            XCTAssertTrue(error is HTTPRequestDecoder.Error)
        }
    }

}

private extension HTTPRequestDecoder {
    static func decodeRequestFromString(_ string: String) async throws -> HTTPRequest {
        try await decodeRequest(from: ConsumingAsyncSequence(string.data(using: .utf8)!))
    }
}
