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

class TraversingJsonGetTests: BaseTraversingTests {
  
  func testFollowUrl() {
    stub(condition: isHost(host)) { _ in
      return self.fixtures.root(type: Fixtures.MediaType.json)
    }
    
    let expectation = self.expectation(description: "request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .json()
      .followUri("http://\(host)/some")
      .get { result, _ in
        test = result!.data
        
        expectation.fulfill()
      }
    
    self.waitForExpectations(timeout: self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["self"].string, "response should contain links")
      XCTAssertNotNil(test["jedi"].string, "response should contain links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testFollowRoot() {
    stub(condition: isHost(host)) { _ in
      return self.fixtures.root(type: Fixtures.MediaType.json)
    }
    
    let expectation = self.expectation(description: "request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .json()
      .follow()
      .get { result, _ in
        test = result!.data
        
        expectation.fulfill()
      }
    
    self.waitForExpectations(timeout: self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["self"].string, "response should contain links")
      XCTAssertNotNil(test["jedi"].string, "response should contain links")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testFollowRelation() {
    var calls = 0
    stub(condition: isHost(host)) { _ in
      calls += 1
      
      switch calls {
      case 1:
        return self.fixtures.root(type: Fixtures.MediaType.json)
      case 2:
        return self.fixtures.collection(type: Fixtures.MediaType.json)
      default:
        return self.fixtures.responseWithCode(404, type: Fixtures.MediaType.json)
      }
    }
    
    let expectation = self.expectation(description: "request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .json()
      .follow("jedi")
      .get { result, _ in
        test = result!.data
        
        expectation.fulfill()
      }
    
    self.waitForExpectations(timeout: self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertEqual(test["jedi"].arrayObject?.count, 2, "response should contain pagination details")
      XCTAssertNotNil(test["next"].string, "response should contain link")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testFollowInnerRelation() {
    var calls = 0
    stub(condition: isHost(host)) { _ in
      calls += 1
      
      switch calls {
      case 1:
        return self.fixtures.root(type: Fixtures.MediaType.json)
      case 2:
        return self.fixtures.collection(type: Fixtures.MediaType.json)
      case 3:
        return self.fixtures.collection(type: Fixtures.MediaType.json)
      default:
        return self.fixtures.responseWithCode(404, type: Fixtures.MediaType.json)
      }
    }
    
    let expectation = self.expectation(description: "request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .json()
      .follow("jedi", "next")
      .get { result, _ in
        test = result!.data
        
        expectation.fulfill()
      }
    
    self.waitForExpectations(timeout: self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertEqual(test["jedi"].arrayObject?.count, 2, "response should contain pagination details")
      XCTAssertNotNil(test["next"].string, "response should contain link")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
  
  func testFollowInnerRelationWithWrongRelation() {
    var calls = 0
    stub(condition: isHost(host)) { _ in
      calls += 1
      
      switch calls {
      case 1:
        return self.fixtures.root(type: Fixtures.MediaType.json)
      case 2:
        return self.fixtures.collection(type: Fixtures.MediaType.json)
      case 3:
        return self.fixtures.collection(type: Fixtures.MediaType.json)
      default:
        return self.fixtures.responseWithCode(404, type: Fixtures.MediaType.json)
      }
    }
    
    let expectation = self.expectation(description: "request should succeed")
    
    var test: TraversonResult?
    var testError: Error?
    traverson
      .from("http://\(host)")
      .json()
      .follow("jedi", "wrong")
      .get { result, error in
        test = result
        testError = error
        
        expectation.fulfill()
      }
    
    self.waitForExpectations(timeout: self.timeout, handler: nil)
    
    XCTAssertNil(test?.data, "response should not exists")
    XCTAssertNotNil(testError, "response should contain error")
  }
}
