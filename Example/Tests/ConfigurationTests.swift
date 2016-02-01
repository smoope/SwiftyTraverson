/*
* Copyright 2016 smoope GmbH
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import XCTest
import OHHTTPStubs
import SwiftyJSON
import SwiftyTraverson

class ConfigurationTests: BaseTests {

  func testSetDefaultHeader() {
    stub(isHost(host)) { request in
      if let _ = request.valueForHTTPHeaderField("Default-Header") {
        return self.fixtures.root()
      } else {
        return self.fixtures.responseWithCode(404)
      }
    }
    
    let traverson = Traverson.Builder()
      .defaultHeader("Default-Header", value: "XXX")
      .build()
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .follow()
      .get { result, _ in
        test = result.data
      
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["_links"].dictionaryObject, "response should contain links")
      XCTAssertEqual(test["_links"].dictionaryObject!.count, 2, "response should contain 2 links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testSetDefaultHeaders() {
    stub(isHost(host)) { request in
      if let _ = request.valueForHTTPHeaderField("Default-Header") {
        return self.fixtures.root()
      } else {
        return self.fixtures.responseWithCode(404)
      }
    }
    
    let traverson = Traverson.Builder()
      .defaultHeaders(["Default-Header": "XXX"])
      .build()
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .follow()
      .get { result, _ in
        test = result.data
      
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["_links"].dictionaryObject, "response should contain links")
      XCTAssertEqual(test["_links"].dictionaryObject!.count, 2, "response should contain 2 links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testSetWithExceededTimeout() {
    stub(isHost(host)) { _ in
      return self.fixtures.root().requestTime(2.0, responseTime: 5.0)
    }
    
    let traverson = Traverson.Builder()
      .requestTimeout(1.0)
      .responseTimeout(1.0)
      .build()
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    var testError: ErrorType?
    traverson
      .from("http://\(host)")
      .follow("jedi")
      .get { result, error in
        test = result.data
        testError = error
        
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)

    XCTAssertNil(test, "response should not exists")
    XCTAssertNotNil(testError, "response should contain error")
  }
  
  func testSetWithTimeout() {
    stub(isHost(host)) { _ in
      return self.fixtures.root().requestTime(2.0, responseTime: 5.0)
    }
    
    let traverson = Traverson.Builder()
      .requestTimeout(10.0)
      .responseTimeout(10.0)
      .build()
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .follow("jedi")
      .get { result, _ in
        test = result.data
      
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["_links"].dictionaryObject, "response should contain links")
      XCTAssertEqual(test["_links"].dictionaryObject!.count, 2, "response should contain 2 links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testSetAuthenticator() {
    stub(isHost(host)) { request in
      if let _ = request.valueForHTTPHeaderField("Authorization") {
        return self.fixtures.root()
      } else {
        return self.fixtures.responseWithCode(404)
      }
    }
    
    let traverson = Traverson.Builder()
      .authenticator(TraversonBasicAuthenticator(username: "username", password: "password"))
      .build()
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .follow()
      .get { result, _ in
        test = result.data
        
        expectation.fulfill()
    }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["_links"].dictionaryObject, "response should contain links")
      XCTAssertEqual(test["_links"].dictionaryObject!.count, 2, "response should contain 2 links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testWithHeader() {
    stub(isHost(host)) { request in
      if let _ = request.valueForHTTPHeaderField("Default-Header") {
        return self.fixtures.root()
      } else {
        return self.fixtures.responseWithCode(404)
      }
    }
    
    let traverson = Traverson.Builder().build()
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .follow()
      .withHeader("Default-Header", value: "XXX")
      .get { result, _ in
        test = result.data
      
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["_links"].dictionaryObject, "response should contain links")
      XCTAssertEqual(test["_links"].dictionaryObject!.count, 2, "response should contain 2 links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testWithHeaders() {
    stub(isHost(host)) { request in
      if let _ = request.valueForHTTPHeaderField("Default-Header") {
        return self.fixtures.root()
      } else {
        return self.fixtures.responseWithCode(404)
      }
    }
    
    let traverson = Traverson.Builder().build()
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .follow()
      .withHeaders(["Default-Header": "XXX"])
      .get { result, _ in
        test = result.data
        
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["_links"].dictionaryObject, "response should contain links")
      XCTAssertEqual(test["_links"].dictionaryObject!.count, 2, "response should contain 2 links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func withTemplateParameter() {
    stub(isHost(host) && isPath("/jedi") && containsQueryParams(["page": "1"])) { request in
      return self.fixtures.root()
    }
    
    let traverson = Traverson.Builder().build()
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .follow("jedi")
      .withTemplateParameter("page", value: "1")
      .get { result, _ in
        test = result.data
        
        expectation.fulfill()
    }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["_links"].dictionaryObject, "response should contain links")
      XCTAssertEqual(test["_links"].dictionaryObject!.count, 2, "response should contain 2 links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func withTemplateParameters() {
    let params = ["page": "1", "sort": "color,desc"]
    
    stub(isHost(host) && isPath("/jedi") && containsQueryParams(params)) { request in
      return self.fixtures.root()
    }
    
    let traverson = Traverson.Builder().build()
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .follow("jedi")
      .withTemplateParameters(params)
      .get { result, _ in
        test = result.data
        
        expectation.fulfill()
    }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["_links"].dictionaryObject, "response should contain links")
      XCTAssertEqual(test["_links"].dictionaryObject!.count, 2, "response should contain 2 links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
}