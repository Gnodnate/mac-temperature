//
//  TemperatureTests.swift
//  TemperatureTests
//
//  Created by Gondnat on 2018/8/29.
//  Copyright © 2018 Destiny. All rights reserved.
//

import XCTest
import Temperature

class TemperatureTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testKeyWord() {
        let keys = ["TC0P", "TC1P", "TC2P", "TCP", "TG0P", "TH0P", "TG0D", "TG0H", "Th0H", "TM0S", "TC0F"]
        for key in keys {
            print("\(key) : \(SMCWrapper.shared().float(forKey: key))")
        }
    }
}
