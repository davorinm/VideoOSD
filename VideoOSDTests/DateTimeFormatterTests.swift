//
//  DateTimeFormatterTests.swift
//  VideoOSDTests
//
//  Created by Davorin Mađarić on 10/12/2018.
//  Copyright © 2018 Davorin Madaric. All rights reserved.
//

import XCTest

class DateTimeFormatterTests: XCTestCase {
    
    func testFormatter() {
        XCTAssertEqual(DateTimeFormatter.formatTime(time: 1), "1:20")
        XCTAssertEqual(DateTimeFormatter.formatTime(time: 61), "1:20")
        XCTAssertEqual(DateTimeFormatter.formatTime(time: 121), "1:20")
        XCTAssertEqual(DateTimeFormatter.formatTime(time: 1000), "1:20")
    }
}
