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

class TraversingGetTests: BaseTraversingTests {
  
  func testFollowUrl() {
    stub(isHost(host)) { _ in
      return self.fixtures.root()
    }
    
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .followUri("http://\(host)/some")
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
  
  func testFollowRoot() {
    stub(isHost(host)) { _ in
      return self.fixtures.root()
    }
    
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
  
  func testFollowRelation() {
    var calls = 0
    stub(isHost(host)) { _ in
      calls += 1
      
      switch calls {
      case 1:
        return self.fixtures.root()
      case 2:
        return self.fixtures.collection()
      default:
        return self.fixtures.responseWithCode(404)
      }
    }
    
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
      XCTAssertNotNil(test["page"].dictionaryObject, "response should contain pagination details")
      XCTAssertEqual(test["_embedded"]["jedi"].arrayObject?.count, 2, "response should contain pagination details")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testFollowInnerRelation() {
    var calls = 0
    stub(isHost(host)) { _ in
      calls += 1
      
      switch calls {
      case 1:
        return self.fixtures.root()
      case 2:
        return self.fixtures.collection()
      case 3:
        return self.fixtures.collection()
      default:
        return self.fixtures.responseWithCode(404)
      }
    }
    
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .follow("jedi", "next")
      .get { result, _ in
        test = result.data
        
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["_links"].dictionaryObject, "response should contain links")
      XCTAssertEqual(test["_links"].dictionaryObject!.count, 2, "response should contain 2 links")
      XCTAssertNotNil(test["page"].dictionaryObject, "response should contain pagination details")
      XCTAssertEqual(test["_embedded"]["jedi"].arrayObject?.count, 2, "response should contain pagination details")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testFollowInnerRelationWithWrongRelation() {
    var calls = 0
    stub(isHost(host)) { _ in
      calls += 1
      
      switch calls {
      case 1:
        return self.fixtures.root()
      case 2:
        return self.fixtures.collection()
      case 3:
        return self.fixtures.collection()
      default:
        return self.fixtures.responseWithCode(404)
      }
    }
    
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: TraversonResult?
    var testError: ErrorType?
    traverson
      .from("http://\(host)")
      .follow("jedi", "wrong")
      .get { result, error in
        test = result
        testError = error
        
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    XCTAssertNil(test?.data, "response should not exists")
    XCTAssertNotNil(testError, "response should contain error")
  }
}
