import Foundation
import Combine
import os.log
import AuthenticationServices
import SwiftRex
import SwiftKeychainWrapper

// MARK: - ACTIONS

//sourcery: Prism
public enum SessionServiceAction {
    case request(SessionRequestAction)
    case status(SessionStatusAction)
}

//sourcery: Prism, imports = ["AuthenticationServices"]
public enum SessionRequestAction {
    case login
    case logout
    case reset
}

//sourcery: Prism
public enum SessionStatusAction {
    case valid
    case terminated
    case undefined
    case registered(String)
    case error(Error)
}

// MARK: - STATE

//sourcery: AutoEquatable
public struct SessionServiceState {

    public var authState: AuthenticationState
    public var identityToken: Data? = nil
    public var authorizationCode: Data? = nil
    public var state: String? = nil
    public var user: String? = nil
    
    public var fullName: PersonNameComponents? = nil
    public var email: String? = nil
    public var realUserStatus: RealUserStatus? = nil
    
    public enum AuthenticationState {
        case authenticated
        case loggedOut
        case undefined
    }
    
    public enum RealUserStatus: Int, Equatable {
        case unsupported = 0, unknown, real
    }
    
    public init(authState: AuthenticationState = .undefined) {
        self.authState = authState
    }
}

public enum CredentialStateResult {
    case success(ASAuthorizationAppleIDProvider.CredentialState)
    case failure(SessionError)
}

// MARK: - ERROR
public enum SessionError: Error {
    case FailureToWriteToKeychain
    case FailureToReadFromKeychain
    case FailureToDecodeIdentityToken
    case UnknownCredentialState
}

// MARK: - CONSTANTS
private enum KeyStorageNamingConstants {
    static let user = "user"
    static let email = "email"
    static let identityToken = "id-token"
}

// MARK: - PROTOCOL
public protocol SessionServiceProvider: ASAuthorizationProvider {
    func getCredentialState(userID: String) -> Future<CredentialStateResult, Never>
}

public protocol SessionServiceStorage {
    func write(data: String, for key: String) -> Bool
    func read(key: String) -> String?
    func remove(key: String) -> Bool
}

public final class SessionServiceMiddleware: Middleware {
    public typealias InputActionType = SessionServiceAction
    public typealias OutputActionType = SessionServiceAction
    public typealias StateType = SessionServiceState

    private static let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SessionServicesMiddleware")

    private var output: AnyActionHandler<OutputActionType>? = nil
    private var state: () -> StateType = {  StateType() }
    
    private var provider: SessionServiceProvider
    private var keychain: SessionServiceStorage
    
    private var userSignal: PassthroughSubject<String, Never> = PassthroughSubject()
    private var cancellable: AnyCancellable?
    
    public init(
        provider: SessionServiceProvider,
        storage: SessionServiceStorage
    ) {
        self.provider = provider
        self.keychain = storage
        
        cancellable = userSignal
            .flatMap { self.provider.getCredentialState(userID: $0) }
            .sink() { [self] result in
                if case let .success(state) = result {
                    switch state {
                    case .authorized:
                        os_log("Credential state : authorized ...",
                               log: KeychainWrapper.logger,
                               type: .debug)
                        output?.dispatch(.status(.valid))
                    case .revoked: output?.dispatch(.status(.terminated))
                    case .notFound:
                        os_log("Credential state : not found ...",
                               log: KeychainWrapper.logger,
                               type: .debug)
                        output?.dispatch(.status(.undefined))
                    default: output?.dispatch(.status(.error(SessionError.UnknownCredentialState)))
                    }
                }
            }
    }
    
    public func receiveContext(getState: @escaping GetState<StateType>, output: AnyActionHandler<OutputActionType>) {
        self.state = getState
        self.output = output
        // After the context is received, we immediately check to see if we have a stored identity token, which
        // would indicate that the user has already registered.
        if let userID = keychain.read(key: KeyStorageNamingConstants.user) {
            userSignal.send(userID)
        } else {
            self.output?.dispatch(.status(.error(SessionError.FailureToReadFromKeychain)))
        }
    }

