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
open class Traverson {
  
  fileprivate var client: Alamofire.SessionManager
  
  fileprivate var authenticator: TraversonAuthenticator?
  
  fileprivate var preemptive: Bool
  
  fileprivate var current: Traversing?
  
  /**
    Constructor with parameters
   
    - Parameters:
      - configuration: Configuration
      - authenticator: Authenticator
   */
  fileprivate init(configuration: URLSessionConfiguration, authenticator: TraversonAuthenticator? = nil, preemptive: Bool) {
    self.client = Alamofire.SessionManager(configuration: configuration)
    self.authenticator = authenticator
    self.preemptive = preemptive
  }
  
  /**
    Constructor with parameters
  */
  public convenience init() {
    self.init(configuration: URLSessionConfiguration.default, preemptive: false)
  }
  
  /**
    Sets the base URL
  
    - Parameter baseUri: URL to start with
  
    - Returns: Traversing object
  */
  open func from(_ baseUri: String) -> Traversing {
    current = Traversing(baseUri: baseUri, client: client, authenticator: authenticator, preemptive: preemptive)
    
    return current!
  }
  
  /**
    Creates a new request based on exsiting one, allowing multiple usage of the same `Traverson` instance
  
    - Returns: Traversing object
  */
  open func newRequest() -> Traversing {
    return current!
  }
  
  /**
    Result callback object
  */
  public typealias TraversonResultHandler = (_ result: TraversonResult?, _ error: Error?) -> Void
  
  /**
    Traverson builder
  */
  open class Builder {
    
    fileprivate var configuration: URLSessionConfiguration
    
    fileprivate var defaultHeaders: [AnyHashable: Any]
    
    fileprivate var useCache: Bool
    
    fileprivate var requestTimeout: TimeInterval
    
    fileprivate var responseTimeout: TimeInterval
    
    fileprivate var authenticator: TraversonAuthenticator?
    
    fileprivate var preemptive: Bool
    
    public init() {
      self.configuration = URLSessionConfiguration.default
      self.defaultHeaders = self.configuration.httpAdditionalHeaders ?? [:]
      self.useCache = true
      self.requestTimeout = self.configuration.timeoutIntervalForRequest
      self.responseTimeout = self.configuration.timeoutIntervalForResource
      self.preemptive = false
    }
    
    /**
      Adds default headers collection
     
      - Parameters defaultHeaders: Collection of default headers to use
     */
    @discardableResult
    open func defaultHeaders(_ defaultHeaders: [String: String]) -> Builder {
      self.defaultHeaders = defaultHeaders
      
      return self
    }
    
    /**
      Adds default header
     
      - Parameters:
      - name: Header's name
      - value: Header's value
     */
    @discardableResult
    open func defaultHeader(_ name: String, value: String) -> Builder {
      defaultHeaders[name] = value
      
      return self
    }
    
    /**
      Disables cache
     */
    @discardableResult
    open func disableCache() -> Builder {
      useCache  = false
      
      return self
    }
    
    /**
      Sets read timeout
     
      - Parameter timout: Request timeout
    */
    @discardableResult
    open func requestTimeout(_ timeout: TimeInterval) -> Builder {
      requestTimeout = timeout
      
      return self
    }
    
    /**
      Sets read timeout
    
      - Parameter timout: Response timeout
    */
    @discardableResult
    open func responseTimeout(_ timeout: TimeInterval) -> Builder {
      responseTimeout = timeout
      
      return self
    }

    /**
     Sets authenticator object
     
     - Parameter authenticator: Authenticator
     */
    @discardableResult
    open func authenticator(_ authenticator: TraversonAuthenticator) -> Builder {
      return self.authenticator(authenticator, preemptive: false)
    }
    
    /**
     Sets authenticator object
     
     - Parameter authenticator: Authenticator
     - Parameter preemptive: Pre-authenticate requests
     */
    @discardableResult
    open func authenticator(_ authenticator: TraversonAuthenticator, preemptive: Bool) -> Builder {
      self.authenticator = authenticator
      self.preemptive = preemptive
      
      return self
    }
    
