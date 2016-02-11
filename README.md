Swift implementation of a Hypermedia API/HATEOAS client / SwiftyTraverson
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

```swift
let traverson = Traverson()
```

### Configuration properties

Use `Traverson.Builder` in order to configure the `Traverson`:

```swift
let traverson = Traverson.Builder()
.requestTimeout(2.0)
.responseTimeout(5.0)
.disableCache()
.defaultHeader("Accept-Language", value: "de-CH")
.build()
```

List of available properties:

//todo Add list

### Making requests

Traverson supports the following HTTP method verbs to operate the data: `GET`, `POST`, `PUT` and `DELETE`.
Below you'll find the examples of using each of these verbs.

Retrieve data:

```swift
traverson
  .from("http://www.some.com")
  .follow("users", "next")
  .get { result, error in
    // Do something...
  }
```

Create data:

```swift
let objectToAdd: Dictionary<String, AnyObject> = ["name": "John Doe"]

traverson
  .from("http://www.some.com")
  .follow("users")
  .post(objectToAdd) { result, error in
    // Do something...
  }
```

Update data:

```swift
let objectToUpdate: Dictionary<String, AnyObject> = ["id": 1, "name": "John Doe"]

traverson
  .from("http://www.some.com")
  .follow("users", "first")
  .put(objectToUpdate) { result, error in
    // Do something...
  }
```

Delete data:

```swift
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

Each one of the described methods expects one 


## License

SwiftyTraverson is available under the Apache License, Version 2.0. See the LICENSE file for more info.
