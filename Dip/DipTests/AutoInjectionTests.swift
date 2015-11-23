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
