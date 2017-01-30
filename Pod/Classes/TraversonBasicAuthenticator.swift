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

import Foundation

/**
  HTTP basic authentication authenticator
 */
open class TraversonBasicAuthenticator: TraversonAuthenticator {
  
  var username: String
  
  var password: String
  
  open var retries = 2
  
  public init(username: String, password: String) {
    self.username = username
    self.password = password
  }
  
  open func authenticate(_ result: @escaping TraversonAuthenticatorResult) {
    let credentials = "\(username):\(password)".data(using: String.Encoding.utf8)!
    let base64Credentials = credentials.base64EncodedString(options: [])
    
    result("Basic \(base64Credentials)")
  }
}
