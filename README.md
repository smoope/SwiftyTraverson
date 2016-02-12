SwiftyTraverson - Swift implementation of a Hypermedia API/HATEOAS client
==========

# Introduction

This framework was inspired by [Traverson javascript library](https://github.com/basti1302/traverson). 

Traverson allows you to follow the relation links within the HATEOAS-based API's response instead of harcoding every single url. 
In addition, the built-in features allow you:
- manage header info sent to server
- handle URI tempalte variables
- use different types of authentication

## Installation

Traverson is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftyTraverson', :git => 'https://github.com/smoope/SwiftyTraverson.git'
```

## Usage

### Initialization

```javascript
let traverson = Traverson()
```

### Configuration properties

Use `Traverson.Builder` in order to configure the `Traverson`:

```javascript
let traverson = Traverson.Builder()
  .requestTimeout(2.0)
  .responseTimeout(5.0)
  .disableCache()
  .defaultHeader("Accept-Language", value: "de-CH")
.build()
```

List of available properties:

| Property | Description | 
|---|---|
| `requestTimeout` | Sets request timeout interval (in seconds) per each request. [More details](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionConfiguration_class/index.html#//apple_ref/occ/instp/NSURLSessionConfiguration/timeoutIntervalForRequest). |
| `responseTimeout` | Sets response timeout interval (in seconds) per each request. [More details](https://developer.apple.com/library/prerelease/ios/documentation/Foundation/Reference/NSURLSessionConfiguration_class/index.html#//apple_ref/occ/instp/NSURLSessionConfiguration/timeoutIntervalForResource). |
| `disableCache` | Disables caching. [More details](#caching). |
| `defaultHeader` | Sets single default header which will be sent to the server per each request. |
| `defaultHeaders` | Sets a collection of default headers which will be sent to the server per each request. |
| `authenticator` | Authenticates every request accordingly to server's security policy. [More details](#authenticating-requests). |

### Making requests

Traverson supports the following HTTP method verbs to operate the data: `GET`, `POST`, `PUT` and `DELETE`.
Below you'll find the examples of using each one of these verbs.

Retrieve data:

```javascript
traverson
  .from("http://www.some.com")
  .follow("users", "next")
  .get { result, error in
    // Do something...
  }
```

Create data:

```javascript
let objectToAdd: Dictionary<String, AnyObject> = ["name": "John Doe"]

traverson
  .from("http://www.some.com")
  .follow("users")
  .post(objectToAdd) { result, error in
    // Do something...
  }
```

Update data:

```javascript
let objectToUpdate: Dictionary<String, AnyObject> = ["id": 1, "name": "John Doe"]

traverson
  .from("http://www.some.com")
  .follow("users", "first")
  .put(objectToUpdate) { result, error in
    // Do something...
  }
```

Delete data:

```javascript
traverson
  .from("http://www.some.com")
  .follow("users")
  .delete { result, error in
    // Do something...
  }
```

As you might noticed, `post` and `put` methods expect an additional parameter represents the object should be created or updated, while 
`get` and `delete` has no such parameter.

### Reading response

Each one of the described methods expects a callback function with the following parameters:
- `result`, an object contains an information about successful result of request
- `error`, a native `ErrorType` object contains error description, in case something went wrong

By default, SwiftyTraverson parses the response as [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)'s `JSON` object. If you like the native way, you can work with `Dictionary`:

```javascript
traverson
  .from("http://www.some.com")
  .follow("users", "next")
  .get { result, _ in
    let json:JSON? = result.data
    let dictionary:[String: AnyObject]? = result.dictionary
    // Do something...
  }
```

### Errors handling

Once something went wrong during the request, the callback's `error` variable will contain a description:

```javascript
traverson
  .from("http://www.some.com")
  .follow("users", "next")
  .get { _, error in
    if let err = error {
      // Handle error...
    }
  }
```

### Authenticating requests

In case of server requires an authentiction, you can use built-in or custom implementation of `TraversonAuthenticator` protocol.

The example shows usage of HTTP basic authentication:

```javascript
let traverson = Traverson.Builder()
  .authenticator(TraversonBasicAuthenticator(username: "username", password: "password"))
  .build()
      
traverson
  .from("http://www.some.com")
  .follow("users", "next")
  .get { result, error in
    // Do something...
  }
```

### Sending additional information

It is possible to send an additional request-scoped information such as HTTP headers:

```javascript
traverson
  .from("http://www.some.com")
  .follow("users", "next")
  .withHeader("Custom-Header", value: "Custom-Value")
  .get { result, error in
    // Do something...
  }
```

Since SwiftyTraverson supports URI templates ([RFC 6570](http://tools.ietf.org/html/rfc6570)), passing a quety parameters are possible as well:

```javascript
traverson
  .from("http://www.some.com")
  .follow("users", "next")
  .withTemplateParameter("page", value: "1")
  .get { result, error in
    // Do something...
  }
```

or even an array:

```javascript
traverson
  .from("http://www.some.com")
  .follow("users", "next")
  .withTemplateParameters(["user": "john", "page": "1", "sort": "color,desc"])
  .get { result, error in
    // Do something...
  }
```

Supposing we have the following URI template: `http://www.some.com/{user}/{?page,sort}`, it will be substituted to `http://www.some.com/john/?page=1&sort=color,desc`.

### Reusing the same traverson instance

Once defined `Traverson` instance can be used mupltiple times by calling `newRequest` method:

```javascript
traverson
  .from("http://www.some.com")
  .follow("users")
  .get { result, error in
    // Do something...
  }

...

traverson
  .newRequest()
  .follow("users")
  .post(objectToAdd) { result, error in
    // Do something...
  }

...

traverson
  .newRequest()
  .follow("users", "1")
  .delete{ result, error in
    // Do something...
  }
```

### Supporting different media types

SwiftyTraverson expects that your server-side implementation follows [HATEOAS](https://en.wikipedia.org/wiki/HATEOAS) principles, no matter which representation technology is used to render the response. Out-of-box it works with both JSON and [JSON HAL](https://tools.ietf.org/html/draft-kelly-json-hal-07) standards. 

In case of using simple JSON representation, you should specify it during the call:

```javascript
traverson
  .from("http://www.some.com")
  .json()
  .follow("users", "next")
  .get { result, error in
    // Do something...
  }
```

Once your response fully follows the HAL standard you should do nothing, it's a default behavior. Alternatively, you can force to use it:

```javascript
traverson
  .from("http://www.some.com")
  .jsonHal()
  .follow("users", "next")
  .get { result, error in
    // Do something...
  }
```

### Caching

By default, all the calls are cached by system framework.  [More details](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/Foundation/Classes/NSURLCache_Class/index.html#//apple_ref/occ/cl/NSURLCache).

## License

SwiftyTraverson is available under the Apache License, Version 2.0. See the LICENSE file for more info.
