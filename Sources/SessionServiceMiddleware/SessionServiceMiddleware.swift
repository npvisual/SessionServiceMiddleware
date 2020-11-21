import Foundation
import os.log
import SwiftRex

// MARK: - ACTIONS

//sourcery: Prism
public enum SessionServiceAction {
    case request(SessionRequestAction)
    case status(SessionServiceState)
}

//sourcery: Prism
public enum SessionRequestAction {
    case start
    case stop
    case refresh
}

// MARK: - STATE
public enum SessionServiceState: Equatable {
    case valid
    case terminated
    case undefined
}

// MARK: - MIDDLEWARE
public final class SessionServiceMiddleware: Middleware {
    public typealias InputActionType = SessionServiceAction
    public typealias OutputActionType = SessionServiceAction
    public typealias StateType = SessionServiceState

    private static let logger = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "SessionServicesMiddleware")

    private var output: AnyActionHandler<OutputActionType>? = nil
    
    public init() { }
    
    public func receiveContext(getState: @escaping GetState<StateType>, output: AnyActionHandler<OutputActionType>) {
        self.output = output
    }

    public func handle(
        action: InputActionType,
        from dispatcher: ActionSource,
        afterReducer : inout AfterReducer
    ) {
        // Actions to be handled BEFORE the reducer pipeline gets to mutate the global state.
        switch action {
            case .request(.start):
                output?.dispatch(.status(.valid))
            case .request(.refresh):
                output?.dispatch(.status(.valid))
            case .request(.stop):
                output?.dispatch(.status(.terminated))
            default:
                break
        }
    }
}

// MARK: - REDUCER
extension Reducer where ActionType == SessionServiceAction, StateType == SessionServiceState {
    public static let session = Reducer { action, state in
        var state = state
        switch action {
        case let .status(value):
            state = value
        default: break
        }
        return state
    }
}
