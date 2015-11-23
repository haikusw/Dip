//
// Dip
//
// Copyright (c) 2015 Olivier Halligon <olivier@halligon.net>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

//MARK: Public

/**
Use this wrapper to identifiy strong properties of the instance that should be injected when you call
`resolveDependencies()` on this instance. Type T can be any type.

- warning:
Do not define this property as optional or container will not be able to inject it.
Instead define it with initial value of `Injected<T>()`.
If you need to nilify wrapped value, assing property to `Injected<T>()`.

**Example**:

```swift
class ClientImp: Client {
  var service = Injected<Service>()
}

```
- seealso: `InjectedWeak`, `DependencyContainer.resolveDependencies(_:)`

*/
public final class Injected<T>: _Injected {
  
  var _value: Any?
  
  public init() {}
  
  public var value: T? {
    get {
      return _value as? T
    }
    set {
      _value = newValue
    }
  }
  
}

/**
 Use this wrapper to identifiy weak properties of the instance that should be injected when you call
 `resolveDependencies()` on this instance. Type T should be a **class** type.
 Otherwise it will cause runtime exception when container will try to resolve the property.
 Use this wrapper to define one of two circular dependencies to avoid retain cycle.
 
 - warning:
 Do not define this property as optional or container will not be able to inject it.
 Instead define it with initial value of `InjectedWeak<T>()`.
If you need to nilify wrapped value, assing property to `InjectedWeak<T>()`.

 **Example**:
 
 ```swift
 class ServiceImp: Service {
   var client = InjectedWeak<Client>()
 }

 ```
 
 - note:
 The only difference between `InjectedWeak` and `Injected` is that `InjectedWeak` uses _weak_ reference
 to store underlying value, when `Injected` uses _strong_ reference.
 For that reason if you resolve instance that holds weakly injected property
 this property will be released when `resolve` returns 'cause no one else holds reference to it.
 
 - seealso: `Injected`, `DependencyContainer.resolveDependencies(_:)`
 
 */
public final class InjectedWeak<T>: _InjectedWeak {

  //Only classes (means AnyObject) can be used as `weak` properties
  //but we can not make <T: AnyObject> cause that will prevent using protocol as generic type
  //so we just rely on user reading documentation and passing AnyObject in runtime
  //also we will throw fatal error if type can not be casted to AnyObject during resolution

  weak var _value: AnyObject?
  
  public init() {}
  
  public var value: T? {
    get {
      return _value as? T
    }
    set {
      _value = newValue as? AnyObject
    }
  }
  
}

extension DependencyContainer {
  
  /**
   Resolves dependencies of passed object. Properties that should be injected must be of type `Injected<T>` or `InjectedWeak<T>`. This method will also recursively resolve their dependencies, building full object graph.
   
   - parameter instance: object whose dependecies should be resolved
   
   - Note:
   Use `InjectedWeak<T>` to define one of two circular dependecies if another dependency is defined as `Injected<U>`.
   This will prevent retain cycle between resolved instances.
   
   **Example**:
   ```swift
   class ClientImp: Client {
     var service = Injected<Service>()
   }
   
   class ServiceImp: Service {
     var client = InjectedWeak<Client>()
   }
   
   //when resolved client will have service injected
   let client = container.resolve() as Client
   
   ```
   
   */
  public func resolveDependencies(instance: Any) {
    for child in Mirror(reflecting: instance).children
      where child.value is _Injected || child.value is _InjectedWeak  {
        
        let tag = Tag.String("\(child.value.dynamicType)")
        if let value = child.value as? _Injected {
          value._value = resolve(tag: tag) as Any
        }
        else if let weakValue = child.value as? _InjectedWeak {
          weakValue._value = resolve(tag: tag) as AnyObject
        }
    }
  }

}

//MARK: - Private

extension DependencyContainer {
  typealias InjectedFactory = ()->Any
  typealias InjectedWeakFactory = ()->AnyObject
  
  static func injectedKey<T>(type: T.Type) -> DefinitionKey {
    return DefinitionKey(protocolType: Any.self, factoryType: InjectedFactory.self, associatedTag: Tag.String(injectedTag(type)))
  }
  
  static func injectedWeakKey<T>(type: T.Type) -> DefinitionKey {
    return DefinitionKey(protocolType: AnyObject.self, factoryType: InjectedWeakFactory.self, associatedTag: Tag.String(injectedWeakTag(type)))
  }
  
  func registerInjected<T, F>(definition: DefinitionOf<T, F>) {
    guard let definition = definition.injectedDefinition else { return }
    definitions[DependencyContainer.injectedKey(T.self)] = definition
  }
  
  func registerInjectedWeak<T, F>(definition: DefinitionOf<T, F>) {
    guard let definition = definition.injectedWeakDefinition else { return }
    definitions[DependencyContainer.injectedWeakKey(T.self)] = definition
  }
  
  func removeInjected<T, F>(definition: DefinitionOf<T, F>) {
    guard definition.injectedDefinition != nil else { return }
    definitions[DependencyContainer.injectedKey(T.self)] = nil
  }
  
  func removeInjectedWeak<T, F>(definition: DefinitionOf<T, F>) {
    guard definition.injectedWeakDefinition != nil else { return }
    definitions[DependencyContainer.injectedWeakKey(T.self)] = nil
  }

}

func injectedTag<T>(type: T.Type) -> String {
  return "\(Injected<T>().dynamicType)"
}

func injectedWeakTag<T>(type: T.Type) -> String {
  return "\(InjectedWeak<T>().dynamicType)"
}

protocol _Injected: class {
  var _value: Any? { get set }
}

protocol _InjectedWeak: class {
  weak var _value: AnyObject? { get set }
}

