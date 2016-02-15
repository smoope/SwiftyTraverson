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

class TraversingJsonPutTests: BaseTraversingTests {
  
  let objectToUpdate: Dictionary<String, AnyObject> = ["name": "Darth Vader"]
  
  func testFollowUrl() {
    stub(isHost(host)) { _ in
      return self.fixtures.item(type: Fixtures.MediaType.json)
    }
    
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .json()
      .followUri("http://\(host)/some")
      .put(objectToUpdate) { result, _ in
        test = result!.data
        
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["id"].int, "response should contain payload")
      XCTAssertNotNil(test["name"].string, "response should contain payload")
      XCTAssertNotNil(test["lightSaber"].string, "response should contain link")
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
        return self.fixtures.root(type: Fixtures.MediaType.json)
      case 2:
        return self.fixtures.item(type: Fixtures.MediaType.json)
      default:
        return self.fixtures.responseWithCode(404, type: Fixtures.MediaType.json)
      }
    }
    
    let expectation = self.expectationWithDescription("request should succeed")
    
    var test: JSON?
    traverson
      .from("http://\(host)")
      .json()
      .follow("jedi")
      .put(objectToUpdate) { result, _ in
        test = result!.data
        
        expectation.fulfill()
      }
    
    self.waitForExpectationsWithTimeout(self.timeout, handler: nil)
    
    if let test = test {
      XCTAssertNotNil(test["id"].int, "response should contain payload")
      XCTAssertNotNil(test["name"].string, "response should contain payload")
      XCTAssertNotNil(test["lightSaber"].string, "response should contain link")
    } else {
      XCTAssertNotNil(test, "response should exists")
    }
  }
}
