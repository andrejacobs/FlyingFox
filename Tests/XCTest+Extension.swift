//
//  XCTAssert+Extension.swift
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

import XCTest

func XCTAssertThrowsError<T, E: Error>(_ expression: @autoclosure () throws -> T,
                                       of type: E.Type,
                                       _ message: @autoclosure () -> String = "",
                                       file: StaticString = #filePath,
                                       line: UInt = #line,
                                       _ errorHandler: (_ error: E) -> Void = { _ in }) {
    XCTAssertThrowsError(try expression(), message(), file: file, line: line) {
        guard let error = $0 as? E else {
            XCTFail(message(), file: file, line: line)
            return
        }
        errorHandler(error)
    }
}

func XCTAssertThrowsError<T, E: Error>(_ expression: @autoclosure () async throws -> T,
                                       of type: E.Type,
                                       _ message: @autoclosure () -> String = "",
                                       file: StaticString = #filePath,
                                       line: UInt = #line,
                                       _ errorHandler: (_ error: E) -> Void = { _ in }) async {
    let result = await Result(catching: expression)
    XCTAssertThrowsError(try result.get(), message(), file: file, line: line) {
        guard let error = $0 as? E else {
            XCTFail(message(), file: file, line: line)
            return
        }
        errorHandler(error)
    }
}

private extension Result where Failure == Error {
    init(catching body: () async throws -> Success) async {
        do {
            self = .success(try await body())
        } catch {
            self = .failure(error)
        }
    }
}
