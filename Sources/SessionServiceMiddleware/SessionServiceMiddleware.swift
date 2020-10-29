import Foundation
import Combine
import os.log
import AuthenticationServices
import SwiftRex
import SwiftKeychainWrapper

// MARK: - ACTIONS

//sourcery: Prism
public enum SessionServicesAction {
    case request(SessionRequestAction)
    case status(SessionStatusAction)
}

public enum SessionRequestAction {
    case authenticated(ASAuthorizationCredential)
    case sessionState(String)
}

public enum SessionStatusAction {
    case valid
    case terminated
    case undefined
    case registered(String)
    case error(Error)
}

public enum AuthenticationServicesState {
    case authenticated
    case loggedOut
    case undefined
    
    struct Credentials {
        var credentials: ASAuthorizationCredential
    }
}

public enum CredentialStateResult {
    case success(ASAuthorizationAppleIDProvider.CredentialState)
    case failure(SessionError)
}

public enum SessionError: Error {
    case FailureToWriteToKeychain
    case UnknownCredentialState
}

private enum KeyStorageNamingConstants {
    static let userID = "userID"
}

public protocol SessionServiceProvider: ASAuthorizationProvider {
    func getCredentialState(userID: String) -> Future<CredentialStateResult, Never>
}

public final class SessionServiceMiddleware: Middleware {
    public typealias InputActionType = SessionServicesAction
    public typealias OutputActionType = SessionServicesAction
    public typealias StateType = AuthenticationServicesState

    private static let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SessionServicesMiddleware")

    private var output: AnyActionHandler<OutputActionType>? = nil
    
    private var provider: SessionServiceProvider
    private var keychain: KeychainWrapper? = nil
    
    private var cancellable: AnyCancellable?
    
    public init(provider: SessionServiceProvider) {
        self.provider = provider
    }
    
    public func receiveContext(getState: @escaping GetState<StateType>, output: AnyActionHandler<OutputActionType>) {
        self.output = output
        self.keychain = KeychainWrapper(serviceName: Bundle.main.bundleIdentifier ?? "SessionServicesMiddleware")
        if let userID = keychain?.string(forKey: KeyStorageNamingConstants.userID) {
            os_log("The federated user ID was retrieved successfully from the keychain : %s",
                   log: SessionServiceMiddleware.logger,
                   type: .debug,
                   userID.debugDescription)
            output.dispatch(.status(.registered(userID)))
        }
    }

    public func handle(
        action: InputActionType,
        from dispatcher: ActionSource,
        afterReducer _: inout AfterReducer
    ) {
        switch action {
        case let .request(.authenticated(credential as ASAuthorizationAppleIDCredential)):
            if !saveUserID(credential.user) { output?.dispatch(.status(.error(SessionError.FailureToWriteToKeychain))) }
        case let .request(.sessionState(user)):
            cancellable = provider
                .getCredentialState(userID: user)
                .sink() { [self] result in
                    if case let .success(state) = result {
                        switch state {
                        case .authorized: output?.dispatch(.status(.valid))
                        case .revoked: output?.dispatch(.status(.terminated))
                        case .notFound: output?.dispatch(.status(.undefined))
                        default: output?.dispatch(.status(.error(SessionError.UnknownCredentialState)))
                        }
                    }
                }
        default:
            break
        }
    }
}

// All the methods used to store and remove properties to / from the user's keychain.
extension SessionServiceMiddleware {
//    private func saveIDToken(_ idToken: AuthToken) {
//        let encoder = JSONEncoder()
//        if let data = try? encoder.encode(idToken) {
//            let saveSuccessful: Bool = KeychainWrapper.standard.set(data, forKey: "id-token")
//            os_log("The ID Token was stored successfully in the keychain : %s",
//                   log: SessionManager.logger,
//                   type: .debug,
//                   saveSuccessful.description)
//            // TODO: add a warning message in case the id token cannot be stored in the keychain.
//        } else {
//            os_log("Unable to decode AuthToken.",
//                   log: SessionManager.logger,
//                   type: .debug,
//                   idToken.email)
//        }
//    }
    
    private func saveUserID(_ userID: String) -> Bool {
        guard let saveSuccessful = keychain?.set(userID, forKey: KeyStorageNamingConstants.userID) else { return false }
        os_log("The federated ID was stored successfully in the keychain : %s",
               log: SessionServiceMiddleware.logger,
               type: .debug,
               saveSuccessful.description)
        return saveSuccessful
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
//    private func removeIDToken() {
//        let removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "id-token")
//        os_log("The ID Token was removed successfully from the keychain : %s",
//               log: SessionManager.logger,
//               type: .debug,
//               removeSuccessful.description)
//        // TODO: add a warning message in case the id token cannot be removed from the keychain.
//    }
//
//    private func removeUserID() {
//        let removeSuccessful: Bool = KeychainWrapper.standard.removeObject(forKey: "userID")
//        os_log("The federated ID was removed successfully from the keychain : %s",
//               log: SessionManager.logger,
//               type: .debug,
//               removeSuccessful.description)
//        // TODO: add a warning message in case the id token cannot be removed from the keychain.
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