    /**
      Builds the Traverson object with custom configuration
    */
    open func build() -> Traverson {
      configuration.httpAdditionalHeaders = defaultHeaders
      configuration.timeoutIntervalForRequest = requestTimeout
      configuration.timeoutIntervalForResource = responseTimeout
      if !useCache {
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
      }
      
      return Traverson(configuration: configuration, authenticator: authenticator, preemptive: preemptive)
    }
  }
  
  open class Traversing {
    
    fileprivate var baseUri: String
    
    fileprivate var client: Alamofire.SessionManager
    
    fileprivate var rels: [String]
    
    fileprivate var headers: [String: String]
    
    fileprivate var templateParameters: [String: String]
    
    fileprivate var dispatchQueue: DispatchQueue? = nil
    
    fileprivate var follow201Location:Bool = false
    
    fileprivate var traverse:Bool = true
    
    fileprivate var linkResolver: TraversonLinkResolver = TraversonJsonHalLinkResolver()
    
    fileprivate var authenticator: TraversonAuthenticator?
    
    fileprivate var preemptive: Bool
    
    fileprivate typealias ResolveUrlHandler = (_ url: String?, _ error: Error?) -> Void
    
    fileprivate init(baseUri: String, client: Alamofire.SessionManager, authenticator: TraversonAuthenticator? = nil, preemptive: Bool) {
      self.baseUri = baseUri
      self.client = client
      self.rels = Array()
      self.headers = Dictionary()
      self.templateParameters = Dictionary()
      self.authenticator = authenticator
      self.preemptive = preemptive
    }

    fileprivate func prepareRequest(_ url: String, method: TraversonRequestMethod, object: [String: AnyObject]? = nil) -> DataRequest {
      switch method {
      case .get:
        return client.request(url, method: .get, headers: headers)
      case .post:
        return client.request(url, method: .post, parameters: object, encoding: JSONEncoding.default, headers: headers)
      case .put:
        return client.request(url, method: .put, parameters: object, encoding: JSONEncoding.default, headers: headers)
      case .delete:
        return client.request(url, method: .delete, headers: headers)
      }
    }
    
    fileprivate func prepareResponse(_ response: Data) -> JSON {
      return JSON(data: response as Data);
    }
    
    fileprivate func call(_ url: String? = nil, method: TraversonRequestMethod, object: [String: AnyObject]? = nil, retries: Int = 0, callback: @escaping TraversonResultHandler) {
      resolveUrl(url, success: { resolvedUrl, error in
        if let resolvedUrl = resolvedUrl {
          self.prepareRequest(
            resolvedUrl,
            method: method,
            object: object
          )
            .response(queue: self.dispatchQueue) { result in
              if let response = result.response, response.statusCode == 401 {
                if let authenticator = self.authenticator {
                  if retries < authenticator.retries {
                    authenticator.authenticate { authenticatorResult in
                      if let authorization = authenticatorResult {
                        self.headers["Authorization"] = authorization
                        self.call(resolvedUrl, method: method, object: object, retries: retries + 1, callback: callback)
                      } else {
                        callback(nil, TraversonError.authenticatorError())
                      }
                    }
                  } else {
                    callback(nil, TraversonError.accessDenied())
                  }
                } else {
                  callback(nil, TraversonError.accessDenied())
                }
              } else {
                if result.response?.statusCode == 201, self.follow201Location {
                    if let location = result.response?.allHeaderFields["Location"] as? String {
                        self.call(location, method: .get, callback: callback)
                    } else {
                        callback(nil, TraversonError.httpException(code: 201, message: "No Location Header found"))
                    }
                } else if let data = result.data, data.count > 0 {
                  callback(TraversonResult(data: self.prepareResponse(data)), nil)
                } else {
                  callback(nil, TraversonError.unknown())
                }
              }
            }
        } else {
          callback(nil, error)
        }
      })
    }
    
    /*
      Follows specified endpoints
    
      - Parameter rels: Collection of endpoints to follow
    
      - Returns: Traversing object
    */
    @discardableResult
    open func follow(_ rels: String...) -> Traversing {
      for rel in rels {
        self.rels.append(rel)
      }
      self.traverse = true
    
      return self
    }
    
