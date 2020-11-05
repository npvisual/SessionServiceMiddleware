import XCTest
import SwiftRex
import Combine
@testable import SessionServiceMiddleware

final class SessionServiceMiddlewareTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
//        XCTAssertEqual(SessionServiceMiddleware().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}



class Store {
    var state: SessionServiceState = SessionServiceState()
    var actionsReceived: [SessionServiceAction] = []
    
    var getState: (() -> SessionServiceState)!
    var actionHandler: AnyActionHandler<SessionServiceAction>!
    
    init() {
        actionHandler = .init { action, _ in
            self.actionsReceived.append(action)
        }
        getState = { self.state }
    }
}

class AuthProviderTest: NSObject, SessionServiceProvider {
    func getCredentialState(userID: String) -> Future<CredentialStateResult, Never> {
        return Future() { promise in
            let credential = CredentialStateResult.success(.authorized)
            return promise(Result.success(credential))
        }
    }
}

class StorageServiceTest: SessionServiceStorage {
    func write(data: Data, for key: String) -> Bool {
        return true
    }
    
    func read(key: String) -> Data? {
        return nil
    }
    
    func remove(key: String) -> Bool {
        return true
    }
}
