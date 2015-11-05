//
//  RuntimeArgumentsTests.swift
//  DipTests
//
//  This code is under MIT Licence. See the LICENCE file for more info.
//

import XCTest
@testable import Dip

private protocol Server {
  weak var client: Client? {get}
}

private protocol Client: class {
  var server: Server? {get}
}

class AutoInjectionTests: XCTestCase {
  
  static var serverDeallocated: Bool = false
  static var clientDeallocated: Bool = false

  private class ServerImp: Server {
    
    deinit {
      AutoInjectionTests.serverDeallocated = true
    }
    
    var _client = InjectedWeak<Client>()
    
    weak var client: Client? {
      return _client.value
    }
  }
  
  private class ClientImp: Client {
    
    deinit {
      AutoInjectionTests.clientDeallocated = true
    }
    
    var _server = Injected<Server>()
    
    var server: Server? {
      return _server.value
    }
  }

  let container = DependencyContainer()
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
    container.reset()
    AutoInjectionTests.serverDeallocated = false
    AutoInjectionTests.clientDeallocated = false
    
    container.register(.ObjectGraph) { ServerImp() as Server }
    container.register(.ObjectGraph) { ClientImp() as Client }

  }

  func testThatItResolvesInjectedDependencies() {
    let client = container.resolve() as Client
    let server = client.server
    XCTAssertTrue(client as! ClientImp === server?.client as! ClientImp)
  }
  
  func testThatThereIsNoRetainCycleForCyrcularDependencies() {
    //given
    var client: Client? = container.resolve() as Client
    XCTAssertNotNil(client)
    
    //when
    client = nil
    
    //then
    XCTAssertTrue(AutoInjectionTests.clientDeallocated)
    XCTAssertTrue(AutoInjectionTests.serverDeallocated)
  }
  
  func testThatItResolvesAutoInjectedSingletons() {
    container.reset()
    
    container.register(.Singleton) { ServerImp() as Server }
    container.register(.Singleton) { ClientImp() as Client }
    
    let sharedClient = container.resolve() as Client
    let sharedServer = container.resolve() as Server

    let client = container.resolve() as Client
    let server = client.server
    
    XCTAssertTrue(client as! ClientImp === sharedClient as! ClientImp)
    XCTAssertTrue(client as! ClientImp === server?.client as! ClientImp)
    XCTAssertTrue(server as! ServerImp === sharedServer as! ServerImp)
  }
  
}
