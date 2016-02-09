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
import SwiftyJSON

/**
  HATEOAS media type response link resolver
 */
public class TraversonJsonHalLinkResolver: TraversonLinkResolver {
  
  public init() { }
  
  public func findNext(rel: String, data: JSON) throws -> String {
    guard let next = data["_links"][rel]["href"].string else { throw TraversonException.RelationNotFound(relation: rel) }
    return next
  }
}