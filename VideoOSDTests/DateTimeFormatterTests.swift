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
        XCTAssertEqual(DateTimeFormatter.formatTime(time: 1), "00:01")
        XCTAssertEqual(DateTimeFormatter.formatTime(time: 61), "01:01")
        XCTAssertEqual(DateTimeFormatter.formatTime(time: 121), "02:01")
        XCTAssertEqual(DateTimeFormatter.formatTime(time: 1000), "16:40")
    }
}
