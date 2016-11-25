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
import SwiftyTraverson

let contentTypeJsonHal = "application/hal+json"

let contentTypeJson = "application/json"

let host: String = "old-republic.com"

class BaseTests: XCTestCase {
  
  let timeout: TimeInterval = 30.0
  
  let fixtures: Fixtures = Fixtures()
  
  override func tearDown() {
    OHHTTPStubs.removeAllStubs()
    
    super.tearDown()
  }
}