    public func handle(
        action: InputActionType,
        from dispatcher: ActionSource,
        afterReducer : inout AfterReducer
    ) {
        // Actions to be handled BEFORE the reducer pipeline gets to mutate the global state.
        switch action {
        case .request(.reset):
            if keychain.remove(key: KeyStorageNamingConstants.user) {
                output?.dispatch(.status(.undefined))
            } else {
                output?.dispatch(.status(.error(SessionError.FailureToWriteToKeychain)))
            }
        case .request(.logout):
            output?.dispatch(.status(.terminated))
        default:
            break
        }
        
        // Actions to be handled AFTER the reducer pipeline has mutated the global state.
        // This is required so we get access to the mutated state, i.e. new credentials
        // so we can save them in the keychain.
        afterReducer = .do { [self] in
            if case .request(.login) = action {
                let afterState = state()
                os_log(
                    "Calling afterReducer closure for login case...",
                    log: KeychainWrapper.logger,
                    type: .debug
                )
                if let userID = afterState.user {
                    keychain.write(
                        data: userID,
                        for: KeyStorageNamingConstants.user
                    ) ? output?.dispatch(.status(.valid)) : output?.dispatch(.status(.error(SessionError.FailureToWriteToKeychain)))
                } else {
                    os_log("Login case, but no user in State...",
                           log: KeychainWrapper.logger,
                           type: .debug)
                    output?.dispatch(.status(.error(SessionError.UnknownCredentialState)))
                }
            }
        }
    }
}

// All the methods used to store and remove properties to / from the user's keychain.
extension KeychainWrapper: SessionServiceStorage {
    
    static let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SessionServiceStorage")
    static public let storage = KeychainWrapper(serviceName: Bundle.main.bundleIdentifier ?? "SessionServiceStorage")
    
    public func write(data: String, for key: String) -> Bool  {
        os_log("Writing key %s to the keychain...",
               log: KeychainWrapper.logger,
               type: .debug,
               key)
        return KeychainWrapper.storage.set(data, forKey: key)
    }
    
    public func read(key: String) -> String? {
        os_log("Reading %s from the keychain...",
               log: KeychainWrapper.logger,
               type: .debug,
               key)
        return KeychainWrapper.storage.string(forKey: key)
    }
    
    public func remove(key: String) -> Bool {
        os_log("Removing %s from the keychain...",
               log: KeychainWrapper.logger,
               type: .debug,
               key)
        return KeychainWrapper.storage.removeObject(forKey: key)
    }

//    private func saveInviteCode(_ code: String) {
//        let saveSuccessful = KeychainWrapper
//            .standard
//            .set(code, forKey: "inviteCode")
//        os_log("The invitation code was stored successfully in the keychain : %s",
//               log: SessionManager.logger,
//               type: .debug,
//               saveSuccessful.description)
//        // TODO: add a warning message in case the invitaiton code cannot be stored in the keychain.
//    }
//
//    private func removeInviteCode() {
//        let removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "inviteCode")
//        os_log("The invitation code was removed successfully from the keychain : %s",
//               log: SessionManager.logger,
//               type: .debug,
//               removeSuccessful.description)
//        // TODO: add a warning message in case the id token cannot be removed from the keychain.
//    }
}

extension ASAuthorizationAppleIDProvider: SessionServiceProvider {
    public func getCredentialState(userID: String) -> Future<CredentialStateResult, Never> {
        return Future() { promise in
            self.getCredentialState(
                forUserID: userID,
                completion: { state, error in
                    os_log("Credential state for : %s",
                           log: KeychainWrapper.logger,
                           type: .debug,
                           userID)
                    if error != nil {
                        promise(Result.success(CredentialStateResult.failure(.UnknownCredentialState)))
                    } else {
                        promise(Result.success(CredentialStateResult.success(state)))
                    }
                }
            )
        }
    }
}

extension Reducer where ActionType == SessionServiceAction, StateType == SessionServiceState {
    public static let session = Reducer { action, state in
        var state = state
        switch action {
        case .status(.terminated):
            state.authState = .loggedOut
        case .status(.undefined):
            state = SessionServiceState()
        case .status(.valid):
            state.authState = .authenticated
        default: break
        }
        return state
    }
}