    fileprivate func traverseToFinalUrl(_ success: @escaping ResolveUrlHandler) {
      do {
        try getAndFindLinkWithRel(baseUri, rels: rels.makeIterator(), success: success)
      } catch let error {
        success(nil, error)
      }
    }
    
    fileprivate func authenticate(_ success: @escaping ResolveUrlHandler) {
      if let authenticator = self.authenticator {
        authenticator.authenticate { authenticatorResult in
          if let authorization = authenticatorResult {
            self.headers["Authorization"] = authorization
            self.traverseUrl(success)
          } else {
            success(nil, TraversonError.authenticatorError())
          }
        }
      } else {
        traverseUrl(success)
      }
    }
    
    fileprivate func resolveUrl(_ url: String? = nil, success: @escaping ResolveUrlHandler) {
      if url == nil {
        if (self.preemptive && self.headers["Authorization"] == nil) {
          authenticate(success)
        } else {
          traverseUrl(success)
        }
      } else {
        success(url!, nil)
      }
    }
    
    fileprivate func traverseUrl(_ success: @escaping ResolveUrlHandler) {
      if self.traverse {
        traverseToFinalUrl(success)
      } else {
        success(URITemplate(template: rels.first!).expand(templateParameters), nil)
      }
    }
    
    private func getAndFindLinkWithRel(_ url: String, rels: IndexingIterator<[String]>, success: @escaping ResolveUrlHandler) throws {
      var rels = rels
      NSLog("Traversing an URL: \(url)");
    
      let next = rels.next()
      if (next == nil) {
        success(url, nil)
      } else {
        call(url, method: TraversonRequestMethod.get, callback: { data, error in
          if let e = error {
            success(nil, e)
          } else {
            do {
              if let json = data!.data {
                let link = try self.linkResolver.findNext(next!, data: json)
                try self.getAndFindLinkWithRel(
                  URITemplate(template: link).expand(self.templateParameters),
                  rels: rels,
                  success: success
                )
              } else {
                throw TraversonError.unknown()
              }
            } catch let error {
              success(nil, error)
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
    @discardableResult
    open func followUri(_ link: String) -> Traversing {
      self.rels.append(link)
      self.traverse = false
    
      return self
    }
    
    @discardableResult
    open func follow201Location(_ follow: Bool) -> Traversing {
      self.follow201Location = follow
      
      return self
    }
    
    @discardableResult
    open func dispatchQueue(_ queue: DispatchQueue) -> Traversing {
        self.dispatchQueue = queue
        
        return self
    }
    
    @discardableResult
    open func json() -> Traversing {
      self.linkResolver = TraversonJsonLinkResolver()
      
      return self
    }
    
    @discardableResult
    open func jsonHal() -> Traversing {
      self.linkResolver = TraversonJsonHalLinkResolver()
      
      return self
    }
    
    @discardableResult
    open func withHeaders(_ headers: [String: String]) -> Traversing {
      for (k, v) in headers {
        self.headers[k] = v
      }
    
      return self
    }
    
    @discardableResult
    open func withHeader(_ name: String, value: String) -> Traversing {
      self.headers[name] = value
    
      return self
    }
    
    @discardableResult
    open func withTemplateParameter(_ name: String, value: String) -> Traversing {
      self.templateParameters[name] = value
    
      return self
    }
    
    @discardableResult
    open func withTemplateParameters(_ parameters: [String: String]) -> Traversing {
      for (k, v) in parameters {
        self.templateParameters[k] = v
      }
    
      return self
    }
    
    open func get(_ result: @escaping TraversonResultHandler) {
      call(method: TraversonRequestMethod.get, callback: result)
    }
    
    open func post(_ object: [String: AnyObject], result: @escaping TraversonResultHandler) {
      call(method: TraversonRequestMethod.post, object: object, callback: result)
    }
    
    open func put(_ object: [String: AnyObject], result: @escaping TraversonResultHandler) {
      call(method: TraversonRequestMethod.put, object: object, callback: result)
    }
    
    open func delete(_ result: @escaping TraversonResultHandler) {
      call(method: TraversonRequestMethod.delete, callback: result)
    }
  }
}
