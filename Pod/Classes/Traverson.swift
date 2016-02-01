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
import Alamofire
import URITemplate
import SwiftyJSON

/**
    Swift implementation of a Hypermedia API/HATEOAS client
 */
public class Traverson {
  
  private var client: Alamofire.Manager
  
  private var authenticator: TraversonAuthenticator?
  
  private var authentication: String?
  
  /**
    Constructor with parameters
   
    - Parameters:
      - configuration: Configuration
      - authenticator: Authenticator
   */
  private init(configuration: NSURLSessionConfiguration, authenticator: TraversonAuthenticator? = nil) {
    self.client = Alamofire.Manager(configuration: configuration)
    self.authenticator = authenticator
  }
  
  /**
    Constructor with parameters
  */
  public convenience init() {
    self.init(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
  }
  
  /**
    Authenticates requests if needed
  */
  private func authenticate() {
    if let auth = authenticator {
      if authentication == nil {
        authentication = auth.authenticate()
      }
    }
  }
  
  /*
    Sets the base URL
  
    - Parameter baseUri: URL to start wit
  
    - Returns: Traversing object
  */
  public func from(baseUri: String) -> Traversing {
    authenticate()
    
    return Traversing(baseUri: baseUri, client: client, authentication: authentication)
  }
  
  /**
    Result callback object
  */
  public typealias TraversonResultHandler = (result: TraversonResult, error: ErrorType?) -> Void
  
  /**
    Traverson builder
  */
  public class Builder {
    
    private var configuration: NSURLSessionConfiguration
    
    private var defaultHeaders: Dictionary<NSObject, AnyObject>
    
    private var useCache: Bool
    
    private var requestTimeout: NSTimeInterval
    
    private var responseTimeout: NSTimeInterval
    
    private var authenticator: TraversonAuthenticator?
    
    public init() {
      self.configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
      self.defaultHeaders = self.configuration.HTTPAdditionalHeaders ?? Dictionary<NSObject, AnyObject>()
      self.useCache = true
      self.requestTimeout = self.configuration.timeoutIntervalForRequest
      self.responseTimeout = self.configuration.timeoutIntervalForResource
    }
    
    /**
      Adds default headers collection
     
      - Parameters defaultHeaders: Collection of default headers to use
     */
    public func defaultHeaders(defaultHeaders: Dictionary<String, String>) -> Builder {
      self.defaultHeaders = defaultHeaders
      
      return self
    }
    
    /**
      Adds default header
     
      - Parameters:
      - name: Header's name
      - value: Header's value
     */
    public func defaultHeader(name: String, value: String) -> Builder {
      defaultHeaders[name] = value
      
      return self
    }
    
    /**
      Disables cache
     */
    public func disableCache() -> Builder {
      useCache  = false
      
      return self
    }
    
    /**
      Sets read timeout
     
      - Parameter timout: Request timeout
    */
    public func requestTimeout(timeout: NSTimeInterval) -> Builder {
      requestTimeout = timeout
      
      return self
    }
    
    /**
      Sets read timeout
    
      - Parameter timout: Response timeout
    */
    public func responseTimeout(timeout: NSTimeInterval) -> Builder {
      responseTimeout = timeout
      
      return self
    }

    /**
     Sets authenticator object
     
     - Parameter authenticator: Authenticator
     */
    public func authenticator(authenticator: TraversonAuthenticator) -> Builder {
      self.authenticator = authenticator
      
      return self
    }
    
    /**
      Builds the Traverson object with custom configuration
    */
    public func build() -> Traverson {
      configuration.HTTPAdditionalHeaders = defaultHeaders
      configuration.timeoutIntervalForRequest = requestTimeout
      configuration.timeoutIntervalForResource = responseTimeout
      if !useCache {
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
      }
      
      return Traverson(configuration: configuration, authenticator: authenticator)
    }
  }
  
  public class Traversing {
    
    private var baseUri: String
    
    private var client: Alamofire.Manager
    
    private var rels: Array<String>
    
    private var headers: Dictionary<String, String>
    
    private var templateParameters: Dictionary<String, String>
  
    private var follow201Location:Bool = false
    
    private var traverse:Bool = true
    
    private typealias ResolveUrlHandler = (url: String?, error: ErrorType?) -> Void
    
    private init(baseUri: String, client: Alamofire.Manager, authentication: String?) {
      self.baseUri = baseUri
      self.client = client
      self.rels = Array()
      self.headers = Dictionary()
      self.templateParameters = Dictionary()
      if let auth = authentication {
        self.headers["Authorization"] = auth
      }
    }
    
    //todo Implement object-to-json serialization instead of using Dictionary
    private func prepareRequest(url: String, method: TraversonRequestMethod, object: Dictionary<String, AnyObject>? = nil) -> Request {
      switch method {
      case .GET:
        return client.request(.GET, url, headers: headers)
      case .POST:
        return client.request(.POST, url, parameters: object, encoding: .JSON, headers: headers)
      case .PUT:
        return client.request(.PUT, url, parameters: object, encoding: .JSON, headers: headers)
      case .DELETE:
        return client.request(.DELETE, url, headers: headers)
      }
    }
    
    private func prepareResponse(response: NSData) -> JSON {
      return JSON(data: response);
    }
    
    private func resolveUrl(url: String? = nil, success: ResolveUrlHandler) {
      if url == nil {
        if traverse {
          traverseToFinalUrl(success)
        } else {
          success(url: URITemplate(template: rels.first!).expand(templateParameters), error: nil)
        }
      } else {
        success(url: url!, error: nil)
      }
    }
  
    private func call(url: String? = nil, method: TraversonRequestMethod, object: Dictionary<String, AnyObject>? = nil, callback: TraversonResultHandler) {
      resolveUrl(url, success: { resolvedUrl, error in
        if let resolvedUrl = resolvedUrl {
          self.prepareRequest(
            resolvedUrl,
            method: method,
            object: object
          )
            .validate()
            .response { _, _, data, error in
              if let data = data where data.length > 0 {
                callback(result: TraversonResult(data: self.prepareResponse(data)), error: nil)
              } else {
                callback(result: TraversonResult(), error: nil)
              }
            }
        } else {
          callback(result: TraversonResult(), error: error)
        }
      })
    }
    
    /*
      Follows specified endpoints
    
      - Parameter rels: Collection of endpoints to follow
    
      - Returns: Traversing object
    */
    public func follow(rels: String...) -> Traversing {
      for rel in rels {
        self.rels.append(rel)
      }
      self.traverse = true
    
      return self
    }
    
    private func traverseToFinalUrl(success: ResolveUrlHandler) {
      do {
        try getAndFindLinkWithRel(baseUri, rels: rels.generate(), success: success)
      } catch let error {
        success(url: nil, error: error)
      }
    }
    
    private func getAndFindLinkWithRel(url: String, var rels: IndexingGenerator<Array<String>>, success: ResolveUrlHandler) throws {
      NSLog("Traversing an URL: \(url)");
    
      let next = rels.next()
      if (next == nil) {
        success(url: url, error: nil)
      } else {
        call(url, method: TraversonRequestMethod.GET, callback: { data, error in
          if let e = error {
            success(url: nil, error: e)
          } else {
            do {
              if let json = data.data {
                if let link = json["_links"][next!]["href"].string {
                  if let _ = json["_links"][next!]["templated"].bool {
                    try self.getAndFindLinkWithRel(
                      URITemplate(template: link).expand(self.templateParameters),
                      rels: rels,
                      success: success
                    )
                  } else {
                    try self.getAndFindLinkWithRel(
                      link,
                      rels: rels,
                      success: success
                    )
                  }
                } else {
                  throw TraversonException.RelationNotFound(relation: next!)
                }
              } else {
                throw TraversonException.RelationNotFound(relation: next!)
              }
            } catch let error {
              success(url: nil, error: error)
            }
          }
        })
      }
    }
    
    /*
      Follows specified endpoints
    
      - Parameter link: Endpoint to follow
    
      - Returns: Traversing object
    */
    public func followUri(link: String) -> Traversing {
      self.rels.append(link)
      self.traverse = false
    
      return self
    }
    
    public func follow201Location(follow: Bool) -> Traversing {
      self.follow201Location = follow
      
      return self
    }
    
    public func withHeaders(headers: Dictionary<String, String>) -> Traversing {
      for (k, v) in headers {
        self.headers[k] = v
      }
    
      return self
    }
    
    public func withHeader(name: String, value: String) -> Traversing {
      self.headers[name] = value
    
      return self
    }
    
    public func withTemplateParameter(name: String, value: String) -> Traversing {
      self.templateParameters[name] = value
    
      return self
    }
    
    public func withTemplateParameters(parameters: Dictionary<String, String>) -> Traversing {
      for (k, v) in parameters {
        self.templateParameters[k] = v
      }
    
      return self
    }
    
    public func get(result: TraversonResultHandler) {
      call(method: TraversonRequestMethod.GET, callback: result)
    }
    
    public func post(object: Dictionary<String, AnyObject>, result: TraversonResultHandler) {
      call(method: TraversonRequestMethod.POST, object: object, callback: result)
    }
    
    public func put(object: Dictionary<String, AnyObject>, result: TraversonResultHandler) {
      call(method: TraversonRequestMethod.PUT, object: object, callback: result)
    }
    
    public func delete(result: TraversonResultHandler) {
      call(method: TraversonRequestMethod.DELETE, callback: result)
    }
  }
}
